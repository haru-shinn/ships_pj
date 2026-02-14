{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {%- if target.name == 'prd' -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- elif target.name == 'stg' -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}_stg 
        {%- elif target.name.startswith('dev') -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}_dev
        {%- endif -%}
    {%- endif -%}
{%- endmacro %}