#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Pod::Usage;
use POSIX;
 
sub readParams {
	my $inFile = shift;
	my %params = ();

	### Read the input file (or config file)
	open (IN, $inFile) || die "Cannot open $inFile for reading!\n";
	while (<IN>) {
		chomp;
		$_=~s/^\s+|\s+$//g;

		if (/^#/ || length($_)==0) {
			### Skip ==> this is comment line or empty space
		} else {
			### reading parameters
			my @f = split(/\t/);
			if ($f[1] ne "=") {
				print STDERR "WARNING: line $. ... Please check!\n";
			} else {
				$f[0] = uc($f[0]);

				### define the parameters
				if ($#f == 1 && $f[1] eq "=") {	### this means the parameter is empty
					### skip
				} else { ### this means the parameter is not empty
					if (defined ($params{$f[0]})) {	### check if $params is defined more than once
						if ($params{$f[0]} ne $f[2]) {
							die "$f[0] is defined more than once and they are contradicting each other. Terminate at line $.\n";
						}
					} else {
						$params{$f[0]} = $f[2];
					}
				}
			}
		}
	}
	close(IN);
	return (%params);
}

sub printParams {
	my (%params) = @_;
	print STDERR "------------------\n";
	print STDERR "DEFINED PARAMETERS\n";
	print STDERR "------------------\n";

	foreach my $parameter (keys %params) {
		print STDERR "$parameter = $params{$parameter}\n";
	}
}

return 1;
