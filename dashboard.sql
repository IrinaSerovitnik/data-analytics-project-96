--Витрина данных с расходами на рекламу (no organic)
with last_visits as (
--расчёт даты последнего визита пользователя
    select
        visitor_id,
        max(visit_date) as last_visit
    from sessions
    where medium != 'organic'
    group by visitor_id
),

--соединение с данными лидов
last_paid_click as (
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
        s.campaign asc
),

--агрегация данных по количеству посетителей и доходам
last_paid_click_agg as (
    select
        lpc.visit_date::date,
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        count(lpc.*) as visitors_count,
        count(lpc.lead_id) as leads_count,
        sum(case when lpc.status_id = 142 then 1 else 0 end) as purchases_count,
        sum(lpc.amount) as revenue
    from last_paid_click as lpc
    group by
        lpc.visit_date::date,
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign
),

--расчёт затрат на рекламу
ads_cost as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign
    union
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from ya_ads
    group by
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign
)

--соединение данных по количеству посетителей, доходам и расходам
select
    lpca.visit_date,
    lpca.utm_source,
    lpca.utm_medium,
    lpca.utm_campaign,
    lpca.visitors_count,
    ac.total_cost,
    lpca.leads_count,
    lpca.purchases_count,
    lpca.revenue
from last_paid_click_agg as lpca
left join ads_cost as ac
    on
        lpca.visit_date = ac.campaign_date::date
        and lpca.utm_source = ac.utm_source
        and lpca.utm_medium = ac.utm_medium
        and lpca.utm_campaign = ac.utm_campaign
order by
    lpca.revenue desc nulls last,
    lpca.visit_date asc,
    lpca.visitors_count desc,
    lpca.utm_source asc,
    lpca.utm_medium asc,
    lpca.utm_campaign asc;

--Расчёт количества дней от клика до покупки (no organic)
with last_visits as (
--расчёт даты последнего визита пользователя
    select
        visitor_id,
        max(visit_date) as last_visit
    from sessions
    where medium != 'organic'
    group by visitor_id
)

--соединение с данными лидов и расчёт разницы дат
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
    l.status_id,
    l.created_at - s.visit_date as diff_date,
    count(l.created_at - s.visit_date)
        over (order by l.created_at - s.visit_date)
    as count_total_diff
from sessions as s
inner join last_visits as lv
    on
        s.visit_date = lv.last_visit
        and s.visitor_id = lv.visitor_id
left join leads as l
    on
        s.visitor_id = l.visitor_id
        and s.visit_date <= l.created_at
where l.status_id = 142
order by
    l.created_at - s.visit_date;

--Витрина данных с расходами на рекламу (organic)
with last_visits as (
    select
        visitor_id,
        max(visit_date) as last_visit
    from sessions
    where medium = 'organic'
    group by visitor_id
),

--соединение с данными лидов
last_paid_click as (
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
        s.campaign asc
)

--агрегация данных по количеству посетителей и доходам
select
    lpc.visit_date::date,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
    count(lpc.*) as visitors_count,
    count(lpc.lead_id) as leads_count,
    sum(case when lpc.status_id = 142 then 1 else 0 end) as purchases_count,
    sum(lpc.amount) as revenue
from last_paid_click as lpc
group by
    lpc.visit_date::date,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign
order by
    sum(lpc.amount) desc nulls last,
    lpc.visit_date::date asc,
    count(lpc.*) desc,
    lpc.utm_source asc,
    lpc.utm_medium asc,
    lpc.utm_campaign asc;
