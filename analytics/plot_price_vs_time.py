import argparse
import sys
import pandas as pd
import plotly.graph_objects as go
import plotly.io as pio

print("[*] STEP 0: Booting up wrapper script and parsing flags...")

# 1. Setup argument parameters 
parser = argparse.ArgumentParser(description="Plot Interactive Order Book Microstructure Map.")
parser.add_argument("--date", required=True)
parser.add_argument("--sym", required=True)
parser.add_argument("--start", required=True)
parser.add_argument("--end", required=True)
parser.add_argument("--port", type=int, default=5001)
args = parser.parse_args()

print("[*] STEP 1: Initializing PyKX Core Engine...")
import pykx as kx

def main():
    start_ts = f"{args.date}D{args.start}"
    end_ts = f"{args.date}D{args.end}"

    print(f"[*] STEP 2: Connecting to running HDB server at localhost:{args.port}...")
    try:
        q_conn = kx.SyncQConnection(host='localhost', port=args.port)
    except Exception as e:
        print(f"[-] ERROR: Port {args.port} is closed. Details: {e}")
        sys.exit(1)

    print("[*] STEP 3: Fetching Level-1 Best Bid/Ask vectors (filtering outliers)...")
    # CRITICAL: We restrict bids to 'max price' and asks to 'min price' per timestamp 
    # to eliminate the far-away \$73k outliers from distorting our visualization scale.
    
    depth_q = f"""
        depthSub: select time, side, price from depth where date={args.date}, sym=`{args.sym}, time within ({start_ts}; {end_ts});
        
        / Find absolute top-of-book levels per millisecond
        topBids: select bid:max price by time from depthSub where side=`buy;
        topAsks: select ask:min price by time from depthSub where side=`sell;
        l1: topBids lj topAsks;
        
        / Filter out massive drop anomalies by ensuring bid/ask are within a reasonable 1% corridor of the mid-price
        0!(select time, bid, ask from l1 where bid > (ask * 0.99))
    """

    
    try:
        l1_book = q_conn(depth_q).pd()
        print(f"[+] Depth extracted: {len(l1_book)} rows.")
    except Exception as e:
        print(f"[-] ERROR: Depth query failed. Details: {e}")
        sys.exit(1)

    print("[*] STEP 4: Fetching execution trades...")
    trade_q = f"""
        0!(select time, price from aggTrade where date={args.date}, sym=`{args.sym}, time within ({start_ts}; {end_ts}))
    """
    
    try:
        trades = q_conn(trade_q).pd()
        print(f"[+] Trades extracted: {len(trades)} rows.")
    except Exception as e:
        print(f"[-] ERROR: Trade query failed. Details: {e}")
        sys.exit(1)

    if l1_book.empty and trades.empty:
        print("[-] WARNING: Zero data records found inside this window.")
        sys.exit(0)

    print("[*] STEP 5: Reformatting datetime arrays...")
    if 'time' in l1_book.columns:
        l1_book['time'] = pd.to_datetime(l1_book['time'])
    if 'time' in trades.columns:
        trades['time'] = pd.to_datetime(trades['time'])

    print("[*] STEP 6: Generating Dynamic Plotly Canvas Layout...")
    fig = go.Figure()

    # 1. Add Depth Buy Price Layer (Red Scatter)
    if not l1_book.empty:
        fig.add_trace(go.Scatter(
            x=l1_book['time'], y=l1_book['bid'],
            mode='markers+lines', name="Depth's Buy Price (Bid)",
            marker=dict(color='red', size=6),
            line=dict(color='rgba(255,0,0,0.3)', width=1, shape='hv') # Adds a faint structural tracking step-line
        ))
        
        # 2. Add Depth Sell Price Layer (Green Scatter)
        fig.add_trace(go.Scatter(
            x=l1_book['time'], y=l1_book['ask'],
            mode='markers+lines', name="Depth's Sell Price (Ask)",
            marker=dict(color='green', size=6),
            line=dict(color='rgba(0,255,0,0.3)', width=1, shape='hv')
        ))

    # 3. Add Trade Execution Prices Layer (Large Blue Focus Points)
    if not trades.empty:
        fig.add_trace(go.Scatter(
            x=trades['time'], y=trades['price'],
            mode='markers', name="aggTrade's Price",
            marker=dict(color='blue', size=10, symbol='circle')
        ))

    # 4. Configure Interactive Layout Controls (Enabling scrolling, zooming, and pan handles)
    fig.update_layout(
        title=dict(text=f"{args.sym} Microstructure Dynamic Chart ({args.date})", font=dict(size=16)),
        xaxis=dict(
            title="Timeline",
            rangeslider=dict(visible=True), # Adds a dedicated time-scroll slider at the bottom
            type="date"
        ),
        yaxis=dict(
            title="Price",
            fixedrange=False # Allows you to scroll/zoom vertically as well as horizontally
        ),
        hovermode="x unified",
        template="plotly_white"
    )

    # 5. Output file generation
    out_html = f"microstructure_interactive_{args.sym}.html"
    fig.write_html(out_html)
    print(f"[+] SUCCESS: Scrollable chart generated successfully at: {out_html}")
    
    # Fire up Firefox/Chrome automatically to show the interactive application
    print("[*] STEP 7: Launching default web browser tab canvas layer...")
    pio.show(fig)

if __name__ == "__main__":
    main()
