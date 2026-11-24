{{ config(materialized='ephemeral') }}

-- raw_permit_i2fas を mart から読むための stg。列は raw のまま
SELECT * FROM {{ ref('raw_permit_i2fas') }}
