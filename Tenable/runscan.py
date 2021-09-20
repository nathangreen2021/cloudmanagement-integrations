import os
import time
import requests
from ipaddress import ip_network, ip_address
from tenable.sc import TenableSC

TENABLE_HOST = os.environ.get("TENABLE_HOST", "")
TENABLE_CREDENTIAL = "Tenable API"

COMMANDER_URL = "https://127.0.0.1/rest/v3"
COMMANDER_USERNAME = os.environ.get("SELECTED_CREDENTIALS_USERNAME")
COMMANDER_PASSWORD = os.environ.get("SELECTED_CREDENTIALS_PASSWORD")
COMMANDER_SSL_VERIFY = False

POLICY_NAME = "#{target.settings.dynamicList['Policy']}"
TARGET_IP = "#{target.ipAddress}"
TARGET_ID = "#{target.id}"
REQUEST_ID = "#{request.id}"
SCAN_CRED_NAME = "Linux"

# ID of the repo in Tenable is the key, value is a subnet covering that repository
REPOSITORY_MAP = {
    1: ip_network("123.456.789.0/24")
}

WAIT_FOR_COMPLETE = True


def main():
    cmdr_api = CommanderAPI(
        COMMANDER_URL,
        COMMANDER_USERNAME,
        COMMANDER_PASSWORD,
        COMMANDER_SSL_VERIFY
    )

    tenable_access, tenable_secret = cmdr_api.get_credential(TENABLE_CREDENTIAL)

    sc_api = TenableAPI(
        TENABLE_HOST,
        access_key=tenable_access,
        secret_key=tenable_secret
    )

    policy_id = sc_api.get_policy_id(POLICY_NAME)

    scan_name = "Ad-hoc Scan #" + str(REQUEST_ID)
    repository_id = sc_api.select_repository(TARGET_IP)
    cred_id = sc_api.find_credential(SCAN_CRED_NAME)
    scan_id = sc_api.create_scan(scan_name, policy_id, TARGET_IP, repository_id, [cred_id])

    print("Scan name={}, id={}".format(scan_name, scan_id))

    # Run the scan
    launch_request = sc_api.scans.launch(scan_id)
    queue_id = launch_request['scanResult']['id']

    print("Scan launched. Queue ID: " + queue_id)

    if WAIT_FOR_COMPLETE:
        result, finish_time = sc_api.wait_scan(queue_id)
        if result != 'Completed':
            raise Exception("Scan did not complete successfully. Status=" + result)
        
        print("Scan completed. Checking results")
        status = sc_api.get_scan_results(TARGET_IP)
        print("Compliance status: " + status)

        cmdr_api.set_attribute(TARGET_ID, "Scan Status", status)
        cmdr_api.set_attribute(TARGET_ID, "Scan Date", finish_time)


class TenableAPI(TenableSC):
    def get_policy_id(api, name):
        # find policy id from name
        policy_list = api.policies.list()
        try:
            return [p['id'] for p in policy_list['usable'] if p['name'] == name][0]
        except:
            raise KeyError("couldn't find policy by that name. " + name)

    def create_scan(api, scan_name, policy_id, target_ip, repository_id, credential_ids=None):
        # Create or get the one-time scan based on the requested policy
        scan_list = api.scans.list()

        check_exists = [s['id'] for s in scan_list['usable'] if s['name'] == scan_name]
        if check_exists:
            # if the scan already exists, don't recreate
            scan_id = check_exists[0]
            print("Scan already exists, id=" + scan_id)
        else:
            scan_create = api.scans.create(
                name=scan_name,
                policy_id=policy_id,
                targets=[target_ip],
                repo=repository_id,
                creds=credential_ids
            )
            scan_id = scan_create['id']
            print("Scan created, id=" + scan_id)

        return scan_id

    def find_credential(api, name):
        """ Gets a credential by name """
        for cred in api.credentials.list()['usable']:
            if cred['name'] == name:
                return cred['id']
        raise KeyError("Credential not found")


    def wait_scan(api, queue_id, wait_time=30, tries=20):
        for _ in range(tries):
            details = api.scan_instances.details(queue_id, fields=['status', 'running', 'finishTime'])
            if details['running'] == 'true' or details['status'] == 'Queued':
                time.sleep(wait_time)
            else:
                return details['status'], details.get('finishTime')
        raise TimeoutError()

    def get_scan_results(api, ip_address, print_counts=True):
        """ Get scan results (PASSED/FAILED) for a particullar IP """
        filters = [
            ('ip', '=', ip_address)
        ]

        vuln_iter = api.analysis.vulns(*filters, tool='sumip')
        try:
            vuln = next(vuln_iter)
            if print_counts:
                print("Vulnerability counts by severity:"
                "\nInfo: {severityInfo}"
                "\nLow: {severityLow}"
                "\nMedium: {severityMedium}"
                "\nHigh: {severityHigh}"
                "\nCritical: {severityCritical}"
                "\nMust have 0 High and Critical vulnerabilities to PASS"
                .format(**vuln)
                )
            if vuln['severityHigh'] != '0' or vuln['severityCritical'] != '0':
                return 'FAILED'
            else:
                return 'PASSED'
        except StopIteration:
            raise Exception("No analysis results for that IP. Please check Tenable")
        except Exception as e:
            raise  Exception("Couldn't get analysis results. Please check Tenable") from e

    def select_repository(self, address):
        """ Select appropriate repository based on subnet """
        ip = ip_address(address)
        for repo_id, net in REPOSITORY_MAP.items():
            if ip in net:
                return repo_id
        raise KeyError("IP not in given repositories")


class CommanderAPI:
    def __init__(self, url, username, password, verify_ssl=True):
        self.url = url
        self.username = username
        self.password = password
        self.token = None
        self.token_age = 0
        self.ses = requests.Session()
        self.ses.verify = verify_ssl

    def _get(self, endpoint):
        self.refresh_token()
        return self.ses.get(self.url + endpoint, headers=self.headers)

    def _post(self, endpoint, data):
        self.refresh_token()
        return self.ses.post(self.url + endpoint, headers=self.headers, json=data)

    @property
    def headers(self):
        return {
            "Content-Type": "application/json",
            "Authorization": "Bearer " + self.token
        }

    def refresh_token(self):
        if self.token is None:
            # if no token, we don't send it in the headers
            token_response = self.ses.post(self.url + "/tokens", headers={"Content-Type": "application/json"}, json={
                "username": self.username,
                "password": self.password
            })

            if token_response.ok:
                self.token = token_response.json()['token']
            else:
                raise Exception("Failed to authenticate with Commander API")
        else:
            refresh_response = self.ses.post(self.url+"/tokens/refresh", headers=self.headers, json={"token": self.token})
            if refresh_response.ok:
                self.token = refresh_response.json()['token']
            else:
                raise Exception("Failed to refresh token")

    def set_attribute(self, vm_id, key, value):
        self._post("/virtual-machines/{}/attributes".format(vm_id), {
            "name": key,
            "value": value
        })
    
    def get_credential(self, credential_name):
        cred = self._get("/credentials/{}".format(credential_name)).json()['password_credential']
        return cred['username'], cred['password']



if __name__ == "__main__":
    main()