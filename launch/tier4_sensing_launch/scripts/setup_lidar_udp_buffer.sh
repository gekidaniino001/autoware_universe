#!/bin/bash
# Copyright 2024 Autoware Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Setup script to increase UDP receive buffer size for LiDAR packet reception.
#
# LiDAR sensors (Velodyne, Hesai, Robosense, Ouster, etc.) transmit point cloud
# data as a continuous stream of UDP packets. If the OS UDP receive buffer is
# too small, packets can be dropped before the driver processes them, leading
# to missing frames or corrupted point clouds.
#
# This script sets the kernel UDP receive buffer to 25 MB (26214400 bytes),
# which is sufficient for high-bandwidth LiDAR sensors.
#
# Usage:
#   sudo bash setup_lidar_udp_buffer.sh [--persistent]
#
#   --persistent: Also write the settings to /etc/sysctl.d/99-lidar-udp-buffer.conf
#                 so that they persist across reboots.

set -e

UDP_BUFFER_SIZE=26214400  # 25 MB

PERSISTENT=false
for arg in "$@"; do
  case "$arg" in
    --persistent)
      PERSISTENT=true
      ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root (use sudo)." >&2
  exit 1
fi

echo "Setting UDP receive buffer size to ${UDP_BUFFER_SIZE} bytes (25 MB)..."

sysctl -w net.core.rmem_max=${UDP_BUFFER_SIZE}
sysctl -w net.core.rmem_default=${UDP_BUFFER_SIZE}

echo "UDP buffer settings applied:"
echo "  net.core.rmem_max    = $(sysctl -n net.core.rmem_max)"
echo "  net.core.rmem_default = $(sysctl -n net.core.rmem_default)"

if [ "${PERSISTENT}" = true ]; then
  SYSCTL_CONF=/etc/sysctl.d/99-lidar-udp-buffer.conf
  echo "Writing persistent configuration to ${SYSCTL_CONF}..."
  cat > "${SYSCTL_CONF}" <<EOF
# Increase UDP receive buffer size for LiDAR packet reception.
# LiDAR sensors send high-bandwidth UDP streams; a large buffer prevents
# packet drops when the driver cannot read fast enough.
net.core.rmem_max=${UDP_BUFFER_SIZE}
net.core.rmem_default=${UDP_BUFFER_SIZE}
EOF
  echo "Persistent configuration written to ${SYSCTL_CONF}."
  echo "Settings will be applied automatically on next boot."
fi

echo "Done."
