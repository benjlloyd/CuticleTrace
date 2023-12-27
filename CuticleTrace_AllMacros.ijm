
macro "CuticleTrace - Batch Generate ROIs" {
	
	
// 1. LOADS FUNCTION TO ITERATIVELY THRESHOLD -  
function ROI_Scaled_ALT(First_Radius,ROI_ParticleSize,Algorithm, BlurVal, BackVal){


// a. Sets scale to Pixel Dimensions
	run("Set Scale...", "distance=0 known=0 unit=pixel");
	
	// c. Sets Measurements 
	//     (if you decide on your radius as 1/2 of the mean minor axis length, you only need to measure the fit ellipse)
	//     (you can add other measurements here if you decide you want to base your radius on something else)
	run("Set Measurements...", "fit redirect=None decimal=3");
	

	// d. LOADS NESTED FUNCTION - 
	function Iterate_ALTRadius(Radius,ParticleSize,Algorithm,BlurVal,BackVal) { 
		
		// i. Duplicates the image
		run("Duplicate...", " ");
		
		// ii. Blurs the image to de-noise it a bit (OPTIONAL):
		run("Gaussian Blur...", "sigma=BlurVal");
	
		// ii. Makes the image 8-bit
		run("8-bit");

		// iii. Runs CLAHE on the image (settings are left at default values)
		run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None* fast_(less_accurate)");
		
		if(BackVal == "Dark on Light"){
		// iv. Runs Auto Local Threshold with the radius and method that you inputted. 
		 if (Algorithm == "Bernsen") {
		run("Auto Local Threshold", "method=Bernsen radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Contrast") {
		run("Auto Local Threshold", "method=Contrast radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Mean") {
		run("Auto Local Threshold", "method=Mean radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Median") {
		run("Auto Local Threshold", "method=Median radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "MidGrey") {
		run("Auto Local Threshold", "method=MidGrey radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Niblack") {
		run("Auto Local Threshold", "method=Niblack radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Otsu") {
		run("Auto Local Threshold", "method=Otsu radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Phansalkar") {
		run("Auto Local Threshold", "method=Phansalkar radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Sauvola") {
		run("Auto Local Threshold", "method=Sauvola radius=Radius parameter_1=0 parameter_2=0 white");
 		} 
		}else {
			 if (Algorithm == "Bernsen") {
		run("Auto Local Threshold", "method=Bernsen radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Contrast") {
		run("Auto Local Threshold", "method=Contrast radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Mean") {
		run("Auto Local Threshold", "method=Mean radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Median") {
		run("Auto Local Threshold", "method=Median radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "MidGrey") {
		run("Auto Local Threshold", "method=MidGrey radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Niblack") {
		run("Auto Local Threshold", "method=Niblack radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Otsu") {
		run("Auto Local Threshold", "method=Otsu radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Phansalkar") {
		run("Auto Local Threshold", "method=Phansalkar radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Sauvola") {
		run("Auto Local Threshold", "method=Sauvola radius=Radius parameter_1=0 parameter_2=0");
 		}
		}
		// v. Generates ROIs and Results Table
		run("Analyze Particles...", "size=ParticleSize display exclude clear include add");

		// vi. Sets radius to "oops" if Analyze Particles didn't work
		if(roiManager("count") == 0){
			ALT_Radius = "oops";
		}
		
		// vii. If Analyze Particles DID work -
		//		Sets new thresholding radius to 1/2 of the average minor axis of the fit ellipse
		
		else {
		
		// vi. Forms Array of “Minor” column
		Minor_array = Table.getColumn("Minor", "Results");

		// vii. Gets statistics for “Minor” column
		Array.getStatistics(Minor_array, min, max, mean, stdDev);

		// viii. Sets our Auto Local Threshold Radius as 1/2 of the mean
		//     MEDIAN WOULD BE BETTER, BUT IMAGEJ CAN'T DO THAT (to my knowledge)
		ALT_Radius = mean/2;
		}

		return ALT_Radius;

		}

	its = 1;
	
	do {
	// e. RUNS NESTED FUNCTION - Applies initial radius, Determines better one
	Second_Radius = Iterate_ALTRadius(First_Radius,ROI_ParticleSize,Algorithm,BlurVal, BackVal);
	
	// j. Sets positive and negative thresholds for whether the function should be run for another iteration 
	//    (currently ±2%, can be changed)
	if_threshold_pos = 1.02 * First_Radius;
	if_threshold_neg = 0.98 * First_Radius;

	// f. If Iterate_AltRadius returned "oops", sets Final_Radius to "unsuccessful"
	if(Second_Radius == "oops") { 
		Final_Radius = "unsuccessful";

	}
	
	// g. If Iterate_ALTRadius returned a value within ±2% of the previous thresholding value, Sets Final_Radius to previous thresholding value 
	else if (Second_Radius < if_threshold_pos && Second_Radius > if_threshold_neg){
		Final_Radius = First_Radius;
		roiManager("Delete");
		close("results");
		
	}
	
	// h. If Iterate_ALTRadius is neither "oops" nor within ±2% of the previous thresholding value, runs the function again
	else {
		
		First_Radius = Second_Radius;
		
	// i. 1st, Clears ROI Manager, deletes results, closes previously thresholded image
	roiManager("Delete");
	close("results");
	close();
	Final_Radius = "na";
	its = its + 1;
	 }
	 } while (Final_Radius == "na" && its < 6); 
	 
	 if(Final_Radius == "na"){
	 	Second_Radius = Iterate_ALTRadius(First_Radius,ROI_ParticleSize,Algorithm,BlurVal, BackVal);
	 	Final_Radius = First_Radius;
	 }
	 
	 return Final_Radius;
}

	
	
// 2. Loads function to skeletonize and dilate that thresholded image 
function Skeleton_Dilate() { 
	run("Auto Threshold", "method=Default white");

	run("Skeletonize");
	run("Options...", "iterations=1 count=1 do=Dilate");
}


// 3. Loads function to generate ROIs, then enlarge and interpolate them


function Generate_ROIset(ParticleSize, Interp) {
	
	// a. Loads nested function to generate the interpolation length for the image
	
		function Interp_Val(ParticleSize) { 

		// i. Set measurements to Area, set scale to pixels
		run("Set Measurements...", "area redirect=None decimal=3");
		run("Set Scale...", "distance=0 known=0 unit=pixel");
	
		// ii. Re-thresholds the image (just inverts the colors), so Fiji will recognize the correct parts
		run("Auto Threshold", "method=Default white");
	
		// iii. Analyze particles
		run("Analyze Particles...", "size=ParticleSize display exclude clear include add");
	
		// iv. If roimanager("count") = 0, return "unsuccessful"
		if(roiManager("count") == 0){
				ival = "unsuccessful";
			}	
		// v. If roimanager("count") > 0, continue code 
 		else {

		// vi. creates array of ROI area values
		Area_array = Table.getColumn("Area", "Results");

		// vii. Gets mean for Area values
		//     	MEDIAN WOULD BE BETTER, BUT IMAGEJ CAN'T DO THAT (to my knowledge)
		Array.getStatistics(Area_array, min, max, mean, stdDev);

		// viii. Calculates interpolation value with the mean area value
		ival = 0.03545 * sqrt(mean);
		}
		
		// ix. Returns interpolation value
		return ival;
		}
	
	// b. Runs Interp_Val to get the interpolation length for the ROIs
	ival = Interp_Val(ParticleSize);
	
	// c. IF ival = "unsuccessful", return "unsuccessful"
		if(ival == "unsuccessful"){
				ival = "unsuccessful";
			}	
	// d. ELSE continue to e.
 		else {
	
	// e. For each ROI:
	counts=roiManager("count");
	for(i=0; i<counts; i++) {
		
		// i. Selects 1 ROI
		roiManager("Select", i);
		
		// ii. Enlarges the ROI to get rid of inclusions due to skeleton branches
    	run("Enlarge...", "enlarge=4");
    	roiManager("Update");
    	
    	// iii. Shrinks the ROI boundary back to exactly the middle of the cell wall
    	run("Enlarge...", "enlarge=-3");
    	roiManager("Update");
    	
    	if (Interp == "Yes") {

    	// iv. Interpolates the ROI boundary according to the length determined by Interp_Val
    	run("Interpolate", "interval=ival smooth");
    	roiManager("Update");
    	}
	}
}
close("Results");

	return ival;
}

// 4. Loads function to get results (ONLY RUNS IF ALL IMAGES HAVE THE SAME SCALE)


function SetScale_Measure(Scale, Units, ParticleSize) { 

close("results");

run("Set Measurements...", "area perimeter bounding fit shape feret's redirect=None decimal=3");
run("Set Scale...", "distance=Scale known=1 unit=Units");

if(roiManager("count") == 0){
	run("Analyze Particles...", "size=ParticleSize display exclude clear include add");
}
if(roiManager("count") != 0){
	
	roiManager("Deselect");
	roiManager("Measure");
	
	IJ.renameResults("Results"); // otherwise below does not work...
for (row=0; row<nResults; row++) {
	Undulation = getResult("Perim.", row) / 
	(2 * PI * sqrt(getResult("Area", row)/PI));
    setResult("UI", row, Undulation);
}
updateResults();
}
}	


// 5. Window Pops up asking you what radius to start with and what ROI size bounds to apply.

Dialog.create("NOTICE");
Dialog.addMessage("IMPORTANT NOTES:");
	Dialog.addMessage("1. The 'Shape Smoothing' plugin from the biomedgroup update site is required to run this macro.");
	Dialog.addMessage("2. ALL input parameters must be acceptable ALL images in the input directory:");
	Dialog.addMessage("     a. When selecting a thresholding algorithm, beware of computationally intense algorithms (Otsu)! ");
	Dialog.addMessage("     b. The initial thresholding radius is a place to start. It must be acceptable for all images, but does not have to be perfect.");
	Dialog.addMessage("     c. The ROI size filter should cover the whole range of cell areas you expect in your dataset.");
	Dialog.addMessage("3. Results files can be generated with this macro ONLY if all images in the input directory have the same scale.");
	Dialog.addMessage("     a. If images have different scales, use macro 'CuticleTrace - Batch Measure (Different Scales)' ");
	Dialog.addMessage("  ");
Dialog.show();




methods = newArray("Sauvola", "Bernsen", "Contrast", "Mean", "Median", "MidGrey", "Niblack", "Otsu", "Phansalkar");
background = newArray("Dark on Light", "Light on Dark");
y_n = newArray("Yes", "No");

Dialog.create("CuticleTrace - Batch Generate ROIs");
	
	Dialog.addMessage("IMAGE INPUT DIRECTORY:");
	Dialog.addDirectory("Directory:", "/Images/");
	Dialog.addMessage("  ");
	
	Dialog.addMessage("CUTICLETRACE INPUT PARAMETERS:");
	Dialog.addChoice("Cell Walls on Background:", background);
	Dialog.addNumber("Gaussian Blur Sigma (pixels):", 2);
	Dialog.addChoice("Thresholding Method:", methods);
	Dialog.addNumber("Initial Threshold Radius (pixels)", 50);
	Dialog.addString("ROI Size Filter (pixels^2)", "500-50000", 10);
	Dialog.addNumber("Smoothing Value (%FDs Retained):", 5);
	Dialog.addChoice("Interpolate ROIs?", y_n);
	Dialog.addMessage("  ");
	
	Dialog.addMessage("OPTIONAL - GENERATE RESULTS FILES (if all images have same scale):");
	Dialog.addCheckbox("Generate results files?", false);
	Dialog.addString("Units", "um");
	Dialog.addNumber("Scale (Pixels/unit)", 0);
	
	
Dialog.show();


InputDir = Dialog.getString();

BackVal = Dialog.getChoice();
BlurVal = Dialog.getNumber();
Algorithm = Dialog.getChoice();
First_Radius = Dialog.getNumber();
ROI_ParticleSize = Dialog.getString();
SmoothVal = Dialog.getNumber();
Interp = Dialog.getChoice();
Make_Results = Dialog.getCheckbox();
Units = Dialog.getString();
Scale = Dialog.getNumber();




// 6. Make Output Directories
ThresholdDir = File.getParent(InputDir) + "/Thresholded_Images/";
File.makeDirectory(ThresholdDir);

SkeletonDir = File.getParent(InputDir) + "/Skeletonized_Images/";
File.makeDirectory(SkeletonDir);

ROIsetsDir = File.getParent(InputDir) + "/ROI_Sets/";
File.makeDirectory(ROIsetsDir);

MetaDir = File.getParent(InputDir) + "/Image_Metadata/";
File.makeDirectory(MetaDir);

if (Make_Results == true) {
	ResultsDir = File.getParent(InputDir) + "/Results_Files/";
	File.makeDirectory(ResultsDir);
}



// 7. Each image is processed in succession.

	// a. Lists the names of all of the images in an array
	filelist = getFileList(InputDir);

	// b. creates new arrays to be filled with the thresholding radii and interpolation values of each image
	radii = newArray(); 
	ivals = newArray();
	
	// c. creates a directory for the image metadata

	// c. For each image:
	for (i = 0; i < lengthOf(filelist); i++) {
	
		// i. Open the image
		open(InputDir + filelist[i]);
		
		// ii. Run ROI_Scaled_ALT
		Rad = ROI_Scaled_ALT(First_Radius, ROI_ParticleSize, Algorithm, BlurVal, BackVal);
		
		// iii. Run the Shape smoothing Plug-in w/ 5% FDs
		run("Shape Smoothing", "relative_proportion_fds=5 absolute_number_fds=SmoothVal keep=[Relative_proportion of FDs] black");
		
		// iv. Save the Thresholded image to the specified folder
		save(ThresholdDir + File.getNameWithoutExtension(InputDir + filelist[i]) +" _Thresholded.tif");
		
		// v. Add the thresholding radius to the radii array
		radii = Array.concat(radii,Rad);
	
		// vi. THEN, Duplicate the image
		run("Duplicate...", " ");
		
		// vii. Skeletonize the duplicated image
		Skeleton_Dilate();
		
		// viii. Save the skeletonized image to the specified folder
		
		save(SkeletonDir + File.getNameWithoutExtension(InputDir + filelist[i]) + "_Skeletonized.tif");
		
		// ix. Generate the enlarged and interpolated ROI set from the Skeletonized image
	
		ival = Generate_ROIset(ROI_ParticleSize, Interp);
		
		// x. Save ROIset
		if(roiManager("count") > 0){
		roiManager("save", ROIsetsDir + File.getNameWithoutExtension(InputDir + filelist[i]) + "_ROIset.zip");
		}
		
		// xi. Add the interpolation length to the ivals array
		ivals = Array.concat(ivals,ival);
		
		// xii. Save small .csv file of just the image's thresholding radius and interpolation length
		r = newArray();
		r = Array.concat(r,Rad);
		
		Table.create("Radius and Interpolation");
		Table.setColumn("Threshold Radius", r);
		if(Interp == "Yes"){
		v = newArray();
		v = Array.concat(v,ival);
		Table.setColumn("Interpolation Length", v);
		}
		saveAs("results", MetaDir + File.getNameWithoutExtension(InputDir + filelist[i]) + "_metadata.csv");
		
				
		//xiii. IF The Generate Results Checkbox was clicked:
		if(Make_Results == true){
			
			// Generate the correctly scaled results file
			SetScale_Measure(Scale, Units, ROI_ParticleSize);
			
			// Save results file
			saveAs("results", ResultsDir + File.getNameWithoutExtension(InputDir + filelist[i]) + "_Results.csv");
		}
		
		// xiv. Close everything
		close("*");
		close("ROI Manager");
		close("results");
		close("*.csv");
		
		
	}


// 8. Creates a table of all of the file names, with Thresholding radii and Interpolation length, and saves to metadata directory
Table.create("Image Metadata");
Table.setColumn("File Name", filelist);
Table.setColumn("Threshold Radius", radii);
if(Interp == "Yes"){
Table.setColumn("Interpolation Length", ivals);
}
saveAs("results", MetaDir + File.getName(InputDir) + "_Images_Metadata.csv");

}


macro "CuticleTrace - Single Image Processor" {
// 1. LOADS FUNCTION TO ITERATIVELY THRESHOLD -  
function ROI_Scaled_ALT(First_Radius,ROI_ParticleSize,Algorithm, BlurVal, BackVal){


// a. Sets scale to Pixel Dimensions
	run("Set Scale...", "distance=0 known=0 unit=pixel");
	
	// c. Sets Measurements 
	//     (if you decide on your radius as 1/2 of the mean minor axis length, you only need to measure the fit ellipse)
	//     (you can add other measurements here if you decide you want to base your radius on something else)
	run("Set Measurements...", "fit redirect=None decimal=3");
	
	// d. sets name of thresholded image
	imagename_threshold = File.getNameWithoutExtension(getTitle()) + "_Thresholded.tif";


	// d. LOADS NESTED FUNCTION - 
	function Iterate_ALTRadius(Radius,ParticleSize,Algorithm,BlurVal,BackVal) { 
		
		// i. Duplicates the image
		run("Duplicate...", "title=&imagename_threshold");
		
		// ii. Blurs the image to de-noise it a bit (OPTIONAL):
		run("Gaussian Blur...", "sigma=BlurVal");
	
		// ii. Makes the image 8-bit
		run("8-bit");

		// iii. Runs CLAHE on the image (settings are left at default values)
		run("Enhance Local Contrast (CLAHE)", "blocksize=127 histogram=256 maximum=3 mask=*None* fast_(less_accurate)");
		
		if(BackVal == "Dark on Light"){
		// iv. Runs Auto Local Threshold with the radius and method that you inputted. 
		 if (Algorithm == "Bernsen") {
		run("Auto Local Threshold", "method=Bernsen radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Contrast") {
		run("Auto Local Threshold", "method=Contrast radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Mean") {
		run("Auto Local Threshold", "method=Mean radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Median") {
		run("Auto Local Threshold", "method=Median radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "MidGrey") {
		run("Auto Local Threshold", "method=MidGrey radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Niblack") {
		run("Auto Local Threshold", "method=Niblack radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Otsu") {
		run("Auto Local Threshold", "method=Otsu radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Phansalkar") {
		run("Auto Local Threshold", "method=Phansalkar radius=Radius parameter_1=0 parameter_2=0 white");
 		} else if (Algorithm == "Sauvola") {
		run("Auto Local Threshold", "method=Sauvola radius=Radius parameter_1=0 parameter_2=0 white");
 		} 
		}else {
			 if (Algorithm == "Bernsen") {
		run("Auto Local Threshold", "method=Bernsen radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Contrast") {
		run("Auto Local Threshold", "method=Contrast radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Mean") {
		run("Auto Local Threshold", "method=Mean radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Median") {
		run("Auto Local Threshold", "method=Median radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "MidGrey") {
		run("Auto Local Threshold", "method=MidGrey radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Niblack") {
		run("Auto Local Threshold", "method=Niblack radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Otsu") {
		run("Auto Local Threshold", "method=Otsu radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Phansalkar") {
		run("Auto Local Threshold", "method=Phansalkar radius=Radius parameter_1=0 parameter_2=0");
 		} else if (Algorithm == "Sauvola") {
		run("Auto Local Threshold", "method=Sauvola radius=Radius parameter_1=0 parameter_2=0");
 		}
		}
		// v. Generates ROIs and Results Table
		run("Analyze Particles...", "size=ParticleSize display exclude clear include add");

		// vi. Sets radius to "oops" if Analyze Particles didn't work
		if(roiManager("count") == 0){
			ALT_Radius = "oops";
		}
		
		// vii. If Analyze Particles DID work -
		//		Sets new thresholding radius to 1/2 of the average minor axis of the fit ellipse
		
		else {
		
		// vi. Forms Array of “Minor” column
		Minor_array = Table.getColumn("Minor", "Results");

		// vii. Gets statistics for “Minor” column
		Array.getStatistics(Minor_array, min, max, mean, stdDev);

		// viii. Sets our Auto Local Threshold Radius as 1/2 of the mean
		//     MEDIAN WOULD BE BETTER, BUT IMAGEJ CAN'T DO THAT (to my knowledge)
		ALT_Radius = mean/2;
		}

		return ALT_Radius;

		}

	its = 1;
	
	do {
	// e. RUNS NESTED FUNCTION - Applies initial radius, Determines better one
	Second_Radius = Iterate_ALTRadius(First_Radius,ROI_ParticleSize,Algorithm,BlurVal, BackVal);
	
	// j. Sets positive and negative thresholds for whether the function should be run for another iteration 
	//    (currently ±2%, can be changed)
	if_threshold_pos = 1.02 * First_Radius;
	if_threshold_neg = 0.98 * First_Radius;

	// f. If Iterate_AltRadius returned "oops", sets Final_Radius to "unsuccessful"
	if(Second_Radius == "oops") { 
		Final_Radius = "unsuccessful";

	}
	
	// g. If Iterate_ALTRadius returned a value within ±2% of the previous thresholding value, Sets Final_Radius to previous thresholding value 
	else if (Second_Radius < if_threshold_pos && Second_Radius > if_threshold_neg){
		Final_Radius = First_Radius;
		roiManager("Delete");
		close("results");
		
	}
	
	// h. If Iterate_ALTRadius is neither "oops" nor within ±2% of the previous thresholding value, runs the function again
	else {
		
		First_Radius = Second_Radius;
		
	// i. 1st, Clears ROI Manager, deletes results, closes previously thresholded image
	roiManager("Delete");
	close("results");
	close();
	Final_Radius = "na";
	its = its + 1;
	 }
	 } while (Final_Radius == "na" && its < 6); 
	 
	 if(Final_Radius == "na"){
	 	Second_Radius = Iterate_ALTRadius(First_Radius,ROI_ParticleSize,Algorithm,BlurVal, BackVal);
	 	Final_Radius = First_Radius;
	 }
	 
	 return Final_Radius;
}
	
	 
	 	   
// 2. Loads function to skeletonize and dilate that thresholded image 
function Skeleton_Dilate() { 
	run("Auto Threshold", "method=Default white");

	run("Skeletonize");
	run("Options...", "iterations=1 count=1 do=Dilate");
}
	     



	
// 3. Loads function to generate ROIs, then enlarge and interpolate them

function Generate_ROIset(ParticleSize, Interp) {
	
	// a. Loads nested function to generate the interpolation length for the image
	
		function Interp_Val(ParticleSize) { 

		// i. Set measurements to Area, set scale to pixels
		run("Set Measurements...", "area redirect=None decimal=3");
		run("Set Scale...", "distance=0 known=0 unit=pixel");
	
		// ii. Re-thresholds the image (just inverts the colors), so Fiji will recognize the correct parts
		run("Auto Threshold", "method=Default white");
	
		// iii. Analyze particles
		run("Analyze Particles...", "size=ParticleSize display exclude clear include add");
	
		// iv. If roimanager("count") = 0, return "unsuccessful"
		if(roiManager("count") == 0){
				ival = "unsuccessful";
			}	
		// v. If roimanager("count") > 0, continue code 
 		else {

		// vi. creates array of ROI area values
		Area_array = Table.getColumn("Area", "Results");

		// vii. Gets mean for Area values
		//     	MEDIAN WOULD BE BETTER, BUT IMAGEJ CAN'T DO THAT (to my knowledge)
		Array.getStatistics(Area_array, min, max, mean, stdDev);

		// viii. Calculates interpolation value with the mean area value
		ival = 0.03545 * sqrt(mean);
		}
		
		// ix. Returns interpolation value
		return ival;
		}
	
	// b. Runs Interp_Val to get the interpolation length for the ROIs
	ival = Interp_Val(ParticleSize);
	
	// c. IF ival = "unsuccessful", return "unsuccessful"
		if(ival == "unsuccessful"){
				ival = "unsuccessful";
			}	
	// d. ELSE continue to e.
 		else {
	
	// e. For each ROI:
	counts=roiManager("count");
	for(i=0; i<counts; i++) {
		
		// i. Selects 1 ROI
		roiManager("Select", i);
		
		// ii. Enlarges the ROI to get rid of inclusions due to skeleton branches
    	run("Enlarge...", "enlarge=4");
    	roiManager("Update");
    	
    	// iii. Shrinks the ROI boundary back to exactly the middle of the cell wall
    	run("Enlarge...", "enlarge=-3");
    	roiManager("Update");
    	
    	if (Interp == true) {

    	// iv. Interpolates the ROI boundary according to the length determined by Interp_Val
    	run("Interpolate", "interval=ival smooth");
    	roiManager("Update");
    	}
	}
}
close("Results");

	return ival;
}

// 4. Loads function to get results

function SetScale_Measure(Scale, Units, ParticleSize) { 

close("results");

run("Set Measurements...", "area perimeter bounding fit shape feret's redirect=None decimal=3");
run("Set Scale...", "distance=Scale known=1 unit=Units");

if(roiManager("count") == 0){
	run("Analyze Particles...", "size=ParticleSize display exclude clear include add");
}
if(roiManager("count") != 0){
	
	roiManager("Deselect");
	roiManager("Measure");
	
	IJ.renameResults("Results"); // otherwise below does not work...
for (row=0; row<nResults; row++) {
	Undulation = getResult("Perim.", row) / 
	(2 * PI * sqrt(getResult("Area", row)/PI));
    setResult("UI", row, Undulation);
}
updateResults();
}
}	



// 5. Window Pops up asking you what radius to start with and what ROI size bounds to apply.

methods = newArray("Sauvola", "Bernsen", "Contrast", "Mean", "Median", "MidGrey", "Niblack", "Otsu", "Phansalkar");
background = newArray("Dark on Light", "Light on Dark");
y_n = newArray("Yes", "No");
outputs = newArray("Thresholded and Skeletonized Image with ROIs and Results", "Thresholded and Skeletonized Image with ROIs", "Thresholded and Skeletonized Image", "Thresholded Image", "Skeletonized Image with ROIs and Results (previously thresholded)", "Skeletonized Image with ROIs (previously thresholded)", "Skeletonized Image (previously thresholded)", "ROIs and Results (previously skeletonized)", "ROIs (previously skeletonized)");
//, "4. Skeletonized Image with ROIs and Results (Previously Thresholded)", "5. ROIs and Results (Previously Skeletonized)"

Dialog.create("CuticleTrace - Single Image Processor");
Dialog.addMessage("IMPORTANT NOTES:");
	Dialog.addMessage("1. The 'Shape Smoothing' plugin from the biomedgroup update site is required to generate thresholded images.");
	Dialog.addMessage("2. When selecting a thresholding algorithm, beware of computationally intense algorithms (Otsu)! ");
	Dialog.addMessage("3. The initial thresholding radius is a place to start. It must be acceptable for the image, but does not have to be perfect.");
	Dialog.addMessage("4. The ROI size filter should cover the whole range of cell areas you expect in your image.");
	Dialog.addMessage("  ");
	Dialog.addChoice("DESIRED OUTPUTS:", outputs);
	Dialog.addMessage("  ");
	Dialog.addMessage("CUTICLETRACE INPUT PARAMETERS:");
	Dialog.addChoice("Cell Walls on Background:", background);
	Dialog.addNumber("Gaussian Blur Sigma (pixels):", 2);
	Dialog.addChoice("Thresholding Method:", methods);
	Dialog.addNumber("Initial Threshold Radius (pixels)", 50);
	Dialog.addString("ROI Size Filter (pixels^2)", "500-50000", 10);
	Dialog.addNumber("Smoothing Value (%FDs Retained):", 5);
	Dialog.addChoice("Interpolate ROIs?", y_n);
	Dialog.addNumber("Scale (Pixels/unit)", 0);
	Dialog.addString("Units", "um")
	
Dialog.show();
output = Dialog.getChoice();
BackVal = Dialog.getChoice();
BlurVal = Dialog.getNumber();
Algorithm = Dialog.getChoice();
First_Radius = Dialog.getNumber();
ROI_ParticleSize = Dialog.getString();
SmoothVal = Dialog.getNumber();
Interp = Dialog.getChoice();
Units = Dialog.getString();
Scale = Dialog.getNumber();


// 6. The image name is read in:
imagename = getTitle();
imagename_noext = File.getNameWithoutExtension(imagename);

// 7. The image is thresholded.
	if(matches(output, ".*Thresholded .*") > 0){
		// i. Run ROI_Scaled_ALT
		Rad = ROI_Scaled_ALT(First_Radius, ROI_ParticleSize, Algorithm, BlurVal, BackVal);
		
		// ii. Run the Shape smoothing plugin w/ specified %FDs
		run("Shape Smoothing", "relative_proportion_fds=SmoothVal absolute_number_fds=2 keep=[Relative_proportion of FDs] black");
		
		// iii. Prints the final thresholding radius to the log.
		print("Final " + Algorithm + " Thresholding Radius (pixels):  " + toString(Rad));	
										
		// iv. Closes ROI Manager
		close("RoiManager");
	}
		
// 8. The thresholded image is duplicated again (to be skeletonized)
	if(matches(output, ".*Skeletonized .*") > 0){
	  imagename_skel = imagename_noext + "_Skeletonized.tif";
	  run("Duplicate...", "title=&imagename_skel ");
		
// 9. The duplicated image is skeletonized

	  Skeleton_Dilate();
}
// 10. Enlarged + Interpolated ROIs are generated from the skeletonized image (If Make_ROIs = true)
if(matches(output, ".*ROIs.*") > 0){
ival = Generate_ROIset(ROI_ParticleSize, Interp);
		
	// a. Print  ROI interpolation length to the log.
	if (Interp == "Yes") {
	print("ROI Interpolation Length (pixels):  " + toString(ival));
	}		
		//xiii. IF The Generate Results Checkbox was clicked:
		if(matches(output, ".*Results.*") > 0){
			
			// Generate the correctly scaled results file
			SetScale_Measure(Scale, Units, ROI_ParticleSize);
			
			// Rename results
			resultsname = imagename_noext + "_Results.csv";
			IJ.renameResults(resultsname);
			
		}


// 11. ROIs are overlain on the original, unprocessed image

if (roiManager("count") > 0) {
	
	selectWindow(imagename);
	imagename_overlay = imagename_noext + "_Overlay.tif";
	run("Duplicate...", "title=&imagename_overlay ");


	roiManager("Deselect");

    roiManager("Set Line Width", 5);
	roiManager("Set Color", "#FFFF00");
	run("From ROI Manager");

	}
}

}


macro "CuticleTrace - Batch Measure (Different Scales)" {



// 1. Creates dialogue window to input necessary parameters
Dialog.create("CuticleTrace - Batch Measure (Different Scales)");
	Dialog.addMessage("Select CSV file to read from. Must have a column for image names and a column for scale. \n Each image MUST have a corresponding ROI set. ");
	Dialog.addFile("Select CSV", "/Image_Scales.csv")
	Dialog.addString("Name of File Names column", "File Name", 25);
	Dialog.addString("Name of Scale column", "Scale (pixels/um)", 25);
	Dialog.addDirectory("Image Directory", "/Images/")
	Dialog.addDirectory("ROI Set Directory", "/ROI_Sets/")
	//Dialog.addDirectory("Results Output Directory", "/Results_Files/")
Dialog.show();

csv = Dialog.getString();
file_column = Dialog.getString();
scale_column = Dialog.getString();
imagedir = Dialog.getString();
roidir = Dialog.getString();
//outputdir = Dialog.getString();

// 2. Create Output Directory
outputdir = File.getParent(imagedir) + "/Results_Files/";
	File.makeDirectory(outputdir);


// 2. Now that we have our inputs, we can get our arrays set up

open(csv);

filenames = Table.getColumn(file_column);
scale_list = Table.getColumn(scale_column);

// 3. For each image...

for (i = 0; i < lengthOf(filenames); i++) {

// 	a. Open Image and ROI set
open(imagedir + filenames[i]);
open(roidir + File.nameWithoutExtension + "_ROIset.zip");

// 	b. Set scale from the csv
Scale = scale_list[i];	
run("Set Measurements...", "area perimeter bounding fit shape feret's redirect=None decimal=3");
run("Set Scale...", "distance=Scale known=1 unit=um");	

// 	c. measure the ROIs	
roiManager("Deselect");
roiManager("Measure");
	
// 	d. add UI column to results
	IJ.renameResults("Results"); // otherwise below does not work...
for (row=0; row<nResults; row++) {
	Undulation = getResult("Perim.", row) / 
	(2 * PI * sqrt(getResult("Area", row)/PI));
    setResult("UI", row, Undulation);
}
updateResults();

// 	e. save results to output directory
saveAs("results", outputdir + File.getNameWithoutExtension(imagedir + filenames[i]) + "_Results.csv");

// 	f. close everything to make space for the next one.
close("Results");
roiManager("deselect");
roiManager("delete");
close("*");


}

} 

macro "CuticleTrace - Batch Overlay" {
// 1. Generates dialogue to input the directories of the ROI sets and Images.
Dialog.create("CuticleTrace - Batch Overlay");
Dialog.addMessage("IMPORTANT NOTE: Each ROIset's file name must start with the same name as its corresponding image.");
	Dialog.addMessage("For example, the ROIset for 'Image_01.jpg' must be named 'Image_01[...].zip'. ");
	Dialog.addMessage("CuticleTrace's default ROIset names all abide by this convention. They are:");
		Dialog.addMessage("		1. '[Image Filename]_ROIset.zip'");
		Dialog.addMessage("		2. '[Image Filename]_ROIset_FILTERED_1MAD.zip'");
		Dialog.addMessage("		3. '[Image Filename]_ROIset_FILTERED_2MAD.zip'");
	Dialog.addMessage("  ");



Dialog.addDirectory("Image Directory", "/path/")
Dialog.addDirectory("ROI set Directory", "/path/")
Dialog.addString("Name for Output Folder", "Images_with_Overlays", 25);
Dialog.addMessage(" ");

Dialog.addMessage("Image Preferences:");
Dialog.addString("Output Format", ".png");
Dialog.addNumber("Line Width (pixels)", "5");
Dialog.addString("Line Color (hex)", "#FFFF00", 10);
Dialog.addString("Fill Color (hex, 'None' for no fill)", "#2CFFFF00", 10);
Dialog.addCheckbox("Label ROIs?", true);
Dialog.addNumber("Label Font Size (if applicable)", 12);

Dialog.show();

imagesdir = Dialog.getString();
ROIsetsdir = Dialog.getString();
outputname = Dialog.getString();

format = Dialog.getString();
thickness = Dialog.getNumber();
color = Dialog.getString();
fillcolor = Dialog.getString();
label = Dialog.getCheckbox();
labsize = Dialog.getNumber();

images_filelist = getFileList(imagesdir);
ROIsets_filelist = getFileList(ROIsetsdir);

OutputDir = File.getParent(imagesdir) + "/" + outputname + "/";
File.makeDirectory(OutputDir);

// 2. For each image-ROI set combo, open them both, format the ROIset as an overlay on the image, and save the image.
for (i = 0; i < lengthOf(images_filelist); i++) {
    imagename = File.getNameWithoutExtension(images_filelist[i]);

    // Find the appropriate ROI set file by checking which file starts with the specified prefix
    var matchingROISetFile = "";
    for (j = 0; j < lengthOf(ROIsets_filelist); j++) {
        if (startsWith(ROIsets_filelist[j], imagename)) {
            matchingROISetFile = ROIsets_filelist[j];
            break;
        }
    }

    // Check if a matching ROI set file was found
    if (lengthOf(matchingROISetFile) > 0) {
        open(imagesdir + images_filelist[i]);
        open(ROIsetsdir + matchingROISetFile);

        if (roiManager("count") > 0) {
            roiManager("Deselect");

            if (fillcolor != "none" || fillcolor != "None") {
                roiManager("Set Fill Color", fillcolor);
                run("From ROI Manager");
            }

            roiManager("Set Line Width", thickness);
            roiManager("Set Color", color);
            run("From ROI Manager");

            if (label == true) {
                run("Labels...", "color=white font=14 show draw");
            }

            save(OutputDir + imagename + "_Overlay" + format);

            roiManager("deselect");
            roiManager("delete");
        }

        close("*");
    } else {
        // Handle the case when there is no corresponding ROI set
        print("No ROI set found for: " + imagename);
    }
}

}













