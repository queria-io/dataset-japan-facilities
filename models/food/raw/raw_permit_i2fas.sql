{# 厚生労働省 食品衛生申請等システム（i2fas）由来の食品営業許可・届出。
   取り下げるときは publish_i2fas を false にする（README の「取り下げ」）。 #}

{{ config(enabled=var('publish_i2fas')) }}

select *
from {{ jff_csv() }}
where sources = {{ jff_i2fas_source() }}
order by {{ jff_spatial_order() }}
