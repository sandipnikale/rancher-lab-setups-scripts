## Bash scripts for rke/rke2/k3s installation with rancher

### USAGE

Download the script with wget or curl and make it executable with 'chmod' and follow below instructions.

Note: defualt rancher password is "admin@12345"

> Standalone Script
```bash
curl -sLO https://raw.githubusercontent.com/sandipnikale/rancher-auto-scripts/main/standalone-rancher.sh
```
> HA Script
```bash
curl -sLO https://raw.githubusercontent.com/sandipnikale/rancher-auto-scripts/main/ha-rancher.sh
```

### For single node rke/rke2/k3s with rancher setup:
```bash
Syntax:
$ ./standalone-rancher.sh {rke OR rke2 OR k3s}

Example:
For rke with rancher:
$ ./standalone-rancher.sh rke 

```

******************************************************************************

### For 3 node HA rke/rke2/k3s with rancher setup:

Note: This is strictly for 3 node clsuter.
Pre-requisite: Make sure to setup passwordless ssh ie. one should login to each of this three node from one another with ssh key. 

```bash
Syntax:
$ ./ha-rancher.sh {rke OR rke2 OR k3s}

Example:
i] For rke with rancher:
$ ./ha-rancher.sh rke 

```
