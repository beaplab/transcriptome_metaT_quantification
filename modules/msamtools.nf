#!/usr/bin/env nextflow

process PROFILE_BAM{
    
    tag "${meta_sam.id}"
    
    conda "bioconda::msamtools"

    input:
    tuple val(meta_t), val(meta_sam), path(bam)

    output:
    tuple val(meta_t), val(meta_sam), path("*.profile.txt.gz")

    script:
    """
    msamtools profile --multi=ignore \
        --label=${meta_sam.id} \
        --nolen --unit=ab \
        -o ${meta_sam.id}.profile.txt.gz $bam
    """
}


