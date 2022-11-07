library(httr)
library(jsonlite)
library(asteRisk)
library(dplyr) 
library(tidyverse)
library(lubridate)

#authentication
resp <- POST("https://www.space-track.org/ajaxauth/login", 
             authenticate("identity","password"),
             accept_json(),
             body=list(identity ='XXXXXXXXXX',
                       password='XXXXXXXXXX',
                       grant_type="password",
                       scope="openid email"),
             ncode = 'json', httr::config(http_version = 2))
#Query 
get_resp <- GET("https://www.space-track.org/basicspacedata/query/class/gp/decay_date/null-val/epoch/%3Enow-30/orderby/norad_cat_id/format/json",
                accept_json(),
                ncode = 'json', httr::config(http_version = 2))

resp2<- content(get_resp, "text")

json<-jsonlite::fromJSON(resp2)


#data prep 
# write conversion functions 

degrees_to_radians<- function(x){ x*pi/180} #degrees to Radians conversion
dateTime<- function(x){
  print(format(as_datetime(x),"%Y-%m-%d %H:%M:%S"))}  #datetime format

#convert strings to numeric, rename cols for Sgdp4 model, convert degrees to radians, string to datetime, and finally convert mean motion to radians per minute ((2*pi)/(1440))

satellite_df<- json %>% mutate_at(c("MEAN_MOTION","INCLINATION","MEAN_ANOMALY","PERIAPSIS","PERIOD","RA_OF_ASC_NODE","BSTAR","ECCENTRICITY"), as.numeric) %>% rename(n0=MEAN_MOTION,M0=MEAN_ANOMALY,i0=INCLINATION,omega0=PERIAPSIS,OMEGA0=RA_OF_ASC_NODE,Bstar=BSTAR,initialDateTime=EPOCH,e0=ECCENTRICITY) %>% mutate_at(c("i0","M0","omega0","OMEGA0"),degrees_to_radians) %>% mutate_at(c("initialDateTime"),dateTime) %>% mutate_at(c("n0"),~.*((2*pi)/(1440))) %>% mutate(targetTime=0)

#modeling function 
Get_Postion_LatLON<- function(x){
  output<- x %>% rowwise %>%
    mutate(SP=list(tryCatch(sgdp4(n0,e0,M0,i0,omega0,OMEGA0,Bstar,initialDateTime,targetTime), error=function(e) NA))) %>% unnest_wider(SP)%>% rowwise%>%
    mutate(LL=list(tryCatch(TEMEtoLATLON(position_TEME = position*1000,dateTime = initialDateTime), error=function(e) NA)))%>%
    unnest_wider(LL,names_repair="unique")
  return(output)
}

#get the final DF
SatellitePositionsDF<- Get_Postion_LatLON(satellite_df)


launch<- SatellitePositionsDF %>% dplyr::select(OBJECT_NAME,OBJECT_TYPE,OBJECT_ID,longitude,latitude,altitude,initialDateTime,COUNTRY_CODE,OBJECT_TYPE,LAUNCH_DATE,PERIOD)%>% group_by(OBJECT_NAME) %>% filter(!is.na(longitude))%>% mutate(orbit2=ifelse(PERIOD<=128,"LEO",ifelse(PERIOD>=129 & PERIOD<=1439,"MEO",ifelse(PERIOD>=1440,"HEO","NA")))) %>% mutate(LAUNCH_DATE=(as_datetime(LAUNCH_DATE)))

