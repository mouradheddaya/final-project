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
        colour = "by buyer/seller Index"
      )+ theme(plot.title = element_text(face = "bold", size = 26),
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
        title = "Median House Value Per Neighborhood",
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
        title = "Average Days on Market",
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
      mutate(X2018.03.x * 10000) %>% 
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
  
  output$index_message <- renderText({
    print("Our index is created using data on the sale-to-list 
          price ratio, the percent of homes that have been subject to a price cut, 
          and the time-on-market (measured as days on Zillow). These three measures 
          are converted into percentile rank, averaged together, and divided by 10 to 
          generate the final index. This index ranges from 0 to 10 and is roughly evenly 
          distributed around a mean of 5.")
  })
  
  output$median_message <- renderText({
    print("The median housing price shows the median value of 
          all houses in all neighborhoods based upon the selected state,
          year and month.")
  })
  
  output$average_message <- renderText({
    print("Represents the average number of days a house 
          in each neighborhood of a selected state is listed on 
          Zillow.com before selling")
  })
  
  # Creates dynamic summary that presents the neighborhood of best investment 
  # based upon the entered state including our custom made invesment score. 
  output$summary <- renderText ({
    table <- best_buy()
    neighborhood <- table[1, "Area"]
    string_n <- neighborhood
    my_summary <- paste("SUMMARY: According to the Data, in", input$state, "State, the top location within the state
                    to purchase a house is in", neighborhood, "as it has the highest score of",
                        round(table[1, "Score"], 2))
    return (my_summary)
  })
  
  output$about <- renderText ({
    title <- ("The Data:")
    para1 <- ("For this project we used data provided by Zillow research.
          In particular we were focused on US housing data regarding median home prices, 
          Zillow's buyer/seller index, and sales of previously foreclosed homes. 
          Since the Zillow datasets do not provide longitude/latitude coordinates 
          we cross listed locations with Google's ggmap package.")
    title2 <- ("The Purpose:") 
    para2 <- ("Using our shiny app as initial starting place house flippers should 
          have a better insight into what neighborhoods may be most lucrative to buy property in.")

    para3 <- ("The first map (buyer index) tells the user which areas in a given state 
          Zillow thinks have more favorable buying conditions right now. 
          A higher number indicates a better buyer market, and a lower number suggests 
          a better sellers market.")
          
    para4 <- ("The second map (median property price) allows the user in addition to select a state, 
          month, and year it also allows the user to choose whether they want to look at
          median house prices for low priced homes, high priced homes, or all homes.")
          
    para5 <- ("Best buy score takes a state as input and returns the top 10 neighborhoods 
          that we think will perform best. The score is based on summing the year over 
          year change in median home prices and the number of sales of previously foreclosed 
          homes per 10,000. When back testing this for the year 2016 (with all 50 states) 
          it showed to be a good indicator 89% of the time.")
          
    para6 <- ("Lastly, our final map displays the average days on market for homes in the chosen state.
          A lower number suggests a higher amount of activity within the local real estate market. 
          This could suggest either a potentially growing area or somewhere where there is too much 
          of a supply shortage. We suggest that users conduct additional research to figure out which 
          is the cause before buying a property.")
          
    para7 <- ("The Data Used: 
          Seller/buyer index (City)
          City_zhvi (bottom tier, by city)
          Foreclosures per 10K homes(neighborhood)
          Foreclosure resales (neighborhood)
          Median listing price (neighborhood) (all)
          Median listing price (neighborhood) (top)
          Median listing price (neighborhood) (bottom)")
    return(paste(title, para1, title2, para2, para3, para4, para5, para6, para7, sep = "\n"))
  })
})
