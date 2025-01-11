{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set group = salt['pillar.get']('celestia_config:user_data:group') %}

{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set node_config = salt['pillar.get']('celestia_config').get(node_type, {}) %}

stop_celestia-appd:
  service.dead:
    - name: celestia-appd

copy_active_keys:
  file.managed:
    - names: 
      - {{ home_folder_path }}/{{ user_name }}/.celestia-app/config/priv_validator_key.json:
        - source: salt://celestia/keys/{{ celestia_grain[0] }}/appd/priv_validator_key.json
      - {{ home_folder_path }}/{{ user_name }}/.celestia-app/config/node_key.json:
        - source: salt://celestia/keys/{{ celestia_grain[0] }}/appd/node_key.json
    - user: celestia

start_celestia:
  service.running:
    - name: celestia-appd