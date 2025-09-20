#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

QEMU_DIR="${QEMU_DIR:-}"
if [ -z "${QEMU_DIR}" ]; then
  QEMU_DIR="${SCRIPT_DIR}/qemu"
fi
if [ ! -d "$QEMU_DIR" ]; then
  mkdir -p "$QEMU_DIR"
fi

OVMF_DIR="${QEMU_DIR}/ovmf"
if [ ! -d "$OVMF_DIR" ]; then
  mkdir -p "$OVMF_DIR"
fi

if [ ! -d "${SCRIPT_DIR}/result-fd" ]; then
  echo "Please run 'nix build nixpkgs#OVMF.fd' first"
  exit 1
fi

if [ ! -f "${SCRIPT_DIR}/result/nixos.img" ]; then
  echo "Please build the nixos image first"
  echo "ex: nix build .#packages.x86_64-linux.hala"
  exit 1
fi

  echo "Copying files to $QEMU_DIR"
  cp -r "${SCRIPT_DIR}/result-fd/FV/OVMF_CODE.fd" "$OVMF_DIR/OVMF_CODE.fd"
  cp -r "${SCRIPT_DIR}/result-fd/FV/OVMF_VARS.fd" "$OVMF_DIR/OVMF_VARS.fd"
  cp -r "${SCRIPT_DIR}/result/nixos.img" "$QEMU_DIR/nixos.img"

sudo chown -R ${USER}:users "$QEMU_DIR"
sudo chmod -R 0766 "$QEMU_DIR"

IMG=${QEMU_DIR}/nixos.img
OVMF_CODE=${OVMF_DIR}/OVMF_CODE.fd
OVMF_VARS=${OVMF_DIR}/OVMF_VARS.fd

#qemu-system-x86_64 \
#  -enable-kvm -cpu host -smp 4 -m 4096 \
#  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
#  -drive if=pflash,format=raw,file=$OVMF_VARS \
#  -drive file="$IMG",if=virtio,format=raw \
#  -device virtio-net-pci,netdev=n0 \
#  -netdev user,id=n0,hostfwd=tcp::2222-:22 \
#  -display gtk -device virtio-vga \
#  -serial mon:stdio

qemu-system-x86_64 \
  -drive file=$IMG,format=raw,if=virtio \
  -m 8G \
  -enable-kvm \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0
