#!/usr/bin/env bash
awk '{
	tot += $1;
} END {
	print tot, "B/s"
}'
