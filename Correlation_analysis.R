#Correlation Analysis R script

#Load libraries
library(raster)
library(ggplot2)
library(dplyr)
library(corrplot)

# DO normality test in a vector and depending on length do KS or SW.
# If TRUE the ovalue indicated NORMAL distribution
check_normality <- function(x, alpha = 0.05) {
  n <- length(x)
  if (n <= 50) {
    # Use Shapiro-Wilk test for small sample sizes
    test_result <- shapiro.test(x)
  } else {
    # Use KS test for larger sample sizes
    # Comparison with a normal distribution
    test_result <- ks.test(x, "pnorm", mean = mean(x), sd = sd(x))
  }
  # Return TRUE if p-value is greater than alpha, indicating normality
  return(test_result$p.value > alpha)
}

# Function to apply check normality to all columns of a dataframe 
check_normality_in_rasters_df <- function(raster_df){
  result_list <- lapply(1:ncol(raster_df), function(i){
    result <- suppressWarnings(check_normality(x = raster_df[,i]))
    return(result)
  })
  return(unlist(result_list))
}

# Produce correlation matrix based on normality
make_corr_matrix <- function(raster_df){
  # Know we need to check if all rasters follow the normal distribution
  rasters_boolean_normality <- check_normality_in_rasters_df(raster_df)
  
  if(length(unique(rasters_boolean_normality)) > 1){
    correlation_matrix <- NA
  } else {
    if(all(rasters_boolean_normality == TRUE)){
      # if all are normal do correlation matrix with pearson
      correlation_matrix <- cor(raster_df, use = "complete.obs", method = "pearson") 
    } else {
      # do correlation with spearman
      correlation_matrix <- cor(raster_df, use = "complete.obs", method = "spearman")
    }
  }
  diag(correlation_matrix) <- NA
  return(correlation_matrix)
}

get_pvalues_correlation_matrix<- function(correlation_matrix){
  #calculate p-values of correlation analysis
  p_values <- matrix(NA, nrow = ncol(correlation_matrix), ncol = ncol(correlation_matrix))
  for (i in 1:(ncol(correlation_matrix) - 1)) {
    for (j in (i + 1):ncol(correlation_matrix)) {
      p_values[i, j] <- p_values[j, i] <- cor.test(raster_data[, i], raster_data[, j], exact = TRUE)$p.value
    }
  }
  return(p_values)
}

# Convert significant pvalues to a symbol for nicer plto. THIS IS OPTIONAL
convert_pvalues_to_symbol<- function(pvalue_correlation_matrix, alpha = 0.05, symbol = "*"){
  # Initialize custom_text matrix to store significant p-values
  custom_text <- matrix("", nrow = nrow(pvalue_correlation_matrix), ncol = ncol(pvalue_correlation_matrix))
  # Add * when p-value < 0.05
  for (i in 1:nrow(pvalue_correlation_matrix)) {
    for (j in 1:ncol(pvalue_correlation_matrix)) {
      if (!is.na(pvalue_correlation_matrix[i, j]) && pvalue_correlation_matrix[i, j] < alpha && pvalue_correlation_matrix[i, j] >= 0) {
        custom_text[i, j] <- symbol
      } else {
        custom_text[i, j] <- ""
      }
    }
  }
  return(custom_text)
}


#Load raster files
raster_list <- list.files(path = "./Data/", pattern = "*.tif", full.names = TRUE, recursive = FALSE)

each_raster <- lapply(raster_list, function(myraster){
  tmp <- raster(myraster, band = 1)
  return(tmp)
})


raster_data <- stack(each_raster) %>%
  as.data.frame(xy = TRUE, na.rm = TRUE) %>%
  dplyr::select(-x,-y)

correlation_matrix <- make_corr_matrix(raster_data) 
p_values <- get_pvalues_correlation_matrix(correlation_matrix) %>%
  convert_pvalues_to_symbol(symbol = "*", alpha = 0.05)

# OPTIONAL 
# #function to replace names of columns and rows in the correlation and p-value matrix
# replace_names <- function(matrix, new_colnames, new_rownames) {
#    colnames(matrix) <- new_colnames
#    rownames(matrix) <- new_rownames
#    return(matrix)
#  }
# 
# #set new names for columns and rows of correlation matrix (to avoid overlap of labels)
# colnames(correlation_matrix) <- c("ES1_1", "ES2_1", "ES3_1", "ES4_1")
# rownames(correlation_matrix) <- c("ES1_1", "ES2_1", "ES3_1", "ES4_1")
# new_colnames <- c("", "", "", "")
# new_rownames <- c("Prov 1", "Regul 1", "Regul 2", "Cult 1") #example of the names of each service under analysis
# correlation_matrix_final <- replace_names (correlation_matrix, new_colnames, new_rownames) 

#set new names for columns and rows of p-values matrix (to avoid overlap of labels)
# colnames(p_values) <- c("[,1]", "[,2]", "[,3]", "[,4]")
# rownames(p_values) <- c("[1,]", "[2,]", "[3,]", "[4,]")
# new_colnames <- c("", "", "", "")
# new_rownames <- c("", "", "", "")
# p_values_final <- replace_names (p_values, new_colnames, new_rownames) 
# 
# # Text to row names in lower part of the matrix
# custom_row_names <- c("Prov 1", "Regul 1", "Regul 2", "Cult 1")


# Plot correlation matrix and associated p-values
par(mar = c(1, 1, 1, 1)) # Set margin size

# Use corrplot to visualize the correlation matrix with colour and p-values
corrplot(correlation_matrix, method = "color", 
         col = colorRampPalette(c("blue", "white", "red"))(200), 
         type = "lower", order = "original", # Placement of values in the matrix and the order of the variables (ES)
         tl.col = "#696565", tl.srt = 45, tl.cex = 1.1, 
         cl.cex = 1.1, addCoef.col = NA, number.cex = 1.1) # Set colour of the diagonal and letter/cell sizes

# Overlay the p-values (only stars) in lower triangle
for (i in 1:nrow(p_values)) { 
  for (j in 1:i) {
    # Calculate position for text overlay
    text(j, nrow(p_values) - i + 1, p_values[i, j], 
         cex = 1.1, font = 2, adj = c(-3.5, -0.5)) #set * position and size
  }
}

# Overlay the p-values (only stars) in lower triangle
for (i in 1:length(custom_text)) { 
  for (j in 1:i) {
    # Calculate position for text overlay
    text(j, nrow(custom_text) - i + 1, custom_text[i], 
         cex = 1.1, font = 2, adj = c(-3.5, -0.5)) #set * position and size
  }
}
