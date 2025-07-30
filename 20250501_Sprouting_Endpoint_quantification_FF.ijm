#@ String (visibility=MESSAGE, value="Parameters for batch processing", required=false) msg1

#@ File (label = "Input directory", style = "directory") 	input
#@ String (label = "File prefix", value = "") 				prefix
#@ String (label = "File extension", value = ".tif") 		suffix
#@ File (label = "Output directory", style = "directory") 	output


#@ String (visibility=MESSAGE, value="Define channels", required=false) msg2
#@ String (choices={"C1-", "C2-", "C3-", "C4-", ""}, style="listBox", value="") cell_channel
#@ String (choices={"C1-", "C2-", "C3-", "C4-", ""}, style="listBox", value="") nuclei_channel
#@ String (choices={"C1-", "C2-", "C3-", "C4-", ""}, style="listBox", value="") raw_channel
#@ File (label = "Cell pixel classifier", style = "file") classifier_path_cell
#@ File (label = "Nuclei pixel classifier", style = "file") classifier_path_nuclei
//#@ String (choices={"C1-", "C2-", "C3-", "C4-", ""}, style="listBox", value="") DNA_channel
#@ Integer (label ="Bead offset", style = "integer", default = "") 	beadoffset
#@ Integer (label ="Blur spatial", style = "integer") 	blur_xy


#@ boolean (label = "Manually remove segmentation artifacts and correct bead detection", style="tickBox") manual_bead_detection

#@ boolean (label = "Batch mode", style="tickBox") batch_mode


//parameters = newArray("cell_channel","ECM_channel","classifier_path_cell","classifier_path_ECM","beadoffset", "blur_temporal", "blur_xy", "NLC_size");
//values = newArray(cell_channel,classifier_path_cell,classifier_path_ECM,beadoffset,blur_temporal, blur_xy, NLC_size);
//Table.create("user_defined_input");
//Table.setColumn("Parameter", parameters);
//Table.setColumn("Value", values);
//Table.save(output+File.separator+"user_defined_input.csv");


if (File.exists(input)==true){
	processFolder(input);
	setBatchMode("show");
	close("*");
	run("Close All");
	run("Collect Garbage");
	showMessage("Finished!");
	
}else{
	print("The specified folder was not found");
}

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	print("Processng folder "+input);
	
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		
		if(File.isDirectory(input + File.separator + list[i]))
			print(i+"/"+list.length);
			processFolder(input + File.separator + list[i]);
		
		if( ((lengthOf(suffix) == 0) || ((lengthOf(suffix) >= 1) && endsWith(list[i], suffix))) && ((lengthOf(prefix) == 0) || ((lengthOf(prefix) >= 1) && startsWith(list[i], prefix))) ){
			print("file "+(i+1)+"/"+list.length+" "+list[i]);
			processFile(input, list[i]);	
		}
	}
}


function processFile(input, file){
	
	prefix_step = newArray(1);
	suffix_step = newArray(1);
	prefix_step[1] = "1_SIFT_"+cell_channel;
	prefix_step[2] = "2_actin_segmented_"+cell_channel;
	prefix_step[3] = "3_actin_segmented_primary_network"+cell_channel;
	prefix_step[4] = "4_bead_"+nuclei_channel;
	prefix_step[5] = "5_bead_dimensions"+nuclei_channel;
	prefix_step[6] = "6_skeleton_"+cell_channel;
	prefix_step[7] = "7_skeleton_analyzed_"+cell_channel;
	prefix_step[8] = "8_network_quantification_"+cell_channel;
	prefix_step[9] = "9_all_nuclei_"+nuclei_channel;
	prefix_step[10] = "10_all_nuclei_"+nuclei_channel;
	prefix_step[11] = "11_network_nuclei_"+nuclei_channel;
	prefix_step[12] = "12_network_nuclei_"+nuclei_channel;
	prefix_step[20] = "20_composit";
	
	suffix_step[1] = ".tiff";
	suffix_step[2] = ".tiff";
	suffix_step[3] = ".tiff";
	suffix_step[4] = ".tiff";
	suffix_step[5] = ".csv";
	suffix_step[6] = ".tiff";
	suffix_step[7] = ".tiff";
	suffix_step[8] = ".csv";
	suffix_step[9] = ".tiff";
	suffix_step[10] = ".csv";
	suffix_step[11] = ".tiff";
	suffix_step[12] = ".csv";
	suffix_step[20] = ".tiff";
	
	close("*");
	//print(input+File.separator+file);
	
	filename = File.getName(file);	
	basename = substring(filename, 0, lengthOf(filename)-lengthOf(suffix));
	output_i = output+File.separator+basename;
	create_directory(output_i);
	 
	// analyze branches based on actin/best focus phase-contrast
	if (cell_channel != ""){
		
		// Segment actin with classifier

		if (output_exist(prefix_step[2], suffix_step[2])==false)
		{
			open(input+File.separator+filename);
			saveAs("Tiff", output_i+File.separator+prefix_step[1]+basename+suffix_step[1]);
			
			getDimensions(width, height, channels, slices, frames);
			rename(filename);
			run("Split Channels");
			
			selectImage(cell_channel+filename);
			run("Segment Image With Labkit", "segmenter_file=["+classifier_path_cell+"] use_gpu=false");
			selectImage("segmentation of "+cell_channel+filename);
			
			run("Threshold...");
			setThreshold(1, 255);
			setOption("BlackBackground", true);
			run("Convert to Mask", "background=Dark black");
			
			saveAs("Tiff", output_i+File.separator+prefix_step[2]+basename+suffix_step[2]);
			close("*");
			run("Collect Garbage");
		}else{print("Found "+prefix_step[2]);}
		
		
		// Remove other networks or artifacts 
		if (output_exist(prefix_step[3], suffix_step[3])==false)
		{
			open(output_i+File.separator+prefix_step[2]+basename+suffix_step[2]);
			//run("Fill Holes", "stack");
			//run("Threshold...");
			//setThreshold(1, 255);
			//setOption("BlackBackground", true);
			//run("Convert to Mask", "stack");

			//find_largest_object();
			//setForegroundColor(255, 255, 255);
			//setBackgroundColor(0, 0, 0);
			//run("Clear Outside", "slice");
			//roiManager("reset");
			
			run("Select None");
			
			if (manual_bead_detection==true){
				setTool("oval");
				setForegroundColor(0, 0, 0);
				if (batch_mode==true){
					setBatchMode("show");
				}
				
				waitForUser("Remove segmentation artifacts and second beads (if present), correct bead detection and click OK when done");
				if (batch_mode==true){
					setBatchMode("hide");
				}
				saveAs("Tiff", output_i+File.separator+prefix_step[3]+basename+suffix_step[3]);
			}
			close("*");
			run("Collect Garbage");
			
			
		}else{print("Found "+prefix_step[3]);}
		
		if (nuclei_channel!= ""){		
		if (output_exist(prefix_step[9], suffix_step[9])==false)
		{
			open(input+File.separator+filename);
			rename(filename);
			run("Split Channels");
			
			selectImage(nuclei_channel+filename);
			run("Segment Image With Labkit", "segmenter_file=["+classifier_path_nuclei+"] use_gpu=false");
			selectImage("segmentation of "+nuclei_channel+filename);
			run("Threshold...");
			setThreshold(1, 255);
			setOption("BlackBackground", true);
			run("Convert to Mask", "background=Dark black");
			rename("nuclei");
			run("Watershed");
			
			open(output_i+File.separator+prefix_step[3]+basename+suffix_step[3]);
			rename("network");
			imageCalculator("AND", "nuclei","network");
			selectWindow("nuclei");
			run("Set Measurements...", "area center perimeter bounding shape area_fraction redirect=None decimal=3");
			run("Analyze Particles...", "size=20-Infinity display add");
			saveAs("Results", output_i+File.separator+prefix_step[10]+basename+suffix_step[10]);		
			saveAs("Tiff", output_i+File.separator+prefix_step[9]+basename+suffix_step[9]);
			close("*");
			run("Collect Garbage");
			
		}else{print("Found "+prefix_step[11]);}
	}else{quit("Nuclei channel not chosen!");}
	
			// detect the bead
		if (output_exist(prefix_step[4], suffix_step[4])==false)
		{
			open(output_i+File.separator+prefix_step[9]+basename+suffix_step[9]);
			// Step 1: Convert the binary image to a distance map
			
			run("Dilate", "stack");
			run("Fill Holes", "stack");
			run("Options...", "iterations=13 count=1 black do=Erode");

			find_largest_object();
			setForegroundColor(255, 255, 255);
			setBackgroundColor(0, 0, 0);
			run("Clear Outside", "slice");
			roiManager("reset");
			
			run("Select None");
			
			run("Options...", "iterations=2 count=1 black do=Erode");
			wait(1000);
			find_largest_object();
			if (selectionType() != -1) {
 				   run("Distance Map");

	 		   // Step 2: Find the maximum value and its location in the distance map
			    run("Find Maxima...", "prominence=1 output=[Point Selection]");
			    getSelectionCoordinates(x, y);
			    x_center = x[0];
			    y_center = y[0];
			
			    // Step 3: Get the maximum distance value, which will be the radius of the circle
			    maxValue = getPixel(x_center, y_center);
			 
		        // Step 4: Draw the largest circle inside the object
		        makeOval(x_center - maxValue, y_center - maxValue, 2 * maxValue, 2 * maxValue);
		        run("Enlarge...", "enlarge=7");
		        wait(1000);
	
		} else {
		    print("Did not detect bead for " + file + ", skipping");
		}
			if (manual_bead_detection==true){
				setTool("oval");
				setForegroundColor(0, 0, 0);
				if (batch_mode==true){
					setBatchMode("show");
				}
				
			open(output_i+File.separator+prefix_step[1]+basename+suffix_step[1]);
			
			rename(filename);
			run("Split Channels");
			
			selectImage(raw_channel+filename);
				
			waitForUser("Remove segmentation artifacts and second beads (if present), correct bead detection and click OK when done");
			if (batch_mode==true){
					setBatchMode("hide");
				}
				//saveAs("Tiff", output_i+File.separator+prefix_step[4]+basename+suffix_step[4]);
			}
			
			//run("Options...", "iterations=30 count=1 black do=Erode");
			//waitForUser("Eroded the binary");
			//run("Fill Holes", "stack");
			//run("Duplicate...", "title=bead");
			//run("Dilate");
			//run("Options...", "iterations=50 count=1 black do=Close");

			//find_largest_object();
			//if (selectionType() != -1) {
			//   waitForUser("Found a selection");
			//    run("Fit Circle");
			//	run("Enlarge...", "enlarge=30");
			//	waitForUser("Fit and enlarged binary");
			//} else {
			//	return;
			//}
			setForegroundColor(255, 255, 255);
			run("Fill", "slice");
			run("Make Inverse");
			setForegroundColor(0, 0, 0);
			run("Fill", "slice");
			setForegroundColor(255, 255, 255);
			run("Select None");
			roiManager("reset");
			run("Threshold...");
			setThreshold(1, 255);
			setOption("BlackBackground", true);
			run("Convert to Mask", "background=Dark black");
			saveAs("Tiff", output_i+File.separator+prefix_step[4]+basename+suffix_step[4]);
			close("*");
			run("Collect Garbage");
		
		}else{print("Found "+prefix_step[4]);}
		
		// measure bead dimensions
		if (output_exist(prefix_step[5], suffix_step[5])==false)
		{			
			open(output_i+File.separator+prefix_step[4]+basename+suffix_step[4]);
			roiManager("reset");
			run("Clear Results");
			run("Set Measurements...", "area center perimeter bounding area_fraction redirect=None decimal=3");
			run("Analyze Particles...", "display");
			
			saveAs("Results", output_i+File.separator+prefix_step[5]+basename+suffix_step[5]);
			run("Clear Results");
			roiManager("reset");

		}else{print("Found "+prefix_step[5]);}
		
		// skeletonize
		if (output_exist(prefix_step[6], suffix_step[6])==false)
		{
			open(output_i+File.separator+prefix_step[4]+basename+suffix_step[4]);
			//run("Options...", "iterations="+(beadoffset)+" count=1 black do=Dilate");
			rename("bead");
			beadID = getImageID();
			open(output_i+File.separator+prefix_step[3]+basename+suffix_step[3]);
			//run("Maximum 3D...", "x=0 y=0 z="+blur_temporal);
			run("Select None");
			
			run("Options...", "iterations="+blur_xy+" count=4 black do=Close");
			
			run("Median...", "radius="+blur_xy+" stack");
			rename("network");
			run("Skeletonize", "stack");
			
			imageCalculator("Subtract stack", "network", "bead");
			selectWindow("network");
			
			selectImage(beadID);
			run("Close");
			
			open(output_i+File.separator+prefix_step[4]+basename+suffix_step[4]);
			rename("bead");
			run("Options...", "iterations="+(20+beadoffset)+" count=1 black do=Erode");
			imageCalculator("Subtract stack", "network", "bead");
			saveAs("Tiff", output_i+File.separator+prefix_step[6]+basename+suffix_step[6]);
			close("*");
			run("Collect Garbage");

		}else{print("Found "+prefix_step[6]);}
		
		// analyze skeleton
		if (output_exist(prefix_step[7], suffix_step[7])==false)
		{
			open(output_i+File.separator+prefix_step[6]+basename+suffix_step[6]);
			getDimensions(width, height, channels, slices, frames);
			if (slices>frames){
				run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
				getDimensions(width, height, channels, slices, frames);
			}
			
			analyze_skeleton();
			
			selectWindow("skeleton_analyzed");
			saveAs("Tiff", output_i+File.separator+prefix_step[7]+basename+suffix_step[7]);
			close("*");
			run("Collect Garbage");
		}else{print("Found "+prefix_step[7]);}
	}else{quit("Actin channel not chosen!");}
	
	if (nuclei_channel!= ""){		
		if (output_exist(prefix_step[11], suffix_step[11])==false)
		{
			open(input+File.separator+filename);
			rename(filename);
			run("Split Channels");
			
			selectImage(nuclei_channel+filename);
			run("Segment Image With Labkit", "segmenter_file=["+classifier_path_nuclei+"] use_gpu=false");
			selectImage("segmentation of "+nuclei_channel+filename);
			run("Threshold...");
			setThreshold(1, 255);
			setOption("BlackBackground", true);
			run("Convert to Mask", "background=Dark black");
			rename("nuclei");
			open(output_i+File.separator+prefix_step[3]+basename+suffix_step[3]);
			rename("network");
			imageCalculator("AND", "nuclei","network");
			rename("network2");
			open(output_i+File.separator+prefix_step[4]+basename+suffix_step[4]);
			rename("bead2");
			imageCalculator("substract","network2", "bead2");
			run("Watershed");
			run("Set Measurements...", "area center perimeter bounding shape area_fraction redirect=None decimal=3");
			run("Analyze Particles...", "size=20-Infinity display add");
			saveAs("Results", output_i+File.separator+prefix_step[12]+basename+suffix_step[12]);
			
			saveAs("Tiff", output_i+File.separator+prefix_step[11]+basename+suffix_step[11]);
			close("*");
			run("Collect Garbage");
			
		}else{print("Found "+prefix_step[11]);}
	}else{quit("Nuclei channel not chosen!");}
	//saveAs("Tiff", output_i+File.separator+imagename);

	if (output_exist(prefix_step[20], suffix_step[20])==false){
		close("*");
		run("Close All");
		
		open(output_i+File.separator+prefix_step[1]+basename+suffix_step[1]);
		rename("raw");
		run("Enhance Contrast...", "saturated=0.35");
		run("Split Channels");
		
		open(output_i+File.separator+prefix_step[4]+basename+suffix_step[4]);
		rename("bead");
		run("Outline");
		
		open(output_i+File.separator+prefix_step[7]+basename+suffix_step[7]);
		rename("skeleton");
		run("glasbey_on_dark");
		run("Maximum...", "radius=1");
		open(output_i+File.separator+prefix_step[9]+basename+suffix_step[9]);
		rename("nuclei");
		run("Outline");	
		// Get the list of all open image titles
		imageTitles = getList("image.titles");
		
		// Check if at least two images are open
		if (lengthOf(imageTitles) < 2) {
		    exit("You need at least two images open to merge channels.");
		}
		
		// Prepare a string with all image titles for merging
		channels = "";
		for (i = 0; i < lengthOf(imageTitles); i++) {
		    channels += "c" + (i + 1) + "=" + imageTitles[i];
		    if (i < lengthOf(imageTitles) - 1) {
		        channels += " "; // Add a space between channel assignments
		    }
		}
		
		// Perform the merge channels operation
		run("Merge Channels...", channels+" create");
	
		saveAs("Tiff", output_i+File.separator+prefix_step[20]+basename+suffix_step[20]);
		close("*");
		run("Collect Garbage");
	}
}


}

//#@ File (label = "path", style = "directory") path
//#@ File (label = "filename", style = "file") filename


function analyze_skeleton(){
			// Create arrays to store columns and concatenate each iteration underneath previous ones
	run("Clear Results");
	roiManager("reset");
	
	parent_skeleton = newArray(0);
	branch_length = newArray(0);
	v1x = newArray(0);
	v1y = newArray(0);
	v2x = newArray(0);
	v2y = newArray(0);
	s_euclidian = newArray(0);
	s_run_average = newArray(0);
	timepoint = newArray(0);
	Tidy_table_length = 0;

	
	skeleton_ID= getImageID();
	
	getDimensions(width, height, channels, slices, frames);
	for (i = 1; i < frames+1; i++){
		selectImage(skeleton_ID);
		setSlice(i);
		run("Duplicate...", "use");
		run("Analyze Skeleton (2D/3D)", "prune=none show");
		
		selectWindow("Branch information");
		// Iterate through results table, adding each column's data underneath existing rows of the arrays
		for (iii = 0; iii < Table.size; iii++) {
		    parent_skeleton[iii+Tidy_table_length] = Table.get("Skeleton ID", iii);
		    branch_length[iii+Tidy_table_length] = Table.get("Branch length", iii);
		    v1x[iii+Tidy_table_length] = Table.get("V1 x", iii);
		    v1y[iii+Tidy_table_length] = Table.get("V1 y", iii);
			v2x[iii+Tidy_table_length] = Table.get("V2 x", iii);
			v2y[iii+Tidy_table_length] = Table.get("V2 y", iii);
			s_euclidian[iii+Tidy_table_length] = Table.get("Euclidian distance", iii);
			s_run_average[iii+Tidy_table_length] = Table.get("running average length", iii);
			timepoint[iii+Tidy_table_length] = i;
		}
		Tidy_table_length += Table.size();
		selectWindow("Tagged skeleton");
		rename("tagged_"+i);
	}
	run("Images to Stack", "name=skeleton_analyzed title=tagged_");
	
	Table.create("tidy_branches_results");
	Table.setColumn("parent_skeleton", parent_skeleton);
	Table.setColumn("branch_length", branch_length);
	Table.setColumn("v1x", v1x);
	Table.setColumn("v1y", v1y);
	Table.setColumn("v2x", v2x);
	Table.setColumn("v2y", v2y);
	Table.setColumn("s_euclidian", s_euclidian);
	Table.setColumn("s_run_average", s_run_average);
	Table.setColumn("timepoint", timepoint);
	selectWindow("tidy_branches_results");
	Table.save(output_i+File.separator+prefix_step[8]+basename+suffix_step[8]);
	
	selectWindow("tidy_branches_results");
	run("Close");
	selectWindow("Branch information");
	run("Close");
	run("Clear Results");
}


function find_largest_object(){
	
	run("Select None");
	run("Clear Results");
	roiManager("reset");
	run("Set Measurements...", "area redirect=None decimal=3");
	run("Analyze Particles...", "display add slice");
	if (roiManager("count") > 0){
		// Finding the result with the largest area
		largest_area = 0;
		largest_index = 0;
		n = roiManager("count");
		for(ii=0; ii < n; ii++){
			i_area = getResult("Area", ii);
			if (largest_area <= i_area){
				roiManager("Select", ii);
				largest_area = i_area;
				largest_index = ii;
			}
		}
	}else{
		print("could not find any object");
	}
}

function output_exist(prefix, suffix){
	
	if (File.exists(output_i+File.separator+prefix+basename+suffix)==true){
		return true;
	}else{
		return false;
	}
	
}


function create_directory(dir_var){
	if (!File.exists(dir_var)){
		File.makeDirectory(dir_var);
		if (File.exists(dir_var)){
			print("Created directory: "+dir_var);
		}else{
			print("Failed to create directory: "+dir_var);
			exit;
		}
	}
}

function quit(message){
	showMessage(message);
	close("*");
	run("Close All");
	run("Collect Garbage");
	exit;
}

	
