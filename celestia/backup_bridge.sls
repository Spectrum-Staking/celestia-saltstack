{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}

{% from 'celestia/modules/lib.jinja' import bridge_dir with context %}
{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set node_config = salt['pillar.get']('celestia_config').get(node_type, {}) %}

stop_celestia-bridge:
  service.dead:
    - name: celestia-bridge

remove_keys:
  file.absent:
    - names:
      - '{{ home_folder_path }}/{{ user_name }}/{{bridge_dir(node_type, node_config.get('chain_id') )}}/keys'

generate_dummy_bridge_key:
  cmd.run:
    - name: |
        {% if node_type == 'testnet' %}
        {{ home_folder_path }}/{{ user_name }}/bin/celestia bridge init --p2p.network mocha
        {% elif node_type == 'mainnet' %}
        {{ home_folder_path }}/{{ user_name }}/bin/celestia bridge init
        {% endif %}
    - runas: {{ user_name }}

start_celestia-bridge:
  service.running:
    - name: celestia-bridge