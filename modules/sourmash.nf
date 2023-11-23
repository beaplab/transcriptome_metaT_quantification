#!/usr/bin/env nextflow

process SIGNATURE_CREATION{

    conda '/home/aauladell/miniconda3/envs/smash'

    tag "${meta}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta}.zip")

    script:
    """
    sourmash sketch dna $fasta -o ${meta}.zip
    """
}

process COMPARE_SIGNATURES{

    conda '/home/aauladell/miniconda3/envs/smash'
    
    tag "${meta_transcriptome} vs ${meta_sample.id}"

    errorStrategy 'ignore'

    input:
    tuple val(meta_transcriptome), path(transcriptome), val(meta_sample), path(sample)

    // we only want to know which ones are the ones that need the quantification
    output:
    tuple val(meta_transcriptome), val(meta_sample), path("${meta_transcriptome}_${meta_sample.id}.csv")

    script:
    """
    sourmash gather $transcriptome $sample -o ${meta_transcriptome}_${meta_sample.id}.csv
    """
}