{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set group = salt['pillar.get']('celestia_config:user_data:group') %}

{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set node_config = salt['pillar.get']('celestia_config').get(node_type, {}) %}


# Stop the Celestia bridge service
stop_celestia_bridge_service:
  service.dead:
    - name: celestia-bridge.service
    - enable: false

# Clone the Celestia node repository
celestia_clone_repo:
  git.latest:
    - name: https://github.com/celestiaorg/celestia-node.git
    - target: {{ home_folder_path }}/{{ user_name }}/celestia-bridge
    - rev: v{{ node_config.get('celestia_node_version') }}
    - user: {{ user_name }}
    - force_reset: True
    - force_fetch: True

# Build the Celestia node binary
celestia_build:
  cmd.run:
    - name: make build
    - cwd: {{ home_folder_path }}/{{ user_name }}/celestia-bridge
    - runas: {{ user_name }}
    - require:
      - git: celestia_clone_repo

# Copy the built binary to the user's bin directory
copy_celestia_bridge_binary:
  file.managed:
    - name: {{ home_folder_path }}/{{ user_name }}/bin/celestia
    - source: {{ home_folder_path }}/{{ user_name }}/celestia-bridge/build/celestia
    - user: {{ user_name }}
    - group: {{ group }}
    - mode: 740
    - require:
      - cmd: celestia_build

# Clean up the repository after building the bridge
celestia_bridge_clean_old_repo:
  file.absent:
    - name: {{ home_folder_path }}/{{ user_name }}/celestia-bridge

# Create celestia logs directory
create_celestia_logs_directory:
  file.directory:
    - name: {{ home_folder_path }}/{{ user_name }}/celestia_logs
    - user: {{ user_name }}
    - group: {{ group }}
    - makedirs: True
    - mode: '0750'

# Start the Celestia bridge service
start_celestia_bridge_service:
  service.running:
    - name: celestia-bridge.service
    - enable: true

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
