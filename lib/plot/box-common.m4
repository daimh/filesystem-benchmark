set term png size 900,300
set output 'm4TestName.png'
set xlabel 'm4XLabel'
set ylabel 'm4Unit'
set border linewidth 1.5
set style line 1 lc rgb '#0060ad' pt 7 ps 1.5 lt 1 lw 8
set style data boxplot
set style line 11 lc rgb '#808080' lt 1
set border 3 back ls 11
set tics nomirror out scale 0.75
set style line 12 lc rgb'#808080' lt 0 lw 1
set grid y
set title 'm4TestName'
set xrange [0.5:m4XRange.5]
changequote(`[', `]')dnl
