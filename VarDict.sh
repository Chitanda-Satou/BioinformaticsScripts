 # 1. Define each arguments first.
 
 
 # 2. Run VarDict.
 
 $VarDict_dir/VarDict \
    -G $GENOME \
    -f $AF_THR \
    -adaptor "AGATCGGAAGAGC" \
    --nosv \
    -N $tumor_sample_name \
    -b "${tumor_bam}|${normal_bam}" \
    -z 1 -c 1 -S 2 -E 3 -g 4 $BED -th ${CPU:-8} > ${tumor_bam_name}.vardict.raw
            
cat "${tumor_bam_name}.vardict.raw" | $VarDict_dir/testsomatic.R > "${tumor_bam_name}.vardict.pval.raw"

# Generate VCF
$VarDict_dir/var2vcf_paired.pl \
    -N "${tumor_sample_name}|${normal_sample_name}" \
    -f $AF_THR "${tumor_bam_name}.vardict.pval.raw" > ${tumor_bam_name}.vardict.vcf
