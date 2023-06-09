# Dump information about this test environment
sessionInfo()
message("\n")
system("cat .NcLibs")
message("\n")
system("cat .Renviron")
message("\n")
print(tibble::tibble(
  Package = names(installed.packages()[,3]),
  Version = unname(installed.packages()[,3])
), n=100)


# Decide what we're going to test...
ncml_url <- "https://dapds00.nci.org.au/thredds/dodsC/fx3/gbr4_bgc_GBR4_H2p0_B3p1_Cq3b_Dhnd.ncml"
bgc_param <- "Chl_a_sum"
dim_t <- 1
dim_k <- 1
dim_j <- 1
dim_i <- 1


# Test with ncks
message("\n\n-------------------------------------------")
message("Testing OPeNDAP Access with nkcs")
nkcs_cmd <- paste(
    'ncks ',
    ' -di,', dim_i, ',', dim_i,
    ' -dj,', dim_j, ',', dim_j,
    ' -dtime,', dim_t, ',', dim_t,
    ' -dk,', dim_k, ',', dim_k,
    ' -v', bgc_param,
    ' "', ncml_url, '#log&show=fetch"',
    sep = '', collapse = ''
)
message(nkcs_cmd)
system(nkcs_cmd)


# Test with the netcdf4 package
message("\n\n-------------------------------------------")
message("Testing OPeNDAP Access via ncdf4 package")
library(ncdf4)
nc <- ncdf4::nc_open(ncml_url)
mydata <- ncdf4::ncvar_get(nc, bgc_param, start = c(dim_t, dim_k, dim_j, dim_i), count=c(dim_t, dim_k, dim_j, dim_i))
print(mydata)

# Test with the tidync package
message("\n\n-------------------------------------------")
message("Testing OPeNDAP Access via tidync package")
library(tidync)
library(dplyr)
nc <- tidync::tidync(ncml_url)
mydata <- nc %>% tidync::activate(bgc_param) %>%
        tidync::hyper_filter( i = i==dim_i, j = j==dim_j, k = k==dim_k, time=index==dim_t) %>%
        tidync::hyper_array(select_var=bgc_param)
print(mydata)
