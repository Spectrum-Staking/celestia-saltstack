# Table of Contents

1. [Celestia Salt Deployment](#celestia-salt-deployment)
2. [Prerequisites](#prerequisites)
3. [Automation Overview](#automation-overview)
   1. [Celestia-Appd Deployment Details](#celestia-appd-deployment-details)
   2. [Celestia-Bridge Deployment Details](#celestia-bridge-deployment-details)
4. [Step-by-Step Installation Instructions](#step-by-step-installation-instructions)
5. [Failover Setup](#failover-setup)
   1. [Celestia-Appd Failover](#celestia-appd-failover)
   2. [Celestia-Bridge Failover](#celestia-bridge-failover)
   3. [Testing the Failover](#testing-the-failover)
6. [Contribution](#contribution)

# Celestia Salt Deployment

This repository provides an automated solution for installing Celestia App (`celestia-appd`) and Celestia Node (`celestia-bridge`) using SaltStack. The deployment process supports both the mainnet and testnet (Mocha) versions.

## Features

- **Flexible Configuration**: Manage Celestia settings through the `celestia_config.sls` file located in the Salt pillar folder.
- **Modular Installation**: Independent processes for deploying `celestia-appd` and `celestia-bridge`.
- **Optimized Syncing**: Snapshot integration to accelerate blockchain node synchronization.
- **Ease of Maintenance**: Structured Salt states for improved clarity and updates.
- **Failover option**: When backup nodes (`celestia-appd` and `celestia-bridge`) are deployed.

# Prerequisites

## Configure Your Salt Environment

Ensure that your [SaltStack environment](https://docs.saltproject.io/en/latest/contents.html) is properly configured.

## Copy the Celestia configuration to the Salt pillar:

1. Copy `celestia_config.sls` to your Salt pillar folder.
2. Update `top.sls` in the pillar directory to include `celestia_config` under the base environment:

```yaml
base:  
  '*':  
    - celestia_config
```

## Configure Salt grains for minions

This guide explains how to configure [Salt grains](https://docs.saltproject.io/salt/user-guide/en/latest/topics/grains.html) to automatically determine whether the `testnet` or `mainnet` version should be installed on a minion. By setting the `celestia` grain, Salt states can dynamically adapt and apply the appropriate configuration based on the grain value.

### Add the celestia grain
To assign the `testnet` value to the `celestia` grain for a specific minion, use the following command:

```yaml
sudo salt <minion> grains.append celestia testnet
```

### Remove the celestia grain
To remove the `testnet` value from the `celestia` grain, use the following command:

```yaml

sudo salt <minion> grains.remove celestia testnet
```

## Copy Celestia deployment files

Place the repository files in the directory: `celestia`.

## Refresh Salt Pillar Data
4. Run the following command to refresh the Salt pillar data:

```bash
sudo salt '*' saltutil.refresh_pillar
```

**Note:** Any changes made to `celestia_config.sls` require a pillar refresh.

# Automation Overview

The deployment process includes two main components:
- **Celestia-Appd**: Installs and configures the blockchain application node.
- **Celestia-Bridge**: Installs and configures the bridge node.

## Celestia-Appd Deployment Details

The `celestia-appd` installation process includes these steps:

### 1. User and Environment Setup
- A new Linux user is created with a home folder and shell.

### 2. Repository Cloning and Binary Installation
- The `celestia-app` repository is cloned from GitHub.
- The binary is installed and moved to `<home_folder>/bin`.
- The cloned repository is cleaned up.

### 3. Service Configuration
- The `celestia-appd.service` file is created and configured.
- The systemd daemon is reloaded.

### 4. Node Initialization
- The service is initialized.
- The genesis file is downloaded.
- Seed nodes are updated.

### 5. Configuration Updates
- The `~/.celestia-app/config/config.toml` file is updated.
- A blockchain snapshot is downloaded from `snapshots.bwarelabs.com`.

### 6. Wallet Creation
- A new wallet is created, with keys saved at `~/celestia_keys/validator_key_output.txt`.

### 7. Service Launch and Logs
- The `celestia-appd` service is started.
- Logs are saved in the `celestia_logs/` directory:
  - `celestia-appd-status.log`
  - `celestia-appd-journal.log`

These steps are grouped together in `deploy_celestia_appd.sls`:

```bash
$ cat deploy_celestia_appd.sls  
include:
  - celestia.modules.modules.common.check_grains
  - celestia.modules.modules.common.create_user
  - celestia.modules.modules.common.install_pkg
  - celestia.modules.celestia_appd.install_celestia_appd
  - celestia.modules.celestia_appd.update_celestia_appd_config
  - celestia.modules.celestia_appd.get_celestia_appd_snapshot
  - celestia.modules.celestia_appd.celestia_app_wallet
  - celestia.modules.celestia_appd.start_celestia_appd
```

## Celestia-Bridge Deployment Details

The `celestia-bridge` installation process includes these steps:

### 1. User and Environment Setup
- A new Linux user is created with a home folder and shell.

### 2. Repository Cloning and Binary Installation
- The `celestia-bridge` repository is cloned from GitHub.
- The binary and `cel-key` file are moved to `<home_folder>/bin`.
- The repository is cleaned up.

### 3. Service Configuration
- The `celestia-bridge.service` file is created and configured.
- The systemd daemon is reloaded.

### 4. Bridge Initialization
- The `celestia bridge init` command generates keys saved in `~/celestia_keys/bridge_key.txt`.

### 5. Configuration Updates
- The `~/.celestia-app/config/config.toml` file is updated for consensus-bridge connectivity.

### 6. Service Launch and Logs
- The `celestia-bridge` service is started.
- Logs are saved in the `celestia_logs/` directory:
  - `celestia-bridge-status.log`
  - `celestia-bridge-journal.log`

These steps are grouped together in `deploy_celestia_bridge.sls`:

```bash
$ cat deploy_celestia_bridge.sls  
include:
  - celestia.modules.modules.common.check_grains
  - celestia.modules.modules.common.create_user
  - celestia.modules.modules.common.install_pkg
  - celestia.modules.celestia_bridge.install_celestia_node
  - celestia.modules.celestia_bridge.connect_consensus_bridge
  - celestia.modules.celestia_bridge.start_celestia_bridge
```

# Step-by-Step Installation Instructions

## Step 1: Validate Your Salt Environment

Before deploying the services, validate your Salt environment by running the following commands with the `test=True` flag:

```bash
sudo salt <minion_name> state.apply celestia.deploy_celestia_appd test=True
sudo salt <minion_name> state.apply celestia.deploy_celestia_bridge test=True
```

If the commands execute successfully, your Salt environment is ready for deployment.

## Step 2: Deploy the Services

Once validation is complete, deploy the Celestia node by running:

```bash
sudo salt <minion_name> state.apply celestia.deploy_celestia_appd
```

Once validation is complete, deploy the Celestia bridge by running:

```bash
sudo salt <minion_name> state.apply celestia.deploy_celestia_bridge
```

# Failover Setup

For users running two independent instances of `celestia-appd` or `celestia-bridge`, follow these steps:

## Celestia-Appd Failover

Copy the following files to the Salt server under the `active/celestia-appd` folder:

```bash
.celestia-app/config/priv_validator_key.json
.celestia-app/config/node_key.json
```

## Celestia-Bridge Failover

Copy the `keys` directory from `.celestia-bridge-mocha-4/keys/` to the Salt server under the `active/celestia-bridge/keys/` folder.

### Final directory structure example:
```bash
celestia/active$ ls -lR
.:
total 8
drwxrwxr-x 2 salt salt 4096 Dec 27 17:21 celestia-appd
drwxrwxr-x 3 salt salt 4096 Dec 27 17:30 celestia-bridge

./celestia-appd:
total 8
-rwxrwx--- 1 salt salt 148 Nov 27 16:29 node_key.json
-rwxrwx--- 1 salt salt 345 Nov 27 16:29 priv_validator_key.json

./celestia-bridge:
total 4
drwxr-xr-x 3 salt salt 4096 Nov 27 20:53 keys

./celestia-bridge/keys:
total 12
drwx------ 2 salt salt 4096 Nov 27 20:52 keyring-test
-rw------- 1 salt salt   55 Nov 27 20:53 NJ3XILLTMSFWWSXEZLUFZVHO5A
-rw------- 1 salt salt  103 Nov 27 20:53 OASSSDFFLLLMV4Q

./celestia-bridge/keys/keyring-test:
total 8
-rw------- 1 salt salt 546 Nov 27 20:52 181c0c722752a17e6b13c666f7734ce1i1ksmc1.address
-rw------- 1 salt salt 760 Nov 27 20:52 my_celes_key.info
```

## Testing the Failover

To verify the failover configuration, use the `test=True` flag with these commands:

### Set Current Instance as Backup:
```bash
sudo salt <current_server> state.apply celestia.backup_bridge test=True
sudo salt <current_server> state.apply celestia.backup_app test=True
```

### Set Backup Instance as Active:
```bash
sudo salt <backup_server> state.apply celestia.active_app test=True
sudo salt <backup_server> state.apply celestia.active_bridge test=True
```

⚠️: **Double-sign risk** Setting Backup instance as active before making Current instance as backup will result in dual-active condition, which might result in double-sign slashing!
Ensure that your `double_sign_check_height` config setting is set to a non-zero value to prevent accidental switchover.

Once verified, remove the `test=True` flag and rerun the commands to proceed with production failover.

# Contribution

Contributions are welcome! Feel free to submit pull requests or report issues to help improve this repository.

