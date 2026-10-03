{# Japan Food Facilities の全件 CSV。pipelines/food.py が data/food/facilities-all.csv に保存する。
   値に改行と二重引用符を含む行があり、自動判定に任せると引用符なしと誤判定して読めない。

   列はヘッダーの名前で選ぶ。read_csv の columns に型を渡すと位置で対応づけられ、
   配布元が列の順番を変えると値が別の列に入ったまま公開される。
   列が消えれば select で止まり、列が増えても公開する列には入らない。 #}
{% macro jff_csv() -%}
(
    select
        prefecture,
        city,
        city_raw,
        name,
        name_kana,
        business_type,
        address,
        lat,
        lng,
        geocoding_level,
        phone,
        license_no,
        license_date,
        expire_date,
        sources,
        licenses
    from read_csv(
        'data/food/facilities-all.csv',
        header = true,
        quote = '"',
        escape = '"',
        all_varchar = true
    )
)
{%- endmacro %}

{# 厚生労働省 食品衛生申請等システム（i2fas）由来の行を表す sources の値。
   この行だけを別のテーブルに分け、そのテーブルを消せば i2fas 由来のデータが
   公開カタログから外れるようにしてある（README の「取り下げ」）。 #}
{% macro jff_i2fas_source() -%}
'厚生労働省 食品衛生申請等システム（オープンデータ）'
{%- endmacro %}

{# 日本の外接矩形。端は沖ノ鳥島 北緯 20.42 / 択捉島 北緯 45.55 /
   与那国島 東経 122.93 / 南鳥島 東経 153.98 #}
{% macro jff_in_japan(lat, lon) -%}
({{ lat }} between 20.0 and 46.0 and {{ lon }} between 122.0 and 154.5)
{%- endmacro %}

{# raw の並び順。近い場所の行が同じ行グループに入るよう、ヒルベルト曲線の順に並べる。
   座標の無い行は末尾にまとめる。 #}
{% macro jff_spatial_order(lat='try_cast(lat as double)', lon='try_cast(lng as double)') -%}
{{ lat }} is null,
    st_hilbert({{ lon }}, {{ lat }}, {'min_x': 122.0, 'min_y': 20.0, 'max_x': 154.5, 'max_y': 46.0}::box_2d)
{%- endmacro %}

{# 公開テーブル。raw_permit と raw_permit_i2fas の両方に同じ整形を当てる。

   - business_type は取得元によって「① 飲食店営業」のように丸数字の番号が付く。
     番号を外したものを business_type、元の値を business_type_raw に置く
   - license_id は licenses 列の表記をライセンス ID に揃えたもの。
     知らない表記が来たら NULL になり、accepted_values のテストで止まる
   - 座標は日本の範囲外を NULL にする #}
{% macro jff_permit(relation) -%}
select
    prefecture,
    city,
    city_raw,
    name,
    name_kana,
    nullif(trim(regexp_replace(business_type, '^[①-⑳㉑-㉟]\s*', '')), '') as business_type,
    business_type as business_type_raw,
    address,
    case when {{ jff_in_japan('lat_d', 'lon_d') }} then lat_d end as lat,
    case when {{ jff_in_japan('lat_d', 'lon_d') }} then lon_d end as lon,
    try_cast(geocoding_level as integer) as geocoding_level,
    phone,
    license_no,
    try_cast(license_date as date) as license_date,
    try_cast(expire_date as date) as expire_date,
    sources as source,
    licenses as license,
    case licenses
        when 'CC BY 4.0' then 'CC-BY-4.0'
        when 'Creative Commons Attribution 4.0 International' then 'CC-BY-4.0'
        when 'CC BY 3.0' then 'CC-BY-3.0'
        when 'CC BY 2.1 JP' then 'CC-BY-2.1-JP'
        when 'CC BY 2.0' then 'CC-BY-2.0'
        when 'CC BY' then 'CC-BY'
        when 'CC0 1.0' then 'CC0-1.0'
        when '公共データ利用規約（第1.0版, PDL1.0）' then 'JP-PDL-1.0'
        when '公共データ利用規約' then 'JP-PDL-1.0'
    end as license_id,
    case when {{ jff_in_japan('lat_d', 'lon_d') }} then st_point(lon_d, lat_d) end as geometry
from (
    select *, try_cast(lat as double) as lat_d, try_cast(lng as double) as lon_d
    from {{ relation }}
)
{%- endmacro %}
