

if(!dir.exists(here::here("data"))) {dir.create(here::here("data"))}
if(!dir.exists(here::here("data", "csv_files"))) {dir.create(here::here("data", "csv_files"))}

if(!file.exists(here::here("data", "csv_files", "npdes_downloads.zip"))) {
  download.file("https://echo.epa.gov/files/echodownloads/npdes_downloads.zip",
                destfile = here::here("data", "csv_files", "npdes_downloads.zip"))
  unzip(here::here("data","csv_files", "npdes_downloads.zip"), 
        exdir = here::here("data", "csv_files"))
}

if(!dir.exists(here::here("data", "csv_files", "effl_data"))) {dir.create(here::here("data", "csv_files", "effl_data"))}


state_eff_download_files <- paste0("https://echo.epa.gov/files/echodownloads/NPDES_by_state_year/", state.abb, "_NPDES_EFF_VIOLATIONS.zip")



purrr::walk(state_eff_download_files, 
            .f = ~ download.file(.x, 
                                 destfile = here::here("data", "csv_files", "effl_data", str_split(.x, "/")[[1]][7])))

state_eff_zip_files <- list.files(here::here("data", "csv_files", "effl_data"),
                                  full.names =  TRUE)

state_eff_zip_files <- stringr::str_subset(state_eff_zip_files, ".zip")

purrr::walk(state_eff_zip_files, 
            .f = ~ unzip(.x, exdir = here::here("data", "csv_files", "effl_data")))
