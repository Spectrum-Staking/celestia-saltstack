{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}

{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set node_config = pillar.get(node_type, {}) %}


# Update the 'indexer' configuration in the Celestia app config file
update_indexer_config:
  file.replace:
    - name: {{ home_folder_path }}/{{ user_name }}/.celestia-app/config/config.toml
    - pattern: '^indexer = .*'
    - repl: 'indexer = "{{ node_config.get('indexer') }}"'
    - append_if_not_found: False

# Add or update the 'min-retain-blocks' setting in the Celestia app config file
add_min_retain_blocks:
  file.replace:
    - name: {{ home_folder_path }}/{{ user_name }}/.celestia-app/config/config.toml
    - pattern: '^min-retain-blocks = \d+'
    - repl: 'min-retain-blocks = {{ node_config.get('min_retain_blocks') }}'
    - append_if_not_found: True
