import os
import requests
from tenable.sc import TenableSC
from datetime import datetime

COMMANDER_URL = "https://127.0.0.1/rest/v3"
COMMANDER_USERNAME = os.environ.get("SELECTED_CREDENTIALS_USERNAME")
COMMANDER_PASSWORD = os.environ.get("SELECTED_CREDENTIALS_PASSWORD")
COMMANDER_SSL_VERIFY = False

TENABLE_HOST = os.environ.get("TENABLE_HOST", "")
TENABLE_CREDENTIAL = "Tenable API"


def get_scan_results(api):
    ips = {}

    for vuln in api.analysis.vulns(tool='sumip'):
        ip = vuln['ip']
        if ip.startswith('127'):
            continue

        try:
            auth_date = int(vuln['lastAuthRun']) if vuln['lastAuthRun'].isdigit() else 0
            unauth_date = int(vuln['lastUnauthRun']) if vuln['lastUnauthRun'].isdigit() else 0
            scan_date = datetime.fromtimestamp(max(auth_date, unauth_date)).strftime("%Y-%m-%d")
        except:
            scan_date = "Unknown"

        if vuln['severityHigh'] != '0' or vuln['severityCritical'] != '0':
            ips[ip] = scan_date, 'FAILED'
        else:
            ips[ip] = scan_date, 'PASSED'

    return ips


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
                print("Failed to authenticate with Commander API")
                exit(1)
        else:
            refresh_response = self.ses.post(self.url+"/tokens/refresh", headers=self.headers, json={"token": self.token})
            if refresh_response.ok:
                self.token = refresh_response.json()['token']
            else:
                print("Failed to refresh token")
                exit(1)


    def vm_list(self):
        vms = self._get("/virtual-machines").json()
        return vms['something']

    def get_vm_ips(self, vm_id):
        vm_details = self._get("/virtual-machines/"+str(vm_id)).json()
        for net_if in vm_details['resources'].get('network_interfaces', []):
            yield net_if.get('public_ipv4_address')
            yield net_if.get('private_ipv4_address')

    def set_attribute(self, vm_id, key, value):
        self._post("/virtual-machines/{}/attributes".format(vm_id), {
            "name": key,
            "value": value
        })

    def get_credential(self, credential_name):
        cred = self._get("/credentials/{}".format(credential_name)).json()['password_credential']
        return cred['username'], cred['password']

def main():
    cmp_api = CommanderAPI(COMMANDER_URL, COMMANDER_USERNAME, COMMANDER_PASSWORD, verify_ssl=COMMANDER_SSL_VERIFY)
    tenable_access, tenable_secret = cmp_api.get_credential(TENABLE_CREDENTIAL)

    sc_api = TenableSC(
        TENABLE_HOST,
        access_key=tenable_access,
        secret_key=tenable_secret
    )

    print("Get scan results from Teneble.sc")
    scan_results = get_scan_results(sc_api)

    print("Get list of VM's and their IP addresses from Commander")
    cmdr_ip_list = {}
    for vm in cmp_api.vm_list():
        vm_id = vm['id']
        cmdr_ip_list[vm_id] = list(cmp_api.get_vm_ips(vm_id))
    
    print("Update custom attributes with scan status")
    for vm, ips in cmdr_ip_list.items():
        stata = [scan_results[ip] for ip in ips if ip in scan_results]

        if stata:
            if any(s == 'FAILED' for d, s in stata):
                status = 'FAILED'
            else:
                status = 'PASSED'
            scan_date = max(d for d, s in stata)
            cmp_api.set_attribute(vm, "Scan Date", str(scan_date))
        else:
            status = 'NOT_SCANNED'
   
        cmp_api.set_attribute(vm, "Scan Status", status)
        print("{}: {}".format(vm, status))


if __name__ == "__main__":
    main()
