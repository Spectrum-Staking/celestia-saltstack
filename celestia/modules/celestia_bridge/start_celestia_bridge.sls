{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set group = salt['pillar.get']('celestia_config:user_data.group') %}


# Start the Celestia bridge service
start_celestia_bridge_service:
  service.running:
    - name: celestia-bridge.service
    - enable: true

# Create bridge keys directory
create_celestia_logs_directory:
  file.directory:
    - name: {{ home_folder_path }}/{{ user_name }}/celestia_logs
    - user: {{ user_name }}
    - group: {{ group }}
    - makedirs: True
    - mode: '0750'

# Check status of the celestia-bridge service and save output to file
check_celestia_service_status:
  cmd.run:
    - name: systemctl status celestia-bridge.service > {{ home_folder_path }}/{{ user_name }}/celestia_logs/celestia-bridge-status.log || true
    - cwd: {{ home_folder_path }}/{{ user_name }}
    - runas: {{ user_name }}
    - shell: /bin/bash

# Save journal logs for celestia-bridge into a file
check_celestia_bridge_journal_logs:
  cmd.run:
    - name: |
        journalctl -u celestia-bridge > \
        {{ home_folder_path }}/{{ user_name }}/celestia_logs//celestia_logs/celestia-bridge-journal.log 2>&1
    - cwd: {{ home_folder_path }}/{{ user_name }}
    - runas: {{ user_name }}
    - shell: /bin/bash