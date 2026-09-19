\p 5011

\l common/schema.q
aggTrade:aggTradeSchema;
depth:depthSchema;

.u.upd:{[tbl;row] tbl insert row;}

tp_handle:hopen `::5010

/ Flush one in-memory table to its matching intraday splayed table.
flush_table:{[tbl]
    if[0=count value tbl; -1 (string .z.T)," - No ",(string tbl)," data arrived. Flush skipped."; :()];

    intra_root:hsym `$"intraday";
    intra_dir:hsym `$"intraday/",(string .z.D),"/",(string tbl),"/";
    intra_dir upsert .Q.en[intra_root] value tbl;

    rowCount:count value tbl;
    tbl set 0#value tbl;

    -1 (string .z.T)," - Flushed ",(string rowCount)," ",(string tbl)," rows to disk. Memory cleared.";
    }

/ 3. Every 30 seconds, flush memory to the temporary disk partition
flush_to_disk:{[]
    flush_table `aggTrade;
    flush_table `depth;
    }

/ 4. Set kdb+ system timer to run every 05 seconds (05000 milliseconds)
\t 5000
.z.ts:{flush_to_disk[]}

/ 5. Midnight Rollover: Move the fully compiled intraday data to the official HDB
.u.endofday:{[]
    -1 "=== Processing Midnight Rollover ===";
    
    / FIX: Use system string format to turn off the timer inside the function
    system "t 0"; 
    
    flush_to_disk[]; / Final flush of any remaining ticks
    
    {
        intra_dir:hsym `$"intraday/",(string .z.D),"/",(string x),"/";
        hdb_dir:hsym `$"hdb/",(string .z.D),"/",(string x),"/";

        if[0=count key intra_dir; -1 "No intraday data found for ",string x; :()];

        day_data:get intra_dir;
        `sym xasc `day_data;

        hdb_dir set day_data;
        @[hdb_dir; `sym; p#];
        } each `aggTrade`depth;
    
    / Clean up temporary intraday files from disk
    hcode: "rm -rf intraday/",(string .z.D);
    system hcode;
    
    / FIX: Use system string format to restart the 30-second timer
    system "t 30000";
    }
