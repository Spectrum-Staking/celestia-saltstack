{% set node_type = pillar.get('celestia_config', {}).get('node_type', 'wrong_node_type') %}
{% set packages = pillar.get('celestia_config', {}).get('packages') %}
{% set node_config = pillar.get(node_type, {}) %}

# Ensure the system is updated and upgraded
update_system:
  cmd.run:
    - name: apt update && apt upgrade -y
    - require:
      - pkg: install_apt_utils

# Ensure apt-utils is installed before running the update and upgrade commands
install_apt_utils:
  pkg.installed:
    - name: apt-utils

# Install the packages
install_packages:
  pkg.installed:
    - pkgs: {{ packages }}

# Ensure that Go repository is added and updated
golang-repo:
  pkgrepo.managed:
    - name: ppa:longsleep/golang-backports
    - refresh_db: true
    - require_in:
      - pkg: golang-go

# Install Go from the backports repository, only if it's not already installed
golang-go:
  pkg.installed:
    - name: golang-go
    - version: {{ node_config.get('go_ver') }}
    - refresh: true
    - allow_updates: true
    - pkgrepo: ppa:longsleep/golang-backports
    - unless: test -x $(which go)
