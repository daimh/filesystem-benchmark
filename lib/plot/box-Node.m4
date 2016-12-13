define([vBc], [esyscmd(echo "scale=2; $1" | bc | tr -d '\n' )])
define([vWidth], [vBc(0.4/m4NodeCnt)])
define([vStep], ifelse(m4NodeCnt, 1, 0, [vBc(0.1/(m4NodeCnt-1))]))
define([vBase], ifelse(m4NodeCnt, 1, 1, [vBc(1+(vStep+vWidth)/2-(vStep+vWidth)*2/m4NodeCnt)]))
define([vIdx], 0)
define([Node], [ifelse($1, , , ["<awk '$[]3==\"$1\"' m4TestName.dat" using (vBc(vBase+(vStep+vWidth)*vIdx)):4:(vWidth):2 title "$1", \
define([vIdx], incr(vIdx))dnl
Node(shift($@))])])dnl
plot Node(m4Nodes)
