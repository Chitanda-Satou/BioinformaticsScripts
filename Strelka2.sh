# 1. Define each arguments first.


# 2. Run Manta.

manta_run_dir="${tumor_bam_name}_manta_somatic"
# Configure pipeline
configManta.py \
            --normalBam $normal_bam \
            --tumorBam $tumor_bam \
            --referenceFasta $GENOME \
            --exome \
            --callRegions $BED_STRELKA \
            --runDir $manta_run_dir
            
${manta_run_dir}/runWorkflow.py -m local -j $CPU
        

# 3. Run Strelka2.

run_dir=${tumor_bam_name}_strelka_somatic

# Configure pipeline
configureStrelkaSomaticWorkflow.py \
    --normalBam $normal_bam \
    --tumorBam $tumor_bam \
    --referenceFasta $GENOME \
    --indelCandidates ${manta_run_dir}/results/variants/candidateSmallIndels.vcf.gz \
    --exome \
    --callRegions $BED_STRELKA \
    --runDir $run_dir
    
# Call mutation:
$run_dir/runWorkflow.py -m local -j $CPU


# 4. Merge mutation.

$GATK_DIR/gatk --java-options $RAM \
    MergeVcfs \
    -I $run_dir/results/variants/somatic.snvs.vcf.gz \
    -I $run_dir/results/variants/somatic.indels.vcf.gz \
    -O ${tumor_bam_name}.strelka.somatic.vcf.gz
    
    
