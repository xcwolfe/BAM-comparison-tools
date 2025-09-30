# After running compare_bams.sh, you will generate a file called bam_comparison_stats.txt. This script allows you to compare the statistics generated in this file on a group-by-group basis, useful for technical replicates or grouped treatments.

module load samtools/

STATS="bam_comparison_stats.txt"
TMPDIR="bam_stats_tmp"
mkdir -p "$TMPDIR"
rm -f "$TMPDIR"/*.txt

summarize_bam() {
  bam="$1"
  label="$(basename "$bam")"
  out="$TMPDIR/${label}.txt"

  {
    echo "Summary for $label ($bam):"
    echo "- Total reads:"
    samtools view -c "$bam"
    echo "- Mapped reads:"
    samtools view -c -F 0x4 "$bam"
    echo "- Properly paired reads:"
    samtools view -c -f 0x2 "$bam"
    echo "- Secondary alignments:"
    samtools view -c -f 0x100 "$bam"
    echo "- Supplementary alignments:"
    samtools view -c -f 0x800 "$bam"
    echo "- Primary alignments (excluding secondary/supplementary/unmapped):"
    samtools view -c -F 0x904 "$bam"
    echo "- Average read depth (across genome):"
    samtools depth "$bam" | awk '{sum+=$3; n++} END{if (n>0) print sum/n; else print 0}'
    echo ""
  } > "$out"
}

export -f summarize_bam
export TMPDIR

## Change your group names here:
PATTERN="^(N2|MEC8|u218|u74).*Aligned.out_sorted.bam$"

find . -maxdepth 1 -type f -name "*Aligned.out_sorted.bam" | \
  sed 's|^\./||' | grep -E "$PATTERN" | sort | \
  parallel -j 20 summarize_bam

: > "$STATS"
for file in $(ls "$TMPDIR"/*.txt | sort); do
  cat "$file" >> "$STATS"
done

awk '
BEGIN {
  FS=":|\\n"
}
function get_group(name) {
  if (name ~ /^MEC8/) return "MEC8"
  if (name ~ /^u218/) return "u218"
  if (name ~ /^u74/) return "u74"
  if (name ~ /^N2-([1-3])/) return "N2_grouped_with_u218_u74"
  if (name ~ /^N2-([4-6])/) return "N2_grouped_with_MEC8"
  return ""
}
{
  if ($0 ~ /^Summary for /) {
    if (group != "" && count == 7) {
      total_sum[group] += val[1]
      mapped_sum[group] += val[2]
      paired_sum[group] += val[3]
      secondary_sum[group] += val[4]
      supplementary_sum[group] += val[5]
      primary_sum[group] += val[6]
      depth_sum[group] += val[7]
      sample_count[group]++
    }
    sample = gensub(/^Summary for ([^ ]+).*/, "\\1", "g", $0)
    group = get_group(sample)
    count = 0
    next
  }
  if ($0 ~ /^[0-9]/ && group != "") {
    val[++count] = $0 + 0
  }
}
END {
  for (g in sample_count) {
    printf "Group: %s\n", g
    printf "  Avg total reads: %.2f\n", total_sum[g] / sample_count[g]
    printf "  Avg mapped reads: %.2f\n", mapped_sum[g] / sample_count[g]
    printf "  Avg properly paired reads: %.2f\n", paired_sum[g] / sample_count[g]
    printf "  Avg secondary alignments: %.2f\n", secondary_sum[g] / sample_count[g]
    printf "  Avg supplementary alignments: %.2f\n", supplementary_sum[g] / sample_count[g]
    printf "  Avg primary alignments: %.2f\n", primary_sum[g] / sample_count[g]
    printf "  Avg read depth: %.2f\n\n", depth_sum[g] / sample_count[g]
  }
}
' "$STATS"
