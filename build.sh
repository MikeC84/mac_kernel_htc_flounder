#!/bin/sh

KERNELDIR="/home/michael/android/kernels/flounder/mac_kernel_htc_flounder"
PACKAGES="/home/michael/android/kernels/flounder/package-flounder"
TOOLCHAIN="/home/michael/android/toolchains/android-toolchain-eabi/bin"
ZIMAGE="/home/michael/android/kernels/flounder/mac_kernel_htc_flounder/arch/arm64/boot/Image.gz-dtb"
CROSSARCH="arm64"
CROSSCC="aarch64-linux-android-"
USERCCDIR="/home/michael/.ccache"
DEFCONFIG="mac_defconfig"

ccache() {
	echo "[BUILD]: ccache configuration...";
	###CCACHE CONFIGURATION STARTS HERE, DO NOT MESS WITH IT!!!
	TOOLCHAIN_CCACHE="$TOOLCHAIN/../bin-ccache"
	gototoolchain() {
		echo "[BUILD]: Changing directory to $TOOLCHAIN/../ ...";
		cd $TOOLCHAIN/../
	}

	gotocctoolchain() {
		echo "[BUILD]: Changing directory to $TOOLCHAIN_CCACHE...";
		cd $TOOLCHAIN_CCACHE
	}

	#check ccache configuration
	#if not configured, do that now.
	if [ ! -d "$TOOLCHAIN_CCACHE" ]; then
		echo "[BUILD]: CCACHE: not configured! Doing it now...";
		gototoolchain
		mkdir bin-ccache
		gotocctoolchain
		ln -s $(which ccache) "$CROSSCC""gcc"
		ln -s $(which ccache) "$CROSSCC""g++"
		ln -s $(which ccache) "$CROSSCC""cpp"
		ln -s $(which ccache) "$CROSSCC""c++"
		gototoolchain
		chmod -R 777 bin-ccache
		echo "[BUILD]: CCACHE: Done...";
	fi
	export CCACHE_DIR=$USERCCDIR
	###CCACHE CONFIGURATION ENDS HERE, DO NOT MESS WITH IT!!!
}

compile() {
	echo "[BUILD]: Setting cross compile env vars...";
	export ARCH=$CROSSARCH
	export CROSS_COMPILE=$CROSSCC
	export PATH=$TOOLCHAIN_CCACHE:${PATH}:$TOOLCHAIN

	echo "[BUILD]: Cleaning kernel...";
	make mrproper
	rm $PACKAGES/mac_flounder*.zip
	rm $PACKAGES/kernel/zImage
	rm $ZIMAGE

	echo "[BUILD]: Using defconfig: $DEFCONFIG...";
	make $DEFCONFIG

	echo "[BUILD]: Bulding kernel...";
	make -j`grep 'processor' /proc/cpuinfo | wc -l`
	echo "[BUILD]: Done!...";
}

kernelzip() {
	echo "[BUILD]: Copy zImage to Package"
	cp arch/arm64/boot/Image.gz-dtb $PACKAGES/kernel/zImage

	echo "[BUILD]: Make kernel.zip"
	export curdate=`date "+%m%d%Y"`
	cd $PACKAGES
	zip -r mac_flounder_$curdate.zip .
	cd $KERNELDIR
}

ccache && compile && kernelzip
