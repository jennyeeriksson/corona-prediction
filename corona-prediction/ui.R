#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)
library(leaflet)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Predict number of corona cases per country"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            h4("Click a country to forecast confirmed Corona cases"),
            sliderInput("days",
                        "How many days would you like to predict?:",
                        min = 2,
                        max = 20,
                        value = 5)
        ),

        # Show a plot of the generated distribution
        mainPanel(
            leafletOutput("map"),
            plotlyOutput("graph")
            
        )
    )
))
