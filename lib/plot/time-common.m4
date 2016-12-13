set term png size 900,300
set output 'm4TestName.png'
set xlabel ''
set ylabel 'm4Unit'
set y2label 'Use%' textcolor 'dark-violet'
set border linewidth 1.5
set style line 1 lc rgb '#0060ad' pt 7 ps 1.5 lt 1 lw 8
set style line 11 lc rgb '#808080' lt 1
set border 3 back ls 11
set tics nomirror out scale 0.75
set style line 12 lc rgb'#808080' lt 0 lw 1
set grid back ls 12
set bmargin 3
set title 'm4TestName'
set timefmt "%Y-%m-%dT%H:%M:%S-"
set xdata time
set y2tics
changequote(`[', `]')dnl
plot "<awk '$2==\"UsePct\"' m4TestName.dat" using 1:3 with linespoints title "Use%" axis x1y2 \
