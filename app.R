library(shiny)
library(raster)
library(ggplot2)
library(dplyr)
library(corrplot)
####################
#0.  LOAD FUNCTIONS

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

get_pvalues_correlation_matrix<- function(correlation_matrix, raster_df){
  #calculate p-values of correlation analysis
  p_values <- matrix(NA, nrow = ncol(correlation_matrix), ncol = ncol(correlation_matrix))
  for (i in 1:(ncol(correlation_matrix) - 1)) {
    for (j in (i + 1):ncol(correlation_matrix)) {
      p_values[i, j] <- p_values[j, i] <- cor.test(raster_df[, i], raster_df[, j], exact = TRUE)$p.value
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

####################

# Application title


# Sidebar with a slider input for number of bins
ui <- shinyUI(
  fluidPage(
    title  <- "Correlation Analysis Rasters" %>% 
      titlePanel(),
    sidebarPanel(
      fileInput("select_tif", "Select Raster files (.tif)", 
                  multiple = TRUE, accept = ".tif"),
      br(),
      actionButton(inputId = "draw_plot", label = "Calculate correlation")
    ),
    shiny::mainPanel(fluidRow(
      plotOutput("plot1", click = "plot_click")
    )
    )
  ))


server <- function(input, output) {
  
  observeEvent(input$draw_plot, {
    
    # Show progress bar during computation
    withProgress(message = "Calculating...", value = 0, {
      
      # Load raster files
      raster_list <- input$select_tif$datapath
      
      each_raster <- lapply(raster_list, function(myraster){
        tmp <- raster(myraster, band = 1)
        return(tmp)
      })
      
      names(each_raster) <- gsub(pattern = ".tif", replacement = "",input$select_tif$name)
      
      # Update progress
      incProgress(0.2, detail = "Processing raster data...")
      
      raster_data <- stack(each_raster) %>%
        as.data.frame(xy = TRUE, na.rm = TRUE) %>%
        dplyr::select(-x,-y)
      
      # Update progress
      incProgress(0.4, detail = "Calculating correlation matrix...")
      
      correlation_matrix <- make_corr_matrix(raster_data) 
      p_values <- get_pvalues_correlation_matrix(correlation_matrix, raster_df = raster_data) %>%
        convert_pvalues_to_symbol(symbol = "*", alpha = 0.05)
      
      # Update progress
      incProgress(0.8, detail = "Rendering plot...")
      
      # Render the plot with corrplot
      output$plot1 <- renderPlot({
        corrplot(correlation_matrix, method = "color", 
                 col = colorRampPalette(c("blue", "white", "red"))(200), 
                 type = "lower", order = "original",
                 tl.col = "#696565", tl.srt = 45, tl.cex = 1.1, 
                 cl.cex = 1.1, addCoef.col = NA, number.cex = 1.1) 
        
        # Overlay the p-values (only stars) in lower triangle
        for (i in 1:nrow(p_values)) {
          for (j in 1:i) {
            text(j, nrow(p_values) - i + 1, p_values[i, j],
                 cex = 1.1, font = 2, adj = c(-3.5, -0.5)) # Set * position and size
          }
        }
      })
      
      # Complete progress
      incProgress(1, detail = "Done!")
    })
  }) 
}




# Run the application 
shinyApp(ui = ui, 
         server = server)