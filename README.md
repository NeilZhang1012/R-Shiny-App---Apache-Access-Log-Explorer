# R-Shiny-App---Apache-Access-Log-Explorer

In order to effectively manage a web server, it is necessary to get feedback about the activity and performance of the server as well as any problems that may be occuring. The Apache HTTP Server provides very comprehensive and flexible logging capabilities. The server access log records all requests processed by the server. Of course, storing the information in the access log is only the start of log management. The most important and useful part is to analyze this information to produce useful statistics. In this repo, I'll demonstrate how to create an Apache Access Log Explorer for log analysis using R shiny package. 

The shiny app I created can be accessed via [Apache Access Log Explorer](https://hui-neil-zhang.shinyapps.io/access_log_explorer/). The screenshot below shows the user interface of the dashboard. Alternatively, you can download the ui.R and server.R files in this repo and run the shiny app on your local machine using RStudio. 

![alt text](https://github.com/NeilZhang1012/R-Shiny-App---Apache-Access-Log-Explorer/blob/master/access_log_screenshot.png)

When you open the web link above or run the shiny app on your local machine, an Apache access log file will be automatically downloaded and converted to a data frame in R (you can change the Apache access log file to any Apache log file you are interested in as long as you have the download link for the log file). Once you select the date range and click the **Change** button, four different plots will be generated according to the date range you selected, including *Traffic Line Chart, Status Barplot, Top 10 Referer, and Response Size Clustering Plot*.
* Traffic Line Chart shows hits across time
* Status Barplot shows the distribution of status code for different time periods
* Top 10 Referer plot shows the top 10 sites that client reports having been referred from
* shows the proportion of different object size returned to the client

