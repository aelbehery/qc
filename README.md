# QC pipeline

## Description

This is a quality control pipeline that  can rename, quality-trim, decontaminate and remove adapters from fastq sequence read files (single- or paired-end).
## Dependencies
The pipeline uses the following software:

 1. [Cutadapt](https://cutadapt.readthedocs.io/en/stable/installation.html).
 2. [Prinseq](https://sourceforge.net/projects/prinseq/files/standalone/).
 3. [BBTools](https://sourceforge.net/projects/bbmap/).
Please, make sure to have the executables of these tools in your path.

## Installation
There is no need for installation; just copy the script to your bin folder and make sure it has executable permissions.

## Running

To know how to use the script and available options, type:

```
qc.sh -h
```
