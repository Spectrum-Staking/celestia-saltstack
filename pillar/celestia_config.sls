celestia_config:
  valid_node_type:
    - testnet
    - mainnet
  user_data:
    user_name: 'celestia'
    group: 'celestia'
    home_folder_path: "/srv"
    shell: '/bin/bash'
  packages:
    - curl
    - tar
    - wget
    - aria2
    - clang
    - pkg-config
    - libssl-dev
    - jq
    - build-essential
    - git
    - make
    - ncdu
  wallet_name: 'validator'

  testnet:
    go_ver: '1.23.2'
    celestia_app_version: '3.2.0-mocha'
    chain_id: 'mocha-4'
    p2p_port: '46656'
    rpc_port: '46657'
    double_sign_check_height: '5'
    prometheus_enabled: 'true'
    prometheus_port: '46660'
    celestia_node_version: '0.20.4-mocha'
    indexer: 'kv'
    min_retain_blocks: '0'
    celestia_bridge_core_ip: 'rpc-mocha.pops.one:26657'
    snapshot_url: 'https://snapshots.bwarelabs.com/celestia/testnet/'

  mainnet:
    go_ver: '1.23.0'
    celestia_app_version: '3.2.0'
    chain_id: 'celestia'
    p2p_port: '46656'
    rpc_port: '46657'
    double_sign_check_height: '5'
    prometheus_enabled: 'true'
    prometheus_port: '46660'
    celestia_node_version: '0.20.4'
    indexer: 'kv'
    min_retain_blocks: '0'
    celestia_bridge_core_ip: 'celestia-mainnet-consensus.itrocket.net'
    snapshot_url: 'https://snapshots.bwarelabs.com/celestia/mainnet/'
