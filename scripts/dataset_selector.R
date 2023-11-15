library(tidyverse)

selection <- commandArgs(trailingOnly = TRUE) %>% str_split( pattern = ',')
selection <- '2012_carradec_tara,2021_tara_polar' %>% str_split_1(pattern = ',')

dataset <- read_csv('/scratch/datasets_symbolic_links/dataset_sheets/metatranscriptomes_datasets.csv')

dir.create('data/sample_sheet/')

date <- lubridate::date(Sys.time())

dataset %>% 
    filter( group %in% selection) %>% 
    write_csv( str_c( 'data/sample_sheet/', date, '_dataset-selection.csv'))

