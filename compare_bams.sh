# List your .bam files here:
bam1="uaf1b_rep1Aligned.sortedByCoord.out.bam"
bam2="uaf1b_rep2Aligned.sortedByCoord.out.bam"
bam3="uaf1b_rep3Aligned.sortedByCoord.out.bam"

module load samtools/

STATS="bam_comparison_stats.txt"
: > "$STATS"

echo "Comparing BAM files: $bam1, $bam2, $bam3" | tee -a "$STATS"
echo "--------------------------------------------------------" | tee -a "$STATS"

summarize_bam() {
  local bam=$1
  local label=$2

  echo "Summary for $label ($bam):" | tee -a "$STATS"

  echo "- Total reads:" | tee -a "$STATS"
  samtools view -c "$bam" | tee -a "$STATS"

  echo "- Mapped reads:" | tee -a "$STATS"
  samtools view -c -F 0x4 "$bam" | tee -a "$STATS"

  echo "- Properly paired reads:" | tee -a "$STATS"
  samtools view -c -f 0x2 "$bam" | tee -a "$STATS"

  echo "- Secondary alignments:" | tee -a "$STATS"
  samtools view -c -f 0x100 "$bam" | tee -a "$STATS"

  echo "- Supplementary alignments:" | tee -a "$STATS"
  samtools view -c -f 0x800 "$bam" | tee -a "$STATS"

  echo "- Primary alignments (excluding secondary/supplementary/unmapped):" | tee -a "$STATS"
  samtools view -c -F 0x904 "$bam" | tee -a "$STATS"

  echo "- Average number of optional fields per read (sample of 100):" | tee -a "$STATS"
  samtools view "$bam" | head -n 100 | awk '{print NF-11}' | awk '{sum+=$1} END{if (NR>0) print sum/NR; else print 0}' | tee -a "$STATS"

  echo "" | tee -a "$STATS"
}

# Change the names and quantities of your replicates here (if applicable):
summarize_bam "$bam1" "Rep1"
summarize_bam "$bam2" "Rep2"
summarize_bam "$bam3" "Rep3"

echo "Comparison complete. See $STATS for details." | tee -a "$STATS"
