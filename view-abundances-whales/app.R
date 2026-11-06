library(shiny)
library(shinyWidgets)
library(leaflet)
library(leaflet.extras)
library(sf)
library(DT)
library(dplyr)
library(tidyr)
library(stringr)

# =========================================================
# IMPORTANT FOR MARINE POLYGONS
# =========================================================

sf::sf_use_s2(FALSE)

# Default subarea used when it is available for the selected species.
default_subarea <- "GsL"

# Friendly labels for the large-area codes used in the consolidated data.
region_labels <- c(
  "NA" = "North Atlantic",
  "NP" = "North Pacific",
  "SA" = "South Atlantic",
  "SEP" = "South East Pacific",
  "SP" = "South Pacific",
  "IO" = "Indian Ocean",
  "SO" = "Southern Ocean",
  "SH" = "Southern Hemisphere"
)

# =========================================================
# COLUMN LABELS
# =========================================================

column_labels <- c(
  regions_code = "Large Area",
  species_code = "Species",
  subareas_subarea = "Subarea",
  category_code = "Category",
  evaluation_extent = "Evaluation Extent",
  trials_usage = "Trials Usage",
  year = "Year",
  startyear = "Start Year",
  endyear = "End Year",
  method_code = "Method",
  correction_code = "Correction",
  estimate = "Estimate",
  cv = "CV",
  se = "SE",
  cvav = "CV Additional Variance",
  lci = "Lower CI",
  uci = "Upper CI",
  references_ref = "References",
  notes = "Notes",
  survey_programme = "Survey Programme",
  pl = "Lower CL",
  pu = "Upper CL",
  season = "Season",
  gnull = "g(0)",
  areacoverage = "Area Coverage",
  sd = "SD",
  cvcalc = "CV Analytical",
  dateadded = "Date Added",
  datemodified = "Date Modified"
)

# =========================================================
# HELPER FUNCTION FOR COLORS (handles >8 categories)
# =========================================================

get_color_palette <- function(domains) {
  n_colors <- length(unique(domains))
  
  if (n_colors <= 8) {
    colorFactor(palette = "Set2", domain = domains)
  } else if (n_colors <= 12) {
    colorFactor(palette = "Set3", domain = domains)
  } else {
    colorFactor(palette = "viridis", domain = domains)
  }
}

# =========================================================
# UI
# =========================================================

ui <- fluidPage(
  
  tags$head(
    tags$style(HTML("
      body {
        background-color: #eaf4fb;
        font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      }

      .container-fluid {
        padding: 20px;
      }

      .shiny-input-container {
        margin-bottom: 18px;
      }

      h2 {
        color: #2b4c66;
        font-weight: 700;
      }

      .well {
        background-color: white;
        border: none;
        border-radius: 20px;
        padding: 24px;
        box-shadow: 0 4px 14px rgba(0,0,0,0.08);
      }

      .tab-content {
        background-color: white;
        padding: 24px;
        border-radius: 0 20px 20px 20px;
        box-shadow: 0 4px 14px rgba(0,0,0,0.08);
      }

      .nav-tabs {
        border-bottom: none;
        display: flex;
        gap: 8px;
      }

      .nav-tabs > li > a {
        background-color: #d7ebf7;
        color: #2b4c66;
        border: none;
        border-radius: 14px 14px 0 0;
        padding: 12px 22px;
        font-weight: 600;
      }

      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:hover {
        background-color: white;
        color: #16354d;
        border: none;
      }

      .bootstrap-select .dropdown-toggle {
        border-radius: 10px;
        border: 1px solid #c7dce8;
      }

      .leaflet-container {
        border-radius: 16px;
      }

      table.dataTable thead {
        background-color: #d7ebf7;
        color: #24435b;
      }

      .btn {
        border-radius: 10px;
      }

      .modal-content {
        border-radius: 20px;
      }
    "))
  ),
  
  titlePanel(
    div(
      style = "
        color:#24435b;
        font-weight:700;
        font-size:34px;
      ",
      "🐋 Whale Abundances Viewer"
    )
  ),
  
  div(
    style = "
      background:#f5f8fa;
      border-left:4px solid #5b7f95;
      padding:12px 16px;
      margin:0 0 18px 0;
      border-radius:4px;
      color:#334e5f;
      font-size:14px;
      line-height:1.5;
    ",
    tags$strong("Data status and provenance. "),
    "The official and most up-to-date release of the IWC cetacean abundance data is available from ",
    tags$a(
      href = "https://doi.org/10.5281/zenodo.24002558",
      "Zenodo (DOI: 10.5281/zenodo.24002558)",
      target = "_blank"
    ),
    ". This viewer currently contains data dated 6 November 2026 and may be updated less frequently than the Zenodo record. ",
    "Please check Zenodo to confirm whether a newer data release is available. The documentation of the data can also be found in the Zenodo record.",
    tags$br(),
    tags$br(),
    "The following GitHub repositories document how the data and spatial subareas are produced. ",
    "The database repository also contains the source code for this application: ",
    tags$a(
      href = "https://github.com/intwhcom/iwc-cetaceans-abundances-database/tree/main",
      "IWC cetacean abundance database",
      target = "_blank"
    ),
    " and ",
    tags$a(
      href = "https://github.com/intwhcom/iwc-cetaceans-abundances-subareas",
      "IWC cetacean abundance subareas",
      target = "_blank"
    ),
    ".",
    tags$br(),
    tags$br(),
    "Please report any issues with the data or this application to ",
    tags$a(
      href = "mailto:statistics@iwc.int",
      "statistics@iwc.int"
    ),
    "."
  ),

  sidebarLayout(
    
    sidebarPanel(
      width = 3,
      
      # SPECIES ----

      pickerInput(
        inputId = "species",
        label = "Select Species:",
        choices = NULL,
        selected = NULL,
        multiple = FALSE,
        options = list(`live-search` = TRUE)
      ),

      # LARGE AREA ----

      pickerInput(
        inputId = "region",
        label = "Select Large Area:",
        choices = NULL,
        selected = NULL,
        multiple = FALSE,
        options = list(`live-search` = TRUE)
      ),

      # AREA SELECTION MODE ----
      
      radioGroupButtons(
        inputId = "selection_mode",
        label = "Choose Area Selection Method:",
        choices = c(
          "📝 List" = "list",
          "🗺 Map" = "map"
        ),
        justified = TRUE,
        selected = "list"
      ),
      
      helpText(
        "You can either select subareas manually from a list or draw a polygon on the map."
      ),
      
      # AREA LIST ----
      
      conditionalPanel(
        condition = "input.selection_mode == 'list'",
        pickerInput(
          inputId = "area",
          label = "Select Areas:",
          choices = NULL,
          selected = NULL,
          multiple = TRUE,
          options = list(
            `actions-box` = TRUE,
            `live-search` = TRUE
          )
        )
      ),
      
      # YEARS ----
      
      sliderInput(
        inputId = "start_year",
        label = "Select Start Year:",
        min = 1980,
        max = 2025,
        value = 1980
      ),
      
      sliderInput(
        inputId = "end_year",
        label = "Select End Year:",
        min = 1980,
        max = 2025,
        value = 2025
      ),
      
      # COLUMNS ----
      
      pickerInput(
        inputId = "columns",
        label = "Select Columns to Display:",
        choices = setNames(
          names(column_labels),
          column_labels
        ),
        selected = c(
          "regions_code",
          "species_code",
          "subareas_subarea",
          "year",
          "estimate",
          "references_ref"
        ),
        multiple = TRUE,
        options = list(
          `actions-box` = TRUE,
          `live-search` = TRUE
        )
      ),
      
      br(),
      
      downloadButton(
        "download_table",
        "⬇ Download Table"
      ),
      
      br(),
      br(),
      
      downloadButton(
        "download_shapefile",
        "🗺 Download Shapefile"
      )
    ),
    
    # MAIN PANEL ----
    
    mainPanel(
      width = 9,
      
      tabsetPanel(
        type = "tabs",
        
        # TABLE ----
        
        tabPanel(
          "📊 Table",
          br(),
          DTOutput("data_table")
        ),
        
        # MAP ----
        
        tabPanel(
          "🗺 Map",
          br(),
          leafletOutput(
            "map",
            height = 650
          )
        ),
        
        # REFERENCES ----
        
        tabPanel(
          "📚 References",
          br(),
          DTOutput("references_table")
        )
      )
    )
  )
)

# =========================================================
# SERVER
# =========================================================

server <- function(input, output, session) {
  
  # =====================================================
  # DATA STORAGE
  # =====================================================
  
  table_data <- reactiveVal()
  reference_data <- reactiveVal()
  shapefile_data <- reactiveVal()
  selected_areas <- reactiveVal(character())
  
  # =====================================================
  # LOAD CONSOLIDATED DATA
  # =====================================================

  # The application uses the same consolidated release files that are
  # distributed with the data package.

  tryCatch({
    table_data(
      read.csv(
        "main_abundances_table.csv",
        stringsAsFactors = FALSE,
        na.strings = ""
      )
    )
  }, error = function(e) {
    showNotification(
      paste("Error loading main abundance table:", e$message),
      type = "error",
      duration = 10
    )
  })

  tryCatch({
    reference_data(
      read.csv(
        "literature_references.csv",
        stringsAsFactors = FALSE,
        na.strings = ""
      )
    )
  }, error = function(e) {
    showNotification(
      paste("Error loading literature references:", e$message),
      type = "error",
      duration = 10
    )
  })

  tryCatch({
    shp <- st_read("subareas.shp", quiet = TRUE)

    if (is.na(st_crs(shp))) {
      st_crs(shp) <- 4326
    } else if (st_crs(shp)$epsg != 4326) {
      shp <- st_transform(shp, 4326)
    }

    shapefile_data(shp)
  }, error = function(e) {
    showNotification(
      paste("Error loading subareas shapefile:", e$message),
      type = "error",
      duration = 10
    )
  })

  # =====================================================
  # UPDATE SPECIES CHOICES WHEN DATA LOADS
  # =====================================================

  observeEvent(table_data(), {
    req(table_data())

    species_choices <- table_data() %>%
      filter(!is.na(species_code), species_code != "") %>%
      pull(species_code) %>%
      unique() %>%
      sort()

    current_species <- isolate(input$species)

    # Select the species associated with the configured default subarea
    # when possible. For the current data this makes Blu the startup species
    # because GsL is a North Atlantic blue-whale subarea.
    default_species <- table_data() %>%
      filter(subareas_subarea == default_subarea) %>%
      pull(species_code) %>%
      unique()

    selected_species <- if (length(default_species) > 0) {
      default_species[[1]]
    } else if (!is.null(current_species) && current_species %in% species_choices) {
      current_species
    } else if (length(species_choices) > 0) {
      species_choices[[1]]
    } else {
      NULL
    }

    updatePickerInput(
      session,
      "species",
      choices = species_choices,
      selected = selected_species
    )
  }, ignoreInit = FALSE)

  # =====================================================
  # UPDATE LARGE-AREA CHOICES WHEN SPECIES CHANGES
  # =====================================================

  observeEvent(input$species, {
    req(input$species, table_data())

    species_regions <- table_data() %>%
      filter(
        species_code == input$species,
        !is.na(regions_code),
        regions_code != ""
      ) %>%
      pull(regions_code) %>%
      unique()

    # Retain the preferred display order defined in region_labels.
    valid_regions <- names(region_labels)[names(region_labels) %in% species_regions]

    # Also retain any future region codes that are not yet in region_labels.
    unknown_regions <- sort(setdiff(species_regions, names(region_labels)))
    valid_regions <- c(valid_regions, unknown_regions)

    display_labels <- ifelse(
      valid_regions %in% names(region_labels),
      unname(region_labels[valid_regions]),
      valid_regions
    )

    current_region <- isolate(input$region)

    default_region <- table_data() %>%
      filter(
        species_code == input$species,
        subareas_subarea == default_subarea
      ) %>%
      pull(regions_code) %>%
      unique()

    default_region <- default_region[default_region %in% valid_regions]

    selected_region <- if (length(default_region) > 0) {
      default_region[[1]]
    } else if (!is.null(current_region) && current_region %in% valid_regions) {
      current_region
    } else if (length(valid_regions) > 0) {
      valid_regions[[1]]
    } else {
      NULL
    }

    updatePickerInput(
      session,
      "region",
      choices = setNames(valid_regions, display_labels),
      selected = selected_region
    )

    # Clear the area selection while the large-area selector is being updated.
    updatePickerInput(
      session,
      "area",
      choices = NULL,
      selected = NULL
    )
    selected_areas(character())
  })

  # =====================================================
  # UPDATE SUBAREA CHOICES WHEN SPECIES / LARGE AREA CHANGES
  # =====================================================

  observeEvent(list(input$species, input$region), {
    req(input$species, input$region, table_data(), shapefile_data())

    valid_areas <- table_data() %>%
      filter(
        species_code == input$species,
        regions_code == input$region,
        !is.na(subareas_subarea),
        subareas_subarea != ""
      ) %>%
      pull(subareas_subarea) %>%
      unique() %>%
      sort()

    default_area <- if (default_subarea %in% valid_areas) {
      default_subarea
    } else {
      NULL
    }

    updatePickerInput(
      session,
      "area",
      choices = valid_areas,
      selected = default_area
    )

    if (is.null(default_area)) {
      selected_areas(character())
    } else {
      selected_areas(default_area)
    }

    # Derive the year controls from the selected species and large area.
    year_values <- table_data() %>%
      filter(
        species_code == input$species,
        regions_code == input$region
      ) %>%
      mutate(
        year0 = dplyr::case_when(
          !is.na(year) ~ as.numeric(year),
          !is.na(startyear) & !is.na(endyear) ~
            round((as.numeric(startyear) + as.numeric(endyear)) / 2),
          TRUE ~ NA_real_
        )
      ) %>%
      pull(year0)

    year_values <- year_values[is.finite(year_values)]

    if (length(year_values) > 0) {
      min_year <- floor(min(year_values))
      max_year <- ceiling(max(year_values))

      updateSliderInput(
        session,
        "start_year",
        min = min_year,
        max = max_year,
        value = min_year
      )

      updateSliderInput(
        session,
        "end_year",
        min = min_year,
        max = max_year,
        value = max_year
      )
    }

    region_name <- if (input$region %in% names(region_labels)) {
      unname(region_labels[input$region])
    } else {
      input$region
    }

    showNotification(
      paste(
        input$species, "—", region_name, "—",
        length(valid_areas), "subareas available"
      ),
      type = "message",
      duration = 3
    )
  })

  # =====================================================
  # AVAILABLE SHAPES (for map selection)
  # =====================================================

  available_shapes <- reactive({
    req(input$species, input$region, shapefile_data(), table_data())

    valid_areas <- table_data() %>%
      filter(
        species_code == input$species,
        regions_code == input$region
      ) %>%
      pull(subareas_subarea) %>%
      unique()

    shapefile_data() %>%
      filter(
        species == input$species,
        large_area == input$region,
        subareas %in% valid_areas
      )
  })

  # =====================================================
  # LIST SELECTION
  # =====================================================
  
  observeEvent(input$area, {
    if (input$selection_mode == "list") {
      selected_areas(input$area)
    }
  })
  
  # =====================================================
  # MAP SELECTION MODAL WITH CONFIRM BUTTON
  # =====================================================
  
  # Store drawn features in a reactiveValues object
  map_state <- reactiveValues(
    drawn_features = list()
  )
  
  observeEvent(input$selection_mode, {
    req(input$species, input$region)
    
    if (input$selection_mode == "map") {
      # Reset drawn features when opening modal
      map_state$drawn_features <- list()
      
      showModal(
        modalDialog(
          title = paste(
            "Draw Polygon to Select Areas -",
            input$species, "-",
            if (input$region %in% names(region_labels)) {
              unname(region_labels[input$region])
            } else {
              input$region
            }
          ),
          
          fluidRow(
            column(
              width = 12,
              actionButton(
                "apply_map_selection",
                "✅ Apply Selection",
                icon = icon("check"),
                style = "margin-bottom: 10px; margin-right: 10px; background-color: #28a745; color: white;"
              ),
              actionButton(
                "clear_map_selection",
                "🗑 Clear All Shapes",
                icon = icon("trash"),
                style = "margin-bottom: 10px; margin-right: 10px;"
              ),
              actionButton(
                "cancel_map_selection",
                "❌ Cancel",
                icon = icon("times"),
                style = "margin-bottom: 10px;"
              ),
              helpText(
                "Draw one or more polygons on the map. Click 'Apply Selection' when finished.",
                br(),
                "💡 Tip: Click the polygon drawing tool (⬟) on the top-left of the map to start drawing.",
                br(),
                "⚠️ Important: After drawing each polygon, the 'Apply Selection' button will capture it."
              )
            )
          ),
          
          leafletOutput("selection_map", height = 550),
          
          easyClose = FALSE,
          size = "l",
          footer = NULL
        )
      )
    }
  })
  
  # =====================================================
  # SELECTION MAP RENDER
  # =====================================================
  
  output$selection_map <- renderLeaflet({
    req(available_shapes())
    
    pal <- get_color_palette(available_shapes()$subareas)
    
    leaflet(options = leafletOptions(preferCanvas = TRUE)) %>%
      addTiles() %>%
      setView(lng = 0, lat = 20, zoom = 2) %>%
      addPolygons(
        data = available_shapes(),
        layerId = ~subareas,
        color = ~pal(subareas),
        fillColor = ~pal(subareas),
        weight = 1,
        fillOpacity = 0.5,
        popup = ~subareas,
        group = "subareas",
        label = ~subareas,
        labelOptions = labelOptions(noHide = FALSE)
      ) %>%
      addDrawToolbar(
        targetGroup = "draw",
        polygonOptions = drawPolygonOptions(shapeOptions = drawShapeOptions(color = "#FF0000", weight = 3)),
        rectangleOptions = FALSE,
        circleOptions = FALSE,
        markerOptions = FALSE,
        polylineOptions = FALSE,
        circleMarkerOptions = FALSE,
        editOptions = editToolbarOptions(edit = TRUE, remove = TRUE)
      ) %>%
      addLayersControl(
        overlayGroups = c("subareas", "draw"),
        options = layersControlOptions(collapsed = FALSE)
      )
  })
  
  # =====================================================
  # CLEAR ALL DRAWN SHAPES
  # =====================================================
  
  observeEvent(input$clear_map_selection, {
    # Clear stored features
    map_state$drawn_features <- list()
    
    # Clear the map drawings
    leafletProxy("selection_map") %>%
      clearGroup("draw") %>%
      addDrawToolbar(
        targetGroup = "draw",
        polygonOptions = drawPolygonOptions(shapeOptions = drawShapeOptions(color = "#FF0000", weight = 3)),
        rectangleOptions = FALSE,
        circleOptions = FALSE,
        markerOptions = FALSE,
        polylineOptions = FALSE,
        circleMarkerOptions = FALSE,
        editOptions = editToolbarOptions(edit = TRUE, remove = TRUE)
      )
    
    showNotification(
      "All drawn shapes cleared. Draw new polygons to select areas.",
      type = "message",
      duration = 3
    )
  })
  
  # =====================================================
  # COLLECT DRAWN FEATURES
  # =====================================================
  
  # Capture all drawn features (most reliable)
  observeEvent(input$selection_map_draw_all_features, {
    if (!is.null(input$selection_map_draw_all_features)) {
      features <- input$selection_map_draw_all_features
      if (length(features$features) > 0) {
        map_state$drawn_features <- features$features
        showNotification(
          paste("✓ Captured", length(map_state$drawn_features), "polygon(s)"),
          type = "message",
          duration = 2
        )
      }
    }
  })
  
  # Also capture individual features as they're drawn
  observeEvent(input$selection_map_draw_new_feature, {
    if (!is.null(input$selection_map_draw_new_feature)) {
      current_features <- map_state$drawn_features
      current_features[[length(current_features) + 1]] <- input$selection_map_draw_new_feature
      map_state$drawn_features <- current_features
      
      showNotification(
        paste("✓ Added polygon. Total drawn:", length(map_state$drawn_features)),
        type = "message",
        duration = 2
      )
    }
  })
  
  # =====================================================
  # APPLY MAP SELECTION
  # =====================================================
  
  observeEvent(input$apply_map_selection, {
    req(available_shapes())
    
    # Get drawn features from storage
    drawn_feature_list <- map_state$drawn_features
    
    # Also check direct input as fallback
    if (length(drawn_feature_list) == 0 && !is.null(input$selection_map_draw_all_features)) {
      drawn_feature_list <- input$selection_map_draw_all_features$features
    }
    
    if (length(drawn_feature_list) == 0) {
      # Show helpful error message with instructions
      showModal(
        modalDialog(
          title = "⚠️ No Polygons Detected",
          div(
            p("No polygons have been drawn on the map."),
            p("To draw a polygon:"),
            tags$ol(
              tags$li("Click the polygon drawing tool (⬟) in the top-left corner of the map"),
              tags$li("Click on the map to create vertices of your polygon"),
              tags$li("Double-click to complete the polygon"),
              tags$li("Click 'Apply Selection' after drawing")
            ),
            p(tags$strong("Note:"), "The polygon outline will appear as you draw. Make sure you double-click to finish."),
            br(),
            p("If you're still having trouble, try using the 'List' selection method instead.")
          ),
          easyClose = TRUE,
          footer = modalButton("OK")
        )
      )
      return()
    }
    
    showNotification(paste("Processing", length(drawn_feature_list), "polygon(s)..."), type = "message", duration = 2)
    
    # Combine all drawn polygons
    all_polygons <- list()
    valid_polygon_count <- 0
    
    for (i in seq_along(drawn_feature_list)) {
      feature <- drawn_feature_list[[i]]
      
      if (is.null(feature$geometry)) next
      
      geom_type <- feature$geometry$type
      
      tryCatch({
        if (geom_type == "Polygon") {
          # Extract coordinates
          coords_list <- feature$geometry$coordinates
          
          # Handle different coordinate structures
          if (length(coords_list) > 0) {
            coords <- coords_list[[1]]
            polygon_matrix <- do.call(rbind, lapply(coords, function(coord) {
              c(coord[[1]], coord[[2]])
            }))
            
            if (nrow(polygon_matrix) >= 3) {
              all_polygons[[length(all_polygons) + 1]] <- st_polygon(list(as.matrix(polygon_matrix)))
              valid_polygon_count <- valid_polygon_count + 1
            }
          }
          
        } else if (geom_type == "MultiPolygon") {
          for (j in seq_along(feature$geometry$coordinates)) {
            coords <- feature$geometry$coordinates[[j]][[1]]
            polygon_matrix <- do.call(rbind, lapply(coords, function(coord) {
              c(coord[[1]], coord[[2]])
            }))
            
            if (nrow(polygon_matrix) >= 3) {
              all_polygons[[length(all_polygons) + 1]] <- st_polygon(list(as.matrix(polygon_matrix)))
              valid_polygon_count <- valid_polygon_count + 1
            }
          }
        }
      }, error = function(e) {
        print(paste("Error processing polygon", i, ":", e$message))
      })
    }
    
    if (valid_polygon_count == 0) {
      showNotification(
        "No valid polygons could be processed. Please ensure your polygon has at least 3 points and is closed by double-clicking.",
        type = "error",
        duration = 5
      )
      return()
    }
    
    # Combine polygons
    suppressWarnings({
      combined_polygon <- st_union(st_sfc(all_polygons, crs = 4326))
      combined_polygon <- st_make_valid(combined_polygon)
      
      valid_shapes <- st_make_valid(available_shapes())
      
      intersects <- st_intersects(valid_shapes, combined_polygon, sparse = FALSE)
    })
    
    selected <- unique(valid_shapes$subareas[intersects[,1]])
    
    if (length(selected) == 0) {
      showNotification(
        "No areas intersect with your drawn polygon(s). Try drawing a larger area or check if your polygon overlaps the available subareas.",
        type = "warning",
        duration = 5
      )
      return()
    }
    
    # Update selections
    selected_areas(selected)
    
    updatePickerInput(
      session,
      "area",
      selected = selected
    )
    
    # Close modal
    removeModal()
    
    # Switch back to list mode
    updateRadioGroupButtons(
      session,
      "selection_mode",
      selected = "list"
    )
    
    showNotification(
      paste("✓ Successfully selected", length(selected), "area(s):", 
            paste(head(selected, 3), collapse = ", "),
            if(length(selected) > 3) paste("and", length(selected)-3, "more") else ""),
      type = "message",
      duration = 6
    )
  })
  
  # =====================================================
  # CANCEL MAP SELECTION
  # =====================================================
  
  observeEvent(input$cancel_map_selection, {
    removeModal()
    
    updateRadioGroupButtons(
      session,
      "selection_mode",
      selected = "list"
    )
    
    showNotification(
      "Map selection cancelled.",
      type = "message",
      duration = 3
    )
  })
  
  # =====================================================
  # FILTERED DATA
  # =====================================================

  # Keep the full filtered records separate from the displayed columns.
  # This prevents the References tab from depending on which columns the
  # user chooses to display in the Table tab.
  filtered_data <- reactive({
    req(
      input$species,
      input$region,
      selected_areas(),
      table_data()
    )

    if (length(selected_areas()) == 0) {
      return(data.frame())
    }

    table_data() %>%
      mutate(
        year0 = dplyr::case_when(
          !is.na(year) ~ as.numeric(year),
          !is.na(startyear) & !is.na(endyear) ~
            round((as.numeric(startyear) + as.numeric(endyear)) / 2),
          TRUE ~ NA_real_
        )
      ) %>%
      filter(
        species_code == input$species,
        regions_code == input$region,
        subareas_subarea %in% selected_areas(),
        !is.na(year0),
        year0 >= input$start_year,
        year0 <= input$end_year
      ) %>%
      select(-year0)
  })

  filtered_table <- reactive({
    data <- filtered_data()

    if (nrow(data) == 0 || is.null(input$columns) || length(input$columns) == 0) {
      return(data.frame())
    }

    display_columns <- intersect(input$columns, names(data))
    data %>% select(all_of(display_columns))
  })

  # =====================================================
  # FILTERED REFERENCES
  # =====================================================

  filtered_references <- reactive({
    req(filtered_data(), reference_data())

    if (nrow(filtered_data()) == 0) {
      return(data.frame())
    }

    ft <- filtered_data() %>%
      filter(
        !is.na(references_ref),
        references_ref != ""
      ) %>%
      tidyr::separate_rows(references_ref, sep = ";") %>%
      transmute(
        ref = trimws(references_ref),
        regions_code = trimws(regions_code),
        species_code = trimws(species_code)
      ) %>%
      filter(ref != "") %>%
      distinct()

    reference_data() %>%
      transmute(
        refid = refid,
        reference_regions = regions_code,
        reference_species = species_code,
        ref = ref,
        fullref = fullref,
        iwcref = iwcref
      ) %>%
      tidyr::separate_rows(reference_species, sep = "\\+") %>%
      tidyr::separate_rows(reference_regions, sep = "\\+") %>%
      mutate(
        reference_species = trimws(reference_species),
        reference_regions = trimws(reference_regions),
        ref = trimws(ref)
      ) %>%
      inner_join(
        ft,
        by = c(
          "ref" = "ref",
          "reference_species" = "species_code",
          "reference_regions" = "regions_code"
        )
      ) %>%
      select(
        species = reference_species,
        ref,
        `full reference` = fullref,
        `IWC reference` = iwcref
      ) %>%
      distinct()
  })

  # =====================================================
  # FILTERED SHAPEFILE
  # =====================================================

  filtered_shapefile <- reactive({
    req(
      input$species,
      input$region,
      selected_areas(),
      shapefile_data()
    )

    if (length(selected_areas()) == 0) {
      return(NULL)
    }

    shapefile_data() %>%
      filter(
        species == input$species,
        large_area == input$region,
        subareas %in% selected_areas()
      )
  })

  # =====================================================
  # CHECK IF DATA EXISTS
  # =====================================================
  
  has_data <- reactive({
    req(filtered_data())
    nrow(filtered_data()) > 0
  })
  
  # =====================================================
  # TABLE OUTPUT
  # =====================================================
  
  output$data_table <- renderDT({
    if (!has_data()) {
      datatable(
        data.frame(Message = "No data available for the selected filters. Please adjust your selections."),
        options = list(dom = "t", pageLength = 1),
        rownames = FALSE
      )
    } else if (ncol(filtered_table()) == 0) {
      datatable(
        data.frame(Message = "Select at least one column to display."),
        options = list(dom = "t", pageLength = 1),
        rownames = FALSE
      )
    } else {
      table_display <- filtered_table()
      colnames(table_display) <- column_labels[colnames(table_display)]

      datatable(
        table_display,
        options = list(
          pageLength = 10,
          scrollX = TRUE
        )
      )
    }
  })

  # =====================================================
  # REFERENCES TABLE
  # =====================================================
  
  output$references_table <- renderDT({
    req(filtered_references())
    
    if (nrow(filtered_references()) == 0) {
      datatable(
        data.frame(Message = "No references available for the selected filters."),
        options = list(dom = "t", pageLength = 1),
        rownames = FALSE
      )
    } else {
      datatable(
        filtered_references(),
        options = list(
          pageLength = 10,
          scrollX = TRUE
        )
      )
    }
  })
  
  # =====================================================
  # MAP OUTPUT
  # =====================================================
  
  output$map <- renderLeaflet({
    req(filtered_shapefile())
    
    if (is.null(filtered_shapefile()) || nrow(filtered_shapefile()) == 0) {
      leaflet() %>%
        addTiles() %>%
        addControl("No areas selected. Use the sidebar to select areas.", position = "topright")
    } else {
      pal <- get_color_palette(filtered_shapefile()$subareas)
      
      leaflet() %>%
        addTiles() %>%
        addPolygons(
          data = filtered_shapefile(),
          color = ~pal(subareas),
          fillColor = ~pal(subareas),
          weight = 2,
          opacity = 1,
          fillOpacity = 0.5,
          popup = ~if("survey" %in% names(filtered_shapefile())) {
            paste("<b>Area:</b> ", subareas, "<br><b>Survey:</b> ", survey)
          } else {
            paste("<b>Area:</b> ", subareas)
          },
          label = ~subareas,
          labelOptions = labelOptions(
            style = list("font-weight" = "normal", padding = "3px 8px"),
            textsize = "12px",
            direction = "auto"
          )
        )
    }
  })
  
  # =====================================================
  # DOWNLOAD TABLE
  # =====================================================
  
  output$download_table <- downloadHandler(
    filename = function() {
      paste0("filtered_table-", Sys.Date(), ".csv")
    },
    content = function(file) {
      if (has_data()) {
        download_data <- filtered_table()
        if (ncol(download_data) == 0) {
          download_data <- filtered_data()
        }
        write.csv(download_data, file, row.names = FALSE)
      } else {
        write.csv(data.frame(Message = "No data available for current filters"), file, row.names = FALSE)
      }
    }
  )
  
  # =====================================================
  # DOWNLOAD SHAPEFILE
  # =====================================================
  
  output$download_shapefile <- downloadHandler(
    filename = function() {
      paste0("filtered_shapefile-", Sys.Date(), ".zip")
    },
    content = function(file) {
      filtered_sf <- filtered_shapefile()
      
      if (is.null(filtered_sf) || nrow(filtered_sf) == 0) {
        showNotification("No shapefile data available to download", type = "warning")
        return()
      }
      
      temp_dir <- tempdir()
      temp_shapefile <- file.path(temp_dir, "filtered_shapefile")
      
      tryCatch({
        st_write(
          filtered_sf,
          paste0(temp_shapefile, ".shp"),
          driver = "ESRI Shapefile",
          delete_layer = TRUE,
          quiet = TRUE
        )
        
        shp_files <- list.files(
          temp_dir,
          pattern = "filtered_shapefile\\.",
          full.names = TRUE
        )
        
        zip::zip(
          zipfile = file,
          files = shp_files,
          mode = "cherry-pick"
        )
        
        showNotification("Shapefile downloaded successfully!", type = "message", duration = 3)
        
      }, error = function(e) {
        showNotification(paste("Error creating shapefile:", e$message), type = "error")
      })
    },
    contentType = "application/zip"
  )
}

# =========================================================
# RUN APP
# =========================================================

shinyApp(ui = ui, server = server)