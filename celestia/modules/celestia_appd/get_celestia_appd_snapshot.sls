{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set group = salt['pillar.get']('celestia_config:user_data:group') %}
{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set node_type = pillar.get('celestia_config', {}).get('node_type', 'wrong_node_type') %}
{% set node_config = pillar.get(node_type, {}) %}

{% set current_date = salt['cmd.run']('date +%Y%m%d') %}
{% set celestia_snapshot = 'celestia' + current_date + '.tar.lz4' %}


# Create the snapshot directory if it doesn't exist
create_snapshot_directory:
  file.directory:
    - name: {{ home_folder_path }}/{{ user_name }}/snapshot
    - makedirs: True
    - user: {{ user_name }}
    - group: {{ group }}
    - mode: '0750'

# Install the lz4 compression tool
install_lz4:
  pkg.installed:
    - name: lz4

# Download the Celestia snapshot for the current date
download_celestia_snapshot:
  cmd.run:
    - name: wget {{ node_config.get('snapshot_url') }}{{ celestia_snapshot }} -O {{ home_folder_path }}/{{ user_name }}/snapshot/{{ celestia_snapshot }}
    - creates: {{ home_folder_path }}/{{ user_name }}/snapshot/celestia{{ celestia_snapshot }}
    - runas: {{ user_name }}

# Stop the Celestia appd service before restoring snapshot
stop_celestia_appd_service:
  service.dead:
    - name: celestia-appd.service

# Backup the validator state if it exists
backup_validator_state:
  cmd.run:
    - name: mv {{ home_folder_path }}/{{ user_name }}/.celestia-app/data/priv_validator_state.json {{ home_folder_path }}/{{ user_name }}/.celestia-app/
    - onlyif: test -f {{ home_folder_path }}/{{ user_name }}/.celestia-app/data/priv_validator_state.json

# Extract the snapshot into the Celestia app directory
extract_snapshot:
  cmd.run:
    - name: lz4 -c -d {{ home_folder_path }}/{{ user_name }}/snapshot/{{ celestia_snapshot }} | tar -x -C {{ home_folder_path }}/{{ user_name }}/.celestia-app
    - runas: {{ user_name }}

# Remove the old priv_validator_state.json file from the data folder
remove_priv_validator_state:
  file.absent:
    - name: {{ home_folder_path }}/{{ user_name }}/.celestia-app/data/priv_validator_state.json

# Restore the priv_validator_state.json file from backup
restore_priv_validator_state:
  cmd.run:
    - name: mv {{ home_folder_path }}/{{ user_name }}/.celestia-app/priv_validator_state.json {{ home_folder_path }}/{{ user_name }}/.celestia-app/data/
    - onlyif: test -f {{ home_folder_path }}/{{ user_name }}/.celestia-app/priv_validator_state.json
    - require:
      - file: remove_priv_validator_state

# Delete the snapshot file after the restore process is complete
delete_celestia_snapshot:
  file.absent:
    - name: {{ home_folder_path }}/{{ user_name }}/snapshot
