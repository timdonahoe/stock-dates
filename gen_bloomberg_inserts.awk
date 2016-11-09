{if (index($1, "date") != 0) {
        MM=substr($2, 2, index($2, "/")-2)
        if (length(MM) == 1) { 
           MM= "0" MM
        }
        REST=substr($2, index($2, "/")+1, length(substr($2, index($2, "/")+1))-2)
        DD=substr(REST, 1, index(REST, "/")-1)
        if (length(DD) == 1) { 
           DD= "0" DD
        }
        YY=substr(REST, index(REST, "/")+1)
        getline;
        SYM=substr($2, 2, index($2, ":")-2)
        print "insert into bfdates (symbol, fdate) values ('" SYM "', to_date('" MM "/" DD "/" YY "', 'MM/DD/YYYY'));"
        }
}
