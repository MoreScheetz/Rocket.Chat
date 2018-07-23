# Purpose: To Automate Install for Rocket.Chat
# Script Created by Nicholas Scheetz @ https://scheetz.io
#
#
# -----------------------------BEGIN----------------------------------------
# Questions

clear
echo 'Welcome to Rocket.Chat installer!'
echo
echo "I need to ask you a few questions before starting the setup."
echo

# Hostname
echo "[+] What is your RocketChat Server hostname?"
read -p "Hostname: " -e -i chat.example.com HOSTNAME
if [[ -z "$HOSTNAME" ]]; then
   printf '%s\n' "No Hostname entered , exiting ..."
   exit 1
fi

# Set hostname 
hostnamectl set-hostname $HOSTNAME

# Server Ip Address
echo "[+] First, provide the IPv4 address of the network interface"
# Autodetect IP address and pre-fill for the user
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
read -p "IP address: " -e -i $IP IP
# If $IP is a private IP address, the server must be behind NAT
if echo "$IP" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
    echo
    echo "This server is behind NAT. What is the public IPv4 address?"
    read -p "Public IP address: " -e PUBLICIP
fi

# Email for certbot
echo "[+] What is your Email address ?"
read -p "Email: " -e EMAIL

if [[ -z "$EMAIL" ]]; then
    printf '%s\n' "No Email entered, exiting..."
    exit 1
fi


#
# FireWall------------------------------------------------------------------

#Confirm UFW is installed:
sudo apt-get install ufw

#Set the default access rules:
sudo ufw default deny incoming
sudo ufw default allow outgoing

#Set the service rules (SSH / HTTPS):
sudo ufw allow 22/tcp
sudo ufw allow 443/tcp

#Enable the firewall:
sudo ufw enable

#Check the Firewall status:
sudo ufw status

# FYI ------------------------------------------------------------
#If you ever add or delete rules you should reload the firewall:
#sudo ufw reload
#If you ever need to turn off the firewall:
#sudo ufw disable
#-----------------------------------------------------------------FYI

#---------------------------------------------------------------------Firewall

# Securing the server: Fail2ban (optional, recommended) ---------------------------------------------------------
# Fail2ban is an intrusion prevention software framework which protects computer servers from brute-force attacks.

sudo apt-get update
sudo apt-get install fail2ban

#----------------------------------------------------------------------------------------------------Fail2Ban

# Install Docker -----------------------------------------------------------------------------------------------

sudo apt-get update
sudo apt-get install docker-ce

---------------------------------------------------------------------------------------------------Docker Install

# Install Docker Compose 1.4.2 ---------------------------------------------------------------------------------

sudo curl -L https://github.com/docker/compose/releases/download/1.4.2/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose

# Set Executable Permissions
sudo chmod +x /usr/local/bin/docker-compose

#----------------------------------------------------------------------------------------------------Install Docker Compose

# Edit Host File ----------------------------------------------------------------------------------------------------------

echo "

127.0.0.1    localhost.localdomain    localhost
127.0.0.1    $HOSTNAME          chat

" > /etc/hosts

#--------------------------------------------------------------------------------------------------------Host File Edit

# CertBOt -------------------------------------------------------------------------------------------------------------------

[ -d certbot ] && rm -rf certbot
git clone https://github.com/certbot/certbot
cd certbot
git checkout v0.23.0
./certbot-auto --noninteractive --os-packages-only
./tools/venv.sh > /dev/null
sudo ln -sf `pwd`/venv/bin/certbot /usr/local/bin/certbot
sudo certbot certonly --manual -d "${HOSTNAME}" -d "*.${HOSTNAME}" --agree-tos --email "${EMAIL}" --preferred-challenges dns-01  --server https://acme-v02.api.letsencrypt.org/directory

# ------------------------------------------------------------------------------------------------------------------- CertBOt

# Nginx-------------------------------------------------------------------------------------------------------------------
sudo apt-get update
sudo apt-get install nginx

#Set Permissions
sudo chmod 400 /etc/nginx/certificate.key

#Generate Strong Diffie Helman Group
sudo openssl dhparam -out /etc/nginx/dhparam.pem 2048

#Configure Nginx
echo "server {
        listen 443 ssl;
        server_name $HOSTNAME;

        error_log /var/log/nginx/rocketchat_error.log;

        ssl_certificate /etc/nginx/certificate.crt;
        ssl_certificate_key /etc/nginx/certificate.key;
        ssl_dhparam /etc/nginx/dhparams.pem;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:20m;
        ssl_session_timeout 180m;

        location / {
            proxy_pass http://$HOSTNAME:3000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forward-Proto http;
            proxy_set_header X-Nginx-Proxy true;
            proxy_redirect off;
        }
    }" > /etc/nginx/sites-available/default
    
    #Test the Config
    sudo service nginx configtest && sudo service nginx restart


#-------------------------------------------------------------------------------------------------------------------Nginx












