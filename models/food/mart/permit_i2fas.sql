{{ config(enabled=var('publish_i2fas')) }}

{{ jff_permit(ref('raw_permit_i2fas')) }}
