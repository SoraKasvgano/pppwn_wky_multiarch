#!/bin/bash
VERSION=2.0

# 加载配置文件（若存在）
if [ -f "/boot/firmware/PPPwn/config.sh" ]; then
    source "/boot/firmware/PPPwn/config.sh"
fi

# 初始化默认变量（带引号避免空格问题）
if [ -z "$INTERFACE" ]; then INTERFACE="eth0"; fi
if [ -z "$FIRMWAREVERSION" ]; then FIRMWAREVERSION="10.01"; fi
if [ -z "$SHUTDOWN" ]; then SHUTDOWN=true; fi
if [ -z "$PPPOECONN" ]; then PPPOECONN=false; fi
if [ -z "$VMUSB" ]; then VMUSB=false; fi
if [ -z "$PPDBG" ]; then PPDBG=false; fi
if [ -z "$TIMEOUT" ]; then TIMEOUT="1m"; fi

# 读取设备型号（兼容非嵌入式系统）
WKYTYP=$(tr -d '\0' </proc/device-tree/model 2>/dev/null)

# 初始默认值（不覆盖配置文件中的VMUSB）
CPPBIN=""

# 1. 优先根据设备型号适配
case "$WKYTYP" in
    *"Xunlei OneCloud"*)
        CPPBIN="pppwn11"
        read -t 15 || true  # 简化等待逻辑
        ;;
    *"Raspberry Pi Zero"*)
        CPPBIN="pppwnpizero"
        read -t 5 || true
        ;;
    *)
        ;;
esac

# 2. 根据CPU架构判断（未匹配型号时）
if [ -z "$CPPBIN" ]; then
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            CPPBIN="pppwnx8664"
            ;;
        aarch64)
            CPPBIN="pppwnarm64"
            ;;
        mips)
            CPPBIN="pppwnmips"
            ;;
        mipsel)
            CPPBIN="pppwnmipsel"
            ;;
        armv6l)
            CPPBIN="pppwnpizero"
            ;;
        armv7l)
            CPPBIN="pppwn7"
            ;;
        *)
            echo "警告：未识别的架构 $ARCH，使用默认arm32位版本" >&2
            CPPBIN="pppwn7"
            ;;
    esac
    read -t 5 || true
fi

# 3. 最终校验（确保变量有值）
if [ -z "$CPPBIN" ]; then
    CPPBIN="pppwn7"
fi

# 检查核心可执行文件是否存在
if [ ! -f "/boot/firmware/PPPwn/$CPPBIN" ]; then
    echo -e "\033[31m错误：未找到可执行文件 /boot/firmware/PPPwn/$CPPBIN\033[0m" | sudo tee /dev/tty1
    exit 1
fi

# 输出程序标识
echo -e "\n\n\033[36m _____  _____  _____
|  __ \\|  __ \\|  __ \\
| |__) | |__) | |__) |_      ___ __
|  ___/|  ___/|  ___/\\ \\ /\\ / / '_ \\
| |    | |    | |     \\ V  V /| | | |
|_|    |_|    |_|      \\_/\\_/ |_| |_|\033[0m
\n\033[33mhttps://github.com/Mintneko/WKY-Pwn\033[0m\n" | sudo tee /dev/tty1
echo -e "\033[92mVersion $VERSION \033[0m" | sudo tee /dev/tty1

# 停止pppoe服务
sudo systemctl stop pppoe >/dev/null 2>&1 &

# 配置网络接口
if [ "$VMUSB" = true ]; then
    echo "USB waiting....."
    read -t 3 || true
    sudo ip link set "$INTERFACE" up
else
    sudo ip link set "$INTERFACE" down
    read -t 5 || true
    sudo ip link set "$INTERFACE" up
fi

# 输出设备信息
echo -e "\n\033[36m$WKYTYP\033[92m\nFirmware:\033[93m $FIRMWAREVERSION\033[92m\nInterface:\033[93m $INTERFACE\033[0m" | sudo tee /dev/tty1
echo -e "\033[92mPPPwn:\033[93m C++ $CPPBIN \033[0m" | sudo tee /dev/tty1

# 配置USB驱动（VMUSB模式）
if [ "$VMUSB" = true ]; then
    sudo rmmod g_mass_storage 2>/dev/null
    FOUND=0
    UDEV=""
    # 查找payloads目录所在的设备
    if [ -d "/media/pwndrives" ]; then
        readarray -t rdirarr < <(sudo ls -1 "/media/pwndrives" 2>/dev/null)
        for rdir in "${rdirarr[@]}"; do
            pdir_path="/media/pwndrives/${rdir}"
            if [ -d "$pdir_path" ]; then
                readarray -t pdirarr < <(sudo ls -1 "$pdir_path" 2>/dev/null)
                for pdir in "${pdirarr[@]}"; do
                    if [[ "${pdir,,}" == "payloads" ]]; then
                        FOUND=1
                        UDEV="/dev/${rdir}"
                        break 2  # 跳出双层循环
                    fi
                done
            fi
        done
    fi
    # 加载USB存储模块
    if [ -n "$UDEV" ]; then
        sudo modprobe g_mass_storage file="$UDEV" stall=0 ro=0 removable=1
    fi
    echo -e "\033[92mUSB Drive:\033[93m Enabled\033[0m" | sudo tee /dev/tty1
fi

# 输出网络访问状态
if [ "$PPPOECONN" = true ]; then
    echo -e "\033[92mInternet Access:\033[93m Enabled\033[0m" | sudo tee /dev/tty1
else
    echo -e "\033[92mInternet Access:\033[93m Disabled\033[0m" | sudo tee /dev/tty1
fi

# 清理旧日志
if [ -f "/boot/firmware/PPPwn/pwn.log" ]; then
    sudo rm -f "/boot/firmware/PPPwn/pwn.log"
fi

# 等待网络链路连接
if ! ethtool "$INTERFACE" 2>/dev/null | grep -q "Link detected: yes"; then
    echo -e "\033[31mWaiting for link\033[0m" | sudo tee /dev/tty1
    while ! ethtool "$INTERFACE" 2>/dev/null | grep -q "Link detected: yes"; do
        read -t 2 || true
    done
    echo -e "\033[32mLink found\033[0m\n" | sudo tee /dev/tty1
fi

# 获取并输出IP地址（兼容更多系统）
WKYIP=$(ip -4 addr show "$INTERFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
if [ -n "$WKYIP" ]; then
    echo -e "\n\033[92mIP: \033[93m $WKYIP\033[0m" | sudo tee /dev/tty1
fi

echo -e "\n\033[95mReady for console connection\033[0m\n" | sudo tee /dev/tty1

# 主循环：执行pppwn并处理结果
while true; do
    # 实时读取调试配置
    if [ -f "/boot/firmware/PPPwn/config.sh" ]; then
        if grep -Fxq "PPDBG=true" "/boot/firmware/PPPwn/config.sh"; then
            PPDBG=true
        else
            PPDBG=false
        fi
    fi

    # 匹配固件版本
case "$FIRMWAREVERSION" in
    "10.00" | "10.01" | "9.00" | "9.60" | "10.50" | "10.70" | "10.71" | "11.00")
        STAGEVER="$FIRMWAREVERSION"  # 直接复用输入值
        ;;
    *)
        STAGEVER="10.01"  # 默认值
        ;;
esac

    # 执行pppwn并处理输出
    while read -r stdo; do
        # 调试日志输出
        if [ "$PPDBG" = true ]; then
            echo -e "$stdo" | sudo tee /dev/tty1 /dev/pts/* 2>/dev/null | sudo tee -a "/boot/firmware/PPPwn/pwn.log" >/dev/null
        fi
        # 处理成功状态
        if [[ "$stdo" == "[+] Done!" ]]; then
            echo -e "\033[32m\nConsole PPPwned! \033[0m\n" | sudo tee /dev/tty1
            if [ "$PPPOECONN" = true ]; then
                sudo systemctl start pppoe >/dev/null 2>&1 &
            else
                if [ "$SHUTDOWN" = true ]; then
                    read -t 5 || true
                    sudo poweroff
                else
                    if [ "$VMUSB" = true ]; then
                        sudo systemctl start pppoe >/dev/null 2>&1 &
                    else
                        sudo ip link set "$INTERFACE" down
                    fi
                fi
            fi
            exit 0
        # 处理错误状态
        elif [[ "$stdo" == *"Scanning for corrupted object...failed"* ]]; then
            echo -e "\033[31m\nFailed retrying...\033[0m\n" | sudo tee /dev/tty1
        elif [[ "$stdo" == *"Unsupported firmware version"* ]]; then
            echo -e "\033[31m\nUnsupported firmware version\033[0m\n" | sudo tee /dev/tty1
            exit 1
        elif [[ "$stdo" == *"Cannot find interface with name of"* ]]; then
            echo -e "\033[31m\nInterface $INTERFACE not found\033[0m\n" | sudo tee /dev/tty1
            exit 1
        fi
    done < <(timeout "$TIMEOUT" sudo "/boot/firmware/PPPwn/$CPPBIN" --interface "$INTERFACE" --fw "${STAGEVER//.}" --stage1 "/boot/firmware/PPPwn/stage1_$STAGEVER.bin" --stage2 "/boot/firmware/PPPwn/stage2_$STAGEVER.bin" 2>&1)

    read -t 1 || true  # 循环间隔
done