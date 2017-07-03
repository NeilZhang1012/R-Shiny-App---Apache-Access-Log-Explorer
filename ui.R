library(shiny)

shinyUI(fluidPage(
  
  tags$head(
    tags$style(HTML("
      .shiny-output-error-validation {
        color: red;
      }
    "))
  ),
  
  titlePanel("Log File Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      dateRangeInput("dates", label = ("Please Select Date Range"),
                     start = "2007-02-01", end = "2007-03-16",
                     min = "2007-02-01", max = "2007-03-16"),
      actionButton("changeButton", "Change"),
      hr(),
      helpText("The end date should be later than the start date. Otherwise, no plot
               will be created and an error message will pop up.")
    ),
    mainPanel(
      textOutput("DateRange"),
      tabsetPanel(
        tabPanel("Traffic", plotOutput("RequestLineChart")),
        tabPanel("Status", plotOutput("StatusBarChart")),
        tabPanel("Top 10 Referer", plotOutput("RefererBarChart")),
        tabPanel("Response Size Clustering", plotOutput("SizeClusterPlot"))
      )
    )
  )
))