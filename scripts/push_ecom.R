library(tidyverse)              #version 1.1.1
library(readxl)                 #version 1.0.0
library(lubridate)              #version 1.6.0
library(stringr)                #version 1.2.0


rm(list = ls())        
source("scripts/helpers/sap_helpers_functions.R")


# SET PARAMS --------------------------------------------------------------
local_files <- list.files("k:/dept/DIGITAL E-COMMERCE/E-COMMERCE/Report E-Commerce/data_lake/ecommerce/", full.names = T, pattern = "csv$")
remote_file <- paste0("sales/ecommerce/",list.files("k:/dept/DIGITAL E-COMMERCE/E-COMMERCE/Report E-Commerce/data_lake/ecommerce/"))



# LOAD sales_dataset DATA -----------------------------------------------------
sales_dataset <- map_df(local_files, read_data)
sales_dataset <- dates_at(sales_dataset, input = c("day"), output = c("day"), drop_oringinal = T, format = "%d.%m.%Y")
sales_dataset <- quantity_at(sales_dataset, input = c("antreg_sales","antsaldi_sales"), output = c("qty_reg","qty_saldi"), drop_oringinal = T)
sales_dataset <- value_at(sales_dataset, c("val_net_antreg_sales","val_net_antsaldi_sales"), output = c("val_loc_reg","val_loc_saldi"), drop_oringinal = T)


sales_dataset <- unpivot_markdowns(data = sales_dataset, 
                               qty_reg_col = "qty_reg", 
                               qty_md_col = "qty_saldi", 
                               val_loc_reg_col = "val_loc_reg", 
                               val_loc_md_col = "val_loc_saldi")



# SAVE INTO LOCAL REPO -----------------------------------------------------
# sales_dataset %>%
#         write.csv2(paste0("k:/dept/DIGITAL E-COMMERCE/E-COMMERCE/Report E-Commerce/analytics/datasets/",remote_file), na = "", row.names = F, dec = ",")


# UPLOAD TO DATA LAKE -----------------------------------------------------
#source token
source("k:/dept/DIGITAL E-COMMERCE/E-COMMERCE/Report E-Commerce/data_lake/token/azure_token.r")


# write file to temporary dir
tempfile <- "k:/dept/DIGITAL E-COMMERCE/E-COMMERCE/Report E-Commerce/data_lake/temp/temp.csv"
sales_dataset %>%
        write.csv2(file = tempfile, na = "", row.names = F, dec = ",")
upload_file <- upload_file(tempfile)



#upload
put_url <- paste0("https://pradadigitaldatalake.azuredatalakestore.net/webhdfs/v1/",remote_file,"?op=CREATE&overwrite=true&write=true")
r <- httr::PUT(put_url,
               body = upload_file,
               add_headers(Authorization = paste0("Bearer ",res$access_token),
                           "Transfer-Encoding" = "chunked"), progress())
r$status_code
file.remove(tempfile)







# END OF SCRIPT -----------------------------------------------------------
cat("Script completed, hit Return to finish...")
a <- readLines(file("stdin"),1)