drop table earning_moves_summary;

create table earning_moves_summary as
select symbol, direction, count(*) moves_count
from earning_moves
where fdate < to_date('&&1')
group by symbol, direction;

create index earning_moves_summary_symbol
on earning_moves_summary (symbol);

drop table earning_move_matches_summary;

create table earning_move_matches_summary as
select primary_symbol, secondary_symbol, direction, count(*) match_count
from earning_move_matches
where fdate < to_date('&&1')
group by primary_symbol, secondary_symbol, direction;

create index earning_move_matches_sum_i1
on earning_move_matches_summary (primary_symbol, direction);

create index earning_move_matches_sum_i2
on earning_move_matches_summary (secondary_symbol, direction);

insert into earning_moves_test_cases (primary_symbol, primary_fdate, direction, 
                                      secondary_symbol, moves_count, match_count, test_name) 
select primary_symbol, em.fdate primary_fdate, em.direction, secondary_symbol, moves_count, match_count,
       '&&1 > &&2 &&3% Moves &&4% Matches'
from earning_moves em, 
     earning_moves_summary ems, 
     earning_move_matches_summary emm
where em.fdate between to_date('&&1') and to_date('&&1')+90
and em.symbol = ems.symbol
and em.direction = ems.direction
and em.symbol = emm.primary_symbol
and em.direction = emm.direction
and moves_count > &&2 
and match_count / moves_count > .&&4;

update earning_moves_test_cases tca
set secondary_fdate = 
    (select min(fdate)
     from fdates
     where symbol = secondary_symbol
     and fdate > tca.primary_fdate 
     and fdate <= end_of_quarter(to_date('&&1')))
where secondary_fdate is null;

delete from earning_moves_test_cases
where secondary_fdate is null;

update earning_moves_test_cases tca
set open = 
    (select open
     from stock
     where symbol = secondary_symbol
     and trade_date = previous_business_day(secondary_fdate)),
    close = 
    (select close
     from stock
     where symbol = secondary_symbol
     and trade_date = next_business_day(secondary_fdate))
where open is null;

update earning_moves_test_cases tca
set move_pct = decode(direction, 'U', (close-open)/open, (open-close)/open)
where move_pct is null;

exit
