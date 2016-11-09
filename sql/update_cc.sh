sqlplus stock/stock << EOF

/*****  Index should already be there.
create index earning_move_matches_corr_i1
on earning_move_matches_corr (primary_symbol, secondary_symbol);
******/

update earning_moves_test_cases tc
set cc = 
   (select corr(primary_move_pct, secondary_move_pct)
    from earning_move_matches_corr ms
    where tc.primary_symbol = ms.primary_symbol
    and tc.secondary_symbol = ms.secondary_symbol
    and tc.primary_fdate > ms.primary_fdate)
where cc is null;

exit;
EOF
date
