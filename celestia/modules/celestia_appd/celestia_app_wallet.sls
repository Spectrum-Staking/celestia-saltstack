{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set wallet_name = salt['pillar.get']('celestia_config:wallet_name') %}

# Ensure app keys directory exists
create_app_keys_directory:
  file.directory:
    - name: {{ home_folder_path }}/{{ user_name }}/celestia_keys
    - user: {{ user_name }}
    - group: {{ user_name }}
    - makedirs: True
    - mode: '0750'

# Create CLI configuration for Celestia application
setup_cli_config:
  cmd.run:
    - name: celestia-appd config keyring-backend test
    - runas: {{ user_name }}
    - env:
        HOME: {{ home_folder_path }}/{{ user_name }}
        PATH: /srv/celestia/bin:/usr/local/bin:/usr/bin:/bin
    - cwd: {{ home_folder_path }}/{{ user_name }}

# Add validator key with complete output capture
# Add validator key with complete output
add_validator_key:
  cmd.run:
    - name: |
        celestia-appd keys add {{ wallet_name }}  >  {{ home_folder_path }}/{{ user_name }}/celestia_keys/{{ wallet_name }}_key_output.txt 2>&1
    - runas: {{ user_name }}
    - creates: {{ home_folder_path }}/{{ user_name }}/celestia_keys/{{ wallet_name }}_key_output.txt
