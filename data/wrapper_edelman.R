#################################
# general
prefix <- ""
rmddir <- "~/EmpNOW/rmd"
thread <- 5
outdir <- ""

# data_edelman.Rmd
fn_hal <- ""
fn_refseq <- ""

dir_hal2maf <- "~/hal2maf"
dir_singleCopy <- "~/getSingleCopy.py"
dir_mafsort <- "~/maf-sort.sh"
dir_msaview <- "~/msa_view"
dir_iqtree2 <- "~/iqtree2"
dir_seqkit <- "seqkit"

# filter_edelman.Rmd
dir_gblocks <- "Gblocks"
params_gblocks <- "-b5=h -b2=7 -b1=7 -b3=999"

# nw_main.Rmd
redo <- FALSE
outgroup <- "HmelRef"

window_len <- 20
window_size <- c(50000)

#################################

run_outdir <- paste0(outdir,"/",prefix,"/")

# data conversion from HAL -> FASTA
rmarkdown::render(input=paste0(rmddir,"/../data/data_edelman.Rmd"),
                  output_file=paste0(outdir,"/data_edelman.html"),
                  params=list(fn_hal=fn_hal, fn_refseq=fn_refseq, thread=thread, outdir=outdir,
                              dir_hal2maf=dir_hal2maf, dir_singleCopy=dir_singleCopy, dir_mafsort=dir_mafsort, dir_msaview=dir_msaview,
                              dir_iqtree2=dir_iqtree2, dir_seqkit=dir_seqkit),
                  quiet=TRUE)

# data filtering
rmarkdown::render(input=paste0(rmddir,"../data/filter_edelman.Rmd"),
                  output_file=paste0(outdir,"/filter_edelman.html"),
                  params=list(data_outdir=outdir, thread=thread, outdir=run_outdir,
                              dir_gblocks=dir_gblocks, params_gblocks=params_gblocks),
                  quiet=TRUE)

# run NOW on every chromosome
ls_chr <- list.dirs(outdir, full.names=F, recursive=F)
ls_chr <- subset(ls_chr, grepl("chr+", ls_chr))

# create sets of parameters
runs <- list()

for (c in ls_chr) {
  out <- paste0(run_outdir,"/",c,"/",c,".html")
  
  currentdir <- paste0(run_outdir,"/",c,"/")
  if (!file.exists(currentdir)) {
    dir.create(currentdir, recursive = T)
  }
  
  input_aln <- ifelse(c=="chr_all",
                      paste0(run_outdir,"/gblocks/all_concat.fa-gb"),
                      paste0(run_outdir,"/gblocks/",c,"_concat.fa-gb"))
  
  temprun <- list(out=out, params=list(rmddir=rmddir,
                                       prefix=c, outdir=currentdir, thread=thread, redo=redo,
                                       iqtree2dir=dir_iqtree2, outgroup=outgroup,
                                       input_aln=input_aln, window_len=window_len, window_size=window_size
  ))
  
  runs <- append(runs, list(temprun))
}

# function to create reports for independent run
make_runs <- function(r) {
  tf <- tempfile()
  dir.create(tf)
  
  rmarkdown::render(input=paste0(rmddir,"/nw_main.Rmd"),
                    output_file=r$out,
                    intermediates_dir=tf,
                    params=r$params,
                    quiet=TRUE)
  unlink(tf)
}

for (r in runs) {
  make_runs(r)
}

#################################