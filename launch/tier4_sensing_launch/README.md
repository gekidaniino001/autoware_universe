# tier4_sensing_launch

## Structure

![tier4_sensing_launch](./sensing_launch.drawio.svg)

## Package Dependencies

Please see `<exec_depend>` in `package.xml`.

## Usage

You can include as follows in `*.launch.xml` to use `sensing.launch.xml`.

```xml
  <include file="$(find-pkg-share tier4_sensing_launch)/launch/sensing.launch.xml">
    <arg name="launch_driver" value="true"/>
    <arg name="sensor_model" value="$(var sensor_model)"/>
    <arg name="vehicle_param_file" value="$(find-pkg-share $(var vehicle_model)_description)/config/vehicle_info.param.yaml"/>
    <arg name="vehicle_mirror_param_file" value="$(find-pkg-share $(var vehicle_model)_description)/config/mirror.param.yaml"/>
  </include>
```

## Launch Directory Structure

This package finds sensor settings of specified sensor model in `launch`.

```bash
launch/
├── aip_x1 # Sensor model name
│   ├── camera.launch.xml # Camera
│   ├── gnss.launch.xml # GNSS
│   ├── imu.launch.xml # IMU
│   ├── lidar.launch.xml # LiDAR
│   └── pointcloud_preprocessor.launch.py # for preprocessing pointcloud
...
```

## Notes

This package finds settings with variables.

ex.)

```xml
<include file="$(find-pkg-share tier4_sensing_launch)/launch/$(var sensor_model)/lidar.launch.xml">
```

## LiDAR UDP Receive Buffer Setup

LiDAR sensors (Velodyne, Hesai, Robosense, Ouster, etc.) transmit point cloud data as a
continuous stream of UDP packets. If the OS UDP receive buffer is too small, packets can be
dropped before the driver reads them, causing missing frames or corrupted point clouds.

The `net_monitor` node reports this condition as **"UDP Buf Errors"** diagnostics warnings
(`RcvbufErrors` in `/proc/net/snmp`).

### Apply (current session only)

```bash
sudo bash $(ros2 pkg prefix tier4_sensing_launch)/share/tier4_sensing_launch/scripts/setup_lidar_udp_buffer.sh
```

### Apply persistently (survives reboot)

```bash
sudo bash $(ros2 pkg prefix tier4_sensing_launch)/share/tier4_sensing_launch/scripts/setup_lidar_udp_buffer.sh --persistent
```

This writes `/etc/sysctl.d/99-lidar-udp-buffer.conf` which sets both
`net.core.rmem_max` and `net.core.rmem_default` to **25 MB** (26214400 bytes).
