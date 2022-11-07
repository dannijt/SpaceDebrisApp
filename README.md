## Space Junk App Background and Overview

### Links to Shiny Applications
[Desktop](https://danni-apps.shinyapps.io/Danni_SpaceJunk/)
[Mobile](https://danni-apps.shinyapps.io/spacedebris_mobile/)

### What is Space Debris?
Orbital debris (aka Space Junk) is any human-made object in orbit about the Earth that no longer serves a useful function. Such debris includes nonfunctional spacecraft, abandoned launch vehicle stages, mission-related debris, and fragmentation debris (source:NASA.gov)

### Purpose of Analysis & Space Debris App 
This project & shiny application is an exploratory tool that showcases the astounding amount of space junk/debris around Earth's orbit for curious users. When I began working with satellite data, I was surprised by the amount of stuff that is in earth's orbit and believe others would be interested as well. Especially in recent years with commercial launches of satellites like Elon Musk's Starlink, the volume of objects in space continues to expand. Every object launched has potential to become space debris. This topic is important because too much space junk impedes spaceflight around earth & increases risk of collisions- which can impact our internet, weather, and communication satellites. 

### Analysis Steps:
Below are the steps required to access, transform, parse, and get positional information for space debris objects visualized in the app. 

1. Access Data Via Space-Track API 
2. Transform JSON responses 
3. Parse TLEs 
4. Use Simplified Perturbation Models to find position of satellites or objects in earth's orbit at a given time
5. Subset Debris objects & Visualize results
6. Build Shiny Application 

## Accessing Data: 
The data used in this App/analysis is from Space-track.org. Users can create an account and use the API. Description from the Space-Track Website:

"USSPACECOM provides space surveillance data to registered users through this public website, www.space-track.org. 18 SDS routinely updates the website with positional data on more than 16,000 satellites in orbit around the Earth. Users can build customized API queries to pull specific data from historical records, and automate the retrieval of new data, help enhance spaceflight safety, prevent potentially catastrophic orbital collisions, and increase international cooperation in space"

## Working with TLE Data 
The data from spacetrack comes in the form of Two-Line Element Sets or TLEs. A description of TLEs from Wikipedia: 
“A two-line element set (TLE) is a data format encoding a list of orbital elements of an Earth-orbiting object for a given point in time, the epoch. Using a suitable prediction formula, the state (position and velocity) at any point in the past or future can be estimated to some accuracy.”

This is what a TLE for a single satellite looks like: 
```
ISS (ZARYA)
1 25544U 98067A   04236.56031392  .00020137  00000-0  16538-3 0  9993
2 25544  51.6335 344.7760 0007976 126.2523 325.9359 15.70406856328906
```
Each number represents an orbital element that we use to predict where a satellite is at a given time. To read more about orbital elements: https://www.space-track.org/documentation#tle


## Using TLEs to Predict Location of a Satellite or Object in Earth's Orbit
Mathematical models are required to translate the TLE information into positional information. To site the R package I used in my analysis: “Unlike positional information of planes and other aircrafts, satellite positions is not readily available for any timepoint along its orbit” (Rafael Ayala, Daniel Ayala, David Ruiz and Lara Selles Vidal (2021). asteRisk: Computation of Satellite Position. R package version 1.1.0. https://CRAN.R-project.org/package=asteRisk) 

The models used for this are called Simplified perturbations models.  From Wikipedia “Simplified perturbations models are a set of five mathematical models (SGP, SGP4, SDP4, SGP8 and SDP8) used to calculate orbital state vectors of satellites and space debris relative to the Earth-centered inertial coordinate system.” 

## Simplified Perturbations Models in R 
I used the R package cited about asterisk created by Rafael Ayala, Daniel Ayala, David Ruiz and Lara Selles Vidal. This package has SGP4 and SDP4 functions to apply orbital propagation models. 

While the asterisk package did most of the heavy lifting, I developed a repeatable approach to applying the propagation models to a larger subset of data. The SGP4/SDP4 functions from the asterisk package reads one input (one TLE) at a time. For this analysis, I wanted to derive the positional information for the entire data set. I created an iterative function to accomplish this (code below). 

```
library(tidyr)
library(dplyr)
library(asteRisk)

propagate <- function(x){
output<- x %>% rowwise %>%
mutate(SP=list(sgdp4(n0,e0,M0,i0,omega0,OMEGA0,Bstar,initialDateTime,targetTime)))
%>% unnest_wider(SP) %>% rowwise %>%
mutate(LL=list(TEMEtoLATLON(position_TEME = position*1000,dateTime = initialDateTime)))%>% unnest_wider(LL,names_repair="unique")
return(output)
}
```
This function reads the input dataframe, uses the sgdp4 function to output position/velocity and the TEMEtoLATLON function (also from the asterisk package) to output geodetic latitude, longitude, and altitude- which is what we can use to plot the information relative to earth/on a map. 

## The Final Data Set & Shiny App: 
To get to the final dataset I used the dplyr package for data wrangling. To filter out the other object types like payloads, rocket bodies, and unknown objects to only contain Debris objects. 

Finally I built a Shiny application with some visuals to explore the findings.  The globe visual and timeseries plot in the application come from the html widgets R package family,namely Threejs & dygraphs. These plots work just like regular R plots, but produce interactive web visualizations based on JavaScript libraries.   The dygraphs package for the timeseries plot also includes an option to add custom CSS which I included in the visualization. The code for the dygraphs and globe visual are included in this repository. 

## Other Related Work 
The SGP4/SDP4 Models can also be used to propagate position of satellites in the future. In another analysis, I have created visualizations that show a complete orbit of a satellites, rather than debris only. This is derived by getting the position at epoch and propagating in intervals to a new target time, which in this case is epoch+ period in mins. the Orbital period represents the time in mins it takes for an object to orbit around another object, in this case the object is Earth.  I will be authoring another shiny app to showcase this analysis. 
