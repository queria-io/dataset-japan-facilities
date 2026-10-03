{# publish_i2fas が false のとき、食品衛生申請等システム由来のテーブルをカタログから落とす。

   モデルを無効にしても DuckLake 側のテーブルは残る。ビルドは公開中のカタログを
   pull してから始まるので、落とさないと前回までの raw_permit_i2fas と permit_i2fas が
   そのまま公開され続ける。

   DROP TABLE / DROP VIEW は IF EXISTS を付けても型が違うとエラーになるので、
   カタログに実際どちらで載っているかを引いてから落とす。
   引き先が duckdb_tables() / duckdb_views() なのは、DuckLake の information_schema が
   カタログを跨いでは見えないため。

   DROP はデータベース名まで修飾する。プロファイルの path が :memory: なので
   接続の既定データベースは memory で、修飾しないと IF EXISTS が空振りして何も落ちない。

   ここで落としても過去のスナップショットからは読める。履歴ごと消す手順は README の「取り下げ」。 #}
{% macro drop_withdrawn_i2fas() %}
  {% if not execute or var('publish_i2fas') %}{{ return('') }}{% endif %}

  {% set found = run_query(
      "SELECT database_name, table_name AS name, 'TABLE' AS kind FROM duckdb_tables()"
      ~ "  WHERE database_name = 'japan_facilities' AND schema_name = 'food'"
      ~ "    AND table_name IN ('raw_permit_i2fas', 'permit_i2fas')"
      ~ " UNION ALL "
      ~ "SELECT database_name, view_name, 'VIEW' FROM duckdb_views()"
      ~ "  WHERE database_name = 'japan_facilities' AND schema_name = 'food'"
      ~ "    AND view_name IN ('raw_permit_i2fas', 'permit_i2fas')"
  ) %}

  {% for row in found.rows %}
    {% set qualified = '"' ~ row[0] ~ '".food."' ~ row[1] ~ '"' %}
    {% do log('dropping withdrawn ' ~ row[2] ~ ' ' ~ qualified, info=True) %}
    {% do run_query('DROP ' ~ row[2] ~ ' IF EXISTS ' ~ qualified) %}
  {% endfor %}
{% endmacro %}
