#Density analysis using Kernel quadratic function

#library upload
library(raster)

# Define the kernel quadratic function
kernel_quadratic <- function(x) {
  return (x^2)
}

# Create a raster stack from your list of rasters
raster_files <- list.files(./Data/*.tif, full.names = TRUE, recursive = FALSE)
raster_stack <- stack(raster_files)

# Sum the raster stack
raster_sum <- sum(raster_stack)

# Define the radius for the focal operation 
radius <- 1  #1 cell equals the raster pixel size
kernel <- matrix(1, nrow = 2 * radius + 1, ncol = 2 * radius + 1)

# Apply the kernel quadratic function to the summed raster using focal
transformed_data <- focal(raster_sum, w = kernel, fun = function(x) kernel_quadratic(sum(x, na.rm = TRUE)))

# Calculate minimum and maximum values for normalization
min_val <- cellStats(transformed_data, stat = 'min')
max_val <- cellStats(transformed_data, stat = 'max')
range_val <- max_val - min_val

# Normalize the raster values to the range 0-1
normalized_data <- (transformed_data - min_val) / range_val

# Define the output file path
output_file <- 'densitymap_radius1.tif'

# Save the normalized raster
writeRaster(normalized_data, filename = output_file, format = "GTiff", overwrite = TRUE)

# Visualize the distribution of values
hist(values(transformed_data), main = "Histogram of Transformed Data", xlab = "Value", breaks = 50)
hist(values(normalized_data), main = "Histogram of Normalized Data", xlab = "Value", breaks = 50)
