library(tidyverse)
library(patchwork)

map.files <- list.files('data/mapping',
                        pattern = 'quant.sf',
                        recursive = TRUE,
                        full.names = T)

sour.files <- list.files('data/statistics/sourmash_gather_output',
                         full.names = T,
                         pattern = '.csv')


comparison.df <- read_csv(sour.files) %>% 
    mutate( sample = basename(filename) %>% str_remove('.zip')) %>% 
    select( sample, f_orig_query) %>% 
    rename( similarity = 'f_orig_query')


# Read all the mappign files with salmon
quant.df <- read_tsv(file = map.files, id = 'sample') %>% 
    mutate(sample = str_remove(pattern = 'data/mapping//mapping_',  sample) %>% 
               str_remove( '_to_EP00618_Florenciella_parvula_index/quant.sf'))

# small subset 
quant_wo_zeroes <- quant.df %>% filter(NumReads > 0) 

# how many genes are present in our transcriptome
number.genes <-  length(unique( quant.df$Name ) )

# For each sample, the transcriptome presents how many genes? 
presence <- quant.df %>% 
    group_by(sample) %>% 
    summarize( count_genes = sum(NumReads > 0) / number.genes)

# how many of the samples present over this value
table(presence$count_genes >= 0.05)

presence.plot <- presence %>% 
    arrange(-count_genes) %>% 
    mutate( rank = 1:390) %>% 
    filter( rank <= 100) %>% 
    ggplot( ) + 
    geom_bar(stat = 'identity', aes(x = rank, y = count_genes)) + 
    scale_y_continuous( labels = scales::percent ) +
    ylab( 'Amount of genes being expressed (more than 1 read)') + 
    ggtitle('The metaT do not present the whole Florenciella genome', 
            subtitle = '51 of the samples present >5% of the genome expressed. Expected?')


# check how often the genes appear
core.genes <- quant_wo_zeroes %>% 
    group_by( Name ) %>% 
    summarise( totalreads = sum(NumReads),
               ocurrence = n() / 390)


core.plot <- core.genes %>% 
    ggplot( aes(ocurrence, totalreads)) + 
    geom_point() + 
    scale_y_log10() + 
    scale_x_continuous( labels = scales::percent ) +
    ylab('Total reads') + 
    xlab('Ocurrence in samples') + 
    ggtitle( 'Some genes are present in all the samples', 
             subtitle = 'Around 200 of them present 100 reads in all Tara metaTs')

    

# How are sourmash and salmon values related between each other -----------

containment_genepres.plot <- presence  %>% 
    left_join(comparison.df, by = 'sample') %>% 
    ggplot( aes(count_genes, similarity)) + 
    geom_point() + 
    scale_x_continuous( labels = scales::percent ) +
    ylab('containment') + 
    ggtitle('Sourmash vs salmon quantification stats',
            subtitle = "In all these samples there is 'something'") + 
    xlab( 'Amount of genes being expressed (more than 1 read)') 

composition <- presence.plot /
    (core.plot +
    containment_genepres.plot)

composition

dir.create('results/figures/eda')
ggsave('results/figures/eda/containment_quant_info.pdf', width = 9,
       height = 8)
