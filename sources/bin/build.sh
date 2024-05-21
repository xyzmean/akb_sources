#!/bin/bash
# by xyzmean

## FUNCTIONS START

# Функция для проверки наличия необходимых инструментов
function check_tools {
  for tool in gcc make 7z; do
    if ! command -v "$tool" > /dev/null; then
      log "ERROR: $tool is not installed." "ERROR"
      exit 1
    fi
  done
}

# Функция для очистки временных файлов
function clean_tmp {
  rm -rf out/build/"$device"/include/generated/compile.h
  rm -f zImage
  rm -f generated.info
  rm -f author.prop
  log "Temporary files removed." "INFO"
}

# Функция для чтения переменных из make.prop
function read_make_prop {
  # Чтение всех переменных за один проход sed
  read -r usr bh arch stampt device cpu imgt loc gcc sha <<< $(sed -n '2p;8p;4p;10p;12p;14p;18p;16p;20p' make.prop)

  # Форматирование даты и времени
  stamp=$(date +"%Y.%m.%d %H:%M")

  # Вычисление остальных переменных
  logb="logb_$stamp"
  otazip="ota_$device_$stamp"
  archp=$(dpkg --print-architecture)
  cpus=$(cat /proc/cpuinfo | grep processor | wc -l)
  th=$(($cpus + 1))
  kernel="$imgt"_"$stamp"

  # Экспортируем переменные
  export usr bh arch stamp stampt logb otazip device cpu imgt loc gcc sha archp cpus th kernel
}

# Функция для вывода информации о сборке
function print_info {
  log "
  Device: $cy$device
  Arch: $cy$arch
  CPU: $cy$cpu
  GCC: $cy$gcc
  Image: $cy$imgt
  Threads: $cy$th" "INFO"
}

# Функция для создания OTA пакета
function make_ota {
  local ota_type="\$1"
  cd out/
  case "$ota_type" in
    "full")
      7z a -tzip "$otazip".zip kernel/"$kernel"
      log "Full OTA package created: $otazip.zip" "INFO"
      ;;
    "incremental")
      # TODO: Реализовать создание incremental OTA пакета
      log "Incremental OTA package creation is not yet implemented." "WARNING"
      ;;
    *)
      log "Invalid OTA type: $ota_type" "ERROR"
      exit 1
      ;;
  esac
  cd ../
}

# Функция для логирования
function log {
  local message="\$1"
  local level="\$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "$timestamp [$level] $message" >> build.log
}

## FUNCTIONS END

# Проверка наличия make.prop
if [ ! -f "make.prop" ]; then
  log "FATAL: make.prop not found!" "ERROR"
  exit 1
fi

# Проверка make.prop на количество строк
ch1=$(sed -n 21p make.prop)
if [ "$ch1" != "" ]; then
  log "FATAL: Bad make.prop" "ERROR"
  exit 1
fi

# Проверка наличия необходимых инструментов
check_tools

# Чтение переменных из make.prop
read_make_prop

# Версия скрипта
ver=1.5-nightly

# Очистка экрана
clear

# Цвета для вывода
e="\x1b["
c=$e"39;49;00m"
y=$e"93;01m"
cy=$e"96;01m"
r=$e"1;91m"
g=$e"92;01m"
m=$e"95;01m"

# Вывод заголовка
log "
  $cy****************************************************
  $cy*       Automatic kernel builder v"$ver"      *
  $cy*                   by xyzmean                     *
  $cy****************************************************
  $y" "INFO"
sleep 3

# Прерывание выполнения при появлении ошибки
set -e

# Тип сборки
if [[ "$sha" != "1" ]]; then
  type="USER"
else
  type="OFFICIAL"
fi

# Вывод информации о сборке
print_info

sleep 4

# Проверка архитектуры
if [[ "$archp" != "amd64" ]]; then
  log "ERROR: Your architecture is not supported. Only amd64 is supported." "ERROR"
  exit 1
fi

# Экспорт переменной CROSS_COMPILE
export CROSS_COMPILE="$PWD"/gcc/bin/"$gcc"

# Переход в директорию sources
cd sources/

# Вывод сообщения о начале сборки
log "Building the kernel..." "INFO"

# Запись времени начала сборки
strt=$(date +"%s")

# Обработка аргументов командной строки
while [[ $# -gt 0 ]]; do
  case "\$1" in
    -o | --optimization)
      optimization="\$2"
      shift 2
      ;;
    -f | --features)
      features="\$2"
      shift 2
      ;;
    -t | --ota-type)
      ota_type="\$2"
      shift 2
      ;;
    *)
      echo "Unknown option: \$1"
      exit 1
      ;;
  esac
done

# Сборка ядра с учетом параметров
make -j"$th" O=../out/build/"$device" "$imgt" \
  "OPTIMIZATION=$optimization" \
  "FEATURES=$features" \
  2>&1 | tee build.log

# Очистка экрана
clear

# Вывод заголовка завершения сборки
log "
$cy****************************************************
$cy*           Automatic kernel builder v"$ver"          *
$cy*                   by xyzmean                    *
$cy****************************************************
$y" "INFO"
log "Build completed!" "INFO"
sleep 3

# Перенос ядра в папку out/kernel
cat ../out/build/"$device"/arch/"$arch"/boot/"$imgt" >../out/kernel/"$kernel"
rm -rf ../out/build/"$device"/arch/"$arch"/boot/
cd ../

# Создание OTA пакета
make_ota "$ota_type"

# Вывод сообщения об очистке временных файлов
log "Cleaning up temporary files..." "INFO"
clean_tmp

# Вывод сообщения о завершении сборки
fnsh=$(date +"%s")
tm=$((fnsh - strt))
log "Build completed in $tm seconds." "INFO"
