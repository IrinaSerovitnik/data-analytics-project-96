--витрина данных для модели атрибуции Last Paid Click (no organic)
with last_visits as (
--расчёт даты последнего визита пользователя
    select
        visitor_id,
        max(visit_date) as last_visit
    from sessions
    where medium != 'organic'
    group by visitor_id
)

--соединение с данными лидов
select
    s.visitor_id,
    s.visit_date,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from sessions as s
inner join last_visits as lv
    on
        s.visit_date = lv.last_visit
        and s.visitor_id = lv.visitor_id
left join leads as l
    on
        s.visitor_id = l.visitor_id
        and s.visit_date <= l.created_at
order by
    l.amount desc nulls last,
    s.visit_date asc,
    s.source asc,
    s.medium asc,
    s.campaign asc;
