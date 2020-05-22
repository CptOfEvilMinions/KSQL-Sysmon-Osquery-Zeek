#### Global vars ####
$OSQUERY_VERSION = "4.0.2"
$POLYLOGYX_VERSION = "v1.0.35.15"
$FILEBEAT_VERSION = "7.7.0"

$LOGSTSH_IP_ADDR = "10.150.100.210"
$LOGSTASH_PORT = "5044"

################################################# Install Osquery #################################################
$osqueryi_path = "C:\Program Files\osquery\osqueryi.exe"
if (!(Test-Path -Path $osqueryi_path)) {
  	Write-Output "[*] - Installing Osquery v$OSQUERY_VERSION"

  	# Move to user's TEMP directory
  	cd $ENV:TEMP

  	# Download Osquery
  	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  	Write-Output https://pkg.osquery.io/windows/osquery-$OSQUERY_VERSION.msi
  	Invoke-WebRequest -Uri https://pkg.osquery.io/windows/osquery-$OSQUERY_VERSION.msi -OutFile osquery-$OSQUERY_VERSION.msi -MaximumRedirection 3

  	# Install Osquery
  	Start-Process $ENV:TEMP\osquery-$OSQUERY_VERSION.msi -ArgumentList '/quiet' -Wait
} else {
  	Write-Output "[*] - Osquery is already installed skipping"
}

################################################# Install/Setup Polylogyx #################################################
$plgx_win_extension_path = "C:\Program Files\osquery\Extensions\plgx_win_extension.ext.exe"
if (!(Test-Path -Path $plgx_win_extension_path)) {
	Write-Output "[*] - Installing Polylogyx osquery extensions"

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
	Copy-Item .\plgx_win_extension.ext.exe -Destination $plgx_win_extension_path
} else {
	Write-Output "[*] - Polylogyx is already installed skipping"
}


################################################# Install/Setup CommunityID extension #################################################
$community_id_ext_path = "C:\Program Files\osquery\Extensions\osquery_community_id.exe"
if (!(Test-Path -Path $community_id_ext_path)) {
	Write-Output "[*] - Installing CommunityID extension"
	cd 'C:\Program Files\osquery'

	# Download ext
	Invoke-WebRequest -Uri https://github.com/CptOfEvilMinions/osquery-go-communityid/releases/download/v1.0/osquery_community_id_ext.exe -OutFile $community_id_ext_path -MaximumRedirection 3
} else {
	Write-Output "[*] - CommunityID is already installed skipping"
}

################################################# Setup Osquerey perms #################################################
# Set perms of extensions
cd 'C:\Program Files\osquery'
icacls .\Extensions /setowner Administrators /t
icacls .\Extensions /grant Administrators:f /t
icacls .\Extensions /inheritance:r /t
icacls .\Extensions /inheritance:d /t

#### Download configs ####
$osquery_flags_path = "C:\Program Files\osquery\osquery.flags"
if (!(Test-Path -Path $osquery_flags_path)) {
	Invoke-WebRequest -Uri https://raw.githubusercontent.com/CptOfEvilMinions/KSQL-Osquery-Zeek/master/conf/osquery/osquery.flags -OutFile $osquery_flags_path
}

$osquery_conf_path = "C:\Program Files\osquery\osquery.conf"
if (!(Test-Path -Path $osquery_conf_path)) {
	Invoke-WebRequest -Uri https://raw.githubusercontent.com/CptOfEvilMinions/KSQL-Osquery-Zeek/master/conf/osquery/osquery.conf -OutFile $osquery_conf_path
}

$osquery_ext_path = "C:\Program Files\osquery\/extensions.load"

if (!(Test-Path -Path $osquery_ext_path)) {
	Invoke-WebRequest -Uri https://raw.githubusercontent.com/CptOfEvilMinions/KSQL-Osquery-Zeek/master/conf/osquery/extensions.load -OutFile $osquery_ext_path
}

################################################# Test Osquery + CommunityID + Polylogyx #################################################
# Test Osquery-polylogyx and win_socket_events table
Stop-Service -Name osqueryd

# Get list of tables
$ouput = (.\osqueryi.exe --flagfile .\osquery.flags --allow_unsafe --json '.tables') | Out-String

# Check if Osquery has tables
if ($ouput -notlike "*community_id*") {
  	Write-Output "[-] - No community_id table"
  	exit
}

if ($ouput -notlike "*win_socket_events*") {
  	Write-Output "[-] - No win_socket_events table"
  	exit
}

# Test win_socket_events table
$ouput = (.\osqueryi.exe --flagfile .\osquery.flags --json 'SELECT * FROM win_socket_events;') | Out-String
Write-Output $ouput

# Test win_socket_events table and community ID
$ouput = (.\osqueryi.exe --flagfile .\osquery.flags --json "SELECT s.local_address, s.local_port, s.remote_address, s.remote_port, s.protocol, c.community_id, s.pid, s.process_name FROM win_socket_events as s JOIN community_id as c ON s.local_address=c.src_ip AND s.local_port=c.src_port AND s.remote_address=c.dst_ip AND s.remote_port=c.dst_port AND s.protocol=c.protocol WHERE action='SOCKET_CONNECT';") | Out-String
Write-Output $ouput

# Restart OsqueryD
Restart-Service -Name osqueryd


################################################# Install/Setup Winlogbeat #################################################
$filebeat_path = "C:\Program Files\Filebeat\"
if (!(Test-Path -Path $filebeat_path)) {
	# Move to user's TEMP directory
	cd $ENV:TEMP

	# Download WinLogBeat
	Invoke-WebRequest -Uri https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$FILEBEAT_VERSION-windows-x86_64.zip -OutFile filebeat-$FILEBEAT_VERSION-windows-x86_64.zip -MaximumRedirection 3

	# Unzip archieve
	Expand-Archive .\filebeat-$FILEBEAT_VERSION-windows-x86_64.zip -DestinationPath .
	Copy-Item ".\filebeat-$FILEBEAT_VERSION-windows-x86_64\" -Destination $filebeat_path -Recurse


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
}







