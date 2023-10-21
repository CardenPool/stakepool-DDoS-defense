# stakepool-iptables-defense
This script configures and deploys iptables rules designed to safeguard a Cardano stakepool from a range of DDoS attack vectors, ensuring rule persistence across reboots



## Installation

## Schedule the cronjob
Every iptable added by command line is not boot proof and will be forget at rebbot time. To make the defense rules loading at boot time, we have to schedule its loading with crontab.
Since this script uses iptables and it requires administrative priviledges to operate, we have to run the script with root priviledges. To achieve this, we have to edit the cronjob list, run with root priviledges, makeng use of the command:
```console
sudo contab -e
```
This will open the contab text editor interface where we have to add the call to our script. Please replace <YOUR-PATH> with your file path.
```bash
#Apply DDoS iptables rules. NOTE: can't use iptables-persistant since we're using UFW (conflict!)
@reboot sleep 20; /<YOUR-PATH>/DDoS-defense.sh
```
PressCTRL+o to save the contab and CTRL+x to come back to te terminal. The script will be executed
