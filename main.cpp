#include "include/websocket.hpp"
#include <iostream>
#include <string>
#include <vector>
#include "include/simdjson.h"
#include "include/parser.hpp"
#include "include/tickerplant.hpp"
#include "include/symbols.hpp"

namespace {
constexpr const char* WS_URL = "stream.binance.com";
constexpr const char* WS_PORT = "9443";
constexpr size_t SYMBOL_COUNT = 3;

std::vector<std::string> get_market_streams(size_t symbol_count) {
    auto streams = get_trade_symbols(symbol_count);
    auto depth_streams = get_depth_symbols(symbol_count);
    streams.insert(streams.end(), depth_streams.begin(), depth_streams.end());
    return streams;
}
}

int main() {
    TickerPlant ticker_plant;
    if (!ticker_plant.connect("127.0.0.1", 5010)) {
        return 1;
    }
    std::cout << "TickerPlant initialized. Awaiting market feed...\n";

    asio::io_context io;
    asio::ssl::context ssl(asio::ssl::context::tls_client);
    ssl.set_default_verify_paths();

    WebSocket socket(io, ssl, WS_URL, WS_PORT);
    socket.connect();

    auto streams = get_market_streams(SYMBOL_COUNT);
    socket.subscribe(streams);

    std::cout << "Subscribed to " << streams.size() << " streams from "
              << SYMBOL_COUNT << " symbols\n";
    for (const auto& stream : streams) {
        std::cout << "  " << stream << "\n";
    }

    while (true) {
        auto msg = socket.read();

        if (msg.find("\"e\":\"aggTrade\"") != std::string::npos) {
            auto trade = parse_agg_trade(msg);
            bool published = ticker_plant.publish_agg_trade(
                "aggTrade",
                trade.event_time,
                trade.symbol,
                trade.aggregate_id,
                trade.price,
                trade.quantity,
                trade.maker);
            std::cout << "[aggTrade] "
                      << trade.symbol
                      << " id=" << trade.aggregate_id
                      << " price=" << trade.price
                      << " size=" << trade.quantity
                      << " published=" << (published ? "yes" : "no")
                      << "\n";
            continue;
        }

        if (msg.find("depthUpdate") != std::string::npos) {
            std::cout << msg;
            auto updates = parse_depth(msg);
            size_t published_count = 0;
            for (const auto& update : updates) {
                if (ticker_plant.publish_depth(
                    "depth",
                    update.event_time,
                    update.symbol,
                    update.received_at,
                    update.side,
                    update.price,
                    update.quantity)) {
                    ++published_count;
                }
            }
            if (!updates.empty()) {
                const auto& first = updates.front();
                std::cout << "[depth] "
                          << first.symbol
                          << " rows=" << updates.size()
                          << " published=" << published_count
                          << " first=" << first.side
                          << " " << first.price
                          << " x " << first.quantity
                          << "\n";
            }
        }
    }

    return 0;
}
