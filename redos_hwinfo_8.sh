#!/bin/bash
###################################################################
#Name		:redos-hwinfo
#Version	:REDOS-8
#Description	:Collecting hardware info
#Author>	:RED-SOFT
#Email		:redos.support@red-soft.ru
###################################################################
SCRIPT_VERSION="REDOS-8"
LOG_FILE="redos-hwinfo_$(date '+%F').log"
IGNORE_ERROR=false

if [ -f $LOG_FILE ]; then
    rm $LOG_FILE
fi

while [ -n "$1" ]
do
case "$1" in
-i) IGNORE_ERROR=true;;
*) ;;
esac
shift
done

runion() {
    printf '%-64s' \ "$1"
    {
        IFS=$'\n' read -r -d '' STDERR;
        IFS=$'\n' read -r -d '' STDOUT;
        IFS=$'\n' read -r -d '' RESCODE;
    } < <((printf '\0%s\0%d\0' "$($2)" "$?" 1>&2) 2>&1)
    JSON_FMT='{"id":"%s","cmd":"%s","ind":"%s","stderr":"%s","stdout":"%s","rescode":"%s"}'
    printf "$JSON_FMT" "$1" "$2" "$3" "$STDERR" "$STDOUT" "$RESCODE" | sed -z 's|\n|\\n|g' | sed 's|\t|     |g' | sed 's|"/|\\"/|g' | sed 's|":\\"/|":"/|g' >> $LOG_FILE
    echo >> $LOG_FILE
    if [ $RESCODE -eq 0 ]; then
        printf '\e[32mOK\e[0m\n'
    else
        printf '\e[31mNO\n%s\e[0m\n' \ "$STDERR"
        if ! $IGNORE_ERROR; then
            exit -1
        fi
    fi
}

cat <<EOT

#####################  REDOS - HARDWARE INFO  #####################
VERSION: $SCRIPT_VERSION
LOG FILE: $LOG_FILE
###################################################################

EOT
runion "DATE" "date"
runion "VERSION" "echo $SCRIPT_VERSION"
##runion "INSTALLING DEPENDECIES" "dnf install -y inxi stress-ng lsscsi p7zip hwinfo hdparm"



runion "BASEBOARD INFO" "dmidecode -t baseboard"
runion "PROCESSOR INFO" "dmidecode -t processor"
runion "MEMORY INFO" "dmidecode -t memory"
runion "DRIVE INFO" "inxi -D"
runion "GRAPHICS INFO" "inxi -G"
runion "AUDIO INFO" "inxi -A"
runion "LSCPU" "lscpu" "1"
runion "STRESS-NG CPU TEST" "stress-ng --cpu 0 -t 90 --metrics-brief" "2"
runion "SENSORS" "sensors " "3"
runion "FREE" "free -h" "4"
runion "DMIDECODE" "dmidecode --type memory" "5"
runion "STRESS-NG RAM TEST" "stress-ng --sequential 0 --class memory --timeout 20s --metrics-brief" "6"
runion "ALL DISK LIST" "echo $(ls -l /dev | grep -E 'sd|hd')" "7"
runion "ALL MOUNTED VOLUME" "df -h" "8"
for j in $(smartctl --scan-open | awk '{print $1}')
do
for i in $(hwinfo --disk | grep -i 'device file: '"$j" | awk -F ': ' '{print $2}')
do
runion "STORAGE SMART" "smartctl --info $i" "9"
runion "DISK SPEED" "hdparm -Tt $i" "10"
done
done
runion "PCI" "lspci" "11"
runion "PCI DRIVERS" "lspci -k" "12"
runion "SCSI" "lsscsi" "13"
runion "USB" "lsusb" "14"
runion "ALL HARDWARE LIST" "inxi -Fxxx" "15"
runion "7ZIP BENCHMARK TEST" "7za b -mm=*" "16"
runion "NETWORK" "mtr -rw -c 3 $(ip route | grep default | awk '{print $3}')" "17"
runion "DMI" "dmidecode" "18"
echo -ne "\nDone! Look at the log file\n"
