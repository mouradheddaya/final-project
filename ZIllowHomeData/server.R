library(shiny)
library(dplyr)
library(ggplot2)
library(maps)
library(ggmap)
library(stringr)
library(openintro)
library(kableExtra)

source('./best_buy.R')

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  buyer_seller <- read.csv("./BuyerSellerIndex_City.csv",
                           stringsAsFactors = FALSE
  )
  neighborhood_all <- read.csv("./Neighborhood_MedianListingPrice_AllHomes.csv",
                               stringsAsFactors = FALSE
  )
  neighborhood_bottom <- read.csv("./Neighborhood_MedianListingPrice_BottomTier.csv",
                                  stringsAsFactors = FALSE
  )
  neighborhood_top <- read.csv("./Neighborhood_MedianListingPrice_TopTier.csv",
                               stringsAsFactors = FALSE
  )
  sales_foreclosed <- read.csv("./SalesPrevForeclosed_Share_Neighborhood.csv",
                               stringsAsFactors = FALSE
  )
  lat_lon <- read.csv("./lat_lon.csv", stringsAsFactors = FALSE)
  buyer_seller <- mutate(buyer_seller, address = paste0(
    buyer_seller$RegionName, ",",
    buyer_seller$State
  ))
  
  # Plots the buyer seller index for a given state
  buyer_index <- reactive ({
    selected_state <- map_data("state", region = sapply(input$state, tolower))
    state_buyer <- filter(lat_lon, State == as.symbol(state2abbr(input$state)))
    
    return(ggplot(data = selected_state, aes(x = long, y = lat, group = group)) +
      geom_polygon(fill = "grey") +
      coord_quickmap() + geom_point(data = state_buyer, aes(
        x = lon, y = lat,
        colour = state_buyer$BuyerSellerIndex
      ), inherit.aes = FALSE) +
      scale_colour_gradient(low = "blue", high = "red") + labs(
        title = "Buyer/Seller Index", 
        subtitle = "The Buyer/Seller Index Our index is created using 
data on the sale-to-list price ratio, the percent of homes that 
have been subject to a price cut, and the time-on-market 
(measured as days on Zillow). These three measures are converted 
into percentile rank, averaged together, and divided by 10 to 
generate the final index. This index ranges from 0 to 10 and is 
roughly evenly distributed around a mean of 5.",
        colour = "by buyer/seller Index"
      )+ theme(plot.title = element_text(face = "bold", size = 26),
               plot.subtitle = element_text(size = 16),
               axis.title = element_text(size = 16)))
  })
  
  # Plots the median house value by neighborhood on a map
  # using parameters of state, year and month, recieve a map of 
  # the average housing prices based on location
  median_value <- reactive ({
    selected_state <- map_data("state", region = sapply(input$state, tolower))
    correct_state <- filter(lat_lon, State == as.symbol(state2abbr(input$state)))
    if (input$income_level == 'all') {
      correct_values <-filter(neighborhood_all, State == as.symbol(state2abbr(input$state)))
    } else if (input$income_level == 'low') {
      correct_values <-filter(neighborhood_bottom, State == as.symbol(state2abbr(input$state)))
    } else if (input$income_level == 'high') {
      correct_values <-filter(neighborhood_top, State == as.symbol(state2abbr(input$state)))
    }
    colnames(correct_state)[colnames(correct_state)=="RegionName"] <- "City"
    median_and_location <- inner_join(correct_values, correct_state, by = "City" )
    
    # if value of month is 01, R evaluates month = 1, therefore I must 
    # convert month value to a string and add the neccessary "0" infront 
    # of certain months in order to gain the correct column name 
    # Also must create correct path through data frame to the specified year
    # and month data

    if (nchar(input$month) == 1) {
      month = paste0("0", input$month)
    }
    right_year <- str_c("median_and_location$X",input$year, ".", input$month)
    
    return(ggplot(data = selected_state, aes(x = long, y = lat, group = group)) +
      geom_polygon(fill = "grey") +
      coord_quickmap() + geom_point(data = median_and_location, aes(
        x = lon, y = lat,
        colour = eval(parse(text = right_year))
      ), inherit.aes = FALSE) +
      scale_colour_gradient(low = "red", high = "blue") + labs(
        title =
          "Median housing price based on year/month", 
        subtitle = "The median housing price shows the median value of 
all houses in all neighborhoods based upon the selected state,
year and month.",
        colour = "by price"
      )+ theme(plot.title = element_text(face = "bold", size = 26),
               plot.subtitle = element_text(size = 16),
               axis.title = element_text(size = 16)))
    })
  
  
  #plots average days on market
  average_days <- reactive ({
    selected_state <- map_data("state", region = sapply(input$state, tolower))
    state_buyer <- filter(lat_lon, State == as.symbol(state2abbr(input$state)))
    
    ggplot(data = selected_state, aes(x = long, y = lat, group = group)) +
      geom_polygon(fill = "grey") +
      coord_quickmap() + geom_point(data = state_buyer, aes(
        x = lon, y = lat,
        colour = state_buyer$DaysOnMarket
      ), inherit.aes = FALSE) +
      scale_colour_gradient(low = "green", high = "red") + labs(
        title =
          "Average Days on Market", 
        subtitle = "Represents the average number of days a house 
in each neighborhood of a selected state is listed on 
Zillow.com before selling",
        colour = "By number of Days"
      ) + theme(plot.title = element_text(face = "bold", size = 26),
                plot.subtitle = element_text(size = 16),
                axis.title = element_text(size = 16))
  })
  
  # The table displays areas with the highest levels of foreclosure sales
  # and the largest increase in median house price. These values are combined
  # to create a score. This relies on data from March 2018.
  # IMPORTANT: high density areas have multiple data points
  # ie downtown Seattle shows up multiple times but those are
  # seperate locations
  best_buy <- reactive ({
    sales <- foreclosure_sales(2018) %>%
      filter(StateName == as.symbol(input$state))
    
    median_house <- neighborhood_all %>%
      select(RegionName, X2017.03, X2018.03) %>%
      mutate(perc_change = (X2018.03 - X2017.03) / X2017.03)
    create_scores <- create_user_score(sales, median_house, 2018) %>% 
      select("Area" = RegionName, "Foreclosure Sales" = X2018.03.x, 
       "Median Price YOYG" = perc_change, Score) %>%
      arrange(desc(Score)) %>%
      head(10)
  })
   
  output$buyerIndex <- renderPlot({
    buyer_index()
  })
  
  output$medianPrice <- renderPlot({
    median_value()
  })
  
  output$avgOnMarket <- renderPlot({
    average_days()
  })
  
  output$bestBuy <- renderTable({
    best_buy()
  })
  

  output$message <- renderText({
    print("The table displays areas with the highest levels of foreclosure sales
      and the largest increase in median house price. These values are combined
      to create a score. The higher the score, the better a location is 
      to invest in. This table shows the top ten neighborhoods to invest in 
      based upon the state selected. This relies on data from March 2018.")
    
  })
})
