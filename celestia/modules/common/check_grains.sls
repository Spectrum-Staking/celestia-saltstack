# First, validate and read all required values
{% set celestia_grain = salt['grains.get']('celestia', []) %}
{% set node_type = celestia_grain[0] if celestia_grain else 'unknown_node_type' %}
{% set valid_node_types = salt['pillar.get']('celestia_config:valid_node_type', []) %}

# Check if the 'celestia' grain exists
check_celestia_grain:
  test.configurable_test_state:
    - name: Check if 'celestia' grain is present
    - result: {{ True if celestia_grain else False }}
    - comment: |
        {%- if celestia_grain %}
        Celestia grain is present on minion: {{ celestia_grain }}
        {%- else %}
        ERROR: Celestia grain is missing! Please ensure the grain is configured on Salt minion.
        {%- endif %}
    - failhard: True

# Validate if the grain value is in the list of valid node types
validate_grain_in_valid_node_types:
  test.configurable_test_state:
    - name: Validate if grain value '{{ node_type }}' is in the valid node types
    - result: {{ True if node_type in valid_node_types else False }}
    - comment: |
        {%- if node_type in valid_node_types %}
        Grain value '{{ node_type }}' is valid. It matches one of the valid node types: {{ valid_node_types | join(', ') }}.
        {%- else %}
        ERROR: Grain value '{{ node_type }}' is not valid! Must be one of: {{ valid_node_types | join(', ') }}.
        {%- endif %}
    - failhard: True
    - require:
      - test: check_celestia_grain
