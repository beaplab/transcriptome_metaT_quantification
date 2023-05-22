#!/usr/bin/env nextflow

include { SIGNATURE_CREATION as SIGNATURE_transcriptome } from './scripts/modules/sourmash.nf'
include { SIGNATURE_CREATION as SIGNATURE_metaT } from './scripts/modules/sourmash.nf'
include { COMPARE_SIGNATURES as GATHER } from './scripts/modules/sourmash.nf'
include { INDEX_W_SALMON as INDEX_W_SALMON } from './scripts/modules/salmon.nf'
include { QUANT_SALMON as QUANT } from './scripts/modules/salmon.nf'


workflow {

// Params ---------------------------------------------------------------------
    params.transcriptome = "data/genomic_data/transcriptomes/nucleotide_version/*.fna.gz"
    params.fastq = "data/metaT_samples_tara-test/*.fasta.gz"


// Channels -------------------------------------------------------------------

    Channel.fromPath( params.fastq )
        .map { it -> [it.simpleName , it ] }
        .set {fastq_sams_ch}
                            

    Channel.fromPath( params.transcriptome )
        .map { it -> [it.simpleName , it ] }
        .set {transcriptome_ch}

// Processes ------------------------------------------------------------------

// Sourmash -------------------------------------------------------------------
    //Creation of signatures

    transcriptome_sigs_ch = SIGNATURE_transcriptome( transcriptome_ch )
    sample_sigs_ch = SIGNATURE_metaT( fastq_sams_ch )

    // combination of the channels
    comparison_sigs_ch = transcriptome_sigs_ch
        .combine(sample_sigs_ch)

    // obtaining all the matches
    gather_res_ch = GATHER( comparison_sigs_ch )

//// Salmon quant ---------------------------------------------------------------

    i_transcriptome_ch = INDEX_W_SALMON( transcriptome_ch )


    fastqs_to_quantify_ch = fastq_sams_ch 
    | combine (gather_res_ch | map {it[0]} | collect | map {[it]})
    | filter { meta, path, to_keep -> (meta in to_keep) }
    | map { it[0,1] }
    | view

    mapping_sams_ch = i_transcriptome_ch
        .combine( fastqs_to_quantify_ch  ) 
        .view()

    salmon_quant_ch = QUANT( mapping_sams_ch )

}
