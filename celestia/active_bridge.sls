stop_celestia-appd:
  service.dead:
    - name: celestia-bridge

copy_priv_key:
  file.recurse:
    - name: /srv/celestia/.celestia-bridge-mocha-4/keys/
    - source: salt://celestia/active/celestia-bridge/keys/
    - user: celestia
    - group: celestia

start_celestia:
  service.running:
    - name: celestia-bridge
    - enable: true
