# 📊 Market Surveillance System - Order Book Microstructure Plotter

This repository contains a high-performance **Market Microstructure Surveillance** framework designed to process high-frequency tick data streams out of **KDB+ HDB** architectures. It features an interactive, dynamic visualization tool built with **Python (PyKX & Plotly)** to zoom, scroll, and audit discrete market-matching trade anomalies against order book boundaries at the millisecond scale.

---

## 🛠️ System Prerequisites

Ensure your host environment (**Fedora Linux**) has the required system packages installed before launching execution loops:

```bash
# 1. Install required Python vector libraries
pip3 install --upgrade pykx pandas plotly

# 2. Configure Fedora system dynamic library paths to point to your system's active Python runtime
export Q_PYTHON_LIB=\$(ldconfig -p | grep -oP '/lib64/libpython3\.\d+\.so\.1\.0' | head -n 1)

# (Optional) Persist environment profile configuration variables across bash initializations
echo "export Q_PYTHON_LIB=\$(ldconfig -p | grep -oP '/lib64/libpython3\.\d+\.so\.1\.0' | head -n 1)" >> ~/.bashrc
```
---

## 🚀 Step-by-Step Execution Guide

To run a deep surveillance plot session, follow these operations across separate terminal panels:

### Step 1: Initialize the HDB Database Engine (Terminal 1)
Boot up your KDB+ historical database partition layer and bind it to a local communication port address:
```bash
q hdb -p 5001
```

### Step 2: Run the Microstructure Plotter (Terminal 2)
In a separate terminal tab window, execute the analytics tracking script using your target timeframe constraints:
```bash
python3 analytics/plot_price_vs_time.py --date 2026.09.19 --sym BTCUSDT --start 10:22:24.000 --end 10:22:29.000 --port 5001
```

---

## 🔍 How to Read the Interactive Analytics View

When execution concludes, the python loop saves a standalone **`microstructure_interactive_BTCUSDT.html`** file to disk and automatically triggers your browser window to display it:

*   🔴 **Red Scatter Dots / Lines**: Represents **Depth's Buy Price (Best Bid)** per timestamp element.
*   🟢 **Green Scatter Dots / Lines**: Represents **Depth's Sell Price (Best Ask)** per timestamp element.
*   🔵 **Blue Scattered Spheres**: Represents actual **Executed Trades (`aggTrade`)** matched directly over time.

---
---

## 🗂️ Database Schema Definitions

The surveillance system expects the following structural vector schemas within your KDB+ historical database partitions:

### 1. `depth` Table (Order Book Updates)

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `date` | `DATE` | Partition date (e.g., `2026.09.19`) |
| `time` | `TIMESPAN` | Engine matching engine occurrence timestamp |
| `sym` | `SYMBOL` | Trading pair ticker identifier (e.g., `BTCUSDT`) |
| `received_at`| `TIMESPAN` | System ingest timestamp for latency auditing |
| `side` | `SYMBOL` | Liquidity parameter: \`buy or \`sell |
| `price` | `FLOAT` | Target order book price level limit |
| `size` | `FLOAT` | Aggregated liquidity volume size available at price |

### 2. `aggTrade` Table (Executed Transactions)

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `date` | `DATE` | Partition date (e.g., `2026.09.19`) |
| `time` | `TIMESPAN` | Transaction execution occurrence timestamp |
| `sym` | `SYMBOL` | Trading pair ticker identifier (e.g., `BTCUSDT`) |
| `aggid` | `LONG` | Unique global matching engine transaction ID |
| `price` | `FLOAT` | Market execution clearing price |
| `size` | `FLOAT` | Cleared execution volume size asset parameter |
| `ismm` | `BOOLEAN` | Market Maker Flag: `1` = Sell Taker, `0` = Buy Taker |

---

## 🔍 Troubleshooting Core System Issues

### 1. `AttributeError` / `nyi` (Not Yet Implemented) Errors
* **Symptom:** Scripts crash during runtime with `nyi` or error messages regarding missing vector object methods.
* **Solution:** Ensure your Python environment is communicating using a port context handle (`kx.SyncQConnection`). Direct file-mounting (`\l path/to/hdb`) using system execution calls inside Python strings is not natively supported under KDB-X embedded environments.

### 2. Connection Refused / Closed Port Errors
* **Symptom:** Python throws: `[-] ERROR: Port 5001 is closed.`
* **Solution:** Verify that your historical database process is actually active and running in its independent terminal tab. Check this by executing:
  ```bash
  # Check if a process is listening on your target port
  ss -tulpn | grep 5001
  ```
  If empty, restart the process via `q hdb -p 5001`.

### 3. Missing Shared Library Objects (`'libpython`)
* **Symptom:** KDB-X crashes instantly on script boot with a `'libpython` error flag.
* **Solution:** The KDB-X runtime cannot locate your active Linux system Python shared library files (`.so`). Verify your environment string parameters before starting execution runs:
  ```bash
  export Q_PYTHON_LIB=$(ldconfig -p | grep -oP '/lib64/libpython3\.\d+\.so\.1\.0' | head -n 1)
  ```

### 4. Empty Plot Output (Blank Canvas Background)
* **Symptom:** The browser window pops open successfully but no scatter points render onto the screen.
* **Solution:** Check your time parameters. KDB is highly case and type-sensitive. Ensure your script timestamp arguments match your data window exactly, e.g., `--start 10:22:24.000 --end 10:22:29.000` (HH:MM:SS.mmm).



