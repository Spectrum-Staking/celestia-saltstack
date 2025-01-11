stop_celestia-appd:
  service.dead:
    - name: celestia-appd

copy_active_keys:
  file.managed:
    - names: 
      - /srv/celestia/.celestia-app/config/priv_validator_key.json:
        - source: salt://celestia/keys/{{ celestia_grain[0] }}/appd/priv_validator_key.json
      - /srv/celestia/.celestia-app/config/node_key.json
        - source: salt://celestia/keys/{{ celestia_grain[0]}} /appd/node_key.json
    - user: celestia

start_celestia:
  service.running:
    - name: celestia-appd