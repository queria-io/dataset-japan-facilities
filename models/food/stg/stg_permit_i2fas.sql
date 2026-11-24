{# raw_permit_i2fas と同じく publish_i2fas で有効・無効を切り替える。無効の raw を ref すると dbt の parse が止まる #}
{{ config(materialized='ephemeral', enabled=var('publish_i2fas')) }}

-- raw_permit_i2fas を mart から読むための stg。列は raw のまま
SELECT * FROM {{ ref('raw_permit_i2fas') }}
