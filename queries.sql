-- Missing rubles report
select description || ' (' || beginning || ' - ' || ending || ')'
from rubles
where count = 0;

-- Third zloty report
select tz.value || ' ' || tz.name || ' (' || tz.beginning || ' - ' || tz.ending || ', ' || tz.material || ', ' ||
       tz.diameter || 'mm' || coalesce(', ' || tz.description, '') || ')',
       count
from third_zloty tz
where count > 1;

-- Missing coins report, no description --
select cou.name || ', ' || cu.name || ', ' || coi.value || ' ' || coi.name || ' (' || coi.beginning || ' - ' ||
       coi.ending || ')'
from countries cou
         left outer join currencies cu on cou.id = cu.country_id
         left outer join coins coi on coi.currency_id = cu.id
where lowest
  and coi.count = 0
  and coi.ending > 1900
order by cou.name, cu.beginning;

-- Missing coins report, with description -- BASE COLLECTION
select cou.name || ', ' || cu.name || ', ' || coi.value || ' ' || coi.name || ' (' || coi.beginning || ' - ' ||
       coi.ending || ')' || coalesce(' (' || coi.description || ')', '')
from countries cou
         left outer join currencies cu on cou.id = cu.country_id
         left outer join coins coi on coi.currency_id = cu.id
where lowest
  and coi.count = 0
  and coi.ending > 1900
order by cou.name, cu.beginning;

-- Coins out of scope
select coi.id, cou.name, cu.name, coi.value, coi.name, coi.beginning, coi.ending
from countries cou
         left join currencies cu on cou.id = cu.country_id
         left join coins coi on cu.id = coi.currency_id
where coi.lowest
  and coi.ending <= 1900
order by cou.name, cu.beginning;

-- Collected coins >= 1900
select cou.name || ', ' || cu.name || ', ' || coi.value || ' ' || coi.name || ' (' || coi.beginning || ' - ' ||
       coi.ending || ')'
from countries cou
         left outer join currencies cu on cou.id = cu.country_id
         left outer join coins coi on coi.currency_id = cu.id
where lowest
  and coi.count > 0
  and coi.ending > 1900
order by cou.name, cu.beginning;

-- Collected coins
select cou.name || ', ' || cu.name || ', ' || coi.value || ' ' || coi.name || ' (' || coi.beginning || ' - ' ||
       coi.ending || ')'
from countries cou
         left outer join currencies cu on cou.id = cu.country_id
         left outer join coins coi on coi.currency_id = cu.id
where lowest
  and coi.count > 0
order by cou.name, cu.beginning;

-- Coins by continent report
select cou.continent,
       count(*)                                                                                  total,
       count(*) filter ( where coi.count > 0 )                                                   collected,
        count(*) filter ( where coi.count = 0 )                                                   missing,
            round(cast(100 * cast(count(*) filter ( where coi.count > 0 ) as double precision) / count(*) as numeric), 1) || '%' progress_percent
from countries cou
         left outer join currencies cu on cou.id = cu.country_id
         left outer join coins coi on cu.id = coi.currency_id
where coi.lowest
  and coi.ending > 1900
group by rollup (cou.continent)
order by continent is not null, cast(count(*) filter ( where coi.count > 0 ) as double precision) / count(*) desc;

-- Finished countries
select *
from countries cou
where exists(select *
             from currencies cu
                      inner join coins coi on cu.id = coi.currency_id
             where cu.country_id = cou.id)
  and not exists(select *
                 from currencies cu
                          inner join coins coi on cu.id = coi.currency_id
                 where cu.country_id = cou.id
                   and coi.count = 0
                   and lowest);

-- Progress report all coins
select (select count(*) from coins where lowest and count > 0) || '/' || (select count(*) from coins where lowest);

-- Progress report >= 1900
with t(collected, left_to_collect) as (
    (select (select count(*)
             from coins
             where lowest
               and count > 0
               and ending > 1900),
            (select count(*) from coins where lowest and ending > 1900)))
select collected || '/' || left_to_collect                                                           progress,
       round(cast(cast(collected as double precision) * 100 / left_to_collect as numeric), 1) || '%' progress_percent
from t;
-- 426 base
-- + 11 old polish coins (543, 544, 545, 546, 547, 548, 549, 550, 551, 552 + szeląg)
-- + [5 - 9] pre 1900 (39, 54, 109, 128, 598[, 103, 361, 631, 657]) == (Hong Kong, United Kingdom, United States, Japan, Austrian empire[, Greece, Isle of Man, Hungary, Gibraltar])

-- Progress report by continent
select cou.continent, count(*) filter ( where coi.count > 0 ) collected, count(*) sum, round(cast(100 * cast(count(*) filter ( where coi.count > 0 ) as double precision) / count(*) as numeric), 1) percent_done
from countries cou
    join currencies cu on cou.id = cu.country_id
    join coins coi on cu.id = coi.currency_id
where coi.ending > 1900
  and lowest
group by cou.continent
order by percent_done desc;

-- Count by country
select cou.continent, cou.name, count(*)
from countries cou
         join currencies cu on cou.id = cu.country_id
         join coins coi on cu.id = coi.currency_id
where coi.ending > 1900
  and lowest
group by cou.name, cou.continent
order by cou.continent, cou.name;

-- Details about coins from a country
select cou.id, cou.name, cu.id, cu.name, coi.id, coi.value, coi.name, coi.beginning, coi.ending, coi.description, coi.count
from countries cou
         join currencies cu on cou.id = cu.country_id
         join coins coi on cu.id = coi.currency_id
where coi.ending > 1900
  and lowest
  and (cou.name ~ 'Greece')
order by coi.ending, coi.beginning;

-- Diameter distribution
select ceil(diameter), count(*)
from coin_diameters
group by ceil(diameter)
order by ceil(diameter);

-- largest coins
select cou.name, cu.name, coi.value, coi.name, cd.diameter
from coin_diameters cd
         join coins coi on coi.id = cd.coin_id
         join currencies cu on coi.currency_id = cu.id
         join countries cou on cu.country_id = cou.id
where cd.diameter > 27;