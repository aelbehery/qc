#!/usr/bin/env bash

usage()
{
echo "
Description: $0 is a quality control pipeline that can rename, quality-trim, decontaminate and remove adapters from fastq sequence read files

Usage:
-s | --single-end       Single-end read file (cannot be combined with -p1 & -p2 options)
-p1 | --pair1           Pair1 file of paired-end reads (cannot be combined with -s option)
-p2 | --pair2           Pair2 file of paired-end reads (cannot be combined with -s option)
-p | --prefix           [optional] a prefix used to rename fastq files
-a | --adapter          adapter sequence or file; if a file is used, the file name has to be preceded by "file:"
                        e.g. -a file:adapter.fasta
-a2 | --adapter         [optional] Adpater for the second pair in the case of paired-end reads. If not supplied,
                        adapter1 will be used for adapter trimming of both pairs.
-d | --decontaminate    fasta file, which includes the sequences to map the reads against; matches will be
                        decontaminated according to the specified minimum %identity.
-id                     minimum match identity used for decontamination; default=0.95
--interleaved           output pairs will be interleaved in one file in the case of paired-end reads
-h | --help             Display this help message and exit
"
}

SINGLE=""
PAIRED=""
PREFIX=""
DECONTAMINATE=""
ID=0.95
INTERLEAVED=""

while [ "$1" != "" ]; do
    case $1 in
        -s | --single-end )           shift
                                                                SEQ=$1
                                ;;
        -p1 | --pair1 )               shift
                                                                SEQ1=$1
                                ;;
        -p2 | --pair2 )               shift
                                                                SEQ2=$1
                                ;;
        -p | --prefix )               shift
                                                                PREFIX=$1
                                ;;
        -a | --adapter )              shift
                                                                ADAPTER=$1
                                                                ADAPTER2="$ADAPTER"
                                ;;
        -a2 | --adapter2 )            shift
                                                                ADAPTER2=$1
                                ;;
        -d | --decontaminate )        shift
                                                                DECONTAMINATE=$1
                                ;;
        -id )                         shift
                                                                ID=$1
                                ;;
        --interleaved )               shift
                                                                INTERLEAVED="yes"
                                ;;
        -h | --help )                                           usage
                                                                exit
                                ;;
        * )                                                     usage
                                                                exit 1
    esac
    shift
done


if [ "$SEQ" != "" ]; then
        if [ "$PREFIX" != "" ]; then
                awk -v p="$PREFIX" '{if(NR%4==1) printf "@%s.%09d\n", p,++i; else if(NR%4==3) printf "+%s.%09d\n", p,i; else print}' $SEQ > ${SEQ%.*}.new.fastq
                SEQ=${SEQ%.*}.new.fastq
        fi
        cutadapt -b $ADAPTER --trim-n -m 50 --max-n 2 -q 15,15 -o ${SEQ%.*}.truncated $SEQ
        prinseq-lite.pl -verbose -fastq ${SEQ%.*}.truncated -lc_threshold 50 -lc_method entropy -derep 12345 -noniupac -min_qual_mean 20 -out_good ${SEQ%.*}_prinseq -out_bad null
        rm ${SEQ%.*}.truncated
        bbmap.sh in=${SEQ%.*}_prinseq.fastq ref="$DECONTAMINATE" nodisk minid="$ID" outu=${SEQ%.*}_qc.fastq
        rm ${SEQ%.*}_prinseq.fastq
fi

if [ "$SEQ1" != "" ]; then
        if [ "$PREFIX" != "" ]; then
                awk -v p="$PREFIX" '{if(NR%4==1) printf "@%s.%09d/1\n", p,++i; else if(NR%4==3) printf "+%s.%09d/1\n", p,i; else print}' $SEQ1 > ${SEQ1%.*}.new.fastq
                awk -v p="$PREFIX" '{if(NR%4==1) printf "@%s.%09d/2\n", p,++i; else if(NR%4==3) printf "+%s.%09d/2\n", p,i; else print}' $SEQ2 > ${SEQ2%.*}.new.fastq
                                SEQ1=${SEQ1%.*}.new.fastq ; SEQ2=${SEQ2%.*}.new.fastq
                fi
                cutadapt -b $ADAPTER -B $ADAPTER2 --trim-n -m 50 --max-n 2 -q 15,15 -o ${SEQ1%.*}.truncated -p ${SEQ2%.*}.truncated $SEQ1 $SEQ2
                prinseq-lite.pl -verbose -fastq ${SEQ1%.*}.truncated -fastq2 ${SEQ2%.*}.truncated -lc_threshold 50 -lc_method entropy -derep 12345 -noniupac -min_qual_mean 20 -out_good ${SEQ1%_*}_prinseq -out_bad null
                rm ${SEQ1%.*}.truncated ${SEQ2%.*}.truncated
                if [ -f ${SEQ1%_*}_prinseq_1_singletons.fastq ]; then
                        rm ${SEQ1%_*}_prinseq_1_singletons.fastq
                fi
                if [ -f ${SEQ1%_*}_prinseq_2_singletons.fastq ]; then
                        rm ${SEQ1%_*}_prinseq_2_singletons.fastq
                fi
                bbmap.sh in=${SEQ1%_*}_prinseq_1.fastq in2=${SEQ1%_*}_prinseq_2.fastq ref="$DECONTAMINATE" nodisk minid="$ID" outu=${SEQ1%_*}_qc.fastq
                rm ${SEQ1%_*}_prinseq_1.fastq ${SEQ1%_*}_prinseq_2.fastq
                if [ "$INTERLEAVED" != "yes" ] ; then
                        reformat.sh in=${SEQ1%_*}_qc.fastq out1=${SEQ1%.*}_qc.fastq out2=${SEQ2%.*}_qc.fastq
                        rm ${SEQ1%_*}_qc.fastq
                fi
fi
