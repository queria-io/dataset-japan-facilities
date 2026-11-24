{{ config(enabled=var('publish_i2fas')) }}

{{ jff_permit(ref('stg_permit_i2fas')) }}
