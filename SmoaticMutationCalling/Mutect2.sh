# 1. Define each arguments first.


# 2. Create PoN.

# Call mutation on normal bams.
gatk --java-options ${RAM} Mutect2 \
      -R ${GENOME} \
      -I ${control_bam} \
      -O ${control_vcf} \
      --max-mnp-distance 0 \
      -L ${BED}
          
# Create PoN.
gatk --java-options ${RAM} GenomicsDBImport \
      -R ${GENOME} \
      --genomicsdb-workspace-path temporary_pon_db \
      -L ${BED} \
      --merge-input-intervals true \
      --tmp-dir tmp \
      -V ${control_vcf1} \
      -V ${control_vcf2} \
      -V ${control_vcf3} \
      -V ...

gatk --java-options ${RAM} CreateSomaticPanelOfNormals \
      -R ${GENOME} \
      --germline-resource ${GERMLINE_RESOURCE} \
      -V gendb://temporary_pon_db \
      -O ${pon_vcf}


# 3. Run Mutect2

$GATK_DIR/gatk --java-options $RAM \
    Mutect2 \
    -R $GENOME \
    -I ${tumor_bam} \
    -I ${normal_bam} \
    -normal ${normal_sample_name} \
    -pon $PON \
    --max-mnp-distance "0" \
    --germline-resource $GERMLINE_RESOURCE \
    --native-pair-hmm-threads ${mutect2_threads:-4} \
    -L $BED -ip $BED_PADDING \
    --f1r2-tar-gz ${tumor_bam_name}.f1r2.tar.gz \
    -O ${tumor_bam_name}_somatic_m2.vcf.gz

# CalculateContamination:
$GATK_DIR/gatk --java-options $RAM \
    LearnReadOrientationModel \
    -I ${tumor_bam_name}.f1r2.tar.gz \
    -O ${tumor_bam_name}.read-orientation-model.tar.gz
    
$GATK_DIR/gatk --java-options $RAM \
    GetPileupSummaries \
    -I ${tumor_bam} \
    -V $SMALL_EXAC \
    -O ${tumor_bam_name}_getpileupsummaries.table \
    -L $BED -ip $BED_PADDING
    
$GATK_DIR/gatk --java-options $RAM \
    CalculateContamination \
    -I ${tumor_bam_name}_getpileupsummaries.table \
    --tumor-segmentation ${tumor_bam_name}.segments.table \
    -O ${tumor_bam_name}_calculatecontamination.table

# FilterMutectCalls:
$GATK_DIR/gatk --java-options $RAM \
    FilterMutectCalls \
    -V ${tumor_bam_name}_somatic_m2.vcf.gz \
    --tumor-segmentation ${tumor_bam_name}.segments.table \
    --contamination-table ${tumor_bam_name}_calculatecontamination.table \
    -ob-priors ${tumor_bam_name}.read-orientation-model.tar.gz \
    -O ${tumor_bam_name}_somatic_oncefiltered.vcf.gz \
    -L $BED -ip $BED_PADDING \
    -R $GENOME
