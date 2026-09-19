#pragma once

#include <string>
#include <vector>

const std::vector<std::string> all_binance_symbols = {
    "btcusdt", "ethusdt", "solusdt", "xrpusdt",
    "bnbusdt", "adausdt", "dogeusdt", "avaxusdt",
    "dotusdt", "maticusdt", "linkusdt", "ltcusdt",
    "shibusdt", "trxusdt", "bchusdt", "xlmusdt",
    "atomusdt", "xplusdt", "filusdt", "aptusdt",
    "nearusdt", "ldousdt", "arbusdt", "opusdt",
    "grtusdt", "ftmusdt", "mkrusdt", "crvusdt",
    "gmxusdt", "dydxusdt", "injusdt", "rndrusdt",
    "woousdt", "oceanusdt", "fetusdt", "agixusdt",
    "stxusdt", "imxusdt", "flowusdt", "chzusdt",
    "galausdt", "axsusdt", "sandusdt", "manadusdt",
    "apeusdt", "thetausdt", "egldusdt", "aaveusdt",
    "rleusdt", "compusdt", "snxusdt", "1inchusdt",
    "cakeusdt", "sushiusdt", "yfiusdt", "enjusdt",
    "lrcusdt", "ankrusdt", "maskusdt", "qtumusdt",
    "eosusdt", "neousdt", "vetusdt", "icpusdt",
    "etcusdt", "zecusdt", "dashusdt", "xmrusdt",
    "wavesusdt", "zilusdt", "hotusdt", "btgusdt",
    "iotausdt", "omgusdt", "bntusdt", "kncusdt",
    "renusdt", "zrxusdt", "balusdt", "audiousdt",
    "bandusdt", "rlcusdt", "ctsiusdt", "stmxusdt",
    "sklusdt", "hiveusdt", "scusdt", "oneusdt",
    "celousdt", "roseusdt", "bicousdt", "glmrusdt",
    "movrusdt", "kavausdt", "minausdt"
};

inline std::vector<std::string> get_symbols(size_t n, const std::string& stream_suffix) {
    if (n > all_binance_symbols.size()) {
        n = all_binance_symbols.size();
    }

    std::vector<std::string> streams;
    streams.reserve(n);
    for (size_t i = 0; i < n; ++i) {
        streams.push_back(all_binance_symbols[i] + stream_suffix);
    }
    return streams;
}

inline std::vector<std::string> get_trade_symbols(size_t n) {
    return get_symbols(n, "@aggTrade");
}

inline std::vector<std::string> get_depth_symbols(size_t n) {
    return get_symbols(n, "@depth@100ms");
}
