#!/bin/bash
echo_color() {

    local backcolor
    local textcolor
    local decotypes
    local echo_opts
    local arg
    local OPTIND
    local OPT

    echo_opts="-e"

    while getopts 'b:t:d:n' arg; do
        case "${arg}" in
            b) backcolor="${OPTARG}" ;;
            t) textcolor="${OPTARG}" ;;
            d) decotypes="${OPTARG}" ;;
            n) echo_opts="-n -e"     ;;
        esac
    done

    shift $((OPTIND - 1))

    case "${backcolor}" in
        "black"   | "Black"   ) backcolor="40" ;;
        "Red"     | "red"     ) backcolor="41" ;;
        "Green"   | "green"   ) backcolor="42" ;;
        "Yellow"  | "yellow"  ) backcolor="43" ;;
        "Blue"    | "blue"    ) backcolor="44" ;;
        "Maganta" | "maganta" ) backcolor="45" ;;
        "Cyan"    | "cyan"    ) backcolor="46" ;;
        "White"   | "white"   ) backcolor="47" ;;
        "40" | "41" | "42" | "43" | "44" | "45" | "46" | "47" ) : ;;
    esac

    case "${textcolor}" in
        "black"   | "Black"   ) textcolor="30" ;;
        "Red"     | "red"     ) textcolor="31" ;;
        "Green"   | "green"   ) textcolor="32" ;;
        "Yellow"  | "yellow"  ) textcolor="33" ;;
        "Blue"    | "blue"    ) textcolor="34" ;;
        "Maganta" | "maganta" ) textcolor="35" ;;
        "Cyan"    | "cyan"    ) textcolor="36" ;;
        "White"   | "white"   ) textcolor="37" ;;
        "30" | "31" | "32" | "33" | "34" | "35" | "36" | "37" ) : ;;
    esac


    echo ${echo_opts} "\e[$([[ -v backcolor ]] && echo -n "${backcolor}"; [[ -v textcolor ]] && echo -n ";${textcolor}"; [[ -v decotypes ]] && echo -n ";${decotypes}")m${@}\e[m"
}
clear
echo "クリーンアップしています..."
echo ""
sudo umount /media/bootpart
sudo umount /media/winpart
sudo rm -rf /media/winpart
sudo rm -rf /media/bootpart
echo "完了"
clear
cd /tmp
echo "このスクリプトではWindows on ArmPEインストーラのセットアップを行います。"
echo "こちらのサイトから最新版のファイルをダウンロードしてください。"
echo "WindowsPEベースインストーラ本体： https://worproject.com/downloads#windows-on-raspberry-pe-based-installer"
echo "Raspberry PiのハードウェアのWindows向けドライバ： https://github.com/worproject/RPi-Windows-Drivers/releases"
echo "Raspberry Pi向けUEFIファームウェアイメージ： https://github.com/pftf/RPi4/releases"
echo -n "Raspberry Piのブートローダを更新するために "
echo_color -t red -d 4 -n "sudo rpi-eeprom-update -a"
echo " をお使いのRaspberry Piで実行しておいてください。"
echo "WindowsのARM64版ISOファイル： https://www.xiuxitong.com/uup/?lang=ja-jp"
lsblk
read -p "上記のデバイスの中から目当てのデバイスを決めて文頭に /dev/をつけて入力してください： " wordevname
echo $wordevname
read -p "続行すると選択したデバイスの全てのデータが消えます。それでもいい場合はEnterを、ここで止める場合はCtrl + Cを押して下さい。"
read -p "ISOファイルのパスを入力してください。： " isops
read -p "WindowsPEベースインストーラ本体のパスを入力してください： " peinps
read -p "Raspberry PiのハードウェアのWindows向けドライバのパスを入力してください： " wordrps
read -p "Raspberry Pi向けUEFIファームウェアイメージのパスを入力してください： " uefips
sudo umount $wordevname"1"
sudo umount $wordevname"2"
sudo umount $wordevname"3"
sudo umount $wordevname"4"
echo "デバイスにGPTパーティションテーブルを適用しています..."
echo ""
sudo parted -s $wordevname mklabel gpt
echo "フォーマット完了"
echo ""
echo "ブートローダパーティションを作成しています..."
echo ""
sudo parted -s $wordevname mkpart primary 1MB 1000MB
sudo parted -s $wordevname set 1 msftdata on
echo "作成完了"
echo ""
echo "インストーラパーティションを作成しています..."
echo ""
sudo parted -s $wordevname mkpart primary 1000MB 7000MB
sudo parted -s $wordevname set 2 msftdata on
echo "作成完了"
echo ""
echo "ブートローダのパーティションをFAT32でフォーマットしています..."
sudo mkfs.fat -F 32 $wordevname"1"
echo "完了"
echo ""
echo "インストーラのパーティションをNTFSでフォーマットしています..."
sudo mkfs.ntfs -f $wordevname"2"
echo "完了"
echo ""
echo "パーティションをマウントしています..."
echo ""
sudo mkdir -p /media/bootpart /media/winpart
sudo mount $wordevname"1" /media/bootpart
sudo mount $wordevname"2" /media/winpart
echo "完了"
echo ""
echo "ISOファイルをマウントしています..."
mkdir -p isomount
sudo mount $isops isomount
echo "完了"
echo ""
echo "ISOファイルのデータコピー"
echo "boot"
sudo cp -r isomount/boot /media/bootpart
echo "efi"
sudo cp -r isomount/efi /media/bootpart
echo "mkdir sources"
sudo mkdir /media/bootpart/sources
echo "boot.wimをコピーしています...（※少し時間がかかります）"
sudo cp isomount/sources/boot.wim /media/bootpart/sources
echo -n "install.wimをコピーしています...（"
echo_color -t red -d 1 -n "※まぁまぁ時間がかかるので気長に待ってください。"
echo "）"
sudo cp isomount/sources/install.wim /media/winpart
echo "コピー完了"
echo ""
echo "ISOファイルのアンマウントをしています..."
sudo umount isomount
echo "完了"
echo ""
echo "必要なファイル類を展開しています..."
unzip $peinps -d peinstaller
sudo cp -r peinstaller/efi /media/bootpart
sudo wimupdate /media/bootpart/sources/boot.wim 2 --command="add peinstaller/winpe/2 /"
unzip $wordrps -d driverpackage
sudo wimupdate /media/bootpart/sources/boot.wim 2 --command="add driverpackage /drivers"
unzip $uefips -d uefipackage
sudo cp uefipackage/* /media/bootpart
echo "完了"
echo ""
echo "不要なファイルを削除しています..."
rm -rf isomount peinstaller driverpackage uefipackage
echo "完了"
echo ""
echo "インストーラデバイスのアンマウントをしています..."
sudo umount /media/bootpart
sudo umount /media/winpart
sudo rm -rf /media/winpart
sudo rm -rf /media/bootpart
echo "完了"
echo ""
cd -
echo "インストーラ作成完了"
