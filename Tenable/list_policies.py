from tenable.sc import TenableSC
import os
import json

TENABLE_HOST = os.environ.get("TENABLE_HOST", "")
TENABLE_ACCESS = os.environ["SELECTED_CREDENTIALS_USERNAME"]
TENABLE_SECRET = os.environ["SELECTED_CREDENTIALS_PASSWORD"]

sc = TenableSC(
    TENABLE_HOST,
    access_key=TENABLE_ACCESS,
    secret_key=TENABLE_SECRET
)

policy_list = sc.policies.list()

print(
    json.dumps([p['name'] for p in policy_list['usable']])
)