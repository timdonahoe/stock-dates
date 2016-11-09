set pagesize 0
set linesize 200
set head off
set echo off
set feedback off
set define off
spool wget_bloomberg_urls.sh
select './curl_command.sh ' || to_char(caldate, 'YYYY-MM-DD') || ' > bloomberg/' || to_char(caldate, 'YYYYMMDD') || '.json.gz'
from calendar
where caldate between sysdate-5 and sysdate+30
order by caldate;

select 'gunzip bloomberg/' || to_char(caldate, 'YYYYMMDD') || '.json'
from calendar
where caldate between sysdate-5 and sysdate+30
order by caldate;

select 'jq ''.events[] | {ticker: .company.ticker, date: .eventTime.date}'' bloomberg/' || to_char(caldate, 'YYYYMMDD') || '.json >> bloomberg/all.txt'
from calendar
where caldate between sysdate-5 and sysdate+30
order by caldate;
spool off
exit
EOF
