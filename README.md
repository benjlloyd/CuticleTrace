# Introduction to CuticleTrace
CuticleTrace is a suite of FIJI and R functions that allow users to the automatically trace and measure leaf epidermal pavement cells in microscope images.

The FIJI macros (in CuticleTrace_AllMacros.ijm) produce three main products from each cuticle image: 
  (1) thresholded and skeletonized binary images, 
  (2) sets of files recording individual cell shapes known as “regions of interest” (ROIs), and 
  (3) shape parameter measurements associated with each ROI. 
The R notebook (CuticleTrace_DataFiltration.Rmd) removes erroneous ROIs from the ROI sets and results files generated in FIJI through the statistical filtration of their shape parameter measurements. This step produces new, filtered, ROI sets that may be reopened in FIJI for visual inspection of the results. Both the FIJI macros and the R notebook functions may be used to individually- or batch-process images. 

# Github Contents
This repository contains the FIJI Macros, R Notebook, Example Dataset, and User Manual for the CuticleTrace Toolkit.
  1. CuticleTrace_AllMacros.ijm contains four FIJI Macros: (1) CuticleTrace - Batch Generate ROIs, (2) CuticleTrace - Single Image Processor, (3) CuticleTrace - Batch Measure (Different Scales), and (4) CuticleTrace - Batch Overlay.
  2. CuticleTrace_DataFiltration.Rmd — the R Notebook used for data filtration within the CuticleTrace pipeline.
  3. CuticleTrace_Example.zip — the example dataset for the tutorial in CuticleTrace_UserManual.pdf
  4. CuticleTrace_UserManual.pdf - an illustrated user manual containing descriptions of all CuticleTrace functions,an illustrated tutorial for        the analysis of the example dataset (CuticleTrace_Example.zip), and detailed instructions on applying CuticleTrace to new datasets.

# Software Requirements
CuticleTrace works on all operating systems that support FIJI and R. To install the necessary software and plugins, follow instructions detailed in the CuticleTrace User Manual.
