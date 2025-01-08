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
