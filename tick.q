\p 5010

d:.z.D
lpath:hsym `$"log/tplog_",string d

/ FIX: Correctly check if the file does not exist using count
if[0=count key lpath; lpath set ()]; 
l:hopen lpath

clients:()

.z.po:{[h] clients::distinct clients,h;}
.z.pc:{[h] clients::clients except h;}

.u.upd:{[tbl;row]
    ts:`timestamp$row[0] * 1000000;

    if[tbl=`aggTrade; payload:(ts; row 1; row 2; row 3; row 4; row 5)];
    if[tbl=`depth; payload:(ts; row 1; `timestamp$row[2]; row 3; row 4; row 5)];
    
    l enlist (`.u.upd; tbl; payload);
    {if[x; (neg x)(`.u.upd; y; z)]}[;tbl;payload] each clients;
    }

.u.end:{[]
    hclose l;
    {if[x; neg[x](".u.endofday")]} each clients;
    d::.z.D;
    lpath::hsym `$"log/tplog_",string d;
    
    / FIX: Initialize the next day's log file container first!
    lpath set (); 
    l::hopen lpath;
    }
