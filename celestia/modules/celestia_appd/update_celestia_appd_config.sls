{% set home_folder = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set node_type = pillar.get('celestia_config', {}).get('node_type', 'wrong_node_type') %}
{% set node_config = pillar.get(node_type, {}) %}

# Replace the RPC port configuration in the config.toml file
replace_rpc_port:
  file.replace:
    - name: {{ home_folder }}/{{ user_name }}/.celestia-app/config/config.toml
    - pattern: 'laddr = "tcp://127.0.0.1:(\d+)"'
    - repl: 'laddr = "tcp://127.0.0.1:{{ node_config.get('rpc_port') }}"'
    - append_if_not_found: False

# Replace the P2P port configuration in the config.toml file
replace_p2p_port:
  file.replace:
    - name: {{ home_folder }}/{{ user_name }}/.celestia-app/config/config.toml
    - pattern: 'laddr = "tcp://0.0.0.0:(\d+)"'
    - repl: 'laddr = "tcp://0.0.0.0:{{ node_config.get('p2p_port') }}"'
    - append_if_not_found: False

# Replace the Prometheus status setting in the config.toml file
replace_prometheus_status_celestia_appd:
  file.replace:
    - name: {{ home_folder }}/{{ user_name }}/.celestia-app/config/config.toml
    - pattern: '^prometheus = .*'
    - repl: 'prometheus = {{ node_config.get('prometheus_enabled') }}'
    - append_if_not_found: False

# Replace the Prometheus port configuration in the config.toml file
replace_prometheus_port_celestia_appd:
  file.replace:
    - name: {{ home_folder }}/{{ user_name }}/.celestia-app/config/config.toml
    - pattern: 'prometheus_listen_addr\s+=\s+\":26660\"'
    - repl: 'prometheus_listen_addr = ":{{ node_config.get('prometheus_port') }}"'
    - append_if_not_found: False

# Replace the double_sign_check_height setting in the config.toml file
replace_double_sign_check_height:
  file.replace:
    - name: {{ home_folder }}/{{ user_name }}/.celestia-app/config/config.toml
    - pattern: '^(double_sign_check_height\s*=\s*)\d+'
    - repl: '\g<1>{{ node_config.get('double_sign_check_height') }}'
    - append_if_not_found: False
