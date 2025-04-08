#!/bin/bash
set -e

# Check if 'builds' folder exists, create it if not
if [ ! -d "./builds" ]; then
    echo "'builds' folder not found. Creating it..."
    mkdir -p ./builds
else
    echo "'builds' folder already exists removing it."
    rm -rf ./builds
    mkdir -p ./builds
fi

# Create the root folder with the current date and time (AM/PM)
cd ./builds
ROOT_DIR="OP12-A15-$(date +'%Y-%m-%d-%I-%M-%p')-release"
echo "Creating root folder $ROOT_DIR..."
mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

# Clone the repositories into the root folder
echo "Cloning repositories..."
git clone https://github.com/TheWildJames/AnyKernel3.git -b android14-5.15
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android14-6.1
git clone https://github.com/TheWildJames/kernel_patches.git

# Get the kernel
echo "Get the kernel..."
mkdir oneplus12_v
cd ./oneplus12_v
repo init -u https://github.com/OnePlusOSS/kernel_manifest.git -b oneplus/sm8650 -m oneplus12_v.xml
repo sync -j$(nproc)

rm -rf ./kernel_platform/common/android/abi_gki_protected_exports_*

# Add KernelSU
echo "adding ksu"
cd ./kernel_platform
curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU/next/kernel/setup.sh" | bash -s next
cd ./KernelSU-Next/kernel
sed -i 's/ccflags-y += -DKSU_VERSION=16/ccflags-y += -DKSU_VERSION=12000/' ./Makefile
cd ../../

#add susfs
echo "adding susfs"
cp ../../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch ./KernelSU-Next/
cp ../../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch ./common/
cp ../../susfs4ksu/kernel_patches/fs/susfs.c ./common/fs/
cp ../../susfs4ksu/kernel_patches/include/linux/susfs.h ./common/include/linux/
cd ./KernelSU-Next/
patch -p1 < 10_enable_susfs_for_ksu.patch
cd ../common
patch -p1 < 50_add_susfs_in_gki-android14-6.1.patch || true
cp ../../kernel_patches/69_hide_stuff.patch ./
patch -p1 -F 3 < 69_hide_stuff.patch || true
cd ..
cp ../kernel_patches/selinux.c_fix.patch ./
patch -p1 -F 3 < selinux.c_fix.patch

cp ../kernel_patches/core_hook.c_fix.patch ./
patch -p1 --fuzz=3 < ./core_hook.c_fix.patch

cp ../kernel_patches/apk_sign.c_fix.patch ./
patch -p1 -F 3 < apk_sign.c_fix.patch


#build Kernel
echo "CONFIG_KSU=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=y" >> ./common/arch/arm64/configs/gki_defconfigig
cd ..
sed -i '2s/check_defconfig//' ./kernel_platform/common/build.config.gki
./kernel_platform/oplus/build/oplus_build_kernel.sh pineapple gki

# Copy Image.lz4
echo "Copying Image"
cp ./out/dist/Image ../AnyKernel3/Image

# Navigate to the AnyKernel3 directory
echo "Navigating to AnyKernel3 directory..."
cd ../AnyKernel3

# Zip the files in the AnyKernel3 directory with a new naming convention
ZIP_NAME="Anykernel3-OP-A15-android14-6.1-KernelSU-SUSFS-$(date +'%Y-%m-%d-%H-%M-%S').zip"
echo "Creating zip file $ZIP_NAME..."
zip -r "../$ZIP_NAME" ./*

# Move back to the root directory (assuming you are already in the correct directory)
cd ..

# GitHub Release using gh CLI
REPO_OWNER="TheWildJames"         # Replace with your GitHub username
REPO_NAME="OnePlus_KernelSU_SUSFS"  # Replace with your repository name
TAG_NAME="v$(date +'%Y.%m.%d-%H%M%S')"   # Unique tag with timestamp to ensure multiple releases on the same day
RELEASE_NAME="OP12 A15 android14-6.1 With KernelSU & SUSFS"  # Updated release name

# Create the release using gh CLI (no need to include $ROOT_DIR)
echo "Creating GitHub release for $RELEASE_NAME..."
gh release create "$TAG_NAME" "$ZIP_NAME" \
  --repo "$REPO_OWNER/$REPO_NAME" \
  --title "$RELEASE_NAME" \
  --notes "Kernel release"

# Final confirmation
echo "GitHub release created and zip file uploaded."
echo "Build and packaging process complete."
