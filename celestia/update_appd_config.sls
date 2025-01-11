{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set group = salt['pillar.get']('celestia_config:user_data:group') %}

{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set node_config = salt['pillar.get']('celestia_config').get(node_type, {}) %}

config:
  file.managed:
    - names:
      - {{ home_folder_path }}/{{ user_name }}/.celestia-app/config/config.toml:
        - source: salt://config/celestia_grain[0]/appd/config.toml
        - template: jinja
      - {{ home_folder_path }}/{{ user_name }}/.celestia-app/config/app.toml:
        - source: salt://config/celestia_grain[0]/appd/app.toml
        - template: jinja
