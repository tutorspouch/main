mkdir kernel_workspace && cd kernel_workspace
git config --global user.name "Numbersf"
git config --global user.email "263623064@qq.com"

curl https://storage.googleapis.com/git-repo-downloads/repo > ~/repo
chmod a+x ~/repo
sudo mv ~/repo /usr/local/bin/repo


repo init -u https://github.com/OnePlusOSS/kernel_manifest.git -b oneplus/sm8650 -m oneplus12_v.xml --depth=1
repo sync -c -j"$(nproc)" --force-sync --no-clone-bundle --no-tags

rm -rf ./kernel_platform/common/android/abi_gki_protected_exports_*

 git clone --recursive https://github.com/WildKernels/AnyKernel3 -b non-gki

          mkdir -p out
          start_time=$(date +%s)
          #export PATH="/usr/lib/ccache:$PATH"
          ./build_with_bazel.py \
            -t pineapple gki \
            --jobs="$(nproc --all)" --verbose_failures --config=stamp \
            --user_kmi_symbol_lists=//msm-kernel:android/abi_gki_aarch64_qcom \
            --ignore_missing_projects -o "$(pwd)/out"
          end_time=$(date +%s)
          build_time=$((end_time - start_time))
          echo "Kernel build time: $build_time seconds"


cp /kernel_workspace/kernel_plaform/out/dist/Image AnyKernel3/Image
cd AnyKernel3
ZIP_NAME="Vanilla-OP12.zip"
zip -r "../$ZIP_NAME" ./*




rm -rf ./kernel_platform/msm-kernel/android/abi_gki_protected_exports_*



 git clone --recursive https://github.com/WildKernels/AnyKernel3 -b non-gki



repo init -u https://github.com/OnePlusOSS/kernel_manifest.git -b oneplus/sm8650 -m oneplus12_v.xml
repo sync -j$(nproc)

git clone https://github.com/TheWildJames/kernel_patches.git
git clone https://gitlab.com/simonpunk/susfs4ksu -b gki-android14-6.1 --depth=1 susfs
git clone https://github.com/ShirkNeko/SukiSU_patch.git

rm kernel_workspace/common/android/abi_gki_protected_exports_* || echo "No protected exports!"


cd ~/kernel_workspace/kernel_platform/
KERNEL_REPO=$(pwd)
cd common
curl -LSs "https://raw.githubusercontent.com/ShirkNeko/SukiSU-Ultra/main/kernel/setup.sh" | bash -s susfs-dev
cd ./KernelSU
KSU_VERSION=$(expr $(/usr/bin/git rev-list --count main) + 10606)
export KSU_VERSION
sed -i "s/DKSU_VERSION=12800/DKSU_VERSION=${KSU_VERSION}/" kernel/Makefile
cd ../
rm ~/kernel_workspace/kernel_platform/msm-kernel/android/abi_gki_protected_exports_*
sed -i 's/ -dirty//g' ~/kernel_workspace/kernel_platform/common/scripts/setlocalversion
sed -i 's/ -dirty//g' ~/kernel_workspace/kernel_platform/msm-kernel/scripts/setlocalversion
cd ~/kernel_workspace/susfs
cp ./kernel_patches/50_add_susfs_in_gki-android14-6.1.patch $KERNEL_REPO/common/
cp ./kernel_patches/fs/* $KERNEL_REPO/common/fs/
cp ./kernel_patches/include/linux/* $KERNEL_REPO/common/include/linux/
cd $KERNEL_REPO/common
patch -p1 < 50_add_susfs_in_gki-android14-6.1.patch
cp ../../kernel_patches/69_hide_stuff.patch ./
patch -p1 -F 3 < 69_hide_stuff.patch
cp ../../kernel_patches/hooks/new_hooks.patch ./
patch -p1 -F 3 < new_hooks.patch


cd ../
echo "CONFIG_KSU=y" >> ./common/arch/arm64/configs/gki_defconfig
echo CONFIG_KSU_MANUAL_HOOK=y >> common/arch/arm64/configs/gki_defconfig
echo CONFIG_KSU_SUSFS_SUS_SU=n >> common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KPM=y" >> ./common/arch/arm64/configs/gki_defconfig
echo CONFIG_KALLSYMS=y >> common/arch/arm64/configs/gki_defconfig


echo "CONFIG_KSU_VFS=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=n" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=n" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" >> ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./common/arch/arm64/configs/gki_defconfig
sed -i 's/check_defconfig//' ./common/build.config.gki
sed -i '$s|echo "\$res"|echo "\-Sun-Kim.Jongun"|' ./common/scripts/setlocalversion
sed -i "/stable_scmversion_cmd/s/-maybe-dirty//g" ./build/kernel/kleaf/impl/stamp.bzl
cd ../
./kernel_platform/oplus/build/oplus_build_kernel.sh pineapple gki
