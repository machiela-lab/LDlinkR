# ldlinkr::ldmatrix

# library(httr)

# This function queries the LDlink > LDmatrix web tool and returns a data frame with the results
# arg1:  between 2 - 1,000 variants, using an rsID or chromosome coordinate (e.g. "chr7:24966446")
# arg2:  pop, a particular population, (e.g. YRI or CEU), multiple allowed, default=CEU
# arg3:  r2d, either "r2" for LD R-squared or "d" for LD D-prime, default="r2"
# arg4:  token, LDlink provided user token, default = NULL, register for token at: https://ldlink.nci.nih.gov/?tab=apiaccess
# arg5:  optional character string naming a path and file


LDmatrix <- function(snps, pop="CEU", r2d="r2", token=NULL, file = FALSE) {

LD_config <- list(ldmatrix_url="https://ldlink.nci.nih.gov/LDlinkRest/ldmatrix",
                  avail_pop=c("YRI","LWK","GWD","MSL","ESN","ASW","ACB",
                              "MXL","PUR","CLM","PEL","CHB","JPT","CHS",
                              "CDX","KHV","CEU","TSI","FIN","GBR","IBS",
                              "GIH","PJL","BEB","STU","ITU",
                              "ALL", "AFR", "AMR", "EAS", "EUR", "SAS"),
                  avail_ld=c("r2", "d")
                )


url <- LD_config[["ldmatrix_url"]]
avail_pop <- LD_config[["avail_pop"]]
avail_ld <- LD_config[["avail_ld"]]

# ensure file option is a character string
  file <- as.character(file)

# Define regular expressions used to check arguments for valid input below
  rsid_pattern <- "^rs\\d{1,}"
  # Syntax               Description
  # ^rs                  rsid starts with 'rs'
  # \\d{1,}              followed by 1 or more digits

  chr_coord_pattern <- "(^chr)(\\d{1,2}|X|x|Y|y):(\\d{8,8})$"
  # Syntax               Description
  # (^chr)               chromosome coordinate starts with 'chr'
  # (\\d{1,2}|X|x|Y|y)   followed by one or two digits, 'X', 'x', 'Y', 'y', to designate chromosome
  # :                    followed by a colon
  # (\\d{8,8})$          followed by 8 digits only to the end of string


# Checking arguments for valid input
  if(!(length(snps) > 1) & (length(snps) <= 1000)) {
    stop("Input is between 2 to 1000 variants.")
  }

  for(i in 1:length(snps)) {
    if(!((grepl(rsid_pattern, snps[i], ignore.case = TRUE)) | (grepl(chr_coord_pattern, snps[i], ignore.case = TRUE))))  {
      stop(paste("Invalid query format for variant: ",snps[i], ".", sep=""))
    }
  }

  if(!(all(pop %in% avail_pop))) {
    stop("Not a valid population code.")
  }

  if(!(r2d %in% avail_ld)) {
    stop("Not a valid r2d.  Enter 'r2' or 'd'.")
  }

  if(is.null(token)) {
    stop("Enter valid access token. Please register using the LDlink API Access tab: https://ldlink.nci.nih.gov/?tab=apiaccess")
  }

  if(!(is.character(file) | file == FALSE)) {
    stop("Invalid input for file option.")
  }


# Request body
snps_to_upload <- paste(unlist(snps), collapse = "\n")
pop_to_upload <- paste(unlist(pop), collapse = "+")
jsonbody <- list(snps=snps_to_upload, pop=pop_to_upload, r2_d=r2d)

# URL string
url_str <- paste(url, "?", "&token=", token, sep="")

# POST command
raw_out <-  POST(url=url_str, body=jsonbody, encode="json")
stop_for_status(raw_out)
# Parse response object
data_out <- read.delim(textConnection(content(raw_out, "text", encoding = "UTF-8")), header=T, sep="\t")

# Check for error in response data
  if(grepl("error", data_out[2,1])) {
    stop(data_out[2,1])
  }

# Evaluate 'file' option
  if (file == FALSE) {
    return(data_out)
  } else if (is.character(file)) {
    print(data_out)
    write.table(data_out, file = file, quote = F, row.names = F, sep = "\t")
    cat(paste("\nFile saved to ",file,".", sep=""))
    return(data_out)
  }

}
############ End Primary Function ##################