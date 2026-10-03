"""Japan Food Facilities データパイプライン。

1. food: 食品営業許可・届出の全件 CSV を取得する
2. dbt: dbt ビルド
"""

import logging

from dbt.cli.main import dbtRunner

from pipelines.food import download_food

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger("pipelines")


def dbt_build():
    dbt = dbtRunner()
    for command in (["deps"], ["build"], ["docs", "generate"]):
        result = dbt.invoke(command)
        if not result.success:
            raise SystemExit(f"dbt {' '.join(command)} failed")


def main():
    logger.info("1/2: food (食品営業許可・届出)")
    download_food()

    logger.info("2/2: dbt build")
    dbt_build()


if __name__ == "__main__":
    main()
