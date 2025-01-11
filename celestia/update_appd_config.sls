{% set celestia_grain = salt['grains.get']('celestia', []) %}

config:
  file.managed:
    - names:
      - {{ home_folder_path }}/{{ user_name }}/.celestia-app/config/config.toml:
        - source: salt://config/celestia_grain[0]/appd/config.toml
        - template: jinja
      - {{ home_folder_path }}/{{ user_name }}/.celestia-app/config/app.toml:
        - source: salt://config/celestia_grain[0]/appd/app.toml
        - template: jinja
