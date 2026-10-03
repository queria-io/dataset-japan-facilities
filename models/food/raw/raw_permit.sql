{# 自治体・都道府県が公開した食品営業許可・届出（厚生労働省 食品衛生申請等システム由来を除く）。 #}

select *
from {{ jff_csv() }}
where sources is distinct from {{ jff_i2fas_source() }}
order by {{ jff_spatial_order() }}
