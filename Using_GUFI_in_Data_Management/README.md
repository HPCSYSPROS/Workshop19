# Using GUFI in Data Management

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3525371.svg)](https://doi.org/10.5281/zenodo.3525371)

**Authors:**
* Chris Hoffman, National Center for Atmospheric Research
* Bill Anderson, National Center for Atmospheric Research

**Abstract:**
Storage systems at the peta-scale and beyond are now a reality. This unprecedented system scale can generate tens of billions of files within its lifetime. Due to this amount of metadata generated, managing it can be a significant challenge. Traditional tools such as ls, find, and du are quickly becoming insufficient for peta-scale storage and beyond.

In this talk, we will share information about the Grand Unified File Index (GUFI) tool and how it can help sites manage large numbers of files and their metadata. As this tool is still under development at the time of investigation, we will go over our methods that are used to index the storage systems at NCAR. Then, the on-going effort of how NCAR is making use of this tool to query metadata will be discussed. Finally, we will share initial testing results that show that find and du commands on some directory trees run over 100 times faster using GUFI.

**Source Code:**
https://github.com/mar-file-system/GUFI
