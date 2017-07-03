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