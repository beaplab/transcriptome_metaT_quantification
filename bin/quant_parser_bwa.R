#!/usr/bin/env Rscript

library(tidyverse)
library(argparser)

# Create a parser
p <- arg_parser("Compile all the quantifications for the transcriptomes")

# Add command line arguments
p <- add_argument(p, "--quant_files", help="the input files", type="character", nargs = Inf)
p <- add_argument(p, "--grouping", help="which groups of samples are we working on", default='2012_carradec_tara')
p <- add_argument(p, "--transcriptome", help="which transcriptome is mapped", default='EP00618_Florenciella_parvula')
p <- add_argument(p, "--single_end", help="either if its single end or not", default= TRUE)
p <- add_argument(p, "--gene_lengths", help="the Effective gene lengths or simply the lengths")

argv <- parse_args(p)

print(argv$quant_files) 

gene_lengths_df <- read_tsv(argv$gene_lengths) %>% select(Name, mean.effective.length)

quant.df <- read_tsv(file = argv$quant_files,
                     id = 'sample',
                     skip = 10,
                     col_names = c('gene', 'NumReads')) %>% 
    mutate( transcriptome = argv$transcriptome,
            sample = basename(sample) %>% str_remove('.profile.txt.gz')) %>% 
    select(transcriptome, sample, everything()) %>% 
    filter(gene != 'Unknown')

if( argv$single_end ){

    quant.df <- quant.df %>% 
        left_join(gene_lengths_df,
                  by = c('gene' = 'Name')) %>% 
        mutate( NumReads = NumReads / 2, 
                reads_p_kilobase = NumReads / mean.effective.length,
                scaling = sum(reads_p_kilobase) / 1e6,
                TPM = reads_p_kilobase / scaling)
    
}else{
    
    quant.df <- quant.df %>% 
        left_join(gene_lengths_df,
                  by = c('gene' = 'Name')) %>% 
        mutate( reads_p_kilobase = NumReads / mean.effective.length,
                scaling = sum(reads_p_kilobase) / 1e6,
                TPM = reads_p_kilobase / scaling)
    
    
    
}

quant.mat.tpm <- quant.df %>%
    pivot_wider(names_from = gene, values_from = TPM, id_cols = sample) 

quant.mat.numreads <- quant.df %>%
    pivot_wider(names_from = gene, values_from = NumReads, id_cols = sample) 

stripname.shared <- str_c(argv$transcriptome,
                          "quant-over",
                          str_c(argv$grouping, '.tsv'), sep = "_" )

write_tsv(x = quant.mat.tpm, file = str_c('TPM_', stripname.shared ))
write_tsv(x = quant.mat.numreads, file = str_c('Numreads_', stripname.shared ))
