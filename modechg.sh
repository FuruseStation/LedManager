#!/bin/bash

echo "起動方法の設定をします。"
while true
do
    echo "起動モードを選択してください。(通常は1)"
    echo "1: CLI起動(LED表示機は自動起動)"
    echo "2: CLI起動(LED表示機は手動起動)" 
    echo "3: GUI起動(LED表示機は手動起動)"
    echo -n "選択: "
    read inread
    if [[ $inread -eq "1" ]]; then
        systemctl set-default multi-user.target
        cp -f ./LedManager/install/autologin.conf /etc/systemd/system/getty@tty1.service.d/
        cp -f ./LedManager/install/LedManager.sh /etc/profile.d/
        
        echo "CLI起動に設定しました。再起動後はデスクトップ画面が使用できなくなります。"
        break
    elif [[ $inread -eq "2" ]]; then
        systemctl set-default multi-user.target
        cp -f /dev/null /etc/systemd/system/getty@tty1.service.d/autologin.conf
        rm -f /etc/profile.d/LedManager.sh
        echo "CLI起動に設定しました。再起動後はデスクトップ画面が使用できなくなります。"
        break
    elif [[ $inread -eq "3" ]]; then
        systemctl set-default graphical.target
        cp -f /dev/null /etc/systemd/system/getty@tty1.service.d/autologin.conf
        rm -f /etc/profile.d/LedManager.sh
        echo "GUI起動に設定しました。"
        break
    else
        echo "入力に誤りがあります。"
    fi
done

echo "起動方法を再設定するには、コマンド `cd $(dirname ${0}) && pwd`/modechg.sh を実行してください。" 
echo "設定完了しました。再起動します。"
sleep 10
reboot