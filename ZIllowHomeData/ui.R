  #
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  #interactive logo
  tags$a(href="https://www.zillow.com/research/data/", 
         img(src = 'zillow-logo.png', height = '100px', width = '100px', align = "right")),
  
  # Application title
  titlePanel("Zillow Home Data"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      selectInput("state", "Select State:",
                  c("Alabama" = "Alabama",
                    "Arkansas" = "Arkansas",
                    "Arizona" = "Arizona",
                    "California" = "California",
                    "Colorado" = "Colorado",
                    "Connecticut" = "Connecticut",
                    "Delaware" = "Delaware",
                    "Florida" = "Florida",
                    "Georgia" = "Georgia",
                    "Idaho" = "Idaho",
                    "Illinois" = "Illinois",
                    "Indiana" = "Indiana",
                    "Iowa" = "Iowa",
                    "Kansas" = "Kansas",
                    "Kentucky" = "Kentucky",
                    "Louisiana" = "Louisiana",
                    "Maine" = "Maine",
                    "Maryland" = "Maryland",
                    "Massachusetts" = "Massachusetts",
                    "Michigan" = "Michigan",
                    "Minnesota" = "Minnesota",
                    "Mississippi" = "Mississippi",
                    "Missouri" = "Missouri",
                    "Montana" = "Montana",
                    "Nebraska" = "Nebraska",
                    "Nevada" = "Nevada",
                    "New Hampshire" = "New Hampshire",
                    "New Jersey" = "New Jersey",
                    "New Mexico" = "New Mexico",
                    "New York" = "New York",
                    "North Carolina" = "North Carolina",
                    "North Dakota" = "North Dakota",
                    "Ohio" = "Ohio",
                    "Oklahoma" = "Oklahoma",
                    "Oregon" = "Oregon",
                    "Pennsylvania" = "Pennsylvania",
                    "Rhode Island" = "Rhode Island",
                    "South Carolina" = "South Carolina",
                    "South Dakota" = "South Dakota",
                    "Tennessee" = "Tennessee",
                    "Texas" = "Texas",
                    "Utah" = "Utah",
                    "Vermont" = "Vermont",
                    "Virginia" = "Virginia",
                    "Washington" = "Washington",
                    "West Virginia" = "West Virginia",
                    "Wisconsin" = "Wisconsin",
                    "Wyoming" = "Wyoming"), selected = "Washington"),
      
      conditionalPanel(
        condition = "input.selected_tab == 2",
        selectInput("year", "Select Year:",
                    c("2010" = "2010",
                      "2011" = "2011",
                      "2012" = "2012",
                      "2013" = "2013",
                      "2014" = "2014",
                      "2015" = "2015",
                      "2016" = "2016",
                      "2017" = "2017",
                      "2018" = "2018"), selected = "2018"),
        selectInput("month", "Select Month:",
                    c("January" = "01",
                      "February" = "02",
                      "March" = "03",
                      "April" = "04",
                      "May" = "05",
                      "June" = "06",
                      "July" = "07",
                      "August" = "08",
                      "September" = "09",
                      "October" = "10",
                      "November" = "11",
                      "December" = "12")),
        radioButtons("income_level", "Filter by Income Level:",
                    c("All" = "all",
                      "Low Income" = "low",
                      "High Income" = "high"))
      )
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       # plotOutput("buyerIndex"),
       # plotOutput("medianPrice"),
       # tableOutput("bestBuy")
      tabsetPanel(
         tabPanel("Buyer/Seller Index", value = 1, plotOutput("buyerIndex")),
         tabPanel("Median Property Price", value = 2, plotOutput("medianPrice")),
         tabPanel("Best Buy Score", value = 3, tableOutput("bestBuy"), textOutput("message")),
         tabPanel("Average Days on Market", value = 4, plotOutput("avgOnMarket")), 
         id = "selected_tab"
      )
    )
)))
