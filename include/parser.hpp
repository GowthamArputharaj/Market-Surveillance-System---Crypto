#pragma once

#include <chrono>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "simdjson.h"

struct Depth {
    int64_t event_time;
    std::string symbol;
    int64_t received_at;
    std::string side;
    double price;
    double quantity;
};

struct Trade {
    int64_t event_time;
    std::string symbol;
    double price;
    double quantity;
    int64_t aggregate_id;
    int64_t first_trade_id;
    int64_t last_trade_id;
    bool maker;
};

inline Trade parse_agg_trade(std::string_view json) {
    simdjson::ondemand::parser parser;
    simdjson::padded_string padded(json);
    auto doc = parser.iterate(padded);

    Trade t;
    t.event_time = doc["E"].get_int64();
    t.symbol = std::string(doc["s"].get_string().value());
    t.price = std::stod(std::string(doc["p"].get_string().value()));
    t.quantity = std::stod(std::string(doc["q"].get_string().value()));
    t.aggregate_id = doc["a"].get_int64();
    t.first_trade_id = doc["f"].get_int64();
    t.last_trade_id = doc["l"].get_int64();
    t.maker = doc["m"].get_bool();

    return t;
}

inline std::vector<Depth> parse_depth(std::string_view json) {
    std::vector<Depth> rows;
    simdjson::ondemand::parser parser;

    simdjson::padded_string padded(json);

    auto doc = parser.iterate(padded);

    int64_t event_time = int64_t(doc["E"]);
    std::string symbol = std::string(std::string_view(doc["s"]));

    auto now = std::chrono::system_clock::now().time_since_epoch();
    int64_t received_at =
        std::chrono::duration_cast<std::chrono::nanoseconds>(now).count();

    // Bids
    for (auto level : doc["b"].get_array()) {
        auto values = level.get_array();

        auto it = values.begin();

        // double price = double(*it);
        // ++it;

        // double quantity = double(*it);
        double price = std::stod(std::string(std::string_view(*it)));
        ++it;

        double quantity = std::stod(std::string(std::string_view(*it)));


        rows.push_back(
            Depth{
                event_time,
                symbol,
                received_at,
                "buy",
                price,
                quantity
            }
        );
    }

    // Asks
    for (auto level : doc["a"].get_array()) {
        auto values = level.get_array();

        auto it = values.begin();

        // double price = double(*it);
        // ++it;

        // double quantity = double(*it);
        double price = std::stod(std::string(std::string_view(*it)));
        ++it;

        double quantity = std::stod(std::string(std::string_view(*it)));


        rows.push_back(
            Depth{
                event_time,
                symbol,
                received_at,
                "sell",
                price,
                quantity
            }
        );
    }

    return rows;
}
