#!/usr/bin/env Rscript

library(tidyverse)
library(argparser)


# Create a parser
p <- arg_parser("Compile all the quantifications for the transcriptomes")

# Add command line arguments
p <- add_argument(p, "--quant_directories", help="the input directories", type="character", nargs = Inf)
p <- add_argument(p, "--grouping", help="which groups of samples are we working on", default='2012_carradec_tara')
p <- add_argument(p, "--transcriptome", help="which transcriptome is mapped", default='EP00618_Florenciella_parvula')
p <- add_argument(p, "--single_end", help="either if its single end or not", default= TRUE)

argv <- parse_args(p)

print(argv$quant_directories) 

map.files <- list.files( argv$quant_directories,
                        pattern = 'quant.sf',
                        full.names = T)

quant.df <- read_tsv(file = map.files, id = 'sample') %>% 
    mutate( transcriptome = argv$transcriptome,
            sample = dirname(sample) %>% basename()) %>% 
    select(transcriptome, sample, everything())

if( argv$single_end ){

    quant.df <- quant.df %>% 
        mutate( NumReads = NumReads / 2, 
                reads_p_kilobase = NumReads / EffectiveLength,
                scaling = sum(reads_p_kilobase) / 1e6,
                TPM = reads_p_kilobase / scaling)

}

quant.mat.tpm <- quant.df %>%
    pivot_wider(names_from = Name, values_from = TPM, id_cols = sample) 

quant.mat.numreads <- quant.df %>%
    pivot_wider(names_from = Name, values_from = NumReads, id_cols = sample) 

quant.gene.chars <- quant.df %>% 
    group_by(Name) %>% 
    summarize( Length = unique(Length), 
            mean.effective.length = mean(EffectiveLength, na.rm = TRUE), 
            presence = sum(NumReads > 0),
            mean.tpm = mean(TPM),
            mean.numreads = mean(NumReads))


stripname.shared <- str_c(argv$transcriptome,
                          "quant-over",
                          str_c(argv$grouping, '.tsv'), sep = "_" )

write_tsv(x = quant.mat.tpm, file = str_c('TPM_', stripname.shared ))
write_tsv(x = quant.mat.numreads, file = str_c('Numreads_', stripname.shared ))
write_tsv(x = quant.gene.chars, file = str_c('gene-characteristics_', stripname.shared ))
