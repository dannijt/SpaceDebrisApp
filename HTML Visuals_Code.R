debris<- launch %>% filter(OBJECT_TYPE=="DEBRIS")

#reactable for country and launch site 


objc<-debris %>% group_by(COUNTRY_CODE,SITE_NAME) %>% summarise(OBJECT_COUNT=n()) 
objc$SITE_NAME<- toupper(objc$SITE_NAME)

Country_table_reactable<- 
  reactable(
    objc,
    groupBy =c("COUNTRY_CODE"),
    searchable = TRUE,
    pagination = FALSE,
    resizable = TRUE,
    defaultSorted = list(OBJECT_COUNT= "desc"),
    wrap=TRUE,
    height=600,
    defaultExpanded = TRUE,
    columns = list(
      COUNTRY_CODE = colDef(minWidth = 60),
      SITE_NAME=colDef(minWidth = 100,align="center"),
      #OBJECT_COUNT=colDef(aggregate = "sum")),
      OBJECT_COUNT= colDef(
        name = "OBJECT COUNT",
        defaultSortOrder = "desc",
        # Render the bar charts using a custom cell render function
        cell = function(value) {
          width <- paste0(value * 100 / max(objc$OBJECT_COUNT), "%")
          # Add thousands separators
          value <- format(value, big.mark = ",")
          bar_chart(value, width = width, fill = "#69b3a2")
        },
        # And left-align the columns
        align = "left"
      )),
    theme = reactableTheme(color = "hsl(233, 9%, 87%)",backgroundColor = "hsl(233, 9%, 19%)",borderColor = "hsl(233, 9%, 22%)",stripedColor = "hsl(233, 12%, 22%)",highlightColor = "hsl(233, 12%, 24%)",style = list(fontFamily = 'SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono","Courier New",monospace'),inputStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),selectStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),pageButtonHoverStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),pageButtonActiveStyle = list(backgroundColor = "hsl(233, 9%, 28%)")))

#reactable for Size summary 
size2<-debris %>% group_by(RCS_SIZE) %>% summarise(OBJECT_COUNT=n())
size2$RCS_SIZE<-str_trim(size2$RCS_SIZE) %>% replace_na("UNKNOWN")
size2<- size2 %>% rename(OBJECT_SIZE=RCS_SIZE)

Size_Reactable<- reactable(
  size2,
  pagination = FALSE,
  resizable = TRUE,
  defaultSorted = list(OBJECT_COUNT= "desc"),
  wrap=TRUE,
  defaultExpanded = TRUE,
  columns = list(
    OBJECT_SIZE= colDef(minWidth = 60),
    #SITE_NAME=colDef(minWidth = 100,align="center",show=FALSE),
    #OBJECT_COUNT=colDef(aggregate = "sum")),
    OBJECT_COUNT= colDef(
      name = "OBJECT COUNT",
      defaultSortOrder = "desc",
      # Render the bar charts using a custom cell render function
      cell = function(value) {
        width <- paste0(value * 100 / max(size2$OBJECT_COUNT), "%")
        # Add thousands separators
        value <- format(value, big.mark = ",")
        bar_chart(value, width = width, fill = "#69b3a2")
      },
      # And left-align the columns
      align = "left"
    )),
  theme = reactableTheme(color = "hsl(233, 9%, 87%)",backgroundColor = "hsl(233, 9%, 19%)",borderColor = "hsl(233, 9%, 22%)",stripedColor = "hsl(233, 12%, 22%)",highlightColor = "hsl(233, 12%, 24%)",style = list(fontFamily = 'SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono","Courier New",monospace'),inputStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),selectStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),pageButtonHoverStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),pageButtonActiveStyle = list(backgroundColor = "hsl(233, 9%, 28%)")))

#reactable for orbit type 

orbit2<-debris %>% group_by(orbit) %>% summarise(OBJECT_COUNT=n())
orbit2<- orbit2 %>% rename(ORBIT_TYPE=orbit)
orbit2$ORBIT_TYPE<- replace_na(orbit2$ORBIT_TYPE,"UNKNOWN")
orbit_type_reactable<- reactable(
  orbit2,
  pagination = FALSE,
  resizable = TRUE,
  defaultSorted = list(OBJECT_COUNT= "desc"),
  wrap=TRUE,
  defaultExpanded = TRUE,
  columns = list(
    ORBIT_TYPE= colDef(minWidth = 60),
    #SITE_NAME=colDef(minWidth = 100,align="center",show=FALSE),
    #OBJECT_COUNT=colDef(aggregate = "sum")),
    OBJECT_COUNT= colDef(
      name = "OBJECT COUNT",
      defaultSortOrder = "desc",
      # Render the bar charts using a custom cell render function
      cell = function(value) {
        width <- paste0(value * 100 / max(orbit2$OBJECT_COUNT), "%")
        # Add thousands separators
        value <- format(value, big.mark = ",")
        bar_chart(value, width = width, fill = "#69b3a2")
      },
      # And left-align the columns
      align = "left"
    )),
  theme = reactableTheme(color = "hsl(233, 9%, 87%)",backgroundColor = "hsl(233, 9%, 19%)",borderColor = "hsl(233, 9%, 22%)",stripedColor = "hsl(233, 12%, 22%)",highlightColor = "hsl(233, 12%, 24%)",style = list(fontFamily = 'SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono","Courier New",monospace'),inputStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),selectStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),pageButtonHoverStyle = list(backgroundColor = "hsl(233, 9%, 25%)"),pageButtonActiveStyle = list(backgroundColor = "hsl(233, 9%, 28%)")))


#dygraph & ThreeJS Globe visuals are manipulated by reactive input to table tab() in shiny app but can adapt for non shiny

dygraph_output<-  dygraph(tab(), main = "") %>% dyShading(from = vals$mindate,to = vals$maxdate, color = "black") %>% dyOptions(labelsUTC = TRUE,fillGraph = TRUE,fillAlpha = 0.4,drawGrid = FALSE,colors = "#69b3a2", axisLineColor = "black") %>%  dySeries("Object.Count", drawPoints = TRUE, color = "#69b3a2") %>% dyRangeSelector(fillColor = "#69b3a1") %>% dyCrosshair(direction = "vertical") %>% dyHighlight(highlightCircleSize = 5,highlightSeriesBackgroundAlpha = 1,hideOnMouseOut = TRUE) %>% dyRoller(rollPeriod = 1) %>% dyCSS("./dy.css") 

GlobeVisual<- globejs(lat = tab2()$latitude,
                      long=tab2()$longitude,
                      value=tab2()$altitude/100000,
                      atmosphere=TRUE, 
                      pointsize=.5,
                      color="#69b3a2")