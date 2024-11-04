# Script for Correlation and Density analysis applied to Raster files
#Statistical Analysis of "Assessing ecosystem services of estuarine ecosystems: A participatory mapping approach in the Sado Estuary, Portugal"
The Statistical Analysis includes correlation and density analysis performed on raster files. Each raster corresponds to the map of supply or demand for each ecosystem service (ES). 

#Repository Structure
**data/** includes 4 data files as examples that can be used with these scripts. 
**README.md** provides information about the repository and details on how to use the data and scripts. 
**Correlation_matrix.R** script to perform correlation analysis
**Density_analysis.R** script to perform density analysis

##Data files
Raster files should be separated by ES supply and demand maps; each raster should only include a pattern of colours (lighter colours indicates no ES supply/demand and darker colours indicate higher provision/demand of ES). Raster files used for analysis should not include background colour or maps. Folder "data/" folder contains examples of ES maps.

##Correlation Analysis
Correlation analysis is useful for assessing the association between two variables (e.g., ES1, ES2). Depending on the study goal, analyses can be performed on ES1 supply vs ES1 demand, or ES1 supply vs ES2 supply. A positive correlation can imply a synergy between ES, whereas a negative correlation may suggest a trade-off. 
Before applying the correlation analysis, parametric tests should be performed to assess whether the data is normally distributed. The script accomodates various data sizes: if the size is <= 5000, a Shapiro-Wilk test is perfomed, otherwise a Kolmogorov-Smirnov test is used. After conducting parametric tests, functions calculate correlation coefficients and associated p-values. Customizations are applied to display p-values in the correlation matrix. 

#Density analysis
Kernel Quadratic Function is used to assess density of ES across the sum of all rasters. Normalization (0-1) is employed to facilitate data interpretation.

#ScriptUse
1 - Open script;
2 - For Correlation analysis install packages 'Raster', 'ggplot2', 'dplyr', 'corrplot'; for Density analysis install package 'Raster';
3 - Insert data files in folder 'Data/' and erase example files;
4 - Run script;
5 - Final step creates a plot with the analysis outputs.

shinyapp:

If you have any further questions, please contact me at: fmafonso@fc.ul.pt
