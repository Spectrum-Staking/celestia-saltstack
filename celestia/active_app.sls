stop_celestia-appd:
  service.dead:
    - name: celestia-appd

copy_priv_key:
  file.managed:
    - name: /srv/celestia/.celestia-app/config/priv_validator_key.json
    - source: salt://celestia/active/celestia-appd/priv_validator_key.json
    - user: celestia

copy_node_key:
  file.managed:
    - name: /srv/celestia/.celestia-app/config/node_key.json
    - source: salt://celestia/active/celestia-appd/node_key.json
    - user: celestia

start_celestia:
  service.running:
    - name: celestia-appd
    - enable: true
