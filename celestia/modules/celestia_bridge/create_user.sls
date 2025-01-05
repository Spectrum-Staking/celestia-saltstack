{% set user_name = salt['pillar.get']('celestia_config:user_data:user_name') %}
{% set group = salt['pillar.get']('celestia_config:user_data:group') %}
{% set home_folder_path = salt['pillar.get']('celestia_config:user_data:home_folder_path') %}
{% set shell = salt['pillar.get']('celestia_config:user_data:shell') %}


# Create a user if it doesn't already exist
create_user:
  user.present:
    - name: {{ user_name }}
    - createhome: True
    - home: {{ home_folder_path }}/{{ user_name }}
    - shell: {{ shell }}
