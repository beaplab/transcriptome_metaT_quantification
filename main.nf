nextflow.enable.dsl=2

process sample_signature{

    conda '/home/aauladell/miniconda3/envs/smash'

    tag "${metaT.simpleName}"

    maxForks 20
    publishDir "data/metaT_samples-signature",
    mode: 'move',
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

    conda '/home/aauladell/miniconda3/envs/smash'

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

    conda '/home/aauladell/miniconda3/envs/smash'
    
    tag "${metaT.simpleName}"

    publishDir "data/statistics/similarity_matrix",
    mode: 'symlink',
    overwrite: true

    input:
    tuple path(transcriptome), path(metaT)

    output:
    path "${transcriptome}_${metaT}.csv"

    script:
    """
    sourmash compare $transcriptome $metaT --csv ${transcriptome}_${metaT}.csv
    """
}


process index_w_salmon{
    
    conda '/home/aauladell/miniconda3/envs/slm3'

    tag "${transcriptome.simpleName}"

    publishDir "data/genomic_data/salmon-signatures",
    mode: 'symlink',
    overwrite: true

    input:
    path transcriptome

    output:
    path "${transcriptome.simpleName}_index"

    script:
    """
    salmon index -t ${transcriptome} \
        -i ${transcriptome.simpleName}_index
    """
}


process map_w_salmon{
    
    conda '/home/aauladell/miniconda3/envs/slm3'
    
    tag "${metaT.simpleName}"

    publishDir "data/mapping",
    mode: 'symlink',
    overwrite: true

    input:
    tuple path(transcriptome_i), path(metaT)

    output:
    path "mapping_${metaT.simpleName}_to_${transcriptome_i.simpleName}"

    script:
    """

    salmon quant -l A \
    -i ${transcriptome_i} \
    -r ${metaT} \
    -p 4 \
    --validateMappings \
    -o mapping_${metaT.simpleName}_to_${transcriptome_i.simpleName}
    """
}

workflow {

// Params ---------------------------------------------------------------------
    params.transcriptome = "data/genomic_data/transcriptomes/nucleotide_version/EP00618_Florenciella_parvula.fna.gz"
    params.fastq = "data/metaT_samples_tara/*.fasta.gz"


// Channels -------------------------------------------------------------------

    fastq_sams_ch = Channel.fromPath( params.fastq )
    transcriptome_ch = Channel.fromPath( params.transcriptome )

// Processes ------------------------------------------------------------------

// Sourmash -------------------------------------------------------------------
    //Creation of signatures
    transcriptome_sigs_ch = transcriptome_signature( transcriptome_ch )
    sample_sigs_ch = sample_signature( fastq_sams_ch )

    // combination of the channels
    comparison_sigs_ch = transcriptome_sigs_ch
        .combine(sample_sigs_ch)

    gather_res_ch = compare_transcriptomes_metaTs( comparison_sigs_ch )

// Salmon quant ---------------------------------------------------------------

    i_transcriptome_ch = index_w_salmon( transcriptome_ch )

    mapping_sams_ch = i_transcriptome_ch
        .combine( fastq_sams_ch )
    
    salmon_quant_ch = map_w_salmon( mapping_sams_ch )

}
