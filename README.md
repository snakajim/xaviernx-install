# xaviernx-install
nvidia jetson xavier nx install tips

## How to set clock config to CPU centric(=max) mode

See manual at

- https://docs.nvidia.com/jetson/l4t/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/clocks.html#wwpID0E05F0HA

Set GPU clock to the lowest to reserve power to CPU.

```
sudo /usr/bin/jetson_clocks --show
sudo /usr/bin/jetson_clocks --store 
cd /sys/devices/gpu.0/devfreq/17000000.gv11b
cat available_frequencies
sudo sh -c "echo 114750000 > max_freq"
cd /sys/devices/17000000.gv11b/devfreq/17000000.gv11b
cat available_frequencies
sudo sh -c "echo 114750000 > max_freq"
```

Then set max mode in CPU,

```
sudo /usr/bin/jetson_clocks
sudo /usr/sbin/nvpmodel -d cool
sudo /usr/sbin/nvpmodel -q
```

To restore previous setting,

```
sudo /usr/bin/jetson_clocks --restore
cd /sys/devices/gpu.0/devfreq/17000000.gv11b
sudo sh -c "echo 1109250000 > max_freq"
cd /sys/devices/17000000.gv11b/devfreq/17000000.gv11b
sudo sh -c "echo 1109250000 > max_freq"
sudo /usr/bin/jetson_clocks.sh --show
```

##  Install Arm Compute Library(v20.11) on aarch64 linux

|env     | tool chain                           | user time(min) | ratio |
|--------|--------------------------------------|----------------|-------|
|native-odroidhc4 Ubuntu20.04 | gcc-8 + ld      | 288            |1.00   |
|native-RPi4-4G Ubuntu20.04   | gcc-8 + ld      | 237            |0.82   |
|native-KhadasVIM3-Pro Ubuntu20.04 | gcc-8 + lld-11| 198        |0.68   |
|native-Xavier-NX-max Ubuntu18.04  | gcc-8 + lld-12|            |   |


##  Install LLVM-1200 on aarch64 linux

|mode    | tool chain                           | user time(min) | ratio |
|--------|--------------------------------------|----------------|-------|
| max    | gcc-7 + ld                           |            |1.00   |

