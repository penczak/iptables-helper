#!/bin/bash

input_file="iptables.yaml" # TODO take from input?

# store tsv of collected values from yaml policies
rules=()
rules_index=0

# foreach client:
while IFS= read -r client; do
  # get ip or ip mask
  ip=$(yq -r ".clients.$client.ip" "$input_file")

  if [ -z "$ip" ] || [ $ip = "null" ]; then
    echo "ERROR ip not provided in client $client"
    exit 1
  fi

  # get policies mentioning this client
  indices=$(yq ".policies | to_entries | map(select(.value.client == \"$client\")) | .[].key" "$input_file")

  # within each policy, take properties, then find services
  for i in $indices; do
    chain=$(yq -r ".policies[$i].chain" "$input_file")

    in_interface=$(yq -r ".policies[$i].in_interface" "$input_file")
    out_interface=$(yq -r ".policies[$i].out_interface" "$input_file")
    # echo "policy[$i] -> chain=$chain in_interface=$in_interface out_interface=$out_interface"

    if [ -z "$chain" ] || [ $chain = "null" ]; then
      echo "ERROR chain not provided in policy[$i]"
      exit 1
    fi

    # foreach allowed service (from policies section):
    while IFS= read -r service_yaml; do
      service=${service_yaml#- }
      # echo $service
      # get that service's details from the services section & save chain type (from policy)
      match_indices=$(yq -r ".services.$service.match | to_entries | .[].key" "$input_file")

      for j in $match_indices; do
        protocol=$(yq -r ".services.$service.match[$j].protocol" "$input_file")
        port=$(yq -r ".services.$service.match[$j].port" "$input_file")

        # echo "client $client service $service -> protocol=$protocol port=$port"

        rules[rules_index++]="$chain"$'\t'"$ip"$'\t'"$in_interface"$'\t'"$out_interface"$'\t'"$protocol"$'\t'"$port"$'\t'"ACCEPT"$'\t'"${client} allowed access to ${service}:"
      done

    done < <(yq -r ".policies[$i].allow" "$input_file")

  done

  # end with default DROP

  rules[rules_index++]="INPUT"$'\t'"$ip"$'\t'"null"$'\t'"null"$'\t'"null"$'\t'"null"$'\t'"DROP"$'\t'"${client} blocked by default on INPUT:"
  rules[rules_index++]="OUTPUT"$'\t'"$ip"$'\t'"null"$'\t'"null"$'\t'"null"$'\t'"null"$'\t'"DROP"$'\t'"${client} blocked by default on OUTPUT:"
  rules[rules_index++]="FORWARD"$'\t'"$ip"$'\t'"null"$'\t'"null"$'\t'"null"$'\t'"null"$'\t'"DROP"$'\t'"${client} blocked by default on FORWARD:"

done < <(yq -r '.clients | keys[]' "$input_file")

formatted_rules=()
formatted_rules_index=0

for rule in "${rules[@]}"; do
  IFS=$'\t' read -r chain ip in_interface out_interface protocol port jump comment <<< $rule

  if [ -z "$chain" ] || [ $chain = "null" ]; then
    echo "ERROR chain not provided in rule ${rule}"
    exit 1
  fi

  if [ -z "$ip" ] || [ $ip = "null" ]; then
    echo "ERROR ip not provided in rule ${rule}"
    exit 1
  fi

  if [ -z "$jump" ] || [ $jump = "null" ]; then
    echo "ERROR jump not provided in rule ${rule}"
    exit 1
  fi

  in_interface_arg=""
  if [ -n "$in_interface" ] && [ "$in_interface" != "null" ]; then
    in_interface_arg=" -i $in_interface"
  fi

  out_interface_arg=""
  if [ -n "$out_interface" ] && [ "$out_interface" != "null" ]; then
    out_interface_arg=" -o $out_interface"
  fi

  protocol_arg=""
  if [ -n "$protocol" ] && [ "$protocol" != "null" ]; then
    protocol_arg=" -p $protocol"
  fi

  port_arg=""
  if [ -n "$port" ] && [ "$port" != "null" ]; then
    port_arg=" --dport $port"
  fi

  if [ -n "$comment" ] && [ "$comment" != "null" ]; then
    formatted_rules[formatted_rules_index++]="# $comment"
  fi

  formatted_rules[formatted_rules_index++]="-A ${chain}_IPTABLES_HELPER -s ${ip}${in_interface_arg}${out_interface_arg}${protocol_arg}${port_arg} -j ${jump}"
  formatted_rules[formatted_rules_index++]=""

done

output_file=()
output_file+='*filter'$'\n'
output_file+='# define chains'$'\n'
output_file+=':INPUT_IPTABLES_HELPER - [0:0]'$'\n'
output_file+=':FORWARD_IPTABLES_HELPER - [0:0]'$'\n'
output_file+=':OUTPUT_IPTABLES_HELPER - [0:0]'$'\n'
output_file+=''$'\n'

for rule in "${formatted_rules[@]}"; do
  output_file+="$rule"$'\n'
done

output_file+=''$'\n'
output_file+='COMMIT'$'\n'
output_file+='# apply with:'$'\n'
output_file+='# sudo iptables-restore --noflush < thisfile.v4'$'\n'

printf "%s\n" "${output_file[@]}" # > "output.v4"

