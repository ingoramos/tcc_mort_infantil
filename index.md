# TCC Mortalidade Infantil

## Introduction

This work emerged from a demand by the Secretaria de Saúde de Florianópolis, in relation to the application of machine learning in some of its processes. Using the data from the Sistema Único de Saúde, more specifically from the Sistema de Informação de Mortalidade (SIM) and the Sistema de Informação de Nascidos Vivos (SINASC), making possible the creation of a model for predicting infant mortality in the city of Florianopolis.
In Florianopolis, in the period from 2014 to 2017, the percentage of infant deaths was approximately 0.70%, while for the first half of 2018 was approximately 0.45%.
Therefore, this work intends to contribute as a study that in the future may collaborate with the reduction of this number of deaths, using newborn data to identify high-risk patients, allowing them to receive a more attentive care to other patients, based on machine learning algorithms.

## Methodology

Data from the years 2014 through 2017 were used for training the machine learning algorithms, while the data from 2018 were used for testing and validating the model. Since it is a binary classification, of a possible death or not, the confusion matrix was chosen to compute the metrics used for validation.
The database had almost 99 variables, from two different sources, these being SINASC and SIM. Although, only the variable called 'OBITO' could be used from the SIM database, since all the other would skew the study, because these others are filled only when a death is confirmed.

So, the features from the SINASC database could all be used for the study, because unlike the other base, this one is filled with data from the live births.
There were some problems with the database, that required some fixes. The first one, was the missing data in some columns, the second was the wrong labeled data and finally, the large amount of variables that might not be meaningful for the creation of the machine learning model.
To solve the problem with the missing data, a function to count these values was created, as the image shows the result:
![Figure: Percentage of missing values](/output1.png)
