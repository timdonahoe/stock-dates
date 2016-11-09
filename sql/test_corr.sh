. $HOME/oraenv.sh
sqlplus stock/stock << EOF
spool test
set echo on
set termout on
set timing on

drop table earning_moves_corr;

create table earning_moves_corr as
select fdates.symbol, fdates.fdate, round((after.close-before.open)/before.open, 2) move_pct
from stock before, stock after, fdates
where before.symbol = fdates.symbol
and   after.symbol = fdates.symbol
and   previous_business_day = before.trade_date
and   next_business_day = after.trade_date;

create index earning_moves_corr_i1
on earning_moves_corr (fdate);

drop table earning_move_matches_corr;

create table earning_move_matches_corr as
select p.symbol primary_symbol, p.fdate primary_fdate, p.move_pct primary_move_pct, 
       s.symbol secondary_symbol, s.fdate secondary_fdate, s.move_pct secondary_move_pct
from earning_moves_corr p, earning_moves_corr s
where s.fdate between p.fdate+1 and end_of_quarter(p.fdate);

create index earning_move_matches_corr_i1
on earning_move_matches_corr (primary_symbol, secondary_symbol);

drop table earning_move_matches_sum_corr;
 
create table earning_move_matches_sum_corr as
select primary_symbol, secondary_symbol, 
       corr(primary_move_pct, secondary_move_pct) cc,
       count(*) match_count
from earning_move_matches_corr
where primary_symbol between 'A' and 'E1'
group by primary_symbol, secondary_symbol;

insert into earning_move_matches_sum_corr
select primary_symbol, secondary_symbol, 
       corr(primary_move_pct, secondary_move_pct) cc,
       count(*) match_count
from earning_move_matches_corr
where primary_symbol between 'E2' and 'J1'
group by primary_symbol, secondary_symbol;

insert into earning_move_matches_sum_corr
select primary_symbol, secondary_symbol, 
       corr(primary_move_pct, secondary_move_pct) cc,
       count(*) match_count
from earning_move_matches_corr
where primary_symbol between 'J2' and 'O1'
group by primary_symbol, secondary_symbol;

insert into earning_move_matches_sum_corr
select primary_symbol, secondary_symbol, 
       corr(primary_move_pct, secondary_move_pct) cc,
       count(*) match_count
from earning_move_matches_corr
where primary_symbol between 'O2' and 'T1'
group by primary_symbol, secondary_symbol;

insert into earning_move_matches_sum_corr
select primary_symbol, secondary_symbol, 
       corr(primary_move_pct, secondary_move_pct) cc,
       count(*) match_count
from earning_move_matches_corr
where primary_symbol between 'T2' and 'ZZZZZZZ'
group by primary_symbol, secondary_symbol;

create index earning_move_matches_sum_ci1
on earning_move_matches_sum_corr (primary_symbol, secondary_symbol);

delete from earning_moves_test_cases
where test_name = '01-Oct-16 > 8 5% Moves 75% Matches'; 
exit;
EOF

cd tim/stock/dates/sql
sqlplus stock/stock @testq 01-Oct-16 8 5 75

./update_cc.sh

sqlplus stock/stock << EOF
set linesize 250
set pagesize 250
select * 
from earning_moves_test_cases 
where cc > .46 
and test_name = '01-Oct-16 > 8 5% Moves 75% Matches' 
order by secondary_fdate;
exit
EOF
date
