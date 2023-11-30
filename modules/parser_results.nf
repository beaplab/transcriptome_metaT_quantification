#!/usr/bin/env nextflow

process QUANTIFICATION_PARSER {

    tag "${meta_t}, ${group}"

    conda "r-argparser r-tidyverse"

    input:
    tuple val(meta_t), val(group), val(single_end), path(dir_quants)

    output: 
    path "TPM_${meta_t}_quant-over_${group}.tsv"
    path "Numreads_${meta_t}_quant-over_${group}.tsv"
    path "gene-characteristics_${meta_t}_quant-over_${group}.tsv"

    script: 
    """
    ${projectDir}/bin/quant_parser.R    --quant_directories ${dir_quants} \
                                        --grouping ${group} \
                                        --transcriptome ${meta_t} \
                                        --single_end ${single_end}
    """


}
