# 食品営業許可・届出の施設一覧

全国の食品営業許可・届出の施設一覧（飲食店・喫茶店・菓子製造業・食肉販売業など約 136 万件）を、SQL で検索・集計・地図表示できるテーブルにしたデータセットです。

## 出典と利用条件

[Japan Food Facilities](https://food.japan-facilities.com/) が配布している全件 CSV を毎週取得し直しています。Japan Food Facilities は、自治体・都道府県・厚生労働省が公開する食品営業許可・届出のオープンデータを集め、共通の列に統一して配布しています。

- データ全体に 1 つのライセンスがあるのではなく、取得元ごとにライセンスが違います。各行の `source` 列が取得元、`license` 列がそのライセンス、`license_id` 列がライセンス ID です（版の表記が無い CC BY は `CC-BY`）
- Japan Food Facilities の提供条件では、商用・非商用を問わず、アプリ・Web サービス・分析・再配布に利用できます。取得元のライセンスはすべて CC BY・公共データ利用規約・CC0 で、非商用に限るものはありません
- 取得元ごとの出典表示は [Japan Food Facilities の出典・ライセンス表示](https://food.japan-facilities.com/attribution.html)にあります。使うときは、使った取得元の出典と、Japan Food Facilities と Queria が加工したものであることを書いてください
- `permit_i2fas` の出典は「[食品衛生申請等システム](https://i2fas.mhlw.go.jp/faspub/IO_S010303.do)」（厚生労働省）です
- Queria は、全件 CSV を取得元によって 2 つのテーブルに分け、業種名の番号の除去、ライセンス表記の正規化、日本の範囲外の座標の除去、ジオメトリの付与を行っています

## テーブル

1 行が許可・届出 1 件で、同じ施設が複数の業種で許可を持つと複数行になります。

| テーブル | 内容 | 行数 |
| --- | --- | ---: |
| `food.permit` | 自治体・都道府県が公開した分（78 の取得元） | 644,462 |
| `food.permit_i2fas` | 厚生労働省 食品衛生申請等システムのオープンデータ由来 | 715,405 |

行数は 2026 年 9 月 28 日のバージョンの値です。

## 使い方

日野市の許可・届出を業種ごとに数える:

```sql
SELECT business_type, count(*) AS permits
FROM (
  SELECT prefecture, city, business_type FROM japan_facilities.food.permit
  UNION ALL
  SELECT prefecture, city, business_type FROM japan_facilities.food.permit_i2fas
)
WHERE prefecture = '東京都' AND city = '日野市'
GROUP BY business_type
ORDER BY permits DESC;
```

## 収録範囲の注意

- 自前で施設一覧を公開していない自治体の区域は `permit_i2fas` にしかありません。千葉・岡山・高知・和歌山・茨城・宮城・島根の各県は `permit` に行が無く、新潟・佐賀・宮崎の各県も `permit` には他県の取得元に入っている数十行以下しかありません。全国を見るときは 2 つのテーブルを `UNION ALL` してください
- `permit_i2fas` には、掲載に賛同した事業者の施設だけが含まれます
- 取得元ごとに収録の範囲が違います。`source` が「東京都（保健医療局）食品関係営業許可台帳」の行は許可だけで届出を含まず、許可番号・許可日・有効期限も空です。都の台帳を届出や許可日まで含めて使うときは `metro_tokyo.hokenjo.food_establishment` を使ってください
- 許可日は半数を超える取得元で全行が空です（行の多いものは大阪市、東京都渋谷区、東京都の台帳、神戸市、鹿児島県）。値があるのは `permit` で 4 割弱、`permit_i2fas` で半分強の行なので、許可日で絞ると多くの行が落ちます
- 許可番号は、`permit` では一部の取得元で全行が空、`permit_i2fas` では 4 割強の行が空です
- 業種名の表記は取得元ごとに違います（「飲食店営業」「飲食店営業(一般飲食店)」など）。業種で絞るときは `LIKE '飲食店営業%'` のように前方一致にしてください
- 廃業した施設や許可期限の切れた施設も残っています
- 市区町村名は Japan Food Facilities が正規化したもので、政令指定都市の区は市にまとめ、郡名は外しています。都道府県・市区町村を特定できなかった行は「不明」です

## 座標の注意

- 緯度経度の多くは Japan Food Facilities が住所から付与した参考値で、各自治体が提供したものではありません
- `geocoding_level` は住所から座標を付与したときの正規化レベルで、3 は町字の代表点、8 は番地以下までです。`lat` が入っていて `geocoding_level` が NULL の行は、元データの座標をそのまま使っています。`lat` が NULL の行は座標がありません
- 日本の範囲外の座標は NULL にしています
