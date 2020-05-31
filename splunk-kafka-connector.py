"""
Author: Ben Bornholm
"""
import splunklib.client as client
from datetime import datetime
import argparse
import requests
import json
import sys
import yaml
import urllib3
urllib3.disable_warnings()


class App:
    def __init__(self, config):
        # Splunk host info
        self.splunk_external_url = config['splunk']['external_url']
        self.splunk_docker_hec_url = config['splunk']['docker_hec_url']

        # Splunk credentials
        self.splunk_username = config['splunk']['username']
        self.splunk_password = config['splunk']['password']

        # Splunk index and connectors
        self.splunk_index_name = config['splunk']['index_name']
        self.splunk_connector_name = config['splunk']['index_name'] + "-" + config['splunk']['hec_base_name']
        self.splunk_hec_token = None

        # Kafka
        self.kafka_connect_url = config['kafka']['connect_extenral_url']
        # self.kafka_connect_hostname = config['kafka']['connect_external_hostname']
        # self.kafka_connect_port = config['kafka']['connect_external_port']
        self.kafak_topics_list = config['kafka']['topics']

        # Verify
        self.verify = config['ssl']['verify']

        # Splink service
        self.service = client.connect(
            host=self.splunk_external_url.split('//')[1].split(':')[0],
            port=self.splunk_external_url.split('//')[1].split(':')[1],
            username=self.splunk_username,
            password=self.splunk_password,
            scheme=self.splunk_external_url.split('//')[0][:-1]
        )


    def list_kafka_splunk_connectors(self):
        headers = {
            "Content-Type": "application/json"
        }
        print (self.kafka_connect_url)
        r = requests.get(self.kafka_connect_url, headers=headers, verify=self.verify)
        
        if r.status_code == 200:
            print (r.json())
        else:
            print ( f"[-] - {datetime.now()} - Unable to get list of Kafka connectors" )
            print (r.text)

    def delete_kafka_splunk_connector(self, splunk_connector_name):
        headers = {
            "Content-Type": "application/json"
        }

        kafka_connect_delete_url = self.kafka_connect_url + "/" + splunk_connector_name
        r = requests.delete(kafka_connect_delete_url, headers=headers, verify=self.verify)

        print (r.status_code)
        if r.status_code == 204:
            print ( f"[+] - {datetime.now()} - Deleted connector between Splunk and Kafka for {splunk_connector_name}" )
        else:
            print ( f"[-] - {datetime.now()} - DID NOT DELETE connector between Splunk and Kafka for {splunk_connector_name}" )
            print (r.text)


    def create_kafka_splunk_connector(self):
        headers = {
            "Content-Type": "application/json"
        }

        print (self.kafak_topics_list)
        json_data = {
            "name": f"{self.splunk_connector_name}",
            "config": {
                "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
                "tasks.max": "10",
                "topics": f"{self.kafak_topics_list}",
                "splunk.hec.uri": f"{self.splunk_docker_hec_url}",
                "splunk.hec.token": f"{self.splunk_hec_token}",
                "splunk.hec.ack.enabled": "true",
                "splunk.hec.raw": "false",
                "splunk.hec.track.data": "true",
                "splunk.hec.ssl.validate.certs": f"{str(self.verify).lower()}"
            }
        }

        r = requests.post(self.kafka_connect_url, headers=headers, data=json.dumps(json_data), verify=self.verify)

        if r.status_code == 201:
            print ( f"[+] - {datetime.now()} - Instantiated connector between Splunk and Kafka for {self.kafak_topics_list}" )
        elif r.status_code == 409:
            print ( f"[+] - {datetime.now()} - Connector between Splunk and Kafka already exists for {self.kafak_topics_list}" )
        else:
            print ( f"[+] - {datetime.now()} - Did NOT create connector between Splunk and Kafka for {self.kafak_topics_list}" )
            print (r.text)


    def check_hec_collector(self):
        """
        Since the Splunk SDK for Python doesn't support HEC I had to use raw queries
        Input: Splunk connection info, Splunk credentials
        Output: If Splunk HEC event collector exists set the variable - Return nothing
        """
        # Set output mode to json
        params = (('output_mode', 'json'),)

        splunkl_url_create_hec_token = f"{self.splunk_external_url}/servicesNS/nobody/system/data/inputs/http/"
        r = requests.get(url=splunkl_url_create_hec_token, params=params, auth=(self.splunk_username, self.splunk_password), verify=self.verify)

        for hec_event_collector in r.json()["entry"]:
            if hec_event_collector["name"].split("//")[1]  == self.splunk_connector_name:
                print ( f"[*] - {datetime.now()} - Did NOT created Splunk HEC token for Kafka-splunk-connector cause it already exists" )
                self.splunk_hec_token = hec_event_collector["content"]["token"]



    def create_splunk_hec_token(self):
        """
        Since the Splunk SDK for Python doesn't support HEC I had to use raw queries
        Input: Splunk connection info, Splunk credentials, index name, and connector name
        Output: Nothin
        """
        # Splunk HEC event collector exists
        self.check_hec_collector()

        if self.splunk_hec_token is None:
            # Set output mode to json
            params = (('output_mode', 'json'),)

            data = {
                "name": f"{self.splunk_connector_name}",
                "index": f"{self.splunk_index_name}",
                "useACK": 1
            }

            params = (('output_mode', 'json'),)
            splunkl_url_create_hec_token = f"{self.splunk_external_url}/servicesNS/nobody/system/data/inputs/http/"
            r = requests.post(url=splunkl_url_create_hec_token, params=params, data=data, auth=(self.splunk_username, self.splunk_password), verify=False)
            
            if r.status_code == 201:
                print ( "[+] - {0} - Created Splunk HEC token for Kafka-splunk-connector: {1}".format( datetime.now(), r.json()["entry"][0]["content"]["token"] ))
                self.splunk_hec_token = r.json()["entry"][0]["content"]["token"] 
            else:
                print ( f"[-] - {datetime.now()} - Did NOT created Splunk HEC token for Kafka-splunk-connector" )
                print (r.text)
        

    def get_splunk_index_list(self):
        """
        https://github.com/splunk/splunk-sdk-python/blob/master/examples/index.py
        https://docs.splunk.com/DocumentationStatic/PythonSDK/1.6.5/client.html#splunklib.client.Indexes.delete
        https://docs.splunk.com/Documentation/Splunk/8.0.3/Search/ExportdatausingSDKs
        https://www.tutorialspoint.com/python/string_startswith.htm
        Input: Splunk service connector
        Output: List of Splunk indexes
        """
        indexes = self.service.indexes
        index_list = [ index.name for index in indexes if not index.name.startswith("_") ]
        return index_list


    def create_splunk_index(self, index_name=None):
        """
        https://dev.splunk.com/enterprise/docs/python/sdk-python/howtousesplunkpython/howtogetdatapython/#To-create-a-new-index
        Input: Splunk service connector, Splunk index list, new Splunk index name
        Output: None - Create new inde
        """
        # Override the index name in config
        if index_name is not None:
            self.splunk_index_name = index_name

        splunk_index_list = self.get_splunk_index_list()

        if self.splunk_index_name not in splunk_index_list:
            mynewindex = self.service.indexes.create(self.splunk_index_name)
            print (f"[+] - {datetime.now()} - Created {self.splunk_index_name} index")
        else:
            print (f"[*] - {datetime.now()} - Index {self.splunk_index_name} already exists, skipping")


if __name__ == "__main__":
    # Read variables from config
    config = None
    with open('conf/python/config.yml') as f:
        config = yaml.load(f, Loader=yaml.FullLoader)
    

    # Argparser
    my_parser = argparse.ArgumentParser()
    my_parser.add_argument('--create_splunk_index', action='store', type=str, help='Create splunk index')
    my_parser.add_argument('--create_splunk_hec_token', action='store_true', help='Create splunk HEC input')
    my_parser.add_argument('--create_kafka_splunk_connector', action='store_true', help='Create splunk index')
    my_parser.add_argument('--delete_kafka_splunk_connector', action='store', type=str, help='Create splunk index')
    my_parser.add_argument('--list_kafka_splunk_connectors', action='store_true', help='List Kafka Connectors')
    my_parser.add_argument('--all', action='store_true', help='Create Splunk index, Create Splunk HEC token, Create Kafka Splunk connector')
    args = my_parser.parse_args()


    # Inti class with vars
    app = App(config)
    
    if args.all:
        app.create_splunk_index()           # Create splunk index
        app.create_splunk_hec_token()       # Ceate HEC token
        app.create_kafka_splunk_connector() # Create Kafka Splunk connector

    # Create Splunk index
    if args.create_splunk_index:
        app.create_splunk_index(args.create_splunk_index)
        
    # Create Splunk HEC token
    if args.create_splunk_hec_token:
        app.create_splunk_hec_token()

    # Create Kafka Splunk connector
    if args.create_kafka_splunk_connector:
        app.create_kafka_splunk_connector()

    # List of Kafka connectors
    if args.list_kafka_splunk_connectors:
         app.list_kafka_splunk_connectors()

    # Delete Kafka Splunk connector
    if args.delete_kafka_splunk_connector:
        app.delete_kafka_splunk_connector(args.delete_kafka_splunk_connector)

    

    