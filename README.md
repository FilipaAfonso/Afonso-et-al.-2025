# Afonso-et-al.-2025
R Script of Afonso et al., 2025 (paper name) useful to perform correlation analysis and density analysis.

##Data files
Raster files should be separated by Ecosystem Services supply and demand maps; each raster should only include a pattern of colours (lighter colours - no ES supply/demand and darker colours - higher provision/demand of ES). Raster files used for analysis should not include background colour or maps. Folder "Data" can be used as example, 4 ES maps were added.

##Correlation Analysis
Correlation analysis is useful to assess the association between two variables (ES1, ES2). A positive correlation can imply a synergy between ES, whereas a negative correlation can possibly imply a trade-off between ES. 
Before applying the correlation analysis, parametric tests should be performed to assess if data is normally distributed. The script allows the analysis in several data sizes (if <= 5000 shapiro-test, and if > 5000 ks-test). 
After parametric analysis, functions to calculate correlation and p-values associated. Different customizations are performed to add p-values to the correlation matrix. 

#Density analysis
Kernel Quadratic Function was used to assess density of ES of the sum of all rasters. Normalization (0-1) was used to facilitate data interpretation.
