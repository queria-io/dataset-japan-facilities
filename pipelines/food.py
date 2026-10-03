"""Japan Food Facilities の全件 CSV を取得する。

Japan Food Facilities は自治体・都道府県・厚生労働省が公開する食品営業許可・届出の
オープンデータを集め、共通の列に揃えて毎週配布している。1行が許可・届出1件で、
各行の sources / licenses 列がその行の取得元とライセンスを示す。

取得元ごとの振り分け（厚生労働省 食品衛生申請等システム由来とそれ以外）は dbt 側で行う。

出力: data/food/facilities-all.csv と data/food/fetch.json

データソース: Japan Food Facilities
https://food.japan-facilities.com/
"""

import json
import logging
import shutil
import time
from datetime import UTC, datetime
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

logger = logging.getLogger("pipelines")

USER_AGENT = "dataset-japan-facilities (+https://github.com/queria-io/dataset-japan-facilities)"

CSV_URL = "https://food.japan-facilities.com/api/facilities-all.csv"

OUTPUT_DIR = Path("data/food")

MAX_RETRIES = 2


def download_csv(url: str, output: Path) -> int:
    partial = output.with_suffix(".part")
    for attempt in range(MAX_RETRIES + 1):
        try:
            request = Request(url, headers={"User-Agent": USER_AGENT})
            with urlopen(request, timeout=120) as response, partial.open("wb") as fh:
                shutil.copyfileobj(response, fh, length=1 << 20)
            partial.replace(output)
            return output.stat().st_size
        except (HTTPError, URLError, TimeoutError) as error:
            if isinstance(error, HTTPError) and error.code < 500:
                raise
            if attempt == MAX_RETRIES:
                raise
            logger.warning("retry %d: %s", attempt + 1, error)
            time.sleep(10 * (attempt + 1))
    raise AssertionError("unreachable")


def download_food() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output = OUTPUT_DIR / "facilities-all.csv"
    size = download_csv(CSV_URL, output)
    logger.info("facilities-all.csv: %.1f MB", size / 1e6)

    (OUTPUT_DIR / "fetch.json").write_text(
        json.dumps(
            {
                "url": CSV_URL,
                "bytes": size,
                "fetched_at": datetime.now(UTC).isoformat(timespec="seconds"),
            },
            ensure_ascii=False,
        )
        + "\n"
    )
