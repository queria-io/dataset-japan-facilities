{# テーブルに1行以上あること。配布元がヘッダーだけの CSV や途中で切れた CSV を出しても
   ビルドは通り、公開中のデータが空で置き換わる。それを止める。 #}
{% test not_empty(model) %}
select 1 as empty
where not exists (select 1 from {{ model }})
{% endtest %}
