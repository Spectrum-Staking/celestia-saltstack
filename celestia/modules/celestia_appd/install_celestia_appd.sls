{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set group = salt['pillar.get']('celestia_config:user_data:group') %}

{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set node_config = pillar.get(node_type, {}) %}


# Create the bin directory for the user if not already present
{{ home_folder_path }}/{{ user_name }}/bin:
  file.directory:
    - user: {{ user_name }}
    - group: {{ group }}
    - mode: 0750
    - makedirs: True

# Add home bin to $HOME/bin to the PATH
add_home_bin_to_path:
  file.append:
    - name: {{ home_folder_path }}/{{ user_name }}/.bashrc
    - text: 'export PATH="{{ home_folder_path }}/{{ user_name }}/bin:$PATH"'

# Clone the Celestia app repository
celestia_appd_clone_repo:
  git.latest:
    - name: https://github.com/celestiaorg/celestia-app.git
    - target: {{ home_folder_path }}/{{ user_name }}/celestia-app
    - rev: v{{ node_config.get('celestia_app_version') }}
    - force_reset: True
    - force_fetch: True
    - user: {{ user_name }}

# Build the Celestia app binary
celestia_appd_build:
  cmd.run:
    - name: make build
    - cwd: {{ home_folder_path }}/{{ user_name }}/celestia-app
    - runas: {{ user_name }}
    - require:
      - git: celestia_appd_clone_repo

# Copy the Celestia-appd  binary to the user's bin directory
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

# Create /etc/systemd/system/celestia-appd.service on destination server
create_celestia_appd_service:
  file.managed:
    - name: /etc/systemd/system/celestia-appd.service
    - mode: '0644'
    - contents: |
        [Unit]
        Description=celestia-appd blockchain node
        Requires=network.target

        [Service]
        User={{ user_name }}
        Type=simple
        TimeoutStartSec=10s
        Restart=always
        RestartSec=3
        ExecStart={{ home_folder_path }}/{{ user_name }}/bin/celestia-appd start
        LimitNOFILE=500000
        LimitNPROC=500000
        Environment="HOME={{ home_folder_path }}/{{ user_name }}"
        Environment="LD_LIBRARY_PATH={{ home_folder_path }}/{{ user_name }}/bin"

        [Install]
        WantedBy=default.target

# Reload systemd daemon to recognize the new service
reload_systemd_daemon:
  cmd.run:
    - name: systemctl daemon-reload

# Initialize the Celestia appd service
celestia_appd_init:
   cmd.run:
    - name: celestia-appd init "node-name" --chain-id {{ node_config.get('chain_id') }}
    - runas: {{ user_name }}

# Download the genesis file for the chain
celestia_appd_download_genesis:
  cmd.run:
    - name: celestia-appd download-genesis {{ node_config.get('chain_id') }}
    - runas: {{ user_name }}

# Fetch and update the seed nodes
fetch_and_update_seeds:
  cmd.run:
    - name: |
        SEEDS=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/{{ node_config.get('chain_id') }}/seeds.txt | tr '\n' ',')
        echo $SEEDS
        sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" $HOME/.celestia-app/config/config.toml
    - runas: {{ user_name }}
    - shell: /bin/bash
    - cwd: {{ home_folder_path }}/{{ user_name }}
    - user: {{ user_name }}
    - group: {{ group }}
