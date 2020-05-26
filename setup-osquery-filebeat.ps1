################################################# Command Line Arguments #################################################
param (
  [parameter(Mandatory=$true)][string]$logstash_ip_addr,
  [parameter(Mandatory=$true)][string]$logstash_port
)

################################################# Global vars #################################################
$OSQUERY_VERSION = "4.2.0"
$POLYLOGYX_VERSION = "v1.0.40.1"
$FILEBEAT_VERSION = "7.7.0"

################################################# Install Osquery #################################################
$osqueryi_path = "C:\Program Files\osquery\osqueryi.exe"
if (!(Test-Path -Path $osqueryi_path)) {
  	Write-Output "[*] - Installing Osquery v$OSQUERY_VERSION"

  	# Move to user's TEMP directory
  	cd $ENV:TEMP

  	# Download Osquery
  	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  	Invoke-WebRequest -Uri https://pkg.osquery.io/windows/osquery-$OSQUERY_VERSION.msi -OutFile osquery-$OSQUERY_VERSION.msi -MaximumRedirection 3

  	# Install Osquery
		Start-Process $ENV:TEMP\osquery-$OSQUERY_VERSION.msi -ArgumentList '/quiet' -Wait
		
		#### Download configs ####
		$osquery_flags_path = "C:\Program Files\osquery\osquery.flags"
		if (!(Test-Path -Path $osquery_flags_path)) {
			Invoke-WebRequest -Uri https://raw.githubusercontent.com/CptOfEvilMinions/KSQL-Osquery-Zeek/master/conf/osquery/osquery.flags -OutFile $osquery_flags_path\osquery.flags
		}

		$osquery_conf_path = "C:\Program Files\osquery\osquery.conf"
		if (!(Test-Path -Path $osquery_conf_path)) {
			Invoke-WebRequest -Uri https://raw.githubusercontent.com/CptOfEvilMinions/KSQL-Osquery-Zeek/master/conf/osquery/osquery.conf -OutFile $osquery_conf_path\osquery.conf
		}

		$osquery_ext_path = "C:\Program Files\osquery\/extensions.load"
		if (!(Test-Path -Path $osquery_ext_path)) {
			Invoke-WebRequest -Uri https://raw.githubusercontent.com/CptOfEvilMinions/KSQL-Osquery-Zeek/master/conf/osquery/extensions.load -OutFile $osquery_ext_path\extensions.load
		}

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
	Invoke-WebRequest -Uri https://github.com/polylogyx/osq-ext-bin/archive/$POLYLOGYX_VERSION.zip -OutFile osq-ext-bin.zip -MaximumRedirection 3

	# Unzip archieve
	Expand-Archive .\osq-ext-bin.zip -DestinationPath .
	cd osq-ext-bin-master

	# Copy extensions toOsquery directory
	New-Item -Path "C:\Program Files\osquery" -Name "Extensions" -ItemType "directory"
	Copy-Item .\plgx_win_extension.ext.exe -Destination $plgx_win_extension_path
} else {
	Write-Output "[*] - Polylogyx is already installed skipping"
}

# Set perms of extensions
cd 'C:\Program Files\osquery'
icacls .\Extensions /setowner Administrators /t
icacls .\Extensions /grant Administrators:f /t
icacls .\Extensions /inheritance:r /t
icacls .\Extensions /inheritance:d /t

# Restart OsqueryD
Restart-Service -Name osqueryd


################################################# Install/Setup Filebeat #################################################
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
	powershell -Exec bypass -File .\install-service-filebeat.ps1

	# Start service
	Start-Service -Name filebeat
}







