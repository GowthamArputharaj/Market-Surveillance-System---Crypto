plotMicrostructureHTML:{[targetDate; targetSym; startTime; endTime]

    / 1. Query HDB tables safely
    depthSub: select time, side, price from depth where date=targetDate, sym=targetSym, time within (startTime; endTime);
    tradeSub: select time, price, ismm from aggTrade where date=targetDate, sym=targetSym, time within (startTime; endTime);

    -1 "[+] Successfully queried HDB tables!";
    -1 "Depth rows found: ", string count depthSub;
    -1 "Trade rows found: ", string count tradeSub;

    if[(0=count depthSub) or 0=count tradeSub; 
        -1 "[-] Error: Data window is missing depth updates or trades."; :()];

    / 2. Process Level 1 boundaries
    bids: select bid:max price by time from depthSub where side=`buy;
    asks: select ask:min price by time from depthSub where side=`sell;
    l1: bids lj asks;
    plotData: aj[`time; tradeSub; l1];

    -1 "[+] Level 1 book processing complete.";
    
    / 3. Generate comma-separated lists for JavaScript arrays safely using native q scalar vector joins (sv)
    tStr: sv[","; "'",/:string[plotData`time],\:("'")];
    /bidStr: sv[","; string plotData`bid];
    /askStr: sv[","; string plotData`ask];
    bidStr: sv[","; string 0.0^plotData`bid];
    askStr: sv[","; string 0.0^plotData`ask];
    
    tBuys: select time, price from plotData where ismm=0;
    tSells: select time, price from plotData where ismm=1;
    
    tbTime: sv[","; "'",/:string[tBuys`time],\:("'")];
    tbPrice: sv[","; string tBuys`price];
    tsTime: sv[","; "'",/:string[tSells`time],\:("'")];
    tsPrice: sv[","; string tSells`price];

    / 4. Build standalone HTML structure
    / 4. Build standalone HTML structure as a single unified text block
    html: "<!DOCTYPE html>\n<html><head><meta charset='utf-8'><script src='https://cdn.plot.ly/plotly-4.0.0.min.js' charset='utf-8'></script></head><body>\n";
    html: html, "<div id='chart' style='width:100%;height:600px;'></div><script>\n";
    html: html, "var bid = {x:[",tStr,"], y:[",bidStr,"], name:'Best Bid', mode:'lines', line:{shape:'hv', color:'green'}};\n";
    html: html, "var ask = {x:[",tStr,"], y:[",askStr,"], name:'Best Ask', mode:'lines', line:{shape:'hv', color:'red'}};\n";
    html: html, "var buys = {x:[",tbTime,"], y:[",tbPrice,"], name:'Taker Buy', mode:'markers', marker:{symbol:'triangle-up', size:10, color:'blue'}};\n";
    html: html, "var sells = {x:[",tsTime,"], y:[",tsPrice,"], name:'Taker Sell', mode:'markers', marker:{symbol:'triangle-down', size:10, color:'magenta'}};\n";
    html: html, "var layout = {title:'",string[targetSym]," Market Microstructure - ",string[targetDate],"', xaxis:{title:'Time'}, yaxis:{title:'Price'}};\n";
    html: html, "Plotly.newPlot('chart', [bid, ask, buys, sells], layout);\n";
    html: html, "</script></body></html>\n";


    / 5. Save HTML output file up one directory into the analytics folder
    hPath: hsym `$"../analytics/microstructure_chart.html";
    /hPath 0: html;
    hPath 0: enlist html;
    
    -1 "[+] Interactive chart generated successfully at analytics/microstructure_chart.html";
 }
