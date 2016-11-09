. $HOME/oraenv.sh
sqlplus stock/stock << EOF

spool cdates
set timing on

insert into earning_moves 
select fdates.symbol, fdates.fdate, before.open, after.close, decode(least(0, after.close-before.open),0,'U','D') direction
from stock before, stock after, fdates
where before.symbol = fdates.symbol
and   after.symbol = fdates.symbol
and   previous_business_day = before.trade_date
and   next_business_day = after.trade_date
and   next_business_day = trunc(sysdate)
and   abs(before.open - after.close) / before.open > .05;

drop table earning_move_matches;

create table earning_move_matches as
select p.symbol primary_symbol, s.symbol secondary_symbol, s.direction, s.fdate
from  earning_moves p, earning_moves s
where s.fdate between p.fdate+1 and end_of_quarter(p.fdate)
and   p.direction = s.direction
group by p.symbol, s.symbol, s.direction, s.fdate;

drop table earning_moves_summary;

create table earning_moves_summary as
select symbol, direction, count(*) moves_count
from earning_moves
group by symbol, direction;

create index earning_moves_summary_symbol
on earning_moves_summary (symbol);

drop table earning_move_matches_summary;

create table earning_move_matches_summary as
select primary_symbol, secondary_symbol, direction, count(*) match_count
from earning_move_matches
group by primary_symbol, secondary_symbol, direction;

create index earning_move_matches_sum_psym
on earning_move_matches_summary (primary_symbol);

create index earning_move_matches_sum_ssym
on earning_move_matches_summary (secondary_symbol);

select sysdate from dual;

set linesize 200
set pagesize 100

select emm.primary_symbol, em.fdate primary_fdate, em.open, em.close, em.direction, emm.secondary_symbol, fdates.fdate, moves_count-1,emm.match_count, corr.cc
from earning_moves em,
     earning_moves_summary ems,
     earning_move_matches_summary emm,
     earning_move_matches_sum_corr corr,
     fdates
where em.fdate between to_date('01-Oct-16') and sysdate 
and em.symbol = ems.symbol
and em.direction = ems.direction
and em.symbol = emm.primary_symbol
and em.direction = emm.direction
and emm.primary_symbol = corr.primary_symbol 
and emm.secondary_symbol = corr.secondary_symbol 
and fdates.symbol = emm.secondary_symbol
and fdates.fdate between sysdate and add_months(to_date('01-Oct-16'), 3)
and moves_count-1 > 8
and emm.match_count / decode(moves_count,1,1,moves_count-1) > .75
and cc > .46
order by fdates.fdate;

spool off


exit
EOF
date
mailx -s "Stock Earnings" tdonahoe@americanwineryguide.com < cdates.lst
