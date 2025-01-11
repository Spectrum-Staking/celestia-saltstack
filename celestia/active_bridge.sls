{% from 'celestia/modules/lib.jinja' import bridge_dir with context %}
{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set node_config = salt['pillar.get']('celestia_config').get(node_type, {}) %}

stop_celestia-appd:
  service.dead:
    - name: celestia-bridge

copy_priv_key:
  file.recurse:
    - name: /srv/celestia/{{bridge_dir(node_type, node_config.get('chain_id') )}}/keys/
    - source: salt://celestia/keys/{{ celestia_grain[0] }}/bridge/keys/
    - user: celestia
    - group: celestia

start_celestia:
  service.running:
    - name: celestia-bridge