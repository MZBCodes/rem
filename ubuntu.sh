#!/bin/bash

# This script will be downloaded off of git/somwehere else and will setup the ubuntu 22 environment with all the tools necessary.

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

REMOTE=1
ADMIN_PASSWORD="8$DistributedSinger"

run_scripts() {
    local password="$1"
    local user="$2"
    local ip="$3"
    local script_name="$4"

    echo "$password $user $ip $script_name"

    # Copy the script to the remote machine
    sshpass -p "$password" scp "$script_name" "$user@$ip:/tmp/"

    # Execute the script remotely using sudo
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$user@$ip" "echo '$password' | sudo -S bash /tmp/$script_name"
}

change_root_password() {
    echo "[+] Changing root password..."
    if [[ REMOTE -eq 1 ]]; then
        echo "root:$ADMIN_PASSWORD" | chpasswd
    else
        echo -n "Root Password: "; read -r pass
        echo "root:$pass" | chpasswd
    fi
    echo "Successfully changed root password"
}

add_admin_users() {
    ADMIN1="dawg"
    ADMIN2="bak"
    echo "[+] Adding in new and backup admin"
    #adding in admin users
    useradd "$ADMIN1"
    useradd "$ADMIN2"
    
    echo "[+] Updating password on accounts"
    #unlocks account by giving them password
    echo "$ADMIN1:$PASS1" | chpasswd
    echo "$ADMIN2:$PASS2" | chpasswd
    
    echo "[+] Add new admins to the sudo group"
    #giving admin privs to new users
    if [[ -n "$WHEEL_OS" ]]; then
	usermod -aG wheel "$ADMIN1"
	usermod -aG wheel "$ADMIN2"
	
    else
	usermod -aG sudo "$ADMIN1"
	usermod -aG sudo "$ADMIN2"
	
    fi
}


get_scripts() {
    mkdir /root/Linux
    wget 'https://github.com/MZBCodes/rem/raw/refs/heads/main/l.tar.gz' -O /root/linux.tar.gz
    tar -xf /root/linux.tar.gz
}

run_hardening_scripts() {
    chmod +x /root/Linux/Scripts/base_harden.sh
    ./base_hardening.sh
}

setup_ansible() {
    echo "[+] Installing dependencies..."
    apt install ansible

    ansible-galaxy collections install pfsensible.core    
}


setup_rsyslog() {
    echo "[+] Setting up rsyslog"
    echo "  [+] Installing rsyslog through apt"
    apt install -y rsyslog

    echo "  [+] Copying rsyslog configs"
    cp /root/Linux/Scripts/base_configs/rsyslog_server.txt /etc/rsyslog.conf

    echo "  [+] Setting up Logging Directory"
    mkdir -p /var/log/audit
    chown syslog:adm /var/log/audit
    chmod 755 /var/log/audit
    
    echo "  [+] Restarting rsyslog..."
    systemctl restart rsyslog
    systemctl enable rsyslog
}

setup_auditd() {
    echo "[+] Setting up auditd"
    echo "  [+] Installing auditd through apt"
    apt install -y auditd
    
    echo "  [+] Copying auditd configs"
    cp /root/Linux/Scripts/base_configs/auditd.txt /etc/audit/rules.d/audit.rules
    
    echo "  [+] Restarting rsyslog..."
    systemctl restart auditd
    systemctl enable auditd

}

setup_coordinate() {
    mkdir /root/coordinate
    wget "https://github.com/MZBCodes/rem/raw/refs/heads/main/coordinate" -O /root/coordinate/coordinate
    chmod +x /root/coordinate/coordinate
    export PATH="$PATH:/root/coordinate/"
}

deploy_scripts() { # talk with shane
    echo "[+] Deploying hardening scripts to all linux machines"
    
    run_scripts "Ch@ng3_m3" "dawg" "10.3.1.4" "base_harden.sh"
    run_scripts "Ch@ng3_m3" "dawg" "10.3.1.5" "base_harden.sh"
    run_scripts "Ch@ng3_m3" "dawg" "10.3.1.100" "base_harden.sh"

    run_scripts "Ch@ng3_m3" "dawg" "192.168.3.2" "base_harden.sh"
    run_scripts "Ch@ng3_m3" "dawg" "192.168.3.3" "base_harden.sh"
}

get_scripts
run_hardening_script
setup_coordinate
deploy_scripts
setup_ansible
setup_auditd
setup_rsyslog
