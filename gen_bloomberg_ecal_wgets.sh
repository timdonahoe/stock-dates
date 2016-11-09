. $HOME/oraenv.sh
cd /home/oracle/tim/stock/dates
sqlplus stock/stock @make_curl_command
chmod 755 wget_bloomberg_urls.sh
rm -f bloomberg/*
./wget_bloomberg_urls.sh
awk -f gen_bloomberg_inserts.awk bloomberg/all.txt > insert_bdates.sql

sqlplus stock/stock << EOF
truncate table bfdates;
set feedback off
@insert_bdates
set feedback on
delete from fdates 
where fdate > sysdate-5;

insert into fdates (symbol, fdate, next_business_day, previous_business_day)
select symbol,
       fdate,
       next_business_day(fdate),
       previous_business_day(fdate)
from   bfdates;

exit
EOF
date
