#### Global vars ####
$OSQUERY_VERSION = "4.0.2"
$POLYLOGYX_VERSION = "v1.0.35.15"
$FILEBEAT_VERSION = "7.7.0"

$LOGSTSH_IP_ADDR = "10.150.100.210"
$LOGSTASH_PORT = "5044"

################################################# Install/Setup Osquery #################################################
# Move to user's TEMP directory
cd $ENV:TEMP

# Download Osquery
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Output https://pkg.osquery.io/windows/osquery-$OSQUERY_VERSION.msi
Invoke-WebRequest -Uri https://pkg.osquery.io/windows/osquery-$OSQUERY_VERSION.msi -OutFile osquery-$OSQUERY_VERSION.msi -MaximumRedirection 3

# Install Osquery
Start-Process $ENV:TEMP\osquery-$OSQUERY_VERSION.msi -ArgumentList '/quiet' -Wait

################################################# Install/Setup Polylogyx #################################################
# Disable Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $true

# Move to user's TEMP directory
cd $ENV:TEMP

# Download Polylogyx-osery-extensions
Invoke-WebRequest -Uri https://github.com/polylogyx/osq-ext-bin/archive/master.zip -OutFile osq-ext-bin.zip -MaximumRedirection 3

# Unzip archieve
Expand-Archive .\osq-ext-bin.zip -DestinationPath .
cd osq-ext-bin-master

# Copy extensions toOsquery directory
New-Item -Path "C:\Program Files\osquery" -Name "Extensions" -ItemType "directory"
Copy-Item .\plgx_win_extension.ext.exe -Destination 'C:\Program Files\osquery\Extensions\plgx_win_extension.ext.exe'


################################################# Install/Setup CommunityID extension #################################################
cd 'C:\Program Files\osquery'

# Download ext
Invoke-WebRequest -Uri https://github.com/CptOfEvilMinions/osquery-go-communityid/releases/download/v1.0/osquery_community_id_ext.exe -OutFile .\Extensions\osquery_community_id.exe -MaximumRedirection 3

################################################# Setup Osquerey perms #################################################
# Set perms of extensions
cd 'C:\Program Files\osquery'
icacls .\Extensions /setowner Administrators /t
icacls .\Extensions /grant Administrators:f /t
icacls .\Extensions /inheritance:r /t
icacls .\Extensions /inheritance:d /t

# Download config
Invoke-WebRequest -Uri https://raw.githubusercontent.com/CptOfEvilMinions/BlogProjects/master/ksql-osquery-zeek-correlator/conf/windows-osquery/osquery.flags -OutFile "C:\Program Files\osquery\osquery.flags"
Invoke-WebRequest -Uri https://raw.githubusercontent.com/CptOfEvilMinions/BlogProjects/master/ksql-osquery-zeek-correlator/conf/windows-osquery/osquery.conf -OutFile "C:\Program Files\osquery\osquery.conf"


# Test Osquery-polylogyx and win_socket_events table
#Stop-Service -Name osqueryd




################################################# Install/Setup Winlogbeat #################################################
# Move to user's TEMP directory
cd $ENV:TEMP

# Download WinLogBeat
Invoke-WebRequest -Uri https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$FILEBEAT_VERSION-windows-x86_64.zip -OutFile filebeat-$FILEBEAT_VERSION-windows-x86_64.zip -MaximumRedirection 3

# Unzip archieve
Expand-Archive .\filebeat-$FILEBEAT_VERSION-windows-x86_64.zip -DestinationPath .
Copy-Item ".\filebeat-$FILEBEAT_VERSION-windows-x86_64\" -Destination 'C:\Program Files\Filebeat\' -Recurse

# Download Filebeat config
cd 'C:\Program Files\Filebeat'
Invoke-WebRequest -Uri https://raw.githubusercontent.com/CptOfEvilMinions/BlogProjects/master/ksql-osquery-zeek-correlator/conf/windows-filebeat/filebeat.yml -OutFile 'C:\Program Files\Filebeat\filebeat.yml'

# Replace logstash IP addr and port
(Get-Content -Path .\filebeat.yml -Raw) -replace "logstash_ip_addr","$LOGSTSH_IP_ADDR" | Set-Content -Path .\filebeat.yml
(Get-Content -Path .\filebeat.yml -Raw) -replace "logstash_port","$LOGSTASH_PORT" | Set-Content -Path .\filebeat.yml

# Install Filebeat
Set-ExecutionPolicy Unrestricted
.\install-service-filebeat.ps1

# Start service
Start-Service -Name filebeat