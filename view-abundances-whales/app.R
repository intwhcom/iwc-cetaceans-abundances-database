library(shiny)
library(shinyWidgets)
library(shinyFiles)  # For file explorer
library(leaflet)
library(sf)
library(DT)
library(dplyr)
library(tidyr)
library(stringr)
# Define UI ####
ui <- fluidPage(
  titlePanel("Whale Abundances Viewer"),
  sidebarLayout(
    sidebarPanel(
      pickerInput(
        inputId = "region",
        label = "Select Ocean Region:",
        choices = c("North Atlantic", "North Pacific", "Southern Hemisphere"),
        selected = "North Atlantic"
      ),
      pickerInput(
        inputId = "species",
        label = "Select Species:",
        choices = NULL,
        options = list(`actions-box` = TRUE),
        multiple = TRUE
      ),
      pickerInput(
        inputId = "area",
        label = "Select Area:",
        choices = NULL,
        options = list(`actions-box` = TRUE),
        multiple = TRUE
      ),
      sliderInput(
        inputId = "start_year",
        label = "Select Start Year:",
        min = 1980, max = 2025, value = 1980, step = 1
      ),
      sliderInput(
        inputId = "end_year",
        label = "Select End Year:",
        min = 1980, max = 2025, value = 2025, step = 1
      ),
      pickerInput(
        inputId = "columns",
        label = "Select Columns to Display:",
        choices = c("regions_code","species_code","subareas_subarea","category_code","evaluation_extent","trials_usage","year","startyear","endyear","method_code","correction_code","estimate","cv","se","cvav","lci","uci","references_ref","notes","survey_programme","pl","pu","season","gnull","areacoverage","sd","cvcalc","dateadded","datemodified"),
        selected = c("regions_code","species_code", "subareas_subarea", "year", "estimate", "references_ref"),
        multiple = TRUE,
        options = list(`actions-box` = TRUE)
      ),
      downloadButton("download_table", "Download Table"),
      downloadButton("download_shapefile", "Download Shapefile")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Table", DTOutput("data_table")),
        tabPanel("Map", leafletOutput("map")),
        tabPanel("references", DTOutput("references_table"))
      )
    )
  )
)

# Define server logic ####
server <- function(input, output, session) {
  user_logged_in <- reactiveVal(FALSE)
  
  showModal(modalDialog(
    title = "Login Required",
    passwordInput("password", "Password", value = ""),
    footer = tagList(
      actionButton("login_btn", "Login"),
      actionButton("cancel_btn", "Cancel")
    ),
    easyClose = FALSE,
    fade = TRUE
  ))
  
  observeEvent(input$login_btn, {
    if (input$password == "scwk2025") {
      user_logged_in(TRUE)
      removeModal()
    } else {
      showModal(modalDialog(
        title = "Error",
        "Incorrect password. Please try again by reloading the app.",
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
    }
  })
  
  observeEvent(input$cancel_btn, {
    stopApp()
  })
  
  observe({
    if (!user_logged_in()) {
      return(NULL)
    }
    
    table_data <- reactiveVal()
    reference_data <- reactiveVal()
    shapefile_data <- reactiveVal()
    
    observe({
      file_prefix <- switch(input$region,
                            "North Atlantic" = "NA",
                            "North Pacific" = "NP",
                            "Southern Hemisphere" = "SH")
      
      if(file_prefix == "NA"){
        table_data(read.csv(paste0(file_prefix, "combined.csv")) %>% mutate(regions_code = "NA"))
        reference_data(read.csv(paste0(file_prefix, "references.csv")) %>% mutate(references.regions_code = "NA"))
      } else {
        table_data(read.csv(paste0(file_prefix, "combined.csv")))
        reference_data(read.csv(paste0(file_prefix, "references.csv")))
      }
      shapefile_data(st_read(paste0(file_prefix, "-subareas.shp")))
      updatePickerInput(session, "species", choices = unique(table_data()$species_code), selected = isolate(input$species))
    })
    
    observeEvent(input$species, {
      req(input$species)
      filtered_areas <- table_data() %>%
        filter(species_code %in% input$species) %>%
        pull(subareas_subarea) %>%
        unique()
      updatePickerInput(session, "area", choices = filtered_areas)
    })
    
    filtered_table <- reactive({
      req(input$species, input$area, input$start_year, input$end_year, input$columns)
      table_data() %>% mutate(year0 = ifelse(is.na(year), round(rowMeans(select(., startyear, endyear), na.rm = TRUE)), year)) %>% 
        filter(species_code %in% input$species, subareas_subarea %in% input$area, year0 >= input$start_year, year0 <= input$end_year) %>%
        select(all_of(input$columns))
    })
    
    filtered_references <- reactive({
      req(input$species,filtered_table())
      ft <- filtered_table() %>% mutate(refs = strsplit(references_ref, ";")) %>% unnest(refs) %>% mutate(refs = trimws(refs)) %>% select(refs,regions_code,species_code) %>% distinct()
      reference_data() %>% mutate(spc = strsplit(references.species_code, "\\+")) %>% unnest(spc) %>% mutate(rgc = strsplit(references.regions_code, "\\+")) %>% unnest(rgc) %>% inner_join(ft, by = c("references.ref" = "refs", "spc" = "species_code", "rgc" = "regions_code")) %>% select(references.species_code,references.ref,references.fullref) %>% distinct() %>% setNames(c('species','ref','full reference'))
    })
    
    filtered_shapefile <- reactive({
      req(input$species, input$area)
      shapefile_data() %>%
        filter(subareas %in% input$area)
    })
    
    output$data_table <- renderDT({
      datatable(filtered_table(), options = list(pageLength = 10))
    })
    
    output$references_table <- renderDT({
      req(filtered_references())
      datatable(filtered_references(), options = list(pageLength = 10))
    })
    
    # Render map
    output$map <- renderLeaflet({
      req(filtered_shapefile())
      pal <- colorFactor(palette = "Set1", domain = filtered_shapefile()$subareas)
      if (input$region == "North Pacific") {
        filteredshape <- filtered_shapefile()
        filteredshape$geometry <- (st_geometry(filteredshape) + c(360,90)) %% c(360) - c(0,90)
        leaflet(options = leafletOptions(worldCopyJump = F)) %>%
          addProviderTiles(providers$OpenStreetMap) %>%
          addPolygons(
            data = filteredshape,
            color = ~pal(subareas),
            weight = 1,
            opacity = 1,
            fillOpacity = 0.4,
            popup = ~paste("<br>Area: ", subareas, "<br>Survey: ", survey)
          )} else {
            leaflet() %>%
              addProviderTiles(providers$OpenStreetMap) %>%
              addPolygons(
                data = filtered_shapefile(),
                color = ~pal(subareas),
                weight = 1,
                opacity = 1,
                fillOpacity = 0.4,
                popup = ~paste("<br>Area: ", subareas, "<br>Survey: ", survey)
              )
          }
    })
    
    
    output$download_table <- downloadHandler(
      filename = function() {
        paste0("filtered_table-", Sys.Date(), ".csv")
      },
      content = function(file) {
        write.csv(filtered_table(), file, row.names = FALSE)
      }
    )
    
    output$download_shapefile <- downloadHandler(
      filename = function() {
        paste0("filtered_shapefile-", Sys.Date(), ".zip")
      },
      content = function(file) {
        temp_dir <- tempdir()
        temp_shapefile <- file.path(temp_dir, "filtered_shapefile")
        if (length(Sys.glob(paste0(temp_shapefile, ".*"))) > 0) {
          file.remove(Sys.glob(paste0(temp_shapefile, ".*")))
        }
        filtered_sf <- filtered_shapefile()
        req(nrow(filtered_sf) > 0)
        st_write(filtered_sf, paste0(temp_shapefile, ".shp"), driver = "ESRI Shapefile", delete_layer = TRUE)
        zip(zipfile = file, files = Sys.glob(paste0(temp_shapefile, ".*")))
        file.remove(Sys.glob(paste0(temp_shapefile, ".*")))
      },
      contentType = "application/zip"
    )
  })
}

shinyApp(ui = ui, server = server)
