# Transcriptome vs metatranscriptomes pipeline

## Objective

An easy to use pipeline to quantify fast a set of transcriptomes over a lot of metatranscriptome samples. It basically does:

-   Compares the signature of the samples against the transcriptome of interest. The signatures are a compressed representation of sequences using hashes, [you can find more information here](https://pubmed.ncbi.nlm.nih.gov/31508216/)).
-   Subset all the samples that have present the transcriptome.
-   Quantifies them with both `salmon` and `BWA`.

In our `nisaba` system, I have previously computed for all of us the `sourmash` signature for all the metatranscriptomes I have downloaded.

In the [metatranscriptomes dataset all info](https://docs.google.com/spreadsheets/d/11mkh7hcndFwxE195rt6JnvfDmUDB1XI-_M87bGpu4bw/edit?usp=sharing) google sheet you can have the information from all the datasets present in `nisaba` so far. You should take a look at it and decide which ones you would like to analyze. Take a look at the `Relevance` column to choose!

## How to

### Preparing the stage

For all these analyses we will need:

-   A folder in which we will generate the quantification outputs.

-   A sample sheet with the paths to the FASTQs in Nisaba (see below how to create it).

-   The transcriptomes.

In my example, I will quantify Florenciella.

    mkdir florenciella_biogeography
    cd florenciella_biogeography

    # a folder for the data we will use
    mkdir data 

    # a folder for some of the scripts 
    mkdir scripts

Once inside, to avoid copying and pasting outputs from previous processes, we can do a [symbolic link](https://www.cyberciti.biz/faq/creating-soft-link-or-symbolic-link/) to the transcriptomes of interest:

    ln -s <path-to-your-dir-transcriptomes> data/transcriptomes     

Now we need to select the samples we are interested in quantify.

#### Sample sheet creation

In `nisaba` there is a csv sheet with all the paths to all the files with this structure:

| group              | name          | fastq_r1                                                                                        | fastq_r2 | single_end | sig                                                                                      |
|--------------------|---------------|-------------------------------------------------------------------------------------------------|----------|------------|------------------------------------------------------------------------------------------|
| 2012_carradec_tara | 004_0o8-5_DCM | `/scratch/datasets_symbolic_links/metatranscriptomes/2012_carradec_tara/004_0o8-5_DCM.fasta.gz` | NA       | TRUE       | `/scratch/datasets_symbolic_links/metaT_signatures/2012_carradec_tara/004_0o8-5_DCM.zip` |

It presents all the information to avoid having individual copies for each. To obtain a subset of it, you can do it with an script I have created, named `scripts/dataset_selector.R`.

We need to download it to the folder we created previously:

    mkdir scripts

    wget https://raw.githubusercontent.com/beaplab/transcriptome_metaT_quantification/main/scripts/dataset_selector.R -O scripts/dataset_selector.R

We will use its output to quantify the desired samples. You have to previously choose which datasets you want to quantify, saving its nicknames from the highlighted column. You can run the script with the following structure:

``` r
Rscript scripts/dataset_selector.R 2012_carradec_tara,2021_tara_polar 
```

In this case, we are focusing in Tara and Tara Polar, but you may be interested into working with something else. It depends entirely on your species of interest. Check the `Relevance` section to decide. You can also run everything, it will take longer but it's ok.

It will have generated `data/sample_sheet/<date>_dataset-selection.csv` which will be the input of our pipeline.

In case you want to run your transcriptome against all the information out there, you can copy directly the csv from the location to your folder: 

    cp /scratch/datasets_symbolic_links/dataset_sheets/metatranscriptomes_datasets.csv data/sample_sheet/<date>_all-samples.csv



### Running nextflow quantification

With all this information you will be able to run the whole pipeline.

Initially we will run a `screen` session for having the call in a background and being able to check the progress.

    screen -R quantifying_<name_user>

This call will open a new session (you will have to press enter after running it). The `-R` flag is to reconnect, but given that there won't be any session with this name, it will create a new one. If we want to get out and continue with our lives, we have to press `Ctrl + A` and then `Ctrl + D`. This keystrokes are the way `screen` has for doing multiple functions. `Ctrl+A` gets you in the 'let's do things at the screen level' and `Ctrl+D` its the 'get me out of screen'.

We will test that everything is working correctly using a test sample sheet, with only 3 samples.

We can download it in a similar fashion than before:

    wget https://raw.githubusercontent.com/beaplab/transcriptome_metaT_quantification/main/data/test_data/sample_sheet/dataset_correspondence_paths_test.csv -O data/sample_sheet/test.csv 

And we will also download a transcriptome in case you are following this example without one.

    wget https://github.com/beaplab/transcriptome_metaT_quantification/raw/main/data/genomic_data/transcriptomes/nucleotide_version/EP00618_Florenciella_parvula.fna.gz -O transcriptomes/Florenciella_parvula.fna.gz

Let's test the quantification then:

    nextflow run beaplab/transcriptome_metaT_quantification \
        --fastq_sheet data/sample_sheet/test.csv \
        --transcriptome "data/transcriptomes/*.fna.gz" \
        --outdir data/test_quantification -r main

A brief explanation of what is happening behind the curtain:

-   nextflow downloads locally the scripts in a hidden folder, and uses them to run.

-   The options are:

    -   the `fastq_sheet` , in this case the test sheet.

    -   the transcriptome, here surrounded by brackets because we want `nextflow` to find all the instances. If yours does not end with `.fna.gz` it won't find it! Change it accordingly.

    -   the `outdir` where everything will be outputted and `-r` which is the release of the software used to run.

If everything worked well, we are good to go, and we can run the program. In my case it would be the following:

    nextflow run beaplab/transcriptome_metaT_quantification \
        --fastq_sheet data/sample_sheet/<sample sheet>.csv \
        --transcriptome "data/transcriptomes/*.fna.gz" \
        --outdir data/quantification -r main

Nextflow should start the different processes automatically.

If for some reason we have to stop the program, we can continue it from where it was left behind adding the `-resume` flag. This is one of the perks of nextflow. The other is that it goes pretty fast at computing everything :)

And then we will continue with the analysis.

Remember to get out of screen! `Ctrl + A` and then `Ctrl + D`.

After a while, we may reconnect again with `screen -R quantifying_<name_user>` to check how everything is going on.

PD: In Nisaba you can find this folder with everything in position to better understand how to structure everything:

    /home/aauladell/small_works/small_examples/florenciella_quantification_example

### Adrià or someone else has updated the workflow: what now

Ok so with nextflow is quite easy to find new versions.

By typing:

    nextflow pull beaplab/transcriptome_metaT_quantification

It will download the new version and prepare it to run.
