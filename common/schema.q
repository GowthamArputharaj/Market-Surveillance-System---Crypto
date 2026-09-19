/ common/schema.q

aggTradeSchema:([] time:`timestamp$(); sym:`symbol$(); aggid:`long$(); price:`float$(); size:`float$(); ismm:`boolean$());
aggTradeCols:`time`sym`aggid`price`size`ismm;

depthSchema:([] time:`timestamp$(); sym:`symbol$(); received_at:`timestamp$(); side:`symbol$(); price:`float$(); size:`float$());

depthCols:`time`sym`received_at`side`price`size;
