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
    
    tag "${meta_sam.id}"

    publishDir "data/mapping/${meta_t}/${meta_sam.group}",
    mode: 'copy',
    overwrite: true

    input:
    tuple val(meta_t), path(transcriptome_i), val(meta_sam), path(reads)

    output:
    path "${meta_sam.id}"

    script:
    def reference   = "--index $transcriptome_i"
    def reads1 = [], reads2 = []
    meta_sam.single_end ? [reads].flatten().each{reads1 << it} : reads.eachWithIndex{ v, ix -> ( ix & 1 ? reads2 : reads1) << v }
    def input_reads = meta_sam.single_end ? "-r ${reads1.join(" ")}" : "-1 ${reads1.join(" ")} -2 ${reads2.join(" ")}"
    """

    salmon quant -l A \
    $reference \
    $input_reads \
    -p 4 \
    --validateMappings \
    -o ${meta_sam.id}
    """
}


//    -i ${transcriptome_i} \
//    -r ${metaT} \
