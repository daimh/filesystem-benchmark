define([Node], [ifelse($1, , , [, "<awk '$[]2==vTask && $[]3==\"$1\"' m4TestName.dat" using 1:4 with linespoints title "$1-vTask" \
Node(shift($@))])])dnl
define([Task], [ifelse($1, , , [define([vTask], $1)dnl
Node(m4Nodes)dnl
Task(shift($@))]) ])dnl
Task(m4Tasks)
