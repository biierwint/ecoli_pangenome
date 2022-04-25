#!/usr/bin/perl -w
# Last Update: 28 April 2017
use strict;
use Getopt::Long;
use Pod::Usage;
use POSIX;
use File::Type;
use Linux::MemInfo;
use Parallel::ForkManager;
use Filesys::Df;
use File::Basename;

use pangenome::psystem;

sub getNumProcesses {
	my $requiredMem = shift;

	### Get number of processes
	my $numProcesses_by_CPUs = getSpawnedProcesses_by_CPUs (10);	### 10 is 10 seconds
	my $numProcesses_by_memory = getSpawnedProcesses_by_memory ($requiredMem);	### 8 is 8GB

	my $numProcesses = $numProcesses_by_memory;
	if ($numProcesses > $numProcesses_by_CPUs) {
		$numProcesses = $numProcesses_by_CPUs;
	}

	return($numProcesses);
}

sub runParallel {
	my ($numCPUs, $requiredMem, @commands) = @_;

	my %returnCode = ();

	my $numProcesses = $numCPUs;
	if ($numProcesses < 0) {
		$numProcesses = getNumProcesses($requiredMem);	
	}

	print STDERR "Number of processes = $numProcesses\n";
	my $pm = Parallel::ForkManager->new($numProcesses);

	$pm->run_on_finish (
		sub { 
			my ($pid, $exit_code, $ident) = @_;
			print "run_on_finish: $ident (pid: $pid) exited " . "with code: [$exit_code]\n";
			my @x=split(/\-/, $ident);
			$x[$#x]=~s/\.sh//g;
			my $id = $x[$#x];
			$returnCode{$id} = $exit_code;
		}
	);

	$pm->run_on_start (
		sub {
			my ($pid,$ident)=@_;
			print "** $ident started, pid: $pid\n";
		}
	);

	for (my $i=0; $i<=$#commands; $i++) {
		# Forks and returns the pid for the child:
		my $pid = $pm->start($commands[$i]) and next;

		system("sh " . $commands[$i]);
		my $exit_code = $? >> 8;

		$pm->finish($exit_code); # Terminates the child process
	}
	$pm->wait_all_children;
	
	return(%returnCode);
}

return 1;
