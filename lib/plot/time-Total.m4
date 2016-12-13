define([Task], [ifelse($1, , , [, "<awk '$[]2==$1' m4TestName.dat" using 1:4 with linespoints title "$1" \
Task(shift($@))]) ]) dnl
Task(m4Tasks) dnl
