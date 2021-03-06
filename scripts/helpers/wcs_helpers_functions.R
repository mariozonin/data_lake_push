

# WCS REPORT -------------------------------------------------------
download_wcs <- function(url,temp = "k:/dept/DIGITAL E-COMMERCE/E-COMMERCE/Report E-Commerce/data_lake/temp/temp.xlsx", remove_temporary = T){
        
        
        h <- new_handle()
        handle_setopt(h, ssl_verifypeer = F)
        curl_download(url, temp, handle = h)
        
        wcs <- read_xlsx(temp, sheet = 1, guess_max = 70000)
        
        if(remove_temporary){
                file.remove(temp)
        }
        
        wcs
}
