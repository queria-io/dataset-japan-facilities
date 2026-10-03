# dataset-japan-facilities

全国の食品営業許可・届出の施設一覧を、Queria のカタログ（[data.queria.io](https://data.queria.io/)）へ
取り込むデータセットです。

## データ出典

[Japan Food Facilities](https://food.japan-facilities.com/) が配布している全件 CSV を毎週取り直しています。
Japan Food Facilities は、自治体・都道府県・厚生労働省が公開する食品営業許可・届出のオープンデータを
集め、共通の列に揃えて配布しています。

データ全体に1つのライセンスがあるのではなく、取得元ごとにライセンスが違います。各行の `source` 列が
取得元、`license` 列がそのライセンス、`license_id` 列がライセンス ID です（版の表記が無い CC BY は `CC-BY`）。取得元ごとの
出典表示は [Japan Food Facilities の出典・ライセンス表示](https://food.japan-facilities.com/attribution.html)
にあります。

`license_id` には `accepted_values` のテストを掛けてあります。Japan Food Facilities が商用利用を
認めないライセンスの取得元を足すと、知らない表記として NULL になり、ビルドが止まります。

## 収録テーブル

`food` スキーマに2テーブル。1行が許可・届出1件で、同じ施設が複数の業種で許可を持つと複数行になります。

| テーブル | 内容 | 行数 |
| --- | --- | ---: |
| `permit` | 自治体・都道府県が公開した分（78 の取得元） | 644,462 |
| `permit_i2fas` | 厚生労働省 食品衛生申請等システムのオープンデータ由来 | 715,405 |

行数は 2026-09-28 版の実測です。自前で施設一覧を公開していない自治体の区域は `permit_i2fas` にしか
ありません。全国を見るときは2テーブルを `UNION ALL` します。

廃業した施設や許可期限の切れた施設も残っています。緯度経度の多くは Japan Food Facilities が住所から
付与したもので、精度は `geocoding_level` で分かります。

## 取り下げ

`permit_i2fas` は、これだけを公開カタログから外せるように別のテーブルにしてあります。

1. `dbt_project.yml` の `publish_i2fas` を `false` にし、`models/food/mart/permit.table.yml` から
   `permit_i2fas` の項目を消して main に入れる。Sync のビルドが冒頭で `raw_permit_i2fas` と
   `permit_i2fas` をカタログから落とし（`macros/drop_withdrawn_i2fas.sql`）、落とした状態で公開する
2. 1 の Sync が終わったら、過去のスナップショットとそのデータファイルを消す。手元で

   ```bash
   export QUERIA_TOKEN="$(op read op://Development/queria-token/QUERIA_TOKEN)"
   uv run queria pull --handle queria
   uv run queria expire --retention-days 0
   uv run queria push
   ```

   2 をやらなくても、毎週の Checkpoint が7日より古いスナップショットを消すので、2週間以内には
   履歴からも消えます。2 は消えるまでの期間を縮めるための手順です。

1 の Sync が終わる前に 2 を流すと、公開中のカタログが参照するファイルを消して読めない時間ができます。
順番を入れ替えないでください。
