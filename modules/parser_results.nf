#!/usr/bin/env nextflow

process QUANTIFICATION_PARSER_S {

    tag "${meta_t}, ${group}"

    conda "r-argparser r-tidyverse"

    input:
    tuple val(meta_t), val(group), val(single_end), path(dir_quants)

    output: 
    tuple val(meta_t), val(group), val(single_end), path("TPM_${meta_t}_quant-over_${group}.tsv")
    tuple val(meta_t), val(group), val(single_end), path("Numreads_${meta_t}_quant-over_${group}.tsv")
    tuple val(meta_t), val(group), val(single_end), path("gene-characteristics_${meta_t}_quant-over_${group}.tsv")

    script: 
    """
    ${projectDir}/bin/quant_parser_salmon.R    \
                                        --quant_directories ${dir_quants} \
                                        --grouping ${group} \
                                        --transcriptome ${meta_t} \
                                        --single_end ${single_end}
    """


}

process QUANTIFICATION_PARSER_B {

    tag "${meta_t}, ${group}"

    conda "r-argparser r-tidyverse"

    input:
    tuple val(meta_t), val(group), val(single_end), path(dir_quants), path(genelengths)

    output: 
    tuple val(meta_t), val(group), val(single_end), path("TPM_${meta_t}_quant-over_${group}.tsv")
    tuple val(meta_t), val(group), val(single_end), path("Numreads_${meta_t}_quant-over_${group}.tsv")
    tuple val(meta_t), val(group), val(single_end), path("gene-characteristics_${meta_t}_quant-over_${group}.tsv")

    script: 
    """
    ${projectDir}/bin/quant_parser_bwa.R  \
                                        --quant_files ${dir_quants} \
                                        --grouping ${group} \
                                        --transcriptome ${meta_t} \
                                        --single_end ${single_end} \
                                        --gene_lengths ${genelengths} \
    """


}

