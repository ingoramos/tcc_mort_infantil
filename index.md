# TCC Mortalidade Infantil

## Introduction

This work emerged from a demand by the Secretaria de Saúde de Florianópolis, in relation to the application of machine learning in some of its processes. Using the data from the Sistema Único de Saúde, more specifically from the Sistema de Informação de Mortalidade (SIM) and the Sistema de Informação de Nascidos Vivos (SINASC), making possible the creation of a model for predicting infant mortality in the city of Florianopolis.
In Florianopolis, in the period from 2014 to 2017, the percentage of infant deaths was approximately 0.70%, while for the first half of 2018 was approximately 0.45%.
Therefore, this work intends to contribute as a study that in the future may collaborate with the reduction of this number of deaths, using newborn data to identify high-risk patients, allowing them to receive a more attentive care to other patients, based on machine learning algorithms.

There is a [dictionary of variables](https://ingoramos.github.io/tcc_mort_infantil/features) that can be useful for reading the rest of this article, to improve your understanding of the variables.

## Methodology

Data from the years 2014 through 2017 were used for training the machine learning algorithms, while the data from 2018 were used for testing and validating the model. Since it is a binary classification, of a possible death or not, the confusion matrix was chosen to compute the metrics used for validation.
The database had almost 99 variables, from two different sources, these being SINASC and SIM. Although, only the variable called 'OBITO' could be used from the SIM database, since all the other would skew the study, because these others are filled only when a death is confirmed.

So, the features from the SINASC database could all be used for the study, because unlike the other base, this one is filled with data from the live births.
There were some problems with the database, that required some fixes. The first one, was the missing data in some columns, the second was the wrong labeled data and finally, the large amount of variables that might not be meaningful for the creation of the machine learning model.
To solve the problem with the missing data, a function to count these values was created, as the image shows the result:
![Figure 1](/imgs/output1.png)
Percentage of missing values

The direct imputation of data method was chosen as the solution, however only the columns that were at least 95% filled could be part of this process, the other ones below this value, were discarded.
With the help from the Mice package for R, which uses machine learning to input the data, it was possible to complete the columns that had missing values, parameterized with the 'cart' method, allowing the input algorithm to work with both types of data, categorical and numerical, present in the database. Some of the doubled features were removed, and also the variables that contained personal information, that should not be shown.
Some of the features are filled with numbers, but they actually represent categorical data, so they must be treated like that.
For example, the variables APGAR1 and APGAR5 are filled in a scale from 1 to 10, but inform the level of asphyxiation of the newborn, it can be severe if the number is below or equal to 2, moderate if it is between 3 and 4, light if it is between 5 and 7 or no asphyxia if greater or equal than 8. As usual, the R language already classifies the data with the read.csv method, but, instead of sticking with this classification, and using the SINASC variable dictionary, some of the features were reclassified, following the explained APGAR example. 

## Feature Selection

For the next steps, the database was divided between categorical and numerical variables to enable the application of three feature selection methods, these being DALEX (used for numerical variables), Information Value and Weights of Evidence (used for categorical variables), and Boruta (used for both).
First, using the numerical data, some correlation heat maps were created, trying to identify some relationships between the variables. As shown in the graph, the variables QTDFILVIVO and QTDGESTAC showed strong correlation, as did the variables SEMAGESTAC and PESO.
![Figure 2](/imgs/output2.png)
HeatMap

To improve prediction, the numerical variables were normalized, as some classification algorithms improve their results this way. The method chosen was the Z-score, so that the mean of the values in each column becomes 0 and the standard deviation 1, turning all the numerical data into a range from -1 to 1.
From this, a new heat map of the correlation matrix was created, but this time with the normalized data. This resulted in the discovery of new strong correlations, as is the case between the variables QTDGESTANT and QTDPARTNOR, and also between QTDPARTNOR and QTDFILVIVO.
As seen in the image, there is still a negative correlation between SEMAGESTAC and PESO in relation to OBITO, indicating that probably the lower the child's weight at birth or the number of weeks of gestation, the more likely the infant death.
![Figure 3](/imgs/output3.png)
HeatMap with normalized data

At this point there are still many variables in the database, which would make it difficult to create the prediction model, besides the fact that not all variables would make sense for the prediction, so it is necessary to make a selection, keeping only those that have some meaning for the prediction.
The first method used to solve this problem was the Boruta package, which makes use of categorical and numerical variables at the same time, selecting the important ones. The algorithm is based on Random Forest and is easy to parameterize. The decision is based on the p-value, which by default is set to 0.01.
The algorithm will evaluate each variable against the dependent variable, and after running, will decide whether to confirm or reject it. There is also the possibility of not being able to decide on it, marking it as tentative. 
![Figure 4](/imgs/output4.png)
Boruta Results

As is the case in the graph shown, the variables in yellow are marked as tentative. To correct this problem, another function of the package is used, which increases the p-value to 0.05, making the algorithm's decision easier. As a result of this process, a graphic was created, with only the accepted and rejected variables.
![Figure 5](/imgs/output5.png)
Important Variables

For the numerical variables, the DALEX package was chosen, which allows the comparison between algorithms, which in this case were Random Forest, Logistic Regression and Support Vector Machines, all parameterized in the same way, as shown in the output in the image.
![Figure 6](/imgs/output6.png)
Parameterized Algorithms

The package also stores the DropOut Loss data, which was used to compare the results. DropOut Loss shows the loss of predictive ability of the model, when a certain variable is removed, i.e. the higher the bar in the graph shown below, the greater the predictive influence of the variable for the model.
![Figure 7](/imgs/output7.png)
DropOut Loss

For categorical variables, the Information Value and Weights of Evidence method was chosen, which results in a numerical value associated with the categorical variable, informing its strength for the model. The way to interpret the numerical value is if it is less than 0.02 the variable is not useful, between 0.1 and 0.3 the variable has an average relationship with the dependent variable, and above 0.3 a strong relationship. The results are shown in the image.
![Figure 8](/imgs/output8.png)
Information Value and Weights of Evidence

## Results

Besides the creation of the prediction model, a descriptive analysis of the data was also made by means of graphs, seeking to better understand some of the relationships among the variables.

### Variable Description
The graph chosen for the visualization of the variables "Semanas de Gestação" and Número de Consultas pré-natal" was the scatter plot, in order to understand the distribution of these data.
![Figure 9](/imgs/output9.png)
Scatter Plot

In the previous graph it is possible to notice some outliers, and in an attempt to better understand this distribution, a new scatter plot was made, but this time with bubbles. The larger the bubble, the greater the number of previous pregnancies, in red the deaths.
![Figure 10](/imgs/output10.png)
Bubble Scatter Plot

The graph confirms that the high number of consultations is not a rule for women who have been through more pregnancies; it is possible to observe a high data density of individuals grouped in the part of the graph that represents between 35 and 43 weeks of gestation, and who at the same time had 10 or fewer consultations, even if some of these women had already been through previous pregnancies. In fact, these variables do not present a very strong correlation, as had already been observed in the correlation matrix, so the high number of consultations may come from other reasons that are not available for analysis in this database.
The ESCMAE and RACACORMAE variables were used in the histogram and boxplot plots in relation to the number of consultations, still trying to identify some kind of relationship outside the heatmap. But for both variables, the number of consultations remains in the same range, from 5 to 11. The boxplot helps on visualizing the individuals for the variables.
![Figure 11](/imgs/output11.png)
Number of consultations for ESCMAE histogram 

![Figure 12](/imgs/output12.png)
Number of consultations for RACACOR/MAE histogram

The average number of consultations does not change much in relation to education or race/color of the mother, remaining around 7 or 8 consultations, but it is still possible to verify the outliers with these graphs, which total a large number of individuals, with more than 15 consultations.
![Figure 13](/imgs/output13.png)
Boxplot ESCMAE

With the donut plot, the visual representation of the percentage value of each data group relative to the total observations for the mother's education variable becomes clearer.
![Figure 14](/imgs/output14.png)
Donut plot

The tree graph allows us to better understand the distribution of the number of consultations by the number of weeks of gestation and if in any way, these variables are related to some type of anomaly identified in the child. There is no pattern, but it can be seen that in cases where there are few weeks of gestation, usually no anomaly is identified, while in cases of longer gestation, not necessarily more consultations are made, and it may or may not be identified an anomaly.
![Figure 15](/imgs/output15.png)
Dendrogram

## Machine Learning

The only data that had been processed was that for the algorithms' training base, which was also used for the exploratory analysis, so it was necessary to use the same processing methods for the algorithms' test data. The training base has data from 2014 through 2017, while the test base has data from the first half of 2018.
For the prediction, a function was created to compare the result of some machine learning algorithms, so that it could choose among the algorithms Randon Forest, Stochastic Gradient Boosting, Neural Network, AdaBoost Classification Trees, eXtreme Gradient Boosting, Stacked AutoEncoder Deep Neural, the one that performed best.
Both databases are unbalanced, which means that there are more observations concerning negative cases (children who did not die) than positive cases (children who died), to solve this problem, two balancing methods were chosen, these being up and smote. Up rearranges a random sample from the minority class (YES) to be the same size as the majority class (NO). Smote is a hybrid method that reduces the sample from the majority class (NO) and synthesizes new data for the minority class (YES).
The metric used to measure the results of the algorithms was specificity, i.e., the ability to correctly predict cases that are actually true positives, in this case, infant deaths, taking into account that the algorithms were classifying "no death" as a positive class.
The numbers were extracted from the confusion matrix, because since it is a classification problem, it allows the comparison of the predicted values with the real values, besides facilitating the calculation of the chosen metrics, in this case, the specificity.
The algorithm was correct in 70% of the infant death cases (19 cases out of 27 registered cases in total) and 97% of the non-death cases (6015 cases out of 6156 registered cases in total), being this the best result achieved by the random forest algorithm, when compared to the other algorithms used.
![Figure 16](/imgs/output16.png)
Random Forest Results

An application was also created with the help of the Shiny and Shinydashboard package, to aggregate all the work processes, similar to a dashboard, which presents the graphics in an interactive way, so that one can explore and compare the available data, also having a page with the graphics and tables referring to the variable selection methods. Finally, the page that allows the input of the newborn's data and that makes the prediction, and returns three possible text results, informing whether the child has high, medium, or low risk of death.
![Figure 17](/imgs/output17.png)
First page of the application

The dashboard has a side tab that allows navigation between four main topics, these being the correlation analysis of the variables, with the four methods used in selecting them, the categorical data analysis, the numerical data analysis, both with some interactive graphs, and finally the prediction.
On the prediction page, there are fields to be filled with data, some of them related to the mother, some related to the child itself, once filled, just click the prediction button, and a sentence will appear indicating the probability of death, with three possible results, child with low, medium or high probability of death.
![Figure 18](/imgs/output18.png)
Prediction page 