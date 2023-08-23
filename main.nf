#!/usr/bin/env nextflow

include { SIGNATURE_CREATION as SIGNATURE_transcriptome } from './scripts/modules/sourmash.nf'
include { COMPARE_SIGNATURES as GATHER } from './scripts/modules/sourmash.nf'
include { INDEX_W_SALMON as INDEX_W_SALMON } from './scripts/modules/salmon.nf'
include { QUANT_SALMON as QUANT } from './scripts/modules/salmon.nf'

def create_fastq_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id           = row.name
    meta.group        = row.group
    meta.single_end   = row.single_end.toBoolean()

    // add path(s) of the fastq file(s) to the meta map
    def fastq_meta = [:]
    def data = [:]
    if (meta.single_end) {
        data.reads = file(row.fastq_r1)
        data.sig = file(row.sig)
//        fastq_meta = [ meta, [ reads: file(row.fastq_r1), sig: file(row.sig) ] ]
    } else {
        data.reads = [file(row.fastq_r1), file(row.fastq_r2) ]
        data.sig = file(row.sig)
//        fastq_meta = [ meta, [ reads: [file(row.fastq_r1), file(row.fastq_r2) ], sig: file(row.sig) ] ]
    }

    fastq_meta = [meta: meta, data: data]
    return fastq_meta
}


workflow {

// Params ---------------------------------------------------------------------
    params.transcriptome = "data/genomic_data/transcriptomes/nucleotide_version/*.fna.gz"
    params.fastq = "data/metaT_samples_tara/*.fasta.gz"

    params.fastq_sheet = "/home/aauladell/projects/beap_index/data/dataset_correspondence_paths.csv"

// Channels -------------------------------------------------------------------

    Channel.fromPath(params.fastq_sheet)
    .splitCsv(header: true)
    .map { create_fastq_channel(it)}
    .set {fastq_ch}

//    Channel.fromPath( params.fastq )
//        .map { it -> [it.simpleName , it ] }
//        .set {fastq_sams_ch}

    Channel.fromPath( params.transcriptome )
        .map { it -> [it.simpleName , it ] }
        .set {transcriptome_ch}

// Processes ------------------------------------------------------------------

// Sourmash -------------------------------------------------------------------
    //Creation of signatures

    transcriptome_sigs_ch = SIGNATURE_transcriptome( transcriptome_ch )
//    sample_sigs_ch = SIGNATURE_metaT( fastq_sams_ch )

    // combination of the channels
    comparison_sigs_ch = transcriptome_sigs_ch
        .combine(
            fastq_ch
            .map{ it -> tuple( it.meta, it.data.sig )}
        )

//
//    // obtaining all the matches
    gather_res_ch = GATHER( comparison_sigs_ch )

////// Salmon quant ---------------------------------------------------------------
//
//    // Create the index from the transcriptomes 
    i_transcriptome_ch = INDEX_W_SALMON( transcriptome_ch )
//
    // Define which samples are needed to quanitfy


    fastqs_to_quantify_ch = fastq_ch 
        .map{ it -> tuple( it.meta, it.data.reads )}
    // create a new element of the list with all the results to keep
    | combine (gather_res_ch | map {it[0]} | collect | map {[it]})
    // filter to that selection
    | filter { meta, path, to_keep -> (meta in to_keep) }
    | map { it[0,1] }
//
    mapping_sams_ch = i_transcriptome_ch
        .combine( fastqs_to_quantify_ch  ) 
//
    salmon_quant_ch = QUANT( mapping_sams_ch )

}
