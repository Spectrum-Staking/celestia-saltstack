stop_celestia:
  service.dead:
    - name: celestia-appd

remove_keys:
  file.absent:
    - names:
      - /srv/celestia/.celestia-app/config/priv_validator_key.json
      - /srv/celestia/.celestia-app/config/node_key.json

start_celestia:
  service.running:
    - name: celestia-appd
seb@spectrum-mgmt:/srv/salt/test/celestia_public$ cat backup_bridge.sls
stop_celestia:
  service.dead:
    - name: celestia-bridge

remove_keys:
  file.absent:
    - names:
      - /srv/celestia/.celestia-bridge-mocha-4/keys

start_celestia:
  service.running:
    - name: celestia-bridge
