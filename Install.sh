# Purpose: To Automate Install for Rocket.Chat
# Script Created by Nicholas Scheetz @ https://scheetz.io
#
#
# -----------------------------BEGIN----------------------------------------
#
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
