#!/usr/bin/env nextflow

process INDEX_W_BWA2{
    
    tag "${meta}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta}_index.*")

    script:
    """
    bwa-mem2 index -p ${meta}_index ${fasta} 
    """
}


process ALIGNMENT_BWA2{
    
    
    tag "${meta_sam.id}"

/*     publishDir "data/mapping/${meta_t}/${meta_sam.group}",
    mode: 'copy',
    overwrite: true */

    input:
    tuple val(meta_t), path(transcriptome_i), val(meta_sam), path(reads)

    output:
    path "${meta_sam.id}.bam"

    script:
    """
    INDEX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`

    bwa-mem2 mem \\
        -t 4 \\
        \$INDEX \\
        $reads \\
        | samtools view --threads 4 -o ${meta_sam.id}.bam -
    """
}
