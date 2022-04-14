with source as (
    select * from {{ source('stg_reporting', 'main_view')}}
)
select * from source