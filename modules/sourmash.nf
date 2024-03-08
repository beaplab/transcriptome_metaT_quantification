#!/usr/bin/env nextflow

process SIGNATURE_CREATION{

    conda 'bioconda::sourmash=4.8.4'

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

    conda 'bioconda::sourmash=4.8.4'
    
    tag "${meta_transcriptome} vs ${meta_sample.id}"

    input:
    tuple val(meta_transcriptome), path(transcriptome), val(meta_sample), path(sample)

    // we only want to know which ones are the ones that need the quantification
    output:
    tuple val(meta_transcriptome), val(meta_sample), path("*.csv")

    script:
    """
    sourmash gather $transcriptome $sample -o ${meta_transcriptome}_${meta_sample.id}.csv

    if [ ! -f ${meta_transcriptome}_${meta_sample.id}.csv ]; then
        touch NOMATCH.csv 
    fi

    """
}
