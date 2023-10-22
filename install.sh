#!/bin/bash

if [ ${EUID:-${UID}} -ne 0 ]; then
    echo "rootで実行する必要があります。sudo をつけて再実行してください"
    exit
fi

#実行ディレクトリ
dir=`pwd`

#権限
chmod -R 777 LedManager/

echo "前提パッケージをインストールします。"
apt update && apt install python3-dev python3-pillow -y
ret=$?

if [ $ret -ne 0 ]; then
    echo "前提パッケージのインストールに失敗しました。中止します。"
    exit
else
    echo "前提パッケージをインストールしました。"
fi

echo "LED制御ライブラリをインストールします。"
rm -rf /tmp/rpi-rgb-led-matrix
cd /tmp
git clone https://github.com/hzeller/rpi-rgb-led-matrix
ret=$?
if [ $ret -ne 0 ]; then
    echo "LED制御ライブラリをダウンロードできませんでした。中止します。"
    exit
fi
cd /tmp/rpi-rgb-led-matrix
make build-python PYTHON=$(command -v python3)
ret=$?
if [ $ret -ne 0 ]; then
    echo "LED制御ライブラリをインストールできませんでした。中止します。"
    exit
fi
sudo make install-python PYTHON=$(command -v python3)
ret=$?
if [ $ret -ne 0 ]; then
    echo "LED制御ライブラリをインストールできませんでした。中止します。"
    exit
else
    echo "LED制御ライブラリをインストールしました。"
fi
echo "LEDパネルの設定をします。"
cp /boot/config.txt /boot/config.txt.bak
sed -i -e 's/^dtparam=audio=on/#dtparam=audio=on/' /boot/config.txt
while true
do
    echo "LEDパネルの接続方法を選択してください。"
    echo "1: Adafruit製 RGB Matrix HAT + RTC for Raspberry Pi"
    echo "2: Adafruit製 RGB Matrix HAT + RTC for Raspberry Pi 4-18番ピン間接続"
    echo "3: electrodragon製 RGB LED Matrix Panel Drive Board For Raspberry Pi"
    echo -n "選択: "
    read inread
    cd $dir
    if [[ $inread -eq "1" ]]; then
        type=$inread
        sed -i -e "s/##MAPPING_TYPE##/'adafruit-hat'/" ./LedManager/install/options.py
        break
    elif [[ $inread -eq "2" ]]; then
        type=$inread
        sed -i -e "s/##MAPPING_TYPE##/'adafruit-hat-pwm'/" ./LedManager/install/options.py
        break
    elif [[ $inread -eq "3" ]]; then
        type=$inread
        sed -i -e "s/##MAPPING_TYPE##/'regular'/" ./LedManager/install/options.py
        break
    else
        echo "入力に誤りがあります。"
    fi
done



cd /tmp/rpi-rgb-led-matrix/examples-api-use
paneltype="FM6126A"
slowdown="2"
count=0
autorun=1
while true
do
    if [ $count -gt 2 ]; then
        echo "LEDパネルの設定ができませんでした。接続に問題があるか、パネルが非対応の可能性があります。"
        echo "LedManager/options.pyに現在の設定を出力します。設定を変更することで表示できるようになるかもしれません。"
        autorun=0
        break
    fi
    if [ $type -eq "1" ]; then
        ./demo -D 0 --led-rows=32 --led-cols=64 --led-chain=2 --led-brightness=30 --led-slowdown-gpio=$slowdown --led-panel-type=$paneltype --led-gpio-mapping=adafruit-hat --led-no-drop-privs > /dev/null 2>&1 &
    elif [ $type -eq "2" ]; then
        ./demo -D 0 --led-rows=32 --led-cols=64 --led-chain=2 --led-brightness=30 --led-slowdown-gpio=$slowdown --led-panel-type=$paneltype --led-gpio-mapping=adafruit-hat-pwm --led-no-drop-privs > /dev/null 2>&1 &
    else
        ./demo -D 0 --led-rows=32 --led-cols=64 --led-chain=2 --led-brightness=30 --led-slowdown-gpio=$slowdown --led-panel-type=$paneltype --led-no-drop-privs > /dev/null 2>&1 &
    fi
    pid=$!
    echo "LEDパネル表示を確認して、状況を選択ください。"
    echo "1: 虹色の正方形が回転している"
    echo "2: 何かしらの表示が出ているが、1のような状況ではない(ノイズがあるなど)"
    echo "3: まったく表示されない"
    echo -n "選択: "
    read inread
    if [[ $inread -eq "1" ]]; then
        cd $dir
        sed -i -e "s/##PANEL_TYPE##/'$paneltype'/" ./LedManager/install/options.py
        sed -i -e "s/##SLOWDOWN##/$slowdown/" ./LedManager/install/options.py
        echo "LEDパネルの設定が完了しました。LedManager/config.jsonに設定を保存しました。"
        break
    elif [[ $inread -eq "2" ]]; then
        slowdown="4"
    elif [[ $inread -eq "3" ]]; then
        paneltype="FM6127"
    else
        echo "入力に誤りがあります。"
    fi
    kill $pid
    count=$(($count+1))
done
kill $pid

cd $dir
cp ./LedManager/install/options.py ./LedManager/options.py

sed -i -e "s&##PROGRAM_DIR##&'$dir'&" ./LedManager/install/LedManager.sh


rm -rf /tmp/rpi-rgb-led-matrix
ret=$?
if [ $ret -ne 0 ]; then
    echo "インストール一時ファイルを削除できませんでした。"
    echo "/tmp/rpi-rgb-led-matrix を手動で削除してください。"
fi

echo "インストールが完了しました。"
if [ $autorun -eq 1 ]; then
    bash ./modechg.sh
fi