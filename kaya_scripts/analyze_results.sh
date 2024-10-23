#!/bin/bash

# This is the bash equivalent of Analyze_Result.csh

# Check the number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <fastq file name> <Fasta dir>"
    exit 0
fi

export MODULEPATH=/group/pgh004/carrow/repo/btseq/env/modules:$MODULEPATH
module load bismark

# Strip two extensions from $1
FastqName="${1%.*}"
FastqName="${FastqName%.*}"

FastaDir="$2"

echo "Running bismark_methylation_extractor"

# Build sam_name
sam_name="${FastaDir}/Output/$(basename "${FastqName}")_bismark_bt2.sam"

# Run bismark_methylation_extractor
bismark_methylation_extractor -s "$sam_name" --bedGraph --counts --cytosine_report --genome_folder "${FastaDir}" --CX --comprehensive -o "${FastaDir}/Output"

# Format the summary report nicely for all C's
CX_name="${FastaDir}/Output/$(basename "${FastqName}")_bismark_bt2.CX_report.txt"

echo "Generating Summary and Hist files"

report_name="${FastaDir}/Output/$(basename "${FastqName}")_bismark_bt2_SE_report.txt"

grep "Sequences analysed in total" "$report_name" | awk '{print "Total # of reads:\t" $NF}' > "$CX_name.summary"

echo -e "Total reads aligned:\t$(grep -v -P '^@' "$sam_name" | wc -l)" >> "$CX_name.summary"

# Get tname list
tname_list=$(grep "^>" "${FastaDir}"/*.fa | sed 's/>//' | awk '{print $1}')

for tname in $tname_list; do
    echo -e "Read aligned to ${tname}:\t$(grep -v -P '^@' "$sam_name" | grep "${tname}" | wc -l)" >> "$CX_name.summary"
done

for tname in $tname_list; do
    echo >> "$CX_name.summary"
    echo "$tname" >> "$CX_name.summary"
    echo "CpG sites" >> "$CX_name.summary"
    echo -e "Position\t#C\t#T\t%Meth" >> "$CX_name.summary"

    grep "${tname}" "$CX_name" | grep '+' | awk 'BEGIN {OFS="\t"} {print $2, substr($7,1,2), $4, $5, ($5>0)?100*$4/($4+$5):0}' > "$CX_name.summary_all"

    grep -w 'CG' "$CX_name.summary_all" | awk 'BEGIN {OFS="\t"} {print $1, $3, $4, $5}' >> "$CX_name.summary"

    echo -e "\nCpA sites" >> "$CX_name.summary"
    echo -e "Position\t#C\t#T\t%Meth" >> "$CX_name.summary"

    grep -w 'CA' "$CX_name.summary_all" | awk 'BEGIN {OFS="\t"} {print $1, $3, $4, $5}' >> "$CX_name.summary"

    echo -e "\nAll C sites" >> "$CX_name.summary"
    cat "$CX_name.summary_all" >> "$CX_name.summary"
    rm "$CX_name.summary_all"

    # Output the pattern distribution CpG
    CpGcontext_name="${FastaDir}/Output/CpG_context_$(basename "${FastqName}")_bismark_bt2.txt"
    CpGList=$(grep "${tname}" "$CX_name" | grep '+' | grep -w 'CG' | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')

    cat "$CpGcontext_name" | grep "${tname}" | awk '{print $1, $4 ":" $2}' | \
    awk '{ stuff[$1] = stuff[$1] $2 " " } END { for (s in stuff) print s, stuff[s] }' | \
    cut -d " " -f 2- | sed 's/^ *//' | tr ' ' ':' | \
    awk -F':' -v list="$CpGList" 'BEGIN {split(list, arr, " ");} {
        for (i in arr) b[arr[i]] = "-";
        for (i = 2; i <= NF; i += 2)
            $(i) == "+" ? b[$(i-1)] = "C" : b[$(i-1)] = "T";
        for (i in arr) printf b[arr[i]] "\t";
        printf "\n"
    }' | sort | uniq -c | sort -nr | \
    awk -v list="$CpGList" 'BEGIN {printf "Count\t" list "\n"} {print $0}' | \
    sed 's/^ *//' | tr ' ' '\t' > "$CpGcontext_name.hist.tmp"

    touch "$CpGcontext_name.hist"
    echo "$tname" >> "$CpGcontext_name.hist"

    awk 'BEGIN {A=0; C=0; G=0; T=0; OFS="\t"} {
        if (NR==1) {
            printf $1 "\t# of A\t# of C\t# of G\t# of T\t# of sites\t";
            for (i=2; i<=NF; i++) printf $i "\t";
            printf "\n";
            next
        }
        for (i=2; i<=NF; i++) {
            if ($i=="A") A++;
            if ($i=="C") C++;
            if ($i=="G") G++;
            if ($i=="T") T++
        }
        printf $1 "\t" A "\t" C "\t" G "\t" T "\t" (A+C+G+T) "\t";
        for (i=2; i<=NF; i++) printf $i "\t";
        printf "\n";
        A=0; C=0; G=0; T=0
    }' "$CpGcontext_name.hist.tmp" >> "$CpGcontext_name.hist"

    echo >> "$CpGcontext_name.hist"
    rm "$CpGcontext_name.hist.tmp"

    # Output the pattern distribution CpA
    CpAcontext_name="${FastaDir}/Output/CpA_context_$(basename "${FastqName}")_bismark_bt2.txt"
    CHHcontext_name="${FastaDir}/Output/CHH_context_$(basename "${FastqName}")_bismark_bt2.txt"
    CHGcontext_name="${FastaDir}/Output/CHG_context_$(basename "${FastqName}")_bismark_bt2.txt"
    CpAList=$(grep "${tname}" "$CX_name" | grep '+' | grep -P 'CA.$' | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')

    cat "$CHHcontext_name" "$CHGcontext_name" | grep "${tname}" | awk '{print $1, $4 ":" $2}' | \
    awk '{ stuff[$1] = stuff[$1] $2 " " } END { for (s in stuff) print s, stuff[s] }' | \
    cut -d " " -f 2- | sed 's/^ *//' | tr ' ' ':' | \
    awk -F':' -v list="$CpAList" 'BEGIN {split(list, arr, " ");} {
        for (i in arr) b[arr[i]] = "-";
        for (i = 2; i <= NF; i += 2)
            $(i) == "+" ? b[$(i-1)] = "C" : b[$(i-1)] = "T";
        for (i in arr) printf b[arr[i]] "\t";
        printf "\n"
    }' | sort | uniq -c | sort -nr | \
    awk -v list="$CpAList" 'BEGIN {printf "Count\t" list "\n"} {print $0}' | \
    sed 's/^ *//' | tr ' ' '\t' > "$CpAcontext_name.hist.tmp"

    touch "$CpAcontext_name.hist"
    echo "$tname" >> "$CpAcontext_name.hist"

    awk 'BEGIN {A=0; C=0; G=0; T=0; OFS="\t"} {
        if (NR==1) {
            printf $1 "\t# of A\t# of C\t# of G\t# of T\t# of sites\t";
            for (i=2; i<=NF; i++) printf $i "\t";
            printf "\n";
            next
        }
        for (i=2; i<=NF; i++) {
            if ($i=="A") A++;
            if ($i=="C") C++;
            if ($i=="G") G++;
            if ($i=="T") T++
        }
        printf $1 "\t" A "\t" C "\t" G "\t" T "\t" (A+C+G+T) "\t";
        for (i=2; i<=NF; i++) printf $i "\t";
        printf "\n";
        A=0; C=0; G=0; T=0
    }' "$CpAcontext_name.hist.tmp" >> "$CpAcontext_name.hist"

    echo >> "$CpAcontext_name.hist"
    rm "$CpAcontext_name.hist.tmp"

done
