{% from 'celestia/modules/lib.jinja' import bridge_dir with context %}
{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set group = salt['pillar.get']('celestia_config:user_data:group') %}

{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set node_config = salt['pillar.get']('celestia_config').get(node_type, {}) %}

stop_celestia-appd:
  service.dead:
    - name: celestia-bridge

copy_priv_key:
  file.recurse:
    - name: {{ home_folder_path }}/{{ user_name }}/{{bridge_dir(node_type, node_config.get('chain_id') )}}/keys/
    - source: salt://celestia/keys/{{ celestia_grain[0] }}/bridge/keys/
    - user: celestia
    - group: celestia

start_celestia:
  service.running:
    - name: celestia-bridge