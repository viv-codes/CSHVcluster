# CSHVcluster

## Installation
1. Install debian in a vm
2. apt update && apt install vim
3. make sure swap is disabled in fstab: `vim /etc/fstab`
4. is swap on? `cat /prox/meminfo | grep "Swap"` if so, reboot and check again to ensure it's off.
5. `chmod +x install.sh` and `./install.sh`
6. reboot
 

 
