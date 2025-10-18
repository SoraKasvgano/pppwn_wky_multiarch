#!/bin/bash

# 创建目标目录（如果不存在）
sudo mkdir -p /boot/firmware/PPPwn

# 拷贝当前脚本所在目录下的所有文件到目标目录
# 获取当前脚本所在目录的绝对路径
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
sudo cp -r "$SCRIPT_DIR"/* /boot/firmware/PPPwn/

while true; do
read -p "$(printf '\r\n\r\n\033[36mDo you want the Wanyun device to connect to the internet after PPPwn? (Y|N):\033[0m ')" pppq
case $pppq in
[Yy]* )
sudo apt install dnsmasq -y
echo 'bogus-priv
expand-hosts
domain-needed
server=8.8.8.8
listen-address=127.0.0.1
port=5353
conf-file=/etc/dnsmasq.more.conf' | sudo tee /etc/dnsmasq.conf
echo 'address=/playstation.com/127.0.0.1
address=/playstation.net/127.0.0.1
address=/playstation.org/127.0.0.1
address=/akadns.net/127.0.0.1
address=/akamai.net/127.0.0.1
address=/akamaiedge.net/127.0.0.1
address=/edgekey.net/127.0.0.1
address=/edgesuite.net/127.0.0.1
address=/llnwd.net/127.0.0.1
address=/scea.com/127.0.0.1
address=/sonyentertainmentnetwork.com/127.0.0.1
address=/ribob01.net/127.0.0.1
address=/cddbp.net/127.0.0.1
address=/nintendo.net/127.0.0.1
address=/ea.com/127.0.0.1' | sudo tee /etc/dnsmasq.more.conf
sudo systemctl restart dnsmasq
echo 'auth
lcp-echo-failure 3
lcp-echo-interval 60
mtu 1482
mru 1482
require-pap
ms-dns 192.168.233.1
netmask 255.255.255.0
defaultroute
noipdefault
usepeerdns' | sudo tee /etc/ppp/pppoe-server-options
while true; do
read -p "$(printf '\r\n\r\n\033[36mDo you want to set a custom PPPoE username and password?\r\nIf you choose "No", the following defaults will be used:\r\n\r\nUsername: \033[33mppp\r\n\033[36mPassword: \033[33mppp\r\n\r\n\033[36m(Y|N)?: \033[0m')" wapset
case $wapset in
[Yy]* ) 
while true; do
read -p "$(printf '\033[33mEnter Username: \033[0m')" PPPU
case $PPPU in
"" ) 
 echo -e '\033[31mCannot be empty!\033[0m';;
 * )  
if grep -q '^[0-9a-zA-Z_ -]*$' <<<$PPPU ; then 
if [ ${#PPPU} -le 1 ]  || [ ${#PPPU} -ge 33 ] ; then
echo -e '\033[31mUsername must be between 2 and 32 characters long\033[0m';
else 
break;
fi
else 
echo -e '\033[31mUsername can only contain alphanumeric characters, underscores, spaces, or hyphens\033[0m';
fi
esac
done
while true; do
read -p "$(printf '\033[33mEnter password: \033[0m')" PPPW
case $PPPW in
"" ) 
 echo -e '\033[31mCannot be empty!\033[0m';;
 * )  
if [ ${#PPPW} -le 1 ]  || [ ${#PPPW} -ge 33 ] ; then
echo -e '\033[31mPassword must be between 2 and 32 characters long\033[0m';
else 
break;
fi
esac
done
echo -e '\033[36mUsing custom settings:\r\n\r\nUsername: \033[33m'$PPPU'\r\n\033[36mPassword: \033[33m'$PPPW'\r\n\r\n\033[0m'
break;;
[Nn]* ) 
echo -e '\033[36mUsing default settings:\r\n\r\nUsername: \033[33mppp\r\n\033[36mPassword: \033[33mppp\r\n\r\n\033[0m'
 PPPU="ppp"
 PPPW="ppp"
break;;
* ) echo -e '\033[31mPlease enter Y or N\033[0m';;
esac
done
echo '"'$PPPU'"  *  "'$PPPW'"  192.168.233.2' | sudo tee /etc/ppp/pap-secrets
INET="true"
SHTDN="false"
echo -e '\033[32mPPPoE installed successfully\033[0m'
break;;
[Nn]* ) 
echo -e '\033[35mSkipping PPPoE installation\033[0m'
INET="false"
while true; do
read -p "$(printf '\r\n\r\n\033[36mDo you want the Wanyun device to shut down automatically after PPPwn succeeds?\r\n\r\n\033[36m(Y|N)?: \033[0m')" pisht
case $pisht in
[Yy]* ) 
SHTDN="true"
echo -e '\033[32mOK! The device will shut down automatically after PPPwn completes.\033[0m'
break;;
[Nn]* ) 
echo -e '\033[35mAlright, the device will not shut down automatically.\033[0m'
SHTDN="false"
break;;
* ) echo -e '\033[31mPlease enter Y or N\033[0m';;
esac
done
break;;
* ) echo -e '\033[31mPlease enter Y or N\033[0m';;
esac
done


while true; do
read -p "$(printf '\r\n\r\n\033[36mWould you like to use the older Python version of PPPwn? It runs significantly slower.\r\n\r\n\033[36m(Y|N)?: \033[0m')" cppp
case $cppp in
[Yy]* ) 
UCPP="false"
sudo apt install python3 python3-scapy -y
echo -e '\033[32mUsing the Python version of PPPwn\033[0m'
break;;
[Nn]* ) 
echo -e '\033[35mUsing the C++ version of PPPwn\033[0m'
UCPP="true"
break;;
* ) echo -e '\033[31mPlease enter Y or N\033[0m';;
esac
done

while true; do
read -p "$(printf '\r\n\r\n\033[36mDo you want to change the PS4 firmware version? Default is 10.01.\r\n\r\n\033[36m(Y|N)?: \033[0m')" fwset
case $fwset in
[Yy]* ) 
while true; do
read -p "$(printf '\033[33mEnter firmware version [11.00 | 10.71 | 10.70 | 10.50 | 10.01 | 10.00 | 9.60 | 9.00]: \033[0m')" FWV
case $FWV in
"" ) 
 echo -e '\033[31mCannot be empty!\033[0m';;
 * )  
if grep -q '^[0-9.]*$' <<<$FWV ; then 
if [[ ! "$FWV" =~ ^("11.00"|"10.71"|"10.70"|"10.50"|"10.01"|"10.00"|"9.60"|"9.00")$ ]]  ; then
echo -e '\033[31mFirmware version must be one of: 11.00, 10.71, 10.70, 10.50, 10.01, 10.00, 9.60, or 9.00\033[0m';
else 
break;
fi
else 
echo -e '\033[31mVersion can only contain numbers and dots\033[0m';
fi
esac
done
echo -e '\033[32mYou are using firmware version '$FWV'\033[0m'
break;;
[Nn]* ) 
echo -e '\033[35mUsing default firmware version: 10.01\033[0m'
FWV="10.01"
break;;
* ) echo -e '\033[31mPlease enter Y or N\033[0m';;
esac
done

ip link

while true; do
read -p "$(printf '\r\n\r\n\033[36mDo you want to change the LAN interface for Wanyun? Default is eth0.\r\n\r\n\033[36m(Y|N)?: \033[0m')" ifset
case $ifset in
[Yy]* ) 
while true; do
read -p "$(printf '\033[33mEnter interface name: \033[0m')" IFCE
case $IFCE in
"" ) 
 echo -e '\033[31mCannot be empty!\033[0m';;
 * )  
if grep -q '^[0-9a-zA-Z_ -]*$' <<<$IFCE ; then 
if [ ${#IFCE} -le 1 ]  || [ ${#IFCE} -ge 17 ] ; then
echo -e '\033[31mInterface name must be between 2 and 16 characters long\033[0m';
else 
break;
fi
else 
echo -e '\033[31mInterface name can only contain alphanumeric characters, underscores, spaces, or hyphens\033[0m';
fi
esac
done
echo -e '\033[32mYou are using interface '$IFCE'\033[0m'
break;;
[Nn]* ) 
echo -e '\033[35mUsing default interface: eth0\033[0m'
IFCE="eth0"
break;;
* ) echo -e '\033[31mPlease enter Y or N\033[0m';;
esac
done

VUSB="false"
DTLINK="false"
echo '#!/bin/bash
INTERFACE="'$IFCE'" 
FIRMWAREVERSION="'$FWV'" 
SHUTDOWN='$SHTDN'
USECPP='$UCPP'
PPPOECONN='$INET'
DTLINK='$DTLINK'
PPDBG=true
TIMEOUT="1m"
VMUSB=false'  | sudo tee /boot/firmware/PPPwn/config.sh >/dev/null 2>&1 &

sudo rm /usr/lib/systemd/system/bluetooth.target >/dev/null 2>&1 &
sudo rm /usr/lib/systemd/system/network-online.target >/dev/null 2>&1 &
sudo sed -i 's^sudo bash /boot/firmware/PPPwn/run.sh \&^^g' /etc/rc.local

echo '[Service]
WorkingDirectory=/boot/firmware/PPPwn
ExecStart=/boot/firmware/PPPwn/run.sh
Restart=never
User=root
Group=root
Environment=NODE_ENV=production
[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/wkypwn.service >/dev/null 2>&1 &

sudo chmod u+rwx /etc/systemd/system/wkypwn.service
sudo systemctl enable wkypwn
sudo systemctl start wkypwn

echo -e '\033[36mInstallation complete,\033[33m rebooting now...\033[0m'
sudo reboot