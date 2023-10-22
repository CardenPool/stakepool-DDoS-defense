# Cardano Stakepool DDoS Defense Script
The *DDoS-defense.sh* script configures and deploys iptables rules designed to safeguard a Cardano stakepool from a range of DDoS attack vectors, ensuring rule persistence across reboots. This script is designed to be fully compatible with UFW.
```console
████              ██              ████
██░░████      ████░░████      ████░░██
██░░░░░░██████░░░░░░░░░░██████░░░░░░██
██░░░░░░░░░░░░░░░░  ░░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░  ░░  ░░  ░░░░░░░░░░░░██
██░░░░░░░░  ░░░░░░  ░░░░░░  ░░░░░░░░██
██░░░░░░      ░░░░  ░░░░      ░░░░░░██
██░░░░░░░░  ░░░░      ░░░░  ░░░░░░░░██
██░░░░░░  ░░░░          ░░░░  ░░░░░░██    _____  _____        _____   _____        __                    
██░░░░░░  ░░░░          ░░░░  ░░░░░░██   |  __ \|  __ \      / ____| |  __ \      / _|                   
  ██░░░░  ░░░░          ░░░░  ░░░░██     | |  | | |  | | ___| (___   | |  | | ___| |_ ___ _ __  ___  ___ 
  ██░░░░░░░░░░░░      ░░░░░░░░░░░░██     | |  | | |  | |/ _ \\___ \  | |  | |/ _ \  _/ _ \ '_ \/ __|/ _ \
    ██░░░░  ░░░░░░  ░░░░░░  ░░░░██       | |__| | |__| | (_) |___) | | |__| |  __/ ||  __/ | | \__ \  __/
    ██░░░░░░  ░░░░  ░░░░  ░░░░░░██       |_____/|_____/ \___/_____/  |_____/ \___|_| \___|_| |_|___/\___|
      ██░░░░░░  ░░  ░░  ░░░░░░██      
      ██░░░░░░░░░░  ░░░░░░░░░░██      
        ██░░░░░░░░░░░░░░░░░░██        
          ██░░░░░░░░░░░░░░██          
            ██░░░░░░░░░░██            
              ██░░░░░░██              
                ██████
```
*IMPORTANT: To ensure that everything is set up correctly, please run the script manually (sudo /FILE-PATH/DDoS-Defense.sh) on one of your relays first and verify that the node is working fine.*

## Installation
1) Download the script to your local drive and grant execute permissions:
   ```console
   wget https://raw.githubusercontent.com/CardenPool/stakepool-DDoS-defense/main/DDoS-defense.sh -P /<DESTINATION-PATH>/
   chmod +x /<DESTINATION-PATH>/DDoS-defense.sh
   ```
2) Customize the script 
Edit the script and update the value within the angle brackets <YOUR-VALUE> for all the fields.
   ```console
   nano /<DESTINATION-PATH>/DDoS-defense.sh
   ```
3) Schedule the cronjob
   Every iptable added by command line is not boot proof and will be forget at reboot time. To make the defense rules loading at boot time, we have to schedule its loading with crontab.
   Since this script uses *iptables* command that requires administrative priviledges to operate, we have to run the script with root priviledges. To achieve this, we have to edit the *root cronjob list*(containing tasks run with root priviledges) makeng use of the command:
   ```console
   sudo contab -e
   ```
   This will open the *contab text editor interface* where we have to add the call to our script. Please replace **<FILE-PATH>** with the right path of your local file and add the call at the end of the list.
   ```bash
   #Apply DDoS iptables rules. NOTE: can't use iptables-persistant since we're using UFW (conflict!)
   @reboot sleep 20; /<FILE-PATH>/DDoS-defense.sh
   ```
   PressCTRL+o to save and update the contab list, then CTRL+x to come back to te terminal. The call run the script at every boot, 20 seconds after boot time to ensure UFW and other services are up and running. You're done!
