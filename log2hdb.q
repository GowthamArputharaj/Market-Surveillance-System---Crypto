/ log2hdb.q
/ Usage: q log2hdb.q -logFile log/tplog_$(date +%Y.%m.%d) -hdbDir hdb

/ 1. Parse command line arguments
defaultLogFile:"log/tplog_",string .z.D;
logFileArg:defaultLogFile;
hdbDirArg:"hdb";
i:0;
while[i<count .z.x;
    if["-logFile"~.z.x i; if[i+1<count .z.x; logFileArg:.z.x i+1]];
    if["-hdbDir"~.z.x i; if[i+1<count .z.x; hdbDirArg:.z.x i+1]];
    i+:1
    ];
logFile:hsym `$logFileArg;
hdbDir:hsym `$hdbDirArg;

/ 2. Canonical schemas
\l common/schema.q
aggTrade:aggTradeSchema;
depth:depthSchema;

/ 3. Batch size
\l common/config.q
batchSize:BATCH_SIZE;

/ Initialize an empty global sym file if it's a completely fresh HDB directory
if[0=count key hdbDir,`sym; (hdbDir,`sym) set `symbol$()];

/ 4. Flush one table batch to date-partitioned HDB
flushBatch:{[tbl]
    if[0=count value tbl; :()];
    batchDate:first `date$(value tbl)`time;
    
    partitionDir:hsym `$((string hdbDir),"/",(string batchDate),"/",(string tbl),"/");
    batch:`time xasc value tbl;

    partitionDir upsert .Q.en[hdbDir] batch;

    -1 "Flushed ",string count batch," ",(string tbl)," rows to ",string partitionDir;
    tbl set 0#value tbl;
    :()
    };

/ 5. Handle replayed TP updates
.u.upd:{[tbl;payload]
    if[not tbl in `aggTrade`depth; :()];
    tbl insert payload;
    if[batchSize<=count value tbl; flushBatch[tbl]];
    :()
    };

/ 6. Start replay
-1 "Starting TP log -> HDB";
-1 "Log: ",string logFile;
-1 "HDB: ",string hdbDir;
-1 "Batch size: ",string batchSize;

/ 7. Stream the TP log
-11!logFile;

/ 8. Flush remaining rows
flushBatch each `aggTrade`depth;

/ 9. Finished
-1 "Replay complete";
