#!/bin/sh

mlton -mlb-path-map mlb-path-map -output example.out example.mlb
mlton -mlb-path-map mlb-path-map -output abt-unparser.out abt-unparser.mlb
mlton -mlb-path-map mlb-path-map -output abt-parser.out abt-parser.mlb
mlton -mlb-path-map mlb-path-map -output abt-patterns.out abt-patterns.mlb
