
### iptables-helper

Generate deterministic `iptables-restore` rules from a simple(ish) YAML definition of clients, services, and policies.

---

## Overview

This project converts a structured YAML file (`iptables.yaml`) into a ready-to-apply `iptables-restore` configuration. It is designed to:

* Centralize firewall intent in a readable format
* Avoid manual rule management
* Ensure consistent rule generation
* Enforce default-deny behavior per client
* Create an easy-to-update way to manage existing rules (just update a "service" definition and re-run, rather than deleting and updating all rules related to a service)

The script uses custom iptables chains (`INPUT_IPTABLES_HELPER`, `OUTPUT_IPTABLES_HELPER`, `FORWARD_IPTABLES_HELPER`) to allow for easy flushing of all rules created by this script, without disrupting existing rules and chains.

The output is applied using `iptables-restore --noflush`, allowing coexistence with existing rules.

---

## Files

* `iptables-helper.sh`
  Parses YAML and generates `iptables-restore`-compatible output.

* `setup.sh`
  Creates helper chains and attaches them to the main chains.

* `iptables.yaml`
  User-defined configuration (clients, services, policies).

---

## Requirements

* `bash`
* `yq` (v4+)
* `iptables`

---

## Configuration

### Example: `iptables.yaml`

```yaml
clients:
  bryce:
    ip: 10.153.150.4

services:
  mumble:
    match:
      - protocol: udp
        port: 64738
      - protocol: tcp
        port: 64738

policies:
  - client: bryce
    chain: INPUT
    in_interface: wg0
    allow:
      - mumble
```

Example output from above:

```text
*filter
:INPUT_IPTABLES_HELPER - [0:0]

-A INPUT_IPTABLES_HELPER -s 10.153.150.4 -i wg0 -p udp --dport 64738 -j ACCEPT
-A INPUT_IPTABLES_HELPER -s 10.153.150.4 -i wg0 -j DROP

COMMIT
```


### Structure

#### `clients`

* Key: client name
* Value:

  * `ip`: IP address or CIDR

#### `services`

* Key: service name
* Value:

  * `match`: list of protocol/port combinations

#### `policies`

* `client`: references a client
* `chain`: `INPUT`, `OUTPUT`, or `FORWARD`
* `in_interface` (optional)
* `out_interface` (optional)
* `allow`: list of service names

---

## Behavior

For each client:

1. Generate `ACCEPT` rules for explicitly allowed services
2. Append a `DROP` rule per chain (INPUT, OUTPUT, FORWARD)

Rules are isolated in custom chains:

* `INPUT_IPTABLES_HELPER`
* `OUTPUT_IPTABLES_HELPER`
* `FORWARD_IPTABLES_HELPER`

These chains are created and attached to the main chains via `setup.sh`.

---

## Usage

### 1. Initialize chains

```bash
sudo ./setup.sh
```

### 2. Generate rules

```bash
./iptables-helper.sh > output.v4
```

### 3. Apply rules

```bash
# flush chains manually and use --noflush to preserve main chains
# and any chains not managed by this tool
sudo iptables -F INPUT_IPTABLES_HELPER
sudo iptables -F INPUT_IPTABLES_HELPER
sudo iptables -F INPUT_IPTABLES_HELPER
sudo iptables-restore --noflush < output.v4
```

---

## Example Output

```text
*filter
:INPUT_IPTABLES_HELPER - [0:0]

-A INPUT_IPTABLES_HELPER -s 10.153.150.4 -i wg0 -p udp --dport 64738 -j ACCEPT
-A INPUT_IPTABLES_HELPER -s 10.153.150.4 -i wg0 -j DROP

COMMIT
```

---

## Notes

* Rule order is significant: allow rules are inserted before deny rules.
* Default behavior is **deny all unspecified traffic per client**.
* `--noflush` ensures existing unrelated rules are preserved.
* Missing or `null` values in YAML will cause the script to exit with an error.

---

## Limitations

* No support for:

  * Source ports
  * Destination IP filtering
  * Stateful matching beyond basic `iptables` defaults
* Assumes IPv4 (`iptables`, not `ip6tables`)
* Does not deduplicate rules

---

## Future Improvements

* IPv6 support
* Rule deduplication
* Validation schema for YAML
* Optional logging rules
* Service grouping / tagging

---

## Safety

Always validate generated rules before applying:

```bash
iptables-restore --test < output.v4
```

