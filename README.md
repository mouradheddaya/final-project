# **Working with Zillow Data** #

## _The data_ ##

For this project we used data provided by Zillow research. You can more about it [here](https://www.zillow.com/research/data/). In particular we were focused on US housing data regarding median home prices,
Zillow's buyer/seller index, and sales of previously foreclosed homes. Since the Zillow datasets do not provide longitude/latitude coordinates we cross listed locations with Google's ggmap package.

## _The Purpose_ ##
Using our shiny app as initial starting place house flippers should have a better insight into what neighborhoods may be most lucrative to buy property in.

The first map (buyer index) tells the user which areas in a given state Zillow thinks have more favorable buying conditions right now. A higher number indicates a better buyer market, and a lower number suggests a better sellers market.

The second map (median property price) allows the user in addition to select a state, month, and year it also allows the user to choose whether they want to look at median house prices for low priced homes, high priced homes, or all homes.

Best buy score takes a state as input and returns the top 10 neighborhoods that we think will perform best. The score is based on summing the year over year change in median home prices and the number of sales of previously foreclosed homes per 10,000. When back testing this for the year 2016 (with all 50 states) it showed to be a good indicator 89% of the time.

Lastly, our final map displays the average days on market for homes in the chosen state. A lower number suggests a higher amount of activity within the local real estate market. This could suggest either a potentially growing area or somewhere where there is too much of a supply shortage. We suggest that users conduct additional research to figure out which is the cause before buying a property.

**You can access our shiny application at [here](https://mouradheddaya.shinyapps.io/ZillowHomeData/?fbclid=IwAR0xjpDsb1qJvSfqhPmwalJ7SRpySxHqoCkDqYJt7_Xi-XrkdrrHD8WrOrE)** 

_Data used_
* 	Seller/buyer index (City)
* City_zhvi (bottom tier, by city)
*	Foreclosures per 10K homes(neighborhood)
*	Foreclosure resales (neighborhood)
*	Median listing price (neighborhood) (all)
*	Median listing price (neighborhood) (top)
*	Median listing price (neighborhood) (bottom)
