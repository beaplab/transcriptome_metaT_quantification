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


quant.df %>% 
    group_by(sample, transcriptome) %>% 
    summarize( mean.tpm = mean(NumReads)) %>% 
    arrange(-mean.tpm) %>% 
    View()
        