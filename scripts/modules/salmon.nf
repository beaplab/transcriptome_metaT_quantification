#!/usr/bin/env nextflow

process INDEX_W_SALMON{
    
    conda '/home/aauladell/miniconda3/envs/slm3'

    tag "${meta}"


    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta}_index")

    script:
    """
    salmon index -t ${fasta} -i ${meta}_index
    """
}


process QUANT_SALMON{
    
    conda '/home/aauladell/miniconda3/envs/slm3'
    
    tag "${meta_sam}"

    publishDir "data/mapping",
    mode: 'symlink',
    overwrite: true

    input:
    tuple val(meta_t), path(transcriptome_i), val(meta_sam), path(metaT)

    output:
    path "mapping_${meta_sam}_to_${meta_t}"

    script:
    """

    salmon quant -l A \
    -i ${transcriptome_i} \
    -r ${metaT} \
    -p 4 \
    --validateMappings \
    -o mapping_${meta_sam}_to_${meta_t}
    """
}
