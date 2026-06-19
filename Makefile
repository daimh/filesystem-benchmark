SHELL = /bin/bash -Eeuo pipefail
include setting.mk
WorkerBin = /tmp/filesystem-benchmark-bin

all :
	make clean
	make init
	for TT in $(Tests); \
	do \
		for TK in $(Tasks); \
		do \
			make -j var/test/$$TT-$$TK; \
		done; \
	done 2>&1 | tee var/test/log
	make rename
	make report

M4Report = cat lib/report/$$TT.m4 \
	| m4 -D m4Tasks="$$(echo $(Tasks) | sed "s/ /, /g")" \
	-D m4NumberOfFiles=$(NumberOfFiles) \
	-D m4MBPerTask=$(MBPerTask) \
	-D m4MBPerSeqIO=$(MBPerSeqIO) \
	-D m4BytesPerRandIO=$(BytesPerRandIO)
report : var/report
var/report : $(addprefix var/plot/,$(Tests))
	cp setting.mk var
	echo -e '# Description' > $@.md
	cat description.md >> $@.md
	echo >> $@.md
	echo "# Plot" >> $@.md
	for TT in $(sort $(Tests)); \
	do \
		echo "##" $$TT; \
		echo; \
		[ ! -f lib/report/$$TT.m4 ] || $(M4Report); \
		echo -e "\n![](plot/$$TT-TotalBox.png)\n"; \
		echo -e "\n![](plot/$$TT-TotalTime.png)\n"; \
		[ $(words $(Nodes)) -eq 1 ] \
			|| echo -e "\n![](plot/$$TT-NodeBox.png)\n"; \
		[ $(words $(Nodes)) -eq 1 ] \
			|| echo -e "\n![](plot/$$TT-NodeTime.png)\n"; \
	done >> $@.md
	echo -e '# Setting\n```' >> $@.md
	grep -v '^#' setting.mk | sed "/^$$/d; s/$$/\n/" | fold -w 60 -s >> $@.md
	echo -e '```\n' >> $@.md
	echo -e "# Source code\nurl: [https://github.com/daimh/filesystem-benchmark](https://github.com/daimh/filesystem-benchmark)\
		\n\ncommit: $$(git describe --always)" >> $@.md
	cd $(@D) && pandoc -V colorlinks=true --toc -o report.pdf report.md

PlotFilter = sed "s@^var/test-@@; s@/$1-@ @; s@.tsk:@ @" \
	| sort -t ' ' -k 1,1 -k 2,2n
define TmplTest
var/plot/$1 :
	mkdir -p $$(@D)
	Unit=$$$$(grep ^Total var/test-20??-??-??T*/$1-*.tsk | cut -d ' ' -f 3 \
		| sort -u); \
	Tasks="$(shell echo $(Tasks) | sed "s/ /,/g")"; \
	Nodes="$(shell echo $(Nodes) | sed "s/ /,/g")"; \
	cat lib/plot/box-common.m4 lib/plot/box-Total.m4 | m4 \
		-D m4XLabel="Task/Node" \
		-D m4XRange=$(words $(Tasks) +1) \
		-D m4TestName=$1-TotalBox \
		-D m4Unit=$$$${Unit} \
		-D m4Tasks=$$$${Tasks} > $$@-TotalBox.plt; \
	cat lib/plot/box-common.m4 lib/plot/box-Node.m4 | m4 \
		-D m4XLabel="Task/Node" \
		-D m4XRange=$(words $(Tasks) +1) \
		-D m4TestName=$1-NodeBox \
		-D m4Unit=$$$${Unit} \
		-D m4Tasks=$$$${Tasks} \
		-D m4Nodes=$$$${Nodes} \
		-D m4NodeCnt=$(words $(Nodes)) > $$@-NodeBox.plt; \
	cat lib/plot/time-common.m4 lib/plot/time-Total.m4 | m4 \
		-D m4TestName=$1-TotalTime \
		-D m4Unit=$$$${Unit} \
		-D m4Tasks=$$$${Tasks} > $$@-TotalTime.plt; \
	cat lib/plot/time-common.m4 lib/plot/time-Node.m4 | m4 \
		-D m4TestName=$1-NodeTime \
		-D m4Unit=$$$${Unit} \
		-D m4Tasks=$$$${Tasks} \
		-D m4Nodes=$$$${Nodes} > $$@-NodeTime.plt
	for TK in $(Tasks); \
	do \
		grep -H ^Total var/test-20??-??-??T*/$1-$$$$TK.tsk; \
	done | $(PlotFilter) > $$@-TotalBox.dat
	grep -Hv ^Filesystem var/test-20??-??-??T*/df-$(word 1,$(Nodes)).txt \
		| sed -E 's@^var/test-@@; s@/@ UsePct @; s/% / /' \
		| tr -s ' ' | cut -d ' ' -f 1,2,7 > $$@-TotalTime.dat
	cp $$@-TotalTime.dat $$@-NodeTime.dat
	cat $$@-TotalBox.dat >> $$@-TotalTime.dat
	for TK in $(Tasks); \
	do \
		grep -Hv ^Total var/test-20??-??-??T*/$1-$$$$TK.tsk; \
	done | $(PlotFilter) > $$@-NodeBox.dat
	cat $$@-NodeBox.dat >> $$@-NodeTime.dat
	cd $$(@D); for F in $$(@F)-*.plt; do gnuplot $$$$F; done

endef

$(eval $(call TmplTest,SeqWriteDd,$$$$TK,$(MBPerTask),/,MiB,\
	real,sed "s/real//"))
$(eval $(call TmplTest,SeqReadDd,$$$$TK,$(MBPerTask),/,MiB,\
	real,sed "s/real//"))
$(eval $(call TmplTest,RandWritePy,1,1,*,IO,,cat))
$(eval $(call TmplTest,RandReadPy,1,1,*,IO,,cat))

$(eval $(call TmplTest,SeqWriteFio,$$$$TK,$(MBPerTask),/,MiB,\
	real,sed "s/real//"))
$(eval $(call TmplTest,SeqReadFio,$$$$TK,$(MBPerTask),/,MiB,\
	real,sed "s/real//"))
$(eval $(call TmplTest,RandWriteFio,1,1,*,IO,bw=,sed "s/WRITE: bw=//"))
$(eval $(call TmplTest,RandReadFio,1,1,*,IO,bw=,sed "s/READ: bw=//"))

$(eval $(call TmplTest,FileCreate,$$$$TK,$(NumberOfFiles),/,Op,\
	real,sed "s/real//"))
$(eval $(call TmplTest,FileOpen,$$$$TK,$(NumberOfFiles),/,Op,\
	real,sed "s/real//"))
$(eval $(call TmplTest,FileRemove,$$$$TK,$(NumberOfFiles),/,Op,\
	real,sed "s/real//"))

define TmplTask
var/test/$1-$2 : $(addprefix var/test/$1-$2-,$(Nodes))
	lib/post-task.sh var/test/$1-$2-*.txt | tee $$@.tsk
	date | tee $$@
endef
$(foreach TT,$(Tests),$(foreach TK,$(Tasks),$(eval $(call \
	TmplTask,$(TT),$(TK)))))

define TmplNodeTask

var/test/FileRemove-$2-$1 : var/test/FileCreate-$2-$1
	ssh $1 'set -Eeuo pipefail; \
		PeerNode=$$$$(cat $(WorkerBin)/PeerNode); \
		time -p ( \
			cd $(MountPoint)/$(TestDir)/var/test; \
			sleep 0.01 & \
			for ((t=0; t<$2; t++)); \
			do \
				rm -rf FileCreate-$2-$$$${PeerNode}.d/t$$$$t & \
			done; \
			wait; \
		) \
	' 2>&1 | tee $$@.raw | lib/post-time.sh $2*$(NumberOfFiles) OP \
		| tee $$@.txt
	date | tee $$@

var/test/FileOpen-$2-$1 : var/test/FileCreate-$2-$1
	ssh $1 'set -Eeuo pipefail; \
		PeerNode=$$$$(cat $(WorkerBin)/PeerNode); \
		time -p ( \
			cd $(MountPoint)/$(TestDir)/var/test; \
			sleep 0.01 & \
			for ((t=0; t<$2; t++)); \
			do \
				( \
					cd FileCreate-$2-$$$${PeerNode}.d/t$$$$t \
						&& ls | xargs -L 8192 cat > /dev/null \
				) & \
			done; \
			wait; \
		) \
	' 2>&1 | tee $$@.raw | lib/post-time.sh $2*$(NumberOfFiles) OP \
		| tee $$@.txt
	date | tee $$@

var/test/FileCreate-$2-$1 : var/test/init-$1
	ssh $1 'set -Eeuo pipefail; \
		cd $(MountPoint)/$(TestDir); \
		time -p ( \
			sleep 0.01 & \
			for ((t=0; t<$2; t++)); \
			do \
				mkdir -p $$@.d/t$$$$t; \
				seq $(NumberOfFiles) | split -l 1 - $$@.d/t$$$$t/ & \
			done; \
			wait; \
		) \
	' 2>&1 | tee $$@.raw | lib/post-time.sh $2*$(NumberOfFiles) OP \
		| tee $$@.txt
	date | tee $$@

var/test/RandReadPy-$2-$1 : var/test/SeqWriteDd-$2-$1
	ssh $1 'set -Eeuo pipefail; \
		PeerNode=$$$$(cat $(WorkerBin)/PeerNode); \
		cd $(MountPoint)/$(TestDir); \
		for ((t=0; t<$2; t++)); \
		do \
			$(WorkerBin)/RandIo.py \
				-b $(BytesPerRandIO) -t $(RandRunSeconds) \
				var/test/SeqWriteDd-$2-$$$${PeerNode}.d/$\
				SeqWriteDd-$2-$$$${PeerNode}.t$$$$t & \
		done; \
		wait; \
	' 2>&1 | tee $$@.raw | lib/post-RandIoPy.sh | tee $$@.txt
	date | tee $$@

var/test/RandWritePy-$2-$1 : var/test/SeqWriteDd-$2-$1
	ssh $1 'set -Eeuo pipefail; \
		cd $(MountPoint)/$(TestDir); \
		for ((t=0; t<$2; t++)); \
		do \
			$(WorkerBin)/RandIo.py -w \
				-b $(BytesPerRandIO) -t $(RandRunSeconds) \
				$$<.d/$$(<F).t$$$$t & \
		done; \
		wait; \
	' 2>&1 | tee $$@.raw | lib/post-RandIoPy.sh | tee $$@.txt
	date | tee $$@

var/test/SeqReadDd-$2-$1 : var/test/SeqWriteDd-$2-$1
	ssh $1 'set -Eeuo pipefail; \
		PeerNode=$$$$(cat $(WorkerBin)/PeerNode); \
		[ "$(Direct)" = 1 ] && Flag="iflag=direct" || Flag=""; \
		cd $(MountPoint)/$(TestDir); \
		time -p ( \
			sleep 0.01 & \
			for ((t=0; t<$2; t++)); \
			do \
				dd $$$${Flag} bs=$(MBPerSeqIO)M of=/dev/null \
					if=var/test/SeqWriteDd-$2-$$$${PeerNode}.d/$\
					SeqWriteDd-$2-$$$${PeerNode}.t$$$$t & \
			done; \
			wait; \
		) \
	' 2>&1 | tee $$@.raw | lib/post-time.sh $2*$(MBPerTask) MiB \
		| tee $$@.txt
	date | tee $$@

var/test/SeqWriteDd-$2-$1 : var/test/init-$1
	ssh $1 'set -Eeuo pipefail; \
		[ "$(Direct)" = 1 ] && Flag="oflag=direct" || Flag=""; \
		cd $(MountPoint)/$(TestDir); \
		mkdir -p $$@.d; \
		time -p ( \
			mkdir -p $$@.d; \
			sleep 0.01 & \
			for ((t=0; t<$2; t++)); \
			do \
				dd $$$${Flag} bs=$(MBPerSeqIO)M if=/dev/zero \
					of=$$@.d/$$(@F).t$$$$t \
					count=$(shell echo $$(($(MBPerTask)/$(MBPerSeqIO)))) & \
			done; \
			wait; \
		) \
	' 2>&1 | tee $$@.raw | lib/post-time.sh $2*$(MBPerTask) MiB \
		| tee $$@.txt
	date | tee $$@

var/test/RandReadFio-$2-$1 : var/test/SeqWriteFio-$2-$1
	ssh $1 'set -Eeuo pipefail; \
		[ "$(RandRunSeconds)" = 0 ] && Runtime="" \
			|| Runtime="--runtime=$(RandRunSeconds)"; \
		PeerNode=$$$$(cat $(WorkerBin)/PeerNode); \
		cd $(MountPoint)/$(TestDir); \
		fio $$$$Runtime \
			--directory=var/test/SeqWriteFio-$2-$$$${PeerNode}.d \
			--name=SeqWriteFio-$2-$$$${PeerNode} \
			--output=$$@.fio \
			--size=$(MBPerTask)M --direct=$(Direct) \
			--bs=$(BytesPerRandIO) \
			--ioengine=libaio --iodepth=16 --numjobs=$2 \
			--runtime=$(RandRunSeconds) \
			--rw=randread --readonly; \
	'
	rsync -av $1:$(MountPoint)/$(TestDir)/$$@*.fio var/test
	lib/post-FioRand.sh $$@*.fio | tee $$@.txt
	date | tee $$@

var/test/RandWriteFio-$2-$1 : var/test/SeqWriteFio-$2-$1
	ssh $1 'set -Eeuo pipefail; \
		[ "$(RandRunSeconds)" = 0 ] && Runtime="" \
			|| Runtime="--runtime=$(RandRunSeconds)"; \
		PeerNode=$$$$(cat $(WorkerBin)/PeerNode); \
		cd $(MountPoint)/$(TestDir); \
		fio $$$$Runtime \
			--directory=var/test/SeqWriteFio-$2-$$$${PeerNode}.d \
			--name=SeqWriteFio-$2-$$$${PeerNode} \
			--output=$$@.fio \
			--size=$(MBPerTask)M --direct=$(Direct) \
			--bs=$(BytesPerRandIO) \
			--ioengine=libaio --iodepth=16 --numjobs=$2 \
			--rw=randwrite; \
	'
	rsync -av $1:$(MountPoint)/$(TestDir)/$$@*.fio var/test
	lib/post-FioRand.sh $$@*.fio | tee $$@.txt
	date | tee $$@

var/test/SeqReadFio-$2-$1 : var/test/SeqWriteFio-$2-$1
	ssh $1 'set -Eeuo pipefail; \
		PeerNode=$$$$(cat $(WorkerBin)/PeerNode); \
		cd $(MountPoint)/$(TestDir); \
		mkdir -p $$@.d; \
		time -p ( \
			mkdir -p $$@.d; \
			sleep 0.01 & \
			fio --directory=var/test/SeqWriteFio-$2-$$$${PeerNode}.d \
				--name=SeqWriteFio-$2-$$$${PeerNode} \
				--output=$$@.fio --size=$(MBPerTask)M \
				--direct=$(Direct) --bs=$(MBPerSeqIO)m --ioengine=libaio \
				--iodepth=16 --numjobs=$2 --rw=read --readonly; \
		) \
	' 2>&1 | tee $$@.raw | lib/post-time.sh $2*$(MBPerTask) MiB \
		| tee $$@.txt
	rsync -av $1:$(MountPoint)/$(TestDir)/$$@*.fio var/test
	date | tee $$@

var/test/SeqWriteFio-$2-$1 : var/test/init-$1
	ssh $1 'set -Eeuo pipefail; \
		cd $(MountPoint)/$(TestDir); \
		mkdir -p $$@.d; \
		time -p ( \
			mkdir -p $$@.d; \
			sleep 0.01 & \
			fio --directory=$$@.d --name=$$(@F) \
				--output=$$@.fio --size=$(MBPerTask)M \
				--direct=$(Direct) --bs=$(MBPerSeqIO)m --ioengine=libaio \
				--iodepth=16 --numjobs=$2 --rw=write; \
		) \
	' 2>&1 | tee $$@.raw | lib/post-time.sh $2*$(MBPerTask) MiB \
		| tee $$@.txt
	rsync -av $1:$(MountPoint)/$(TestDir)/$$@*.fio var/test
	date | tee $$@

endef
$(foreach N,$(Nodes),$(foreach TT,$(Tasks),$(eval $(call \
	TmplNodeTask,$N,$(TT)))))

rename : $(addprefix var/test/rename-,$(Nodes))
	mv var/test var/test-$$(date -Is)

clean :
	make -j $(addprefix var/test/killall-,$(Nodes))
	make $(addprefix var/test/rm-,$(Nodes))
	rm -rf var/test

debug :
	$(SetupOs);

init : $(addprefix var/test/init-,$(Nodes))
	lib/worker-bin/check-os-packages.sh localhost

define TmplNode
var/test/rename-$1 :
	ssh $1 "set -Eeuo pipefail; \
		df -Ph $(MountPoint); \
		mv $(MountPoint)/$(TestDir)/var/test \
			$(MountPoint)/$(TestDir)/var/test-$$$$(date -Is) || : \
	" > $$(@D)/df-$1.txt

var/test/killall-$1 :
	-ssh $1 "killall -9 dd fio seq split rm RandIo.py"

var/test/rm-$1 :
	ssh $1 "rm -rf $(MountPoint)/$(TestDir)/var/test"

var/test/init-$1 :
	[ "$(Direct)" = 1 -o "$(Direct)" = 0 ]
	ssh $1 mountpoint $(MountPoint)
	rsync -a lib/worker-bin/ $1:$(WorkerBin)
	ssh $1 "$(WorkerBin)/check-os-packages.sh $1"
	mkdir -p $$(@D)
	ssh $1 "set -Eeuo pipefail; \
		mkdir -p $(MountPoint)/$(TestDir)/PeerNode; \
		touch $(MountPoint)/$(TestDir)/PeerNode/$1; \
		Pct=\$$$$(df -P $(MountPoint) | tail -n 1 | tr -s ' ' \
			| cut -d ' ' -f 5 | tr -d %); \
		[ \$$$$Pct -ge $(ReduceFromPct) ] || exit 0; \
		while :; \
		do \
			[ \$$$$Pct -ge $(ReduceToPct) ] || break; \
			RmDir=\$$$$(ls $(MountPoint)/$(TestDir)/var/ | grep ^test-20 \
				| shuf | head -n 1) || break; \
			echo "MSG-001: Removing \$$$$RmDir as the usage is \$$$$Pct%"; \
			rm -r $(MountPoint)/$(TestDir)/var/\$$$$RmDir; \
			sleep 60; \
			Pct=\$$$$(df -P $(MountPoint) | tail -n 1 | tr -s ' ' \
				| cut -d ' ' -f 5 | tr -d %); \
		done; \
	"
	Prev=$(lastword $(Nodes)); \
	for N in $(Nodes); \
	do \
		if [ "$$$$N" = "$1" ]; \
		then \
			ssh $1 " \
				if [ -f $(MountPoint)/$(TestDir)/PeerNode/$$$$Prev ]; \
				then \
					echo $$$$Prev > $(WorkerBin)/PeerNode; \
				else \
					echo $1 > $(WorkerBin)/PeerNode; \
				fi \
			"; \
			break; \
		fi; \
		Prev=$$$$N; \
	done
	date | tee $$@
endef
$(foreach N,$(Nodes),$(eval $(call TmplNode,$N)))

help : #@ print this help
	@grep ^[a-zA-Z0-9] Makefile \
		| grep ' #@ ' \
		| grep -v ^var \
		| LC_ALL=C sort \
		| sed "s/^/make /; s/ :.* #@ /\n/; s/$$/\n/" \
		| fold -sw 70 \
		| sed "/^make/b; s/^/\t/"
