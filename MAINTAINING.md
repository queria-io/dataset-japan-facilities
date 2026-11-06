# 運用メモ

## ライセンスのテスト

`license_id` には `accepted_values` のテストを掛けてあります。Japan Food Facilities が商用利用を認めないライセンスの取得元を追加すると、未知の表記として NULL になり、ビルドが止まります。

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
