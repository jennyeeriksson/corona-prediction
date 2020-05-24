#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(dplyr)
library(leaflet)
library(shiny)
library(plotly)
library(lubridate)
library(forecast)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {


    data<-loadData()

    # Create map
    output$map <- renderLeaflet({
        groupedData<- data.frame(data %>% group_by(Country_Region) %>% summarize(lat=lat[which.max(tot_cases)], lng=lng[which.max(tot_cases)]))
        groupedData %>% leaflet() %>% addTiles() %>% addMarkers(~lng, ~lat)
    })
    
    # User clicks map
    chosenCountry <- reactive({
        l<-input$map_marker_click
        if(!is.null(l))
        {
        country<-data[data$lat==l$lat & data$lng==l$lng, "Country_Region"]
        as.character(country[[1]])
        }
         })
    
    output$chosenReg<-renderText({
        chosenCountry()
    })
    
    # Show and predict future cases
    output$graph<-renderPlotly({
        selectedCountry<-chosenCountry()
        if(!is.null(selectedCountry))
        {
         selectedData<-data[data$Country_Region==selectedCountry,]
         
         fcastData<-data.frame(fcast(selectedData, input$days))

         selectedData %>%ggplot(aes(x=as.Date(Last_Update), y=tot_cases)) + geom_line() + 
             geom_line(data=fcastData, aes(x=seq(as.Date(selectedData$Last_Update[length(selectedData$Last_Update)])+1, length.out=input$days, by="days"), y=Point.Forecast, color="Predicted")) +
             geom_line(data=fcastData, aes(x=seq(as.Date(selectedData$Last_Update[length(selectedData$Last_Update)])+1, length.out=input$days, by="days"), y=Lo.95, color="95% CI")) +
             geom_line(data=fcastData, aes(x=seq(as.Date(selectedData$Last_Update[length(selectedData$Last_Update)])+1, length.out=input$days, by="days"), y=Hi.95, color="95% CI")) +
             labs(x="Date", y="Confirmed cases", title=as.character(selectedCountry))
         }
    })

})

loadData<-function()
{
    #Find files
    startDate<-as.Date("2020-03-10")
    today<-Sys.Date()
    dates<-seq(startDate, today, by="days")
    dates<-format(dates, "%m-%d-%Y")
    baseUrl<-"https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_daily_reports/"
    filenames<-paste(as.character(dates),".csv", sep="")
    urls<-paste(baseUrl,filenames, sep="")
    
    #download data from repo
    for(i in 1:length(urls))
    {
        #Load data
        if(!file.exists(filenames[i]))
        {
            try(
            download.file(urls[i], filenames[i])
            )
        }
    }

    #Load data and merge tables
    data <- data.frame()
    for(file in dir(".", pattern=".csv"))
    {

        if(file.size(file) > 0){
        newdata<-read.csv(file)
        # Data pre processing
        names(newdata)[grep("lat",names(newdata), ignore.case = T)]<-"lat"
        names(newdata)[grep("long|lng",names(newdata), ignore.case = T)]<-"lng"
        names(newdata)[grep("Country.*region",names(newdata), ignore.case = T)]<-"Country_Region"
        names(newdata)[grep("Last.*update",names(newdata), ignore.case = T)]<-"Last_Update"
        newdata<-newdata %>% group_by(Country_Region) %>% summarize(tot_death=sum(na.omit(Deaths)), tot_cases=sum(na.omit(Confirmed)), lat=na.omit(lat)[which.max(Confirmed)], lng=na.omit(lng)[which.max(Confirmed)], Last_Update=Last_Update[1])
        newdata<-newdata[complete.cases(newdata), ]
        data<-rbind(data,newdata)
        }

    }

    data<-data.frame(data)

    #Erase countries with cases below 500
    maxCasePerCountry<-tapply(data$tot_cases, data$Country_Region, max)
    data[data$Country_Region %in% names(which(maxCasePerCountry>500)),]

}

fcast<-function(data, numDays)
{
    tsdata<-ts(data$tot_cases)
    forecast(tsdata, numDays, level=95)
}