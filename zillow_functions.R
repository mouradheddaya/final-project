library(dplyr)
library(ggplot2)
library(maps)
library(ggmap)

buyer_seller <- read.csv("final-project/BuyerSellerIndex_City.csv",
  stringsAsFactors = FALSE
)
neighborhood_all <- read.csv("final-project/Neighborhood_MedianListingPrice_AllHomes.csv",
  stringsAsFactors = FALSE
)
neighborhood_bottom <- read.csv("final-project/Neighborhood_MedianListingPrice_BottomTier.csv",
  stringsAsFactors = FALSE
)
neighborhood_top <- read.csv("final-project/Neighborhood_MedianListingPrice_TopTier.csv",
  stringsAsFactors = FALSE
)
sales_foreclosed <- read.csv("final-project/SalesPrevForeclosed_Share_Neighborhood.csv",
  stringsAsFactors = FALSE
)
lat_lon <- read.csv("final-project/lat_lon.csv", stringsAsFactors = FALSE)
buyer_seller <- mutate(buyer_seller, address = paste0(
  buyer_seller$RegionName, ",",
  buyer_seller$State
))

# lat_lon <- cbind(buyer_seller, geocode(as.character(buyer_seller$address),
#   source = "dsk"
# ))
# write.csv(lat_lon, file = "final-project/lat_lon.csv")

# Plots the buyer seller index for a given state
buyer_index <- function(state) {
  selected_state <- map_data("state", region = sapply(state, tolower))
  state_buyer <- filter(lat_lon, State == as.symbol(
    sapply(substring(state, 1, 2), toupper)
  ))

  ggplot(data = selected_state, aes(x = long, y = lat, group = group)) +
    geom_polygon(fill = "grey") +
    coord_quickmap() + geom_point(data = state_buyer, aes(
      x = lon, y = lat,
      colour = state_buyer$BuyerSellerIndex
    ), inherit.aes = FALSE) +
    scale_colour_gradient(low = "blue", high = "red") + labs(
      title =
        "Buyer/Seller Index", colour = "by buyer/seller Index"
    )
}

buyer_index("Washington")

# Plots the median house value by neighborhood on a map


# first we want to see if foreclosure sales and median house price
# increases indicate a potential buying opportunity. We compared national
# data for areas from March 2015 and March 2016 with the highest levels of
# foreclosure sales and the largest 1 year increase in median house price.
# These values are added to create a score. This score is then compared to
# March 2018 data.
theory <- function() {
  sales <- foreclosure_sales(2016)

  median_house <- neighborhood_all %>%
    select(RegionName, X2015.03, X2016.03, X2018.03) %>%
    mutate(perc_change = (X2016.03 - X2015.03) / X2015.03, result = (X2018.03
    - X2016.03) / X2016.03)

  create_scores <- create_user_score(sales, median_house, 2016)

  test <- create_user_score(sales, median_house, 2016) %>%
    filter(is.na(score) == FALSE & is.na(result) == FALSE) %>%
    count(Worked = (score > 0 & result > 0) | (score < 0 & result < 0) |
      (score < 0 & result > 0))

  # here we only count if the score indicated a
  # good purchase that lost money
  test[2, 2] / sum(test$n)
}

foreclosure_sales <- function(year) {
  date <- paste0("X", year, ".03")
  sales_foreclosed %>%
    select(RegionID, RegionName, StateName, !!as.symbol(date)) %>%
    filter(is.na(date) == FALSE)
}

create_user_score <- function(sales, median_house, year) {
  date_x <- paste0("X", year, ".03.x")
  create_scores <- inner_join(sales, median_house, by = "RegionName")
  mutate(create_scores, score = perc_change + !!as.symbol(date_x))
}

# The table displays areas with the highest levels of foreclosure sales
# and the largest increase in median house price. These values are combined
# to create a score. This relies on data from March 2018.
# IMPORTANT: high density areas have multiple data points
# ie downtown Seattle shows up multiple times but those are
# seperate locations
best_buy <- function(state) {
  sales <- foreclosure_sales(2018) %>%
    filter(StateName == as.symbol(state))

  median_house <- neighborhood_all %>%
    select(RegionName, X2017.03, X2018.03) %>%
    mutate(perc_change = (X2018.03 - X2017.03) / X2017.03)
  create_scores <- create_user_score(sales, median_house, 2018) %>%
    group_by(RegionID) %>%
    select(RegionName, score) %>%
    arrange(desc(score)) %>%
    head(10)
}
