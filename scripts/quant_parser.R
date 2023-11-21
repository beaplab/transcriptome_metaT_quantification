library(tidyverse)
library(patchwork)

map.files <- list.files('data/mapping',
                        pattern = 'quant.sf',
                        recursive = TRUE,
                        full.names = T)

quant.df <- read_tsv(file = map.files, id = 'sample') %>% 
    mutate( transcriptome = dirname(sample) %>% dirname() %>% basename(),
            sample = dirname(sample) %>% basename()) %>% 
    select(transcriptome, sample, everything())


quant.mat.tpm <- quant.df %>%
    pivot_wider(names_from = Name, values_from = TPM, id_cols = sample) 

quant.mat.numreads <- quant.df %>%
    pivot_wider(names_from = Name, values_from = NumReads, id_cols = sample) 

quant.gene.chars <- quant.df %>% 
    group_by(Name) %>% 
    summarize( Length = unique(Length), 
             mean.effective.length = mean(EffectiveLength), 
             presence = sum(NumReads > 0),
             mean.tpm = mean(TPM),
             mean.numreads = mean(NumReads))

