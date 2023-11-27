#!/usr/bin/env nextflow

include { SIGNATURE_CREATION as SIGNATURE_transcriptome } from './modules/sourmash.nf'
include { COMPARE_SIGNATURES as GATHER } from './modules/sourmash.nf'

include { INDEX_W_SALMON } from './modules/salmon.nf'
include { QUANT_SALMON as QUANT } from './modules/salmon.nf'

include { INDEX_W_BWA2 } from './modules/bwa.nf'
include { ALIGNMENT_BWA2 } from './modules/bwa.nf'

include { QUANTIFICATION_PARSER } from './modules/parser_results.nf'


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
    } else {
        data.reads = [file(row.fastq_r1), file(row.fastq_r2) ]
        data.sig = file(row.sig)
    }

    fastq_meta = [meta: meta, data: data]
    return fastq_meta
}


workflow {

// Params ---------------------------------------------------------------------

    params.transcriptome = "data/genomic_data/transcriptomes/nucleotide_version/*.fna.gz"
    params.fastq_sheet = "/home/aauladell/projects/beap_index/data/dataset_correspondence_paths.csv"
    params.outdir = "data/quantification"

// Channels -------------------------------------------------------------------

    Channel.fromPath(params.fastq_sheet)
    .splitCsv(header: true)
    .map { create_fastq_channel(it)}
    .set {fastq_ch}

    Channel.fromPath( params.transcriptome )
        .map { it -> [it.simpleName , it ] }
        .set {transcriptome_ch}

// Processes ------------------------------------------------------------------

// Sourmash -------------------------------------------------------------------
    //Creation of signatures
    transcriptome_sigs_ch = SIGNATURE_transcriptome( transcriptome_ch )

    // combination of the channels
    comparison_sigs_ch = transcriptome_sigs_ch
        .combine(
            fastq_ch
            .map{ it -> tuple( it.meta, it.data.sig )}
        )


    // obtaining all the matches
    gather_res_ch = GATHER( comparison_sigs_ch )
    // only keep results with match
    .filter { it[2].baseName != 'NOMATCH'} 


// Salmon quant ---------------------------------------------------------------

    // Create the index from the transcriptomes 
    i_transcriptome_ch = INDEX_W_SALMON( transcriptome_ch )


    fastqs_to_quantify_ch = i_transcriptome_ch 
        .map{it[0]}
        .combine( 
            fastq_ch
            .map{it -> tuple(it.meta, it.data.reads)}
        )
        // filters all the transcriptomes not found in gather
        .combine( gather_res_ch | map {it -> [it[0], it[1].id] } | groupTuple, by: 0) 
        // selecting only transcriptome / sample comparison 
        .filter { meta_i, meta_sample, path_sample, to_keep -> (meta_sample.id in to_keep) }
        .map { it[0,1,2]}
        
    mapping_sams_ch = i_transcriptome_ch
        .combine( fastqs_to_quantify_ch, by:0  ) 

    salmon_quant_ch = QUANT( mapping_sams_ch )

// BWA2 quant ---------------------------------------------------------------

    i_transcriptome_bwa_ch = INDEX_W_BWA2( transcriptome_ch )

    aligning_sams_ch = i_transcriptome_bwa_ch
        .combine( fastqs_to_quantify_ch, by:0 ) 

    bwa_align_ch = ALIGNMENT_BWA2( aligning_sams_ch )

// Parsing quantifications --------------------------------------------------

    quants_grouped_ch = salmon_quant_ch
    .map{it -> tuple( [it[0], it[1].group, it[1].single_end], it[2] )}
    .groupTuple() 
    //TODO eventually put more beautiful? 
    .map{ it -> tuple( it[0][0], it[0][1], it[0][2], it[1])}


    quant_matrix_ch = QUANTIFICATION_PARSER( quants_grouped_ch ) 


}
