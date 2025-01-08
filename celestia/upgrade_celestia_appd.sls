{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set group = salt['pillar.get']('celestia_config:user_data:group') %}

{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set node_config = salt['pillar.get']('celestia_config').get(node_type, {}) %}


# Stop the Celestia appd service
stop_celestia_appd_service:
  service.dead:
    - name: celestia-appd.service
    - enable: false

# Clone the Celestia app repository
celestia_appd_clone_repo:
  git.latest:
    - name: https://github.com/celestiaorg/celestia-app.git
    - target: {{ home_folder_path }}/{{ user_name }}/celestia-app
    - rev: v{{ node_config.get('celestia_app_version') }}
    - force_reset: True
    - force_fetch: True
    - user: {{ user_name }}

# Build the Celestia appd binary
celestia_appd_build:
  cmd.run:
    - name: make build
    - cwd: {{ home_folder_path }}/{{ user_name }}/celestia-app
    - runas: {{ user_name }}
    - require:
      - git: celestia_appd_clone_repo

# Copy the Celestia-appd binary to the user's bin directory
copy_celestia_appd_binary:
  file.managed:
    - name: {{ home_folder_path }}/{{ user_name }}/bin/celestia-appd
    - source: {{ home_folder_path }}/{{ user_name }}/celestia-app/build/celestia-appd
    - user: {{ user_name }}
    - group: {{ group }}
    - mode: 740
    - require:
      - cmd: celestia_appd_build

# Clean up the repository after building the app
celestia_appd_clean_old_repo:
  file.absent:
    - name: {{ home_folder_path }}/{{ user_name }}/celestia-app

# Create celestia logs directory
create_celestia_logs_directory:
  file.directory:
    - name: {{ home_folder_path }}/{{ user_name }}/celestia_logs
    - user: {{ user_name }}
    - group: {{ group }}
    - makedirs: True
    - mode: '0750'

# Start the Celestia appd service again
start_celestia_appd_service:
  service.running:
    - name: celestia-appd.service
    - enable: true

# Check status of the celestia-appd service and save output to file
check_celestia_service_status:
  cmd.run:
    - name: systemctl status celestia-appd.service > {{ home_folder_path }}/{{ user_name }}/celestia_logs/post_upgrade_celestia-appd-status.log || true
    - cwd: {{ home_folder_path }}/{{ user_name }}
    - runas: {{ user_name }}
    - shell: /bin/bash

# Save journal logs for celestia-appd into a file
check_celestia_appd_journal_logs:
  cmd.run:
    - name: |
        journalctl -u celestia-appd > \
        {{ home_folder_path }}/{{ user_name }}/celestia_logs/post_upgrade_celestia-appd-journal.log 2>&1
    - cwd: {{ home_folder_path }}/{{ user_name }}
    - runas: {{ user_name }}
    - shell: /bin/bash
