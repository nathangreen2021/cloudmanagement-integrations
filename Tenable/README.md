# Tenable.SC Integration

Simple Tenable.SC scripts.

## Requirements
* Python 3
* pyTenable >= 1.3

## Scripts
### Request a scan on a target VM - `runscan.py`
Meant to be run as part of a "change request" to request a vulnerability scan on a target VM.

Requires the following inputs:
* `target.settings.dynamicList['Policy']` - For selecting which policy to use. Can be selected using `list_policies.py`
* `target.ipAddress` - identifies the VM in Tenable
* `target.id` - for setting the custom attribute after the scan
* `request.id` - for naming the ad-hoc scan

Note: If `WAIT_FOR_COMPLETE` is set, the script will wait, and after scan completion will set custom attributes to store the result (Scan Status and Scan Date)

### Synchronize scan results - `sync_scan_status.py`
This will iterate over the VM inventory and check scan status in Tenable and set the appropriate custom attributes

### List scan policies - `list_policies.py`
Utility for listing available scan policies. Useful for dynamic lists.