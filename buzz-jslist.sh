i=0
for dev in $(find /dev/input -name "js*" | sort); do
    path=$(udevadm info --name=$dev | grep DEVPATH | cut -d= -f2)
    name=$(</$(dirname sys$path)/name)
    echo $dev $i $name
    ((i++))
done
