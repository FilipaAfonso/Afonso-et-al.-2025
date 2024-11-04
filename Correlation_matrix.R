#Correlation Analysis R script

#Load libraries
library(raster)
library(ggplot2)
library(dplyr)
library(corrplot)

#Load raster files
raster_stack <- stack(./data/*.tif, full.names = TRUE, recursive = FALSE)

#Convert raster files to data frame
raster_df <- as.data.frame(raster_stack, xy = TRUE, na.rm = TRUE) 
raster_data <- raster_df %>% dplyr::select(-x, -y) # Remove x and y coordinates for correlation analysis


#Function to check parametric assumptions
check_parametric_assumptions <- function(raster_list) {
  lapply(raster_list, function(r) {
    raster_data <- na.omit(values(r))
    if (length(raster_data) < 3) return(list(method = "Not enough data"))

    if (length(raster_data) <= 5000) {
      test <- shapiro.test(raster_data)
    } else {
      test <- ks.test(raster_data, "pnorm", mean(raster_data), sd(raster_data))
    }

    list(
      raster = r,
      method = test$method,
      statistic = test$statistic,
      p.value = test$p.value
    )
  })
}

# Apply the function and print results
results <- check_parametric_assumptions(list(ES1, ES2, ES3, ES4))
print(results)

#perform correlation analysis
correlation_matrix <- cor(raster_data, use = "complete.obs") 

#calculate p-values of correlation analysis
p_values <- matrix(NA, nrow = ncol(correlation_matrix), ncol = ncol(correlation_matrix))
for (i in 1:(ncol(correlation_matrix) - 1)) {
  for (j in (i + 1):ncol(correlation_matrix)) {
    p_values[i, j] <- p_values[j, i] <- cor.test(raster_data[, i], raster_data[, j])$p.value
  }
}

#replace diagonal values with NA for clarity in the plot
diag(correlation_matrix) <- NA
diag(p_values) <- NA

#print both matrix to assess column/row names
print(correlation_matrix)
print(p_values)

#function to replace names of columns and rows in the correlation and p-value matrix
replace_names <- function(matrix, new_colnames, new_rownames) {
   colnames(matrix) <- new_colnames
   rownames(matrix) <- new_rownames
   return(matrix)
 }

#set new names for columns and rows of correlation matrix (to avoid overlap of labels)
colnames(correlation_matrix) <- c("ES1_1", "ES2_1", "ES3_1", "ES4_1")
rownames(correlation_matrix) <- c("ES1_1", "ES2_1", "ES3_1", "ES4_1")
new_colnames <- c("", "", "", "")
new_rownames <- c("Prov 1", "Regul 1", "Regul 2", "Cult 1") #example of the names of each service under analysis
correlation_matrix_final <- replace_names (correlation_matrix, new_colnames, new_rownames) 

#set new names for columns and rows of p-values matrix (to avoid overlap of labels)
colnames(p_values) <- c("[,1]", "[,2]", "[,3]", "[,4]")
rownames(p_values) <- c("[1,]", "[2,]", "[3,]", "[4,]")
new_colnames <- c("", "", "", "")
new_rownames <- c("", "", "", "")
p_values_final <- replace_names (p_values, new_colnames, new_rownames) 

# Text to row names in lower part of the matrix
custom_row_names <- c("Prov 1", "Regul 1", "Regul 2", "Cult 1")

# Initialize custom_text matrix to store significant p-values
custom_text <- matrix("", nrow = nrow(correlation_matrix_final), ncol = ncol(correlation_matrix_final))

# Add * when p-value < 0.05
for (i in 1:nrow(p_values_final)) {
  for (j in 1:ncol(p_values_final)) {
    if (!is.na(p_values_final[i, j]) && p_values_final[i, j] < 0.05 && p_values_final[i, j] >= 0) {
      custom_text[i, j] <- "*"
    } else {
      custom_text[i, j] <- ""
    }
  }
}

# Plot correlation matrix and associated p-values
tiff(filename = "ES_correlation_analysis.tiff",  width = 4000, height = 4000, res = 300) # Set name of file, size and resolution
par(mar = c(1, 1, 1, 1)) # Set margin size

# Use corrplot to visualize the correlation matrix with colour and p-values
corrplot(correlation_matrix_final, method = "color", 
         col = colorRampPalette(c("blue", "white", "red"))(200), 
         type = "lower", order = "original", # Placement of values in the matrix and the order of the variables (ES)
         tl.col = "#696565", tl.srt = 45, tl.cex = 1.1, 
         cl.cex = 1.1, addCoef.col = NA, number.cex = 1.1) # Set colour of the diagonal and letter/cell sizes

# Overlay the p-values (only stars) in lower triangle
for (i in 1:length(custom_text)) { 
  for (j in 1:i) {
    # Calculate position for text overlay
    text(j, nrow(custom_text) - i + 1, custom_text[i], 
         cex = 1.1, font = 2, adj = c(-3.5, -0.5)) #set * position and size
  }
}

# Overlay the column labels
for (i in 1:length(custom_row_names)) {
  x <- i
  y <- nrow(correlation_matrix_final) - i + 1
  rect(x - 0.5, y - 0.5, x + 0.5, y + 0.5, col = "white", border = "white")
  text(x, y, custom_row_names[i], cex = 1.1, font = 3, col = "#696565", adj = c(0.1, 0.5))
}

dev.off()

