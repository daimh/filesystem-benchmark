#!/usr/bin/env bash
grep -H ^ $* | cut -d - -f 3- | sed "s/.txt:/ /" | awk '{
	print $0;
	s += $2;
	unit = $3;
} END {
	print "Total", s, unit;
}'
