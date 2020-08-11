# Install IIS
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Disable Windows firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False