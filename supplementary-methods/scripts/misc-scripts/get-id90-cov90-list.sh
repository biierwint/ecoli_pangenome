cat cdhit-c0.90-s0.90.out.clstr | 
	perl -ne '{chomp; if (/^>/) {print "\n$_";}
		else {@f=split(); $f[2]=~s/^>//g; $f[2]=~s/\.\.\.$//g; if ($f[$#f] eq "*") {print "\t$f[2]\(*\)";} else {print "\t$f[2]";}}}' |
	perl -ne '{chomp; 
		if (/^>/) {
			@f=split(/\t/);
			if ($#f>1) {
				for ($i=1; $i<=$#f; $i++) {
					if ($f[$i]=~/\(*\)/) {
						$temp=$f[1];
						$f[1] = $f[$i];
						$f[$i] = $temp;
						$f[1]=~s/[\(\*\)]//g; 
						last;
					}
				}
				print join("\t", @f), "\n";
			}
		}
	}' | cut -f2- > mylist-id90-cov90.txt
