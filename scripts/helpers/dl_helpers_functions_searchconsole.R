data_lake_push <- function(dataset, remote_file, temppath = "k:/dept/DIGITAL E-COMMERCE/E-COMMERCE/Report E-Commerce/data_lake/temp/", remove_temp = T, clean_line_breaks = T, preserve_chinese = F){
        
        options(scipen=999)
        
        if(clean_line_breaks){
                dataset <- dataset %>%
                        mutate_if(is.character, ~ gsub(pattern = "\n|\r\n",replacement = " ",x = .))
        }
        
        tempfile <- paste0(temppath,"push_tmp_",format(Sys.time(),"%Y%m%d_%H%M%S"),".csv")
        
        if(!preserve_chinese){
                dataset %>%
                        write_csv(path = tempfile)
        } else {
                
                for(i in which(sapply(dataset, is.character))){
                        Encoding(dataset[[i]]) <- "unknown"
                }
                
                dataset %>%
                        write.csv2(file = tempfile, na = "", quote = T, row.names = F)
        }
        
        
        upload_file <- upload_file(tempfile)
        
        
        
        #upload
        put_url <- paste0("https://pradadigitaldatalake.azuredatalakestore.net/webhdfs/v1/",remote_file,"?op=CREATE&overwrite=true&write=true")
        r <- httr::PUT(put_url,
                       body = upload_file,
                       add_headers(Authorization = paste0("Bearer ",res$access_token),
                                   "Transfer-Encoding" = "chunked"), progress())
        r$status_code
        
        # delete temp file
        if(remove_temp){
                rr <- file.remove(tempfile)
        }
        message(paste0("Uploaded file: ",remote_file))
        
}

data_lake_fetch <- function(data_lake_file, remove_temp = T, temppath = "k:/dept/DIGITAL E-COMMERCE/E-COMMERCE/Report E-Commerce/data_lake/temp/"){
        
        #download file
        r <- httr::GET(paste0("https://pradadigitaldatalake.azuredatalakestore.net/webhdfs/v1/",data_lake_file,"?op=OPEN&read=true"),
                       add_headers(Authorization = paste0("Bearer ",res$access_token)))
        
        tempfile <- paste0(temppath, "fetch_tmp_",format(Sys.time(),"%Y%m%d_%H%M%S"),".csv")
        
        #write to temp dir
        writeBin(content(r), tempfile) 
        
        #read
        dataset<- read_csv2(tempfile, col_types = cols(.default = col_character()))
        
        if(remove_temp){
                r <- file.remove(tempfile)
        }
        
        
        dataset
        
        
}


data_lake_list <- function(remote_dir){
        
        r <- httr::GET(paste0("https://pradadigitaldatalake.azuredatalakestore.net/webhdfs/v1/",remote_dir,"?op=LISTSTATUS"),add_headers(Authorization = paste0("Bearer ",res$access_token)))
        files <- toJSON(jsonlite::fromJSON(content(r,"text")), pretty = TRUE) %>% fromJSON(simplifyDataFrame = T)
        
        files <- files$FileStatuses$FileStatus %>% 
                tbl_df() %>% 
                arrange(desc(pathSuffix))
        
        
        
        
}