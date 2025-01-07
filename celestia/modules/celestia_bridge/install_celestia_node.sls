{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set group = salt['pillar.get']('celestia_config:user_data:group') %}

{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set node_config = pillar.get(node_type, {}) %}


# Create the bin directory if not already present
{{ home_folder_path }}/{{ user_name }}/bin:
  file.directory:
    - user: {{ user_name }}
    - group: {{ group }}
    - mode: 0750
    - makedirs: True

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

# Run make cel-key
celestia_cel_key_build:
  cmd.run:
    - name: make cel-key
    - cwd: {{ home_folder_path }}/{{ user_name }}/celestia-bridge
    - runas: {{ user_name }}
    - require:
      - git: celestia_clone_repo

# Copy the built celetia key to the user's bin directory
copy_cel_key_binary:
  file.managed:
    - name: {{ home_folder_path }}/{{ user_name }}/bin/cel-key
    - source: {{ home_folder_path }}/{{ user_name }}/celestia-bridge/cel-key
    - user: {{ user_name }}
    - group: {{ group }}
    - mode: 740
    - require:
      - cmd: celestia_cel_key_build

# Clean up the repository after building the bridge
celestia_bridge_clean_old_repo:
  file.absent:
    - name: {{ home_folder_path }}/{{ user_name }}/celestia-bridge

# Create /etc/systemd/system/celestia-bridge.service on destination server
create_celestia_bridge_service:
  file.managed:
    - name: /etc/systemd/system/celestia-bridge.service
    - mode: '0750'
    - contents: |
        [Unit]
        Description=celestia-bridge blockchain node
        Requires=network.target

        [Service]
        User={{ user_name }}
        Type=simple
        TimeoutStartSec=10s
        Restart=always
        RestartSec=3
        ExecStart={{ home_folder_path }}/{{ user_name }}/bin/celestia bridge start \
        --core.ip rpc-mocha.pops.one:26657 \
        --p2p.network mocha
        LimitNOFILE=1400000
        Environment="HOME={{ home_folder_path }}/{{ user_name }}"
        Environment="LD_LIBRARY_PATH={{ home_folder_path }}/{{ user_name }}/bin"

        [Install]
        WantedBy=default.target

# Reload systemd daemon to recognize the new service
reload_systemd_daemon:
  cmd.run:
    - name: systemctl daemon-reload

# Create bridge keys directory
create_bridge_keys_directory:
  file.directory:
    - name: {{ home_folder_path }}/{{ user_name }}/celestia_keys
    - user: {{ user_name }}
    - group: {{ group }}
    - makedirs: True
    - mode: '0750'

# Run celestia bridge init
initialize_celestia_bridge:
  cmd.run:
    - name: |
        {% if node_type == 'celestia_testnet' %}
        {{ home_folder_path }}/{{ user_name }}/bin/celestia bridge init --core.ip {{ node_config.get('celestia_bridge_core_ip') }} --p2p.network mocha > {{ home_folder_path }}/{{ user_name }}/celestia_keys/bridge_key.txt 2>&1
        {% elif node_type == 'celestia_mainnet' %}
        {{ home_folder_path }}/{{ user_name }}/bin/celestia bridge init --core.ip {{ node_config.get('celestia_bridge_core_ip') }} > {{ home_folder_path }}/{{ user_name }}/celestia_keys/bridge_key 2>&1
        {% else %}
        echo "Invalid node type: {{ node_type }}" >&2
        exit 1
        {% endif %}
    - runas: {{ user_name }}
    - env:
        HOME: {{ home_folder_path }}/{{ user_name }}
    - creates: {{ home_folder_path }}/{{ user_name }}/celestia_keys/bridge_key.txt
    - cwd: {{ home_folder_path }}/{{ user_name }}
    - shell: /bin/bash
