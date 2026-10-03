{# permit に厚生労働省 食品衛生申請等システム由来の行が混ざっていないこと。
   Japan Food Facilities が取得元の名前を変えると jff_i2fas_source() と一致しなくなり、
   その行が permit 側に落ちる。そうなると permit_i2fas を消しても取り下げにならないので止める。 #}

select source, count(*) as n
from {{ ref('permit') }}
where source like '%食品衛生申請等システム%'
   or source like '%i2fas%'
group by source
