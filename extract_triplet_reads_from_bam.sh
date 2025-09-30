module load samtools/

# List your .bam file as well as your coordinates of interest here:
samtools view AVA1Aligned.sortedByCoord.out.bam III:834305-835213 | awk '{id_count[$1]++} END {for (id in id_count) if (id_count[id] == 3) print id}' > reads_list.txt

read_ids=$(<reads_list.txt)

samtools view AVA1Aligned.sortedByCoord.out.bam III:834305-835213 | \
awk -v ids="$read_ids" 'BEGIN {
    split(ids, id_array, "\n")  # Split read IDs into an array
    for (i in id_array) {
        read_id[id_array[i]] = 1;  # Store read IDs in an associative array
    }
} 
{
    if ($1 in read_id) {  # Check if the read ID is in the provided list
        id_count[$1]++;
        if ($0 ~ /SA:Z:/) sa_count[$1]++;
    }
} 
END {
    for (id in id_count) 
        if (id_count[id] == 3 && sa_count[id] == 2) 
            print id;
}'
