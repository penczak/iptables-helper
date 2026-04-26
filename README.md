
diff after setup.sh
https://diffviewer.vercel.app/v2/diff#H4sIAAAAAAAAA-1XXWuDMBT9K8GnDdrS0q_RN6vZKpMq0bKXQnGaVUFUNGUrY_99Wmu3VleNTWFjCkJpOCf33Jt7c3znXDviJpxgG44HpLm60MFN4LuOuQW8IEBVv12GS48Y4RoTkDxB6BPgBwRE_iY0MTh-LBwRxzOI43sJLqXYrRiuC0C7Hf_wtq82Do-RhX-aJCIGwQBBmdeh2IKazk9lSZtB8YScmEFK3ut2esN-_HY7g_PkCcQKyGQ0GPfvTug2FjVdAjmiE5GiZoBM-lm6CpKGbCWV0NFKytNVkDRiK6mEjlZSnq6CpDFbSSV0tJLydAkoedMZcK-gJx6JLKeAqAiPELUXGkRV58A3WBYQDbJO79U63bXOz4UVUhY64zH9xZ3mHNz0QIhf4p09E0eX1b5Aa2n9TuNpT5EkPkCWYaU6LwxL0BmGdNW7Mhf6oc0ZpzTJCX2PS3Mdojkv14DujwYFkDrRhQk8hMwug7k9dhOTDT_X4sLG6TVOr3F6_9zp7Tp_JalJg0FtNYOySmfLGqv4263iPg1siszebaaMbKJr_GrjVxu_WqX2f8yvFt40uZlxjb2KL8hr7PTDIGRm-F07ko1n7MauXwmddbzgAh2_kfRbIFuKY_HW2EpXPj4BLKaIDREWAAA

diff after iptables-restore --noflush < output.v4
https://diffviewer.vercel.app/v2/diff#H4sIAAAAAAAAA-2Z72uCQBjH_5XDVxvUKGo1euf0tskkRY29CYazWwmiohdbjP3v87KCsh-ePo4xThCi4_ne8328e-6TfUnBIpVGkrJw_RBpY3PioKs4CnxvhWRFwaZzPU2mIXWTOaGIXXESURTFFKXRMvEI2r9mJKV-6FI_CllcLrEecYMAoXY7-xCuPhYk2Y88-qVHU-pSgiysyw5WW9h25Htds5-weiBOvTgX73Zuure97O7c9M-Ls5BZTEeD_rB3dyC3nHHLsZA9OdUyzG3A1vpZuRKWbmEtXZDjtVSUK2FpAGvpghyvpaJcCUtDWEsX5HgtFeVY0Hrnv2om22DYfn3CuomtspuWCbA7byIPhvUiWypkG1EN5Rlb7YnNl9MmbJsQT2SVzVtpe1RagJUe8aYMMA_ZmDjAR0WuCJNd_uDRVRcl5D0bDT2S1luARwrOnU_73tLURwyZVu6zZlqKA5hSoyd-IfVdrwEuKasJf6PRxg62xrJeIXSzNDgCuQt9tIC7lOEqWJhj3bab0D_V0ZqY6_gB2cRMJxohzFRSS0oE8AvgF8AvgF8AvwB-AfwnFqAA_r9w4gvgF8D_q8D_H8-B3_sRA0zUwLxfF9AhiBqY9-sCOgRRA_N-XUCHIGpg3q-5axt9IfAfm57UYv9q6u4bCaSRZCT-PDMbIId80vz9x3Yoq284J7N85PsHI3j-0QwdAAA

need to run per chain before applying to reset chain:
sudo iptables -F INPUT_IPTABLES_HELPER
sudo iptables -F FORWARD_IPTABLES_HELPER
sudo iptables -F OUTPUT_IPTABLES_HELPER


### example output
*filter
# define (or redefine) only your chains
:INPUT_CLIENT_FRIEND1 - [0:0]
:FORWARD_CLIENT_FRIEND1 - [0:0]

# ensure jump hooks exist (make sure not to duplicate? it currently will duplicate)
-A {chaintype} -s {clientipmask} -j {chaintype}_CLIENT_{clientname}
-A FORWARD -s 10.153.150.4/32 -j FORWARD_CLIENT_FRIEND1

# your generated rules live only here
-A INPUT_CLIENT_BRYCE -p tcp --dport 64738 -j ACCEPT

COMMIT
# apply:
# MAKE SURE TO INCLUDE --noflush
# sudo iptables-restore --noflush < rules.v4

*filter
# define (or redefine) only your chains
:INPUT_CLIENT_FRIEND1 - [0:0]
:FORWARD_CLIENT_FRIEND1 - [0:0]

# ensure jump hooks exist (make sure not to duplicate? it currently will duplicate)
-A {chaintype} -s {clientipmask} -j {chaintype}_CLIENT_{clientname}
-A FORWARD -s 10.153.150.4/32 -j FORWARD_CLIENT_FRIEND1

# your generated rules live only here
-A INPUT_CLIENT_BRYCE -p tcp --dport 64738 -j ACCEPT

COMMIT
# apply:
# MAKE SURE TO INCLUDE --noflush
# sudo iptables-restore --noflush < rules.v4
