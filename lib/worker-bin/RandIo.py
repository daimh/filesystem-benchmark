#!/usr/bin/python3
import argparse
import multiprocessing
import os
import random
import sys
import time
_description = '''random IO benchmark tool

AUTHOR
	Manhong Dai, daimh@umich.edu'''


def get_args():
	parser = argparse.ArgumentParser(
		prog='random-io-test',
		formatter_class=argparse.RawDescriptionHelpFormatter,
		description=_description
	)
	parser.add_argument('FILE', help='a file or a block device', nargs='+')
	parser.add_argument('--version', action='version', version='20161212')
	parser.add_argument(
		'-s',
		'--seed',
		help='random seed, Setting seed will read from the same location '
		'as in previous runs',
		type=int
	)
	parser.add_argument(
		'-j',
		'--jobs',
		help='number of jobs running simultaneously per FILE, default 1',
		type=int,
		default=1
	)
	parser.add_argument(
		'-t',
		'--time',
		help='maximum runtime in seconds, 0 means no limitation. default 0',
		type=int,
		default=0
	)
	parser.add_argument(
		'-b',
		'--bs',
		help='read/write BS bytes at a time. BS may be followed by the '
		'multiplicative suffixes, k=1024, m=1024^2, g=1024^3, t=1024^4, '
		'default 1',
		default='1'
	)
	parser.add_argument(
		'-w',
		'--write',
		help='write test. IT WILL DESTROY DATA!!!',
		action='store_true'
	)
	return parser.parse_args()


def get_file_size(filename):
	fd = os.open(filename, os.O_RDONLY)
	try:
		return os.lseek(fd, 0, os.SEEK_END)
	finally:
		os.close(fd)


class Worker(multiprocessing.Process):
	def __init__(self, iops, fname, fsize, seed, begin, args):
		multiprocessing.Process.__init__(self)
		self.iops = iops
		self.fname = fname
		self.fsize = fsize
		self.seed = seed
		self.begin = begin
		self.args = args

	def run(self):
		if self.args.write:
			blockwrite = bytes(self.args.bs)
			fd = open(self.fname, 'rb+', buffering=0)
		else:
			fd = open(self.fname, 'rb', buffering=0)
		random.seed(self.seed)
		count = 0
		duration = time.time()
		sequence = list(range(int(self.fsize / self.args.bs)))
		random.shuffle(sequence)
		for i in sequence:
			if (
				self.args.time > 0 and
				time.time() - self.begin >= self.args.time
			):
				break
			fd.seek(i * self.args.bs)
			if self.args.write:
				fd.write(blockwrite)
				fd.flush()
				os.fsync(fd)
			else:
				fd.read(self.args.bs)
			count += 1
		duration = time.time() - duration
		fd.close()
		self.iops.acquire()
		self.iops.value += count / duration
		self.iops.release()


def main():
	args = get_args()
	if args.seed is None:
		random.seed(time.time())
	else:
		random.seed(args.seed)
	if args.bs[-1] in ['k', 'K']:
		args.bs = int(args.bs[:-1]) * 1024
	elif args.bs[-1] in ['m', 'M']:
		args.bs = int(args.bs[:-1]) * 1024 * 1024
	elif args.bs[-1] in ['g', 'G']:
		args.bs = int(args.bs[:-1]) * 1024 * 1024 * 1024
	elif args.bs[-1] in ['t', 'T']:
		args.bs = int(args.bs[:-1]) * 1024 * 1024 * 1024 * 1024
	else:
		args.bs = int(args.bs)
	iops = multiprocessing.Value('f', 0)
	workers = []
	begin = time.time()
	for fname in args.FILE:
		fsize = get_file_size(fname)
		for i in range(args.jobs):
			workers.append(Worker(iops, fname, fsize, random.random(), begin, args))
	count = 0
	while count < len(workers):
		workers[count].start()
		if args.time > 0 and time.time() - begin > args.time:
			print(
				'MSG-001: not all processes were started within the time '
				'limit. Please either increase "-t" or reduce "-j"',
				file=sys.stderr
			)
			break
		count += 1
	for idx in range(count):
		workers[idx].join()
	print(f'{int(iops.value * args.bs)} B/S')
	if iops.value == 0 or count != len(workers):
		print(
			'MSG-002: not all processes got a chance to issue IO '
			'limit. Please either increase "-t" or reduce "-j"',
			file=sys.stderr
		)
		sys.exit(1)


if __name__ == '__main__':
	main()
