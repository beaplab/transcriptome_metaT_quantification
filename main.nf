nextflow.enable.dsl=2

process sample_signature{

    tag "${metaT.simpleName}"

    maxForks 20
    publishDir "data/metaT_samples-signature",
    mode: 'symlink',
    overwrite: true

    input:
    path metaT

    output:
    path "${metaT.simpleName}.zip"

    script:
    """
    sourmash sketch dna $metaT -o ${metaT.simpleName}.zip
    """
}

process transcriptome_signature{

    tag "${transcriptome.simpleName}"

    publishDir "data/genomic_data/sourmash-signatures",
    mode: 'symlink',
    overwrite: true

    input:
    path transcriptome

    output:
    path "${transcriptome.simpleName}.zip"

    script:
    """
    sourmash sketch dna $transcriptome -o ${transcriptome.simpleName}.zip
    """
}

process compare_transcriptomes_metaTs{
    
    tag "${metaT.simpleName}"

    publishDir "data/statistics/similarity_matrix",
    mode: 'symlink',
    overwrite: true

    input:
    path transcriptome
    path metaT

    output:
    path "${metaT}.csv"

    script:
    """
    sourmash compare $transcriptome $metaT --csv ${metaT}.csv 
    """
}


workflow {

// Params ---------------------------------------------------------------------
    params.transcriptome = "data/genomic_data/transcriptomes/nucleotide_version/EP00618_Florenciella_parvula.fna.gz"
    //params.fastq = "data/metaT_samples_tara/*.fasta.gz"


// Channels -------------------------------------------------------------------

    fastq_sams_ch = Channel.fromPath( "data/metaT_samples_tara/*.fasta.gz" )

    transcriptome_ch = Channel.fromPath( params.transcriptome )

// Processes ------------------------------------------------------------------
    transcriptome_sigs_ch = transcriptome_signature( transcriptome_ch )
    sample_sigs_ch = sample_signature(fastq_sams_ch)

    // we need to combine and produce all the possible comparisons 
    transcriptome_ch
        .combine(fastq_sams_ch)
        .view()
    //compare_transcriptomes_metaTs( transcriptome_sigs, sample_sigs )


}
