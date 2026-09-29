#!/bin/bash

set -e

# Set correct path
export PATH="$(realpath ../../clang-r563880c/bin):$PATH"

which clang
clang --version

export KROOT="$(realpath ../)"

export OUT="${KROOT}/out"

export BUILD_OPTIONS=(
    -C "${KROOT}"
    O="${OUT}"
    -j$(nproc --all)
    ARCH=arm64
    CC=clang
    CROSS_COMPILE=aarch64-linux-gnu-
    LLVM=1
    LLVM_IAS=1
    LD=ld.lld
    AR=llvm-ar
    NM=llvm-nm
    OBJCOPY=llvm-objcopy
    OBJDUMP=llvm-objdump
    STRIP=llvm-strip
)

export KCFLAGS="-Wno-incompatible-function-pointer-types"

# Device to package: bangkk (default), xpeng or tundra
export DEVICE="${DEVICE:-bangkk}"

# This is required, audio will not work otherwise
export TARGET_PRODUCT="${TARGET_PRODUCT:-$DEVICE}"

if [ "$BUILD" = 1 ]; then
  rm -rf "${OUT}"
fi

configure() {
  case "$DEVICE" in
    bangkk)
      make "${BUILD_OPTIONS[@]}" \
            vendor/holi-qgki_defconfig \
            vendor/ext_config/lineage_moto-holi.config \
            vendor/ext_config/moto-holi-bangkk.config
      ;;
    xpeng|tundra)
      make "${BUILD_OPTIONS[@]}" \
            vendor/lahaina-qgki_defconfig \
            vendor/lineage_moto-lahaina.config \
            vendor/lineage_${DEVICE}.config
      ;;
    *)
      echo "Unsupported DEVICE: $DEVICE" >&2
      exit 1
      ;;
  esac
}

build_image() {
  make "${BUILD_OPTIONS[@]}"
}

build_modules() {
  make "${BUILD_OPTIONS[@]}" modules
}

modules_install() {
  rm -rf "${OUT}/modules_install"
  make "${BUILD_OPTIONS[@]}" modules_install INSTALL_MOD_PATH=modules_install
}


make_anykernel() {
  rm -rf {Image,Image.gz,Image.gz-dtb,dtb,dtb.img,dtbo.img,modules,vendor_ramdisk}

  mkdir -p modules/{system,vendor}/lib/modules

  cp "${OUT}/arch/arm64/boot/Image" Image

  # Stage the selected device's module data (bangkk lives in the repo root)
  if [ -d "$DEVICE" ]; then
    cp -f "$DEVICE/no-load.txt" no-load.txt
    cp -f "$DEVICE/modules-load-recovery.txt" modules-load-recovery.txt
    MODS_SRC_DIR="$(ls -d "${OUT}/modules_install/lib/modules"/* | head -1)"
    [ -f "$DEVICE/modules.load" ] && cp -f "$DEVICE/modules.load" "$MODS_SRC_DIR/modules.load"
  fi

  ./place-modules.sh "${OUT}/modules_install/lib/modules"/* modules/vendor/lib/modules "/vendor/lib/modules"

  find modules -name "*.ko" -exec llvm-strip --strip-unneeded -g {} \;

  rm -f "moto-$ZIPPREFIX-anykernel.zip"

  zip -r "moto-$ZIPPREFIX-anykernel.zip" * -x *anykernel.zip place-modules.sh mkdtboimg.py .gitignore .build-placeholder *.txt xpeng/* tundra/*
}


if [ ! -e .build-placeholder ]; then
  echo "Be in anykernel dir"
  exit 1
fi

configure

[ "$BUILD" = 1 ] && (build_image && build_modules && modules_install)

[ "$ANYKERNEL" = 1 ] && make_anykernel


# Build command
# BUILD=1 ANYKERNEL=1 ZIPPREFIX=test ./build.sh
