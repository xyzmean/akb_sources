#!/bin/bash
# by xyzmean

# Экспорт функций
export a1=$(sed -n 2p make.prop)
export a2=$(sed -n 8p make.prop)
export a3=$(sed -n 4p make.prop)
export a4=$(date +"%Y.%m.%d %H:%M")
export a5=$(date +"%d.%m.%Y-%H:%M")
export a6=logb_"$stamp"
export a7=ota_akb_"$stamp"
export a8=$(sed -n 12p make.prop)
export a9=$(sed -n 10p make.prop)
export a10=$(sed -n 14p make.prop)
export a11=$(sed -n 18p make.prop)
export a12=$(sed -n 16p make.prop)
export a13="1"
function exportcm() {
  export ARCH="$arch"
  export TARGET_ARCH="$arch"
  export KBUILD_BUILD_USER="$author"
  export KBUILD_BUILD_HOST="$bh"
}
clear
ver=1.5-nightly
e="\x1b["
c=$e"39;49;00m"
y=$e"93;01m"
cy=$e"96;01m"
r=$e"1;91m"
g=$e"92;01m"
m=$e"95;01m"
conf=$(sed -n 6p make.prop)
arch=$a3
device=$a8
# Вывод тайтла и создание необходимых папок
echo -e "
$cy****************************************************
$cy*           Automatic kernel builder v"$ver"  *
$cy*                   by xyzmean                     *
$cy****************************************************
$y"
sleep 3
set -e
./bin/akb_clean
rm -f gen.info
mkdir out
mkdir out/build
mkdir out/kernel
mkdir out/ota
exportcm
stamp=$(date +"%H:%M:%S %Y.%m.%d")
# Генерация бесполезной херни
echo "generated by fuldaros's script on "$stamp" " >gen.info
# Выбор необходимого дефконфига
cd sources
make O=../out/build/"$device" "$conf"
cd ../
./bin/akb_build
####### script v1.5 (stable)
