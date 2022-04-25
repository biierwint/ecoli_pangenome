#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Pod::Usage;
use POSIX;
use Linux::MemInfo;
use Filesys::Df;
use List::Util qw(sum);
use utf8;

sub getSpawnedProcesses_by_CPUs {
	my $seconds = shift;

	### check total CPU available
	my $numCPU = 0;
	open (STAT, "/proc/stat") || die "Failed reading CPU statistics!\n";
	while (<STAT>) {
		if (/^cpu/) {
			$numCPU++;
		}
	}
	close (STAT);

	print STDERR "Total number of CPUs in the system = " . ($numCPU-1)  . "\n";

	my $averageUsage = 0;
	my ($prev_idle, $prev_total) = qw(0 0);

	for (my $i=1; $i<=($seconds+1); $i++) {
		open(STAT, "/proc/stat") or die "Cannot open file to read CPU statistics!\n";
		while (<STAT>) {
			if (/^cpu\s+[0-9]+/) {
				my @cpu = split /\s+/, $_;
				shift @cpu;

				my $idle = $cpu[3];
				my $total = sum(@cpu);

				my $diff_idle = $idle - $prev_idle;
				my $diff_total = $total - $prev_total;
				my $diff_usage = 100 * ($diff_total - $diff_idle) / $diff_total;
		
				$prev_idle = $idle;
				$prev_total = $total;

				if ($i > 1) {
					$averageUsage += $diff_usage;
				}
			}
			
        	}
        	close STAT;
        	sleep 1;
	}

	$averageUsage = $averageUsage/$seconds;

	my $percentAvailable = 100 - $averageUsage;
	$averageUsage = sprintf "%.2f%%", $averageUsage;
	print STDERR "Current average CPU usage over 10seconds = $averageUsage\n\n";

	### Percentage of One CPU ###
	my $onecpu = 100/$numCPU;

	### How many processes should be spawned?
	### Leave $onecpu process free
	my $numProcesses = int(($percentAvailable-$onecpu) / $onecpu);
	if ($numProcesses >= ($numCPU-1)) {
		$numProcesses = $numCPU - 2;
	}

	return($numProcesses);
} 

sub getSpawnedProcesses_by_memory {
	my $requiredMem = shift;	### required memory in GigaBytes

	my %mem_info = get_mem_info();

	my $availMem = int(($mem_info{"MemFree"}/1024 + $mem_info{"Buffers"}/1024 + $mem_info{"Cached"}/1024)/1024);
	#print STDERR "Available memory for usage: " . $availMem . " GB\n";

	my $numProcesses = int($availMem/$requiredMem);

	return($numProcesses);
}

sub getFreeDiskSpace {
	my $disklocation = shift;

	my $disk = df($disklocation);
	my $availDisk = int( ($disk->{bavail}/1024)/1024);
	return($availDisk);
}

return 1;

