# Transcriptome vs metatranscriptomes pipeline

## Objective 

An easy to use pipeline to quantify fast a set of transcriptomes over a lot of metatranscriptome samples. It basically does: 

- Compares the signature of the samples against the transcriptome of interest.
- Subset all the samples that have present the transcriptome.
- Quantifies them with both `salmon` and `BWA`.

In our `nisaba` system, I have previously computed for all of us the `sourmash` signature for all the metatranscriptomes I have downloaded. 

In the [metatranscriptomes dataset all info](https://docs.google.com/spreadsheets/d/11mkh7hcndFwxE195rt6JnvfDmUDB1XI-_M87bGpu4bw/edit?usp=sharing) google sheet you can have the information from all the datasets present in `nisaba` so far. You should take a look at it and decide which ones you would like to analyze. 
Take a look at the `Relevance` column to choose! 

## How to

### Cloning this project 

Initially we will copy this directory to the location you would like to calculate everything: 

```
git clone https://github.com/beaplab/transcriptome_metaT_quantification.git
```
It will download a directory with all the scripts inside. Then you can change the name of the folder to your project. 

```
mv transcriptome_metaT_quantification biogeography_marine-kinetoplastids
```
And once inside, you can create in the data folder a soft link to the location of your transcriptomes: 

```
ln -s <path-to-your-dir-transcriptomes> data/transcriptomes     
```

And we are ready to quantify.


### Sample sheet creation 

In `nisaba` there is a csv sheets with all the paths to all the files to avoid having copies of them. To obtain a subset of it, you can do it with the `scripts/dataset_selector.R`. We will use its output to quantify the desired samples.
You can run the script with the following structure: 

```r
Rscript scripts/dataset_selector.R 2012_carradec_tara,2021_tara_polar 
```
In which you define the nicknames of the datasets you want to compare. In this case, we are focusing in Tara and Tara Polar, but you may be interested into working with something else. It depends entirely on your species of interest. Check the `Relevance` section to decide. You can also run everything, it will take longer but it's ok. 

It will have generated `data/sample_sheet/2023-11-15_dataset-selection.csv` which will be the input of our pipeline.

### Running nextflow quantification 

With all this information you will be able to run the whole pipeline. 

Initially we will run a `screen` session for having the call in a background and being able to check the progress. 

```
screen -R quantifying_<name_user>
```

This call will open a new session (you will have to press enter maybe). The `-R` flag is to reconnect, but given that there won't be any session with this name, it will create a new one. 
If we want to get out and continue with our lives, we have to press `Ctrl + A` and then `Ctrl + D`. This keystrokes are the way `screen` has for doing multiple functions. `Ctrl+A` gets you in the 'let's do things at the screen level' and `Ctrl+D` its the 'get me out of screen'. 

After a while, we may reconnect again with `screen -R quantifying_<name_user>` to check how everything is going on. 

Inside the session therefore, we will run the following: 

```
nextflow run main.nf  \
        --fastq_sheet data/test_data/sample_sheet/dataset_correspondence_paths_test.csv \
        --transcriptome data/genomic_data/transcriptomes/nucleotide_version/*.fna.gz \
        --outdir data/test_quantification
```

If you have paid close attention, you will see that this is a test. It will allow us to see if everything is in the right place. 
If everything seems to run smooth, cool! If not, time to talk with Adri. 

Expecting the first case, we could continue with our analysis: 


```
nextflow run main.nf  \
        --fastq_sheet data/sample_sheet/2023-11-15_dataset-selection.csv  \
        --transcriptome data/genomic_data/transcriptomes/<path to nucleotides> \
        --outdir data/quantification
```


And then we will continue with the analysis. 




