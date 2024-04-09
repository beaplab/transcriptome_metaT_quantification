library(tidyverse, quietly = T)

selection <- commandArgs(trailingOnly = TRUE) %>% str_split_1( pattern = ',')

print( str_c('The selection of datasets are the following:', selection)) 

dataset <- read_csv('/scratch/datasets_symbolic_links/dataset_sheets/metatranscriptomes_datasets.csv')

dir.create('data/sample_sheet/')

date <- lubridate::date(Sys.time())

dataset %>% 
    filter( group %in% selection) %>% 
    write_csv( str_c( 'data/sample_sheet/', date, '_dataset-selection.csv'))

print( str_c( 'Saved results in ',
              str_c( 'data/sample_sheet/', date, '_dataset-selection.csv')))
