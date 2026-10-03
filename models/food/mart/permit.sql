select {{ jff_permit_columns() }}
from (
    select *, try_cast(lat as double) as lat_d, try_cast(lng as double) as lon_d
    from {{ ref('raw_permit') }}
)
