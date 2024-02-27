#!/usr/bin/env bash

nextflow run main.nf \
    --fastq_sheet data/test_data/sample_sheet/dataset_correspondence_paths_test.csv \
    --transcriptome "data/genomic_data/transcriptomes/nucleotide_version/*.fna.gz" \
    --outdir data/quantification \
    -resume


