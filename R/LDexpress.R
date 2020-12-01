# LDlinkR::LDexpress


############ Begin Primary Function ##################
#' Search if a list of genomic variants (or variants in LD with those variants) is associated with gene
#' expression in tissues of interest. Quantitative trait loci data is downloaded from the
#' [GTEx Portal](https://gtexportal.org/home/).
#'
#' @param snps between 1 - 10 variants, using an rsID or chromosome coordinate (e.g. "chr7:24966446")
#' @param pop a 1000 Genomes Project population, (e.g. YRI or CEU), multiple allowed, default = "CEU"
#' @param tissue select from 1 - 54 non-diseased tissue sites collected for the GTEx project, mulitple
#' allowed.  User input is "tissue_abbrev" (tissue abbreviation) code listed in available GTEx tissue sites using the
#' `list_getex_tissues()` function (e.g. "ADI_SUB" for Adipose Subcutaneous).  Default = "ALL" for all
#' available tissue sites.
#' @param r2d either "r2" for LD R2 or "d" for LD D', default = "r2".
#' @param r2d_threshold R2 or D' (depends on 'r2d' user input parameter) threshold for LD filtering. Any variants
#' within -/+ of the specified genomic window and R^2 or D' less than the threshold will be removed. Value needs
#' to be in the range 0 to 1. Default value is 0.1.
#' @param p_threshold define the eQTL significance threshold used for returning query results. Default value
#' is 0.1 which returns all GTEx eQTL associations with P-value less than 0.1.
#' @param win_size set genomic window size for LD calculation. Specify a value greater than or equal to zero and less than or
#' equal to 1,000,000bp. Default value is -/+ 500,000bp.
#' @param token LDlink provided user token, default = NULL, register for token at  \url{https://ldlink.nci.nih.gov/?tab=apiaccess}
#' @param file Optional character string naming a path and file for saving results.  If file = FALSE, no file will be generated, default = FALSE.
#'
#' @return A data frame of all query variant RS numbers, respective QTL which are in LD with query variant,
#' and associated gene expression.
#' @importFrom httr POST content stop_for_status
#' @importFrom utils capture.output read.delim write.table
#' @export
#'
#' @examples
#' \dontrun{LDexpress(snps = c("rs345", "rs456"),
#'                    pop = c("YRI", "CEU"),
#'                    tissue = c("ADI_SUB", "ADI_VIS_OME"),
#'                    r2d = "r2",
#'                    r2d_threshold = "0.1",
#'                    p_threshold = "0.1",
#'                    win_size = "500000",
#'                    token = Sys.getenv("LDLINK_TOKEN")
#'                   )
#'          }
#'
LDexpress <- function(snps, pop = "CEU", tissue = "ALL",
                      r2d = "r2", r2d_threshold = 0.1,
                      p_threshold = 0.1, win_size = 500000,
                      token = NULL, file = FALSE) {

     LD_config <- list(ldexpress_url_base = "https://ldlink.nci.nih.gov/LDlinkRest/ldexpress",
                       avail_pop = c("YRI","LWK","GWD","MSL","ESN","ASW","ACB",
                                     "MXL","PUR","CLM","PEL","CHB","JPT","CHS",
                                     "CDX","KHV","CEU","TSI","FIN","GBR","IBS",
                                     "GIH","PJL","BEB","STU","ITU",
                                     "ALL", "AFR", "AMR", "EAS", "EUR", "SAS"),
                        avail_ld = c("r2", "d"),
          avail_tissue_ldexpress = c("Adipose_Subcutaneous", "Adipose_Visceral_Omentum", "Adrenal_Gland", "Artery_Aorta",
                                     "Artery_Coronary", "Artery_Tibial", "Bladder", "Brain_Amygdala",
                                     "Brain_Anterior_cingulate_cortex_BA24", "Brain_Caudate_basal_ganglia",
                                     "Brain_Cerebellar_Hemisphere", "Brain_Cerebellum", "Brain_Cortex",
                                     "Brain_Frontal_Cortex_BA9", "Brain_Hippocampus", "Brain_Hypothalamus",
                                     "Brain_Nucleus_accumbens_basal_ganglia", "Brain_Putamen_basal_ganglia",
                                     "Brain_Spinal_cord_cervical_c-1", "Brain_Substantia_nigra", "Breast_Mammary_Tissue",
                                     "Cells_Cultured_fibroblasts", "Cells_EBV_transformed_lymphocytes", "Cervix_Ectocervix",
                                     "Cervix_Endocervix", "Colon_Sigmoid", "Colon_Transverse",
                                     "Esophagus_Gastroesophageal_Junction",	"Esophagus_Mucosa", "Esophagus_Muscularis",
                                     "Fallopian_Tube", "Heart_Atrial_Appendage", "Heart_Left_Ventricle", "Kidney_Cortex",
                                     "Kidney_Medulla", "Liver", "Lung", "Minor_Salivary_Gland", "Muscle_Skeletal",
                                     "Nerve_Tibial", "Ovary", "Pancreas", "Pituitary", "Prostate",
                                     "Skin_Not_Sun_Exposed_Suprapubic", "Skin_Sun_Exposed_Lower_leg",
                                     "Small_Intestine_Terminal_Ileum", "Spleen", "Stomach", "Testis", "Thyroid", "Uterus",
                                     "Vagina", "Whole_Blood", "ALL"),
             avail_tissue_abbrev = c("ADI_SUB", "ADI_VIS_OME", "ADR_GLA", "ART_AOR", "ART_COR", "ART_TIB", "BLA", "BRA_AMY",
                                     "BRA_ANT_CIN_COR_BA2", "BRA_CAU_BAS_GAN", "BRA_CER_HEM", "BRA_CER", "BRA_COR",
                                     "BRA_FRO_COR_BA9", "BRA_HIP", "BRA_HYP", "BRA_NUC_ACC_BAS_GAN", "BRA_PUT_BAS_GAN",
                                     "BRA_SPI_COR_CER_C-1", "BRA_SUB_NIG", "BRE_MAM_MAM_TIS", "CEL_CUL_FIB", "CEL_EBV_TRA_LYN",
                                     "CER_ECT", "CER_END", "COL_SIG", "COL_TRA", "ESO_GAS_JUN", "ESO_MUC", "ESO_MUS", "FAL",
                                     "HEA_ATR", "HEA_LEF", "KID_COR", "KID_MED", "LIV", "LUN", "MIN_SAL_GLA", "MUS_SKE",
                                     "NER_TIB", "OVA", "PAN", "PIT", "PRO", "SKI_NOT_SUN_EXP_SUP", "SKI_SUN_EXP_LOW_LEG",
                                     "SMA_INT_TER_ILE", "SPL", "STO", "TES", "THY", "UTE", "VAG", "WHO_BLO", "ALL")
                      )


url <- LD_config[["ldexpress_url_base"]]
avail_pop <- LD_config[["avail_pop"]]
avail_ld <- LD_config[["avail_ld"]]
avail_tissue <- LD_config[["avail_tissue_abbrev"]]

# ensure file option is a character string
#  file <- as.character(file)

# Define regular expressions used to check arguments for valid input below
  rsid_pattern <- "^rs\\d{1,}"
  # Syntax               Description
  # ^rs                  rsid starts with 'rs'
  # \\d{1,}              followed by 1 or more digits

  chr_coord_pattern <- "(^chr)(\\d{1,2}|X|x|Y|y):(\\d{1,9})$"
  # Syntax               Description
  # (^chr)               chromosome coordinate starts with 'chr'
  # (\\d{1,2}|X|x|Y|y)   followed by one or two digits, 'X', 'x', 'Y', 'y', to designate chromosome
  # :                    followed by a colon
  # (\\d{1,9})$          followed by 1 to 9 digits only to the end of string


# Checking arguments for valid input
  if(!(length(snps) >= 1) & (length(snps) <= 10)) {
    stop("Input is between 1 to 10 variants.")
  }

  for(i in 1:length(snps)) {
    if(!((grepl(rsid_pattern, snps[i], ignore.case = TRUE)) | (grepl(chr_coord_pattern, snps[i], ignore.case = TRUE))))  {
      stop(paste("Invalid query format for variant: ",snps[i], ".", sep=""))
    }
  }

  if(!(all(pop %in% avail_pop))) {
    stop("Not a valid population code.")
  }

  if(length(pop) > 1) {
    pop=paste(unlist(pop), collapse = "+")
  }

  if(!(all(tissue %in% avail_tissue))) {
    stop("Invalid tissue abbreviation code. Please lookup using the `list_gtex_tissues()` function.")
  }

  if(!(r2d %in% avail_ld)) {
    stop("Not a valid r2d.  Enter 'r2' or 'd'.")
  }

  # first, ensure 'r2d_threshold' is type 'numeric'
  r2d_threshold <- as.numeric(r2d_threshold)

  if (!(r2d_threshold >= 0 & r2d_threshold <= 1)) {
    stop(paste("'r2d' threshold must be between 0 and 1: ", r2d_threshold, ".", sep=""))
  } else {
    # convert back to character
    r2d_threshold <- as.character(r2d_threshold)
  }

  # first, ensure 'p_threshold' is type 'numeric'
  p_threshold <- as.numeric(p_threshold)

  if (!(p_threshold >= 0 & p_threshold <= 1))
  {
    stop(paste("P threshold must be between 0 and 1: ", p_threshold, ".", sep=""))
  } else {
    # convert back to character
    p_threshold <- as.character(p_threshold)
  }

  # first, ensure 'win_size' is type 'integer'
  win_size <- as.integer(win_size)

  if (!(win_size >= 0 & win_size <= 1000000))
  {
    stop(paste("Window size must be between 0 and 1000000 bp: ", win_size, ".", sep=""))
  } else {
    # convert back to character
    win_size <- as.character(win_size)
  }

  if(is.null(token)) {
    stop("Enter valid access token. Please register using the LDlink API Access tab: https://ldlink.nci.nih.gov/?tab=apiaccess")
  }

  if(!(is.character(file) | file == FALSE)) {
    stop("Invalid input for file option.")
  }

# When 'tissue' is 'ALL'
if (length(tissue) == 1) {
   if (tissue == "ALL") {
      tissue <- avail_tissue[1:54]
   }
}

# Request body
snps_to_upload <- paste(unlist(snps), collapse = "\n")
pop_to_upload <- paste(unlist(pop), collapse = "+")

  # Convert 'tissue' parameter with tissue abbreviations to 'tissue_ldexpress' format
  # and create 'tissue_to_upload' character vector.
    tissue <- toupper(tissue) # ensure 'tissue' parameter abbrev is all upper case
    tissues_to_upload <- character() # initialize empty character vector

    for(i in 1:length(tissue)) {     # convert tissue abbreviation to full length 'tissue_ldexpress' format
      tissues_to_upload <- append(tissues_to_upload,
                                  LD_config[["avail_tissue_ldexpress"]][LD_config[["avail_tissue_abbrev"]] == tissue[i]],
                                  after = length(tissues_to_upload))
    }

    # collapse list of tissues, separated by '+' character
    tissues_to_upload <- paste(unlist(tissues_to_upload), collapse = "+")

    jsonbody <- list(snps = snps_to_upload,
                     pop = pop_to_upload,
                     tissues = tissues_to_upload,
                     r2_d = r2d,
                     r2_d_threshold = r2d_threshold,
                     p_threshold = p_threshold,
                     window = win_size
                    )

# URL string
url_str <- paste(url, "?", "token=", token, sep="")

# POST command
raw_out <-  httr::POST(url=url_str, body=jsonbody, encode="json")
httr::stop_for_status(raw_out)
# Parse response object
data_out <- read.delim(textConnection(httr::content(raw_out, "text", encoding = "UTF-8")), header=T, sep="\t")
# convert 'factor' to 'character'
data_out[] <- lapply(data_out, as.character)

# Check for error in response data
if(grepl("error", data_out[1,1])) {
  stop(data_out[1,1])
 }

# Evaluate 'file' option
  if (file == FALSE) {
    return(data_out)
  } else if (is.character(file)) {
    # `invisible(capture.output())` wrapped around `write.table`function,
    # suppresses output to console
    invisible(capture.output(write.table(data_out,
                                         file = file,
                                         quote = F,
                                         row.names = F,
                                         sep = "\t")
                             )
              )
    cat(paste("\nFile saved to ",file,".", sep=""))
    return(data_out)
  }

}
############ End Primary Function ##################
