#!/usr/bin/env bash
grep bw= $* | sed "s/.*bw=//; s/ .*//" | awk 'BEGIN{
	tot = 0.0;
} {
	v = 0.0 + $1;
	if ($1 ~ "GiB/s$")
		v *= 2^30
	else if ($1 ~ "MiB/s$")
		v *= 2^20
	else if ($1 ~ "KiB/s$")
		v *= 2^10
	else {
		print "ERR-005: contact developer with this error code";
		exit 123;
	}
	tot += v;
} END {
	print tot/NR, "B/s"
}'
