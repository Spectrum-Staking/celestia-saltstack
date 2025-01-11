{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}

stop_celestia:
  service.dead:
    - name: celestia-appd

remove_keys:
  file.absent:
    - names:
      - {{ home_folder_path }}/{{ user_name }}/.celestia-app/config/priv_validator_key.json
      - {{ home_folder_path }}/{{ user_name }}/.celestia-app/config/node_key.json

start_celestia:
  service.running:
    - name: celestia-appd
