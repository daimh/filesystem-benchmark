#!/usr/bin/env bash
Total=$(($1))
grep ^real | awk -v Tot=$Total -v Unit=$2 '{
	print Tot / $2, Unit "/s"
}'
