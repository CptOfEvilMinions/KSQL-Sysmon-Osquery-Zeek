# Filebeat

## Install Filebeat
1. `wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -`
1. `sudo apt-get install apt-transport-https -y`
1. `echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list`
1. `sudo apt-get update -y && sudo apt-get install filebeat -y`
1. `sudo systemctl enable filebeat`

## Setup Zeek logging
1. `sudo curl <GITHUB URL>/filebeat.yml -o /etc/filebeat/filebeat.yml`
1. `sudo curl <GITHUB URL>/filebeat_zeek.yml -o /etc/filebeat/conf.d/zeek.yml`
1. `sudo sed -i 's/logstash_ip_addr/<Logstash IP addr or FQDN>/g' /etc/filebeat/filebeat.yml`
1. `sudo sed -i 's/logstash_port/<Logstash port>/g' /etc/filebeat/filebeat.yml`
1. `sudo systemctl restart filebeat`

## References
* [Download Filebeat](https://www.elastic.co/downloads/beats/filebeat)
* [Filebeat - Log Input](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-input-log.html#filebeat-input-log)
* []()
* []()
* []()
* []()