### run-recluster.sh <identity> <coverage>
### run-recluster.sh 60 60
awk 'NR>1' final-output-cdhit-id60-cov60.txt | cut -f4- |
	perl -ne '{chomp; @f=split(/[\t\;\,]/); for ($i=0; $i<=$#f; $i++) { if ($f[$i] ne "*") {print "$f[$i]\t";}} print "\n";}' > original-clusters.txt

awk 'NR>1' final-output-cdhit-id60-cov60.txt | cut -f3 > cluster_id.txt

### select longest
select-longest -i original-clusters.txt -l protein-sequences.txt

cut -f1 original-clusters.txt-sorted > selected-ids.txt
paste cluster_id.txt original-clusters.txt-sorted > clusterid2protein.txt

### extract-fasta-id
extract-fasta-id -i merged.faa -l selected-ids.txt > original-clusters.fa

### CD-HIT clustering
cd-hit -i original-clusters.fa -c 0.4 -s 0.5 -M 16000 -n 2 -d 50 -o cdhit-c0.40-s0.50-n2.out

### get-new-cluster
generate-new-cluster -l clusterid2protein.txt -c cdhit-c0.40-s0.50-n2.out.clstr -p hmmsearch-EscherichiaColi-PFAM.txt

cat new-cluster | perl -ne '{chomp; @f=split(/\t/); if ($#f>1) {print "$_\n";}}' | cut -f2- > to-merge-cluster.txt

fsieve -s log-remove-cluster -m final-output-cdhit-id60-cov60.txt -i 3
merge-clusters -i sieved-final-output-cdhit-id60-cov60.txt -l to-merge-cluster.txt -o recluster-output-cdhit-id60-cov60.txt
