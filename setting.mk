# Nodes to be benchmarked
Nodes = 127.0.0.1 127.0.0.2
# MountPoint of the storage
MountPoint = /tmp
# TestDir is a directory under MountPoint
TestDir = filesystem-benchmark-testdir
# start to remove the test files randomly if the filesystem's used percentage is equal or above ReduceFromPct. 101 or greater number means such reduce will never happen
ReduceFromPct = 90
# until the usage percentage is equal or below ReduceToPct
ReduceToPct = 10

Tests = SeqWriteDd SeqWriteFio SeqReadDd SeqReadFio RandWritePy RandWriteFio RandReadPy RandReadFio FileCreate FileOpen FileRemove
# Direct=1/0. 1 uses non-buffered IO. applicable to all tests except FileCreate, FileOpen, FileRemove
Direct = 1
# tasks per node
Tasks = 1
# file size applicable to all tests except File{Create|Open|Remove}. Note MBPerTask should be multiple of MBPerSeqIO below
MBPerTask = 128
# Sequential IO size in MB, applicable to tests: SeqWriteDd, SeqReadDd, SeqWriteFio, SeqReadFio
MBPerSeqIO = 16
# NumberOfFiles applicable to tests: FileCreate, FileOpen, and FileRemove
NumberOfFiles = 128
#RandRunSeconds applicable to tests: RandWriteFio, RandReadFio, RandWritePy, and RandReadPy
RandRunSeconds = 10
# Random IO size in bytes, applicable to tests: RandWriteFio, RandReadFio, RandWritePy, and RandReadPy
BytesPerRandIO = 4096
