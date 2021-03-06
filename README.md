# R-Shiny-App---Apache-Access-Log-Explorer

In order to effectively manage a web server, it is necessary to get feedback about the activity and performance of the server as well as any problems that may be occuring. The Apache HTTP Server provides very comprehensive and flexible logging capabilities. The server access log records all requests processed by the server. Of course, storing the information in the access log is only the start of log management. The most important and useful part is to analyze this information to produce useful statistics. In this repo, I'll demonstrate how to create an Apache Access Log Explorer for log analysis using R shiny package. 

The shiny app I created can be accessed via [Apache Access Log Explorer](https://hui-neil-zhang.shinyapps.io/access_log_explorer/). The screenshot below shows the user interface of the dashboard. Alternatively, you can download the ui.R and server.R files in this repo and run the shiny app on your local machine using RStudio. 

![alt text](https://github.com/NeilZhang1012/R-Shiny-App---Apache-Access-Log-Explorer/blob/master/access_log_screenshot.png)

When you open the web link above or run the shiny app on your local machine, an Apache access log file will be automatically downloaded and converted to a data frame in R (you can change the Apache access log file to any Apache log file you are interested in as long as you have the download link for the log file). Once you select the date range and click the **Change** button, four different plots will be generated according to the date range you selected, including *Traffic Line Chart, Status Barplot, Top 10 Referer, and Response Size Clustering Plot*.
* Traffic Line Chart shows hits across time.
* Status Barplot displays the distribution of status code for different time periods.
* Top 10 Referer plot can tell us the top 10 sites that client reports having been referred from.
* Response Size Clustering Plot shows the proportion of different object size returned to the client.

In addition, the number of days within your selected date range will also be shown on the dashboard. If the selected end date is earlier than the start date, an error message in red color will pop up.

Below is the codes I wrote to create my log file explorer, you can use it as your starting point and modify it to meet your needs and requirements.

ui.R:
```
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
```
server.R:
```
library(shiny)
library(dplyr)
library(ggplot2)

temp <- tempfile()
download.file("http://users.csc.tntech.edu/~elbrown/access_log.bz2",temp)
access_log <- read.table(bzfile(temp), fill=TRUE, skipNul = TRUE, stringsAsFactors = FALSE)
unlink(temp)
colnames(access_log) <- c("IP", "Ident", "User", "Request_Date_Time", "Zone", "Request",
                   "Status", "Size", "Referer", "Browser")
access_log$Request_Date <- as.Date(substring(access_log$Request_Date_Time, 2, 12), "%d/%b/%Y")

shinyServer(function(input, output){
  
  output$DateRange <- renderText({
    input$changeButton
    isolate({
      validate(
        need(input$dates[2] > input$dates[1], "Error:The end date should be later than start date. Please select valid date range.")
      )
      paste("Your date range is", difftime(input$dates[2], input$dates[1], units = "days"), "days")
    })
  })
  
  output$RequestLineChart <- renderPlot({
    input$changeButton
    isolate({
      validate(
        need(input$dates[2] > input$dates[1], "")
      )
      date_seq <- seq(input$dates[1], input$dates[2], by = "day")
      selected_data <- filter(access_log, Request_Date %in% date_seq)
      request_count <- selected_data %>% group_by(Request_Date) %>% summarise(count = n())
      ggplot(request_count, aes(Request_Date, count)) + geom_point(color="red") + geom_line(color="blue") +
        xlab("Date") + ylab("Request Count") + ggtitle("Traffic to Site for the Selected Date Range") +
        theme(plot.title = element_text(hjust = 0.5))
    })
  })
  
  output$StatusBarChart <- renderPlot({
    input$changeButton
    isolate({
      validate(
        need(input$dates[2] > input$dates[1], "")
      )
      date_seq <- seq(input$dates[1], input$dates[2], by = "day")
      selected_data <- filter(access_log, Request_Date %in% date_seq)
      ggplot(selected_data, aes(x=format(Status))) + geom_bar() +
        xlab("Status") + ylab("Count") + ggtitle("Status Count for the Selected Date Range") +
        theme(plot.title = element_text(hjust = 0.5))
    })
  })
  
  output$RefererBarChart <- renderPlot({
    input$changeButton
    isolate({
      validate(
        need(input$dates[2] > input$dates[1], "")
      )
      date_seq <- seq(input$dates[1], input$dates[2], by = "day")
      selected_data <- filter(access_log, Request_Date %in% date_seq)
      referer_count <- selected_data %>% group_by(Referer) %>% summarise(Count=n()) %>% 
        arrange(desc(Count)) %>% filter(Referer != "" & Referer != "-") %>% 
        top_n(10, Count)
      ggplot(referer_count, aes(Referer, Count)) + geom_bar(aes(fill=Referer), stat = "identity") + 
        ggtitle("Top 10 Referer for the Selected Date Range") +
        theme(axis.text.x=element_blank(), axis.ticks.x=element_blank(), plot.title = element_text(hjust = 0.5))
    })
  })
  
  output$SizeClusterPlot <- renderPlot({
    validate(
      need(input$dates[2] > input$dates[1], "")
    )
    access_log$Size <- as.integer(access_log$Size)
    access_log_size <- na.omit(access_log$Size)
    set.seed(123)
    clusters <- kmeans(access_log_size, 3, iter.max = 100, nstart = 25)
    clusters_data <- as.data.frame(cbind(c("Large Size Response", "Medium Size Response", "Small Size Response"), 
                                         round(clusters$centers/1024,2), clusters$size), stringsAsFactors = FALSE)
    names(clusters_data) <- c("Cluster", "Mean_Response_Size_in_Kb", "Count")
    clusters_data$Count <- as.numeric(clusters_data$Count)
    ggplot(clusters_data, aes(x=Cluster, y=Count)) + 
      geom_bar(aes(fill = Mean_Response_Size_in_Kb), stat="identity") + 
      xlab("Clusters") + ylab("Number of Request (In log10 Scale)") + scale_y_log10() + 
      ggtitle("Clustering Plot of Response Size for the Whole Period") + theme(plot.title = element_text(hjust = 0.5))
  })
  
})
```
