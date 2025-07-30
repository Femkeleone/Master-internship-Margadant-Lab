#@ String (visibility=MESSAGE, value="Parameters for batch processing", required=false) msg1

#@ File (label = "Input directory", style = "directory") 	input

#@ String (visibility=MESSAGE, value="Find files containing the following character strings (leave empty to open all files in directory)", required=false) msg2
#@ String (label = "Find file with prefix", value = "") 				prefix
#@ String (label = "Find file with suffix", value = ".tif") 			suffix

#@ String (visibility=MESSAGE, value="-----------------------------", required=false) msg3
#@ String (visibility=MESSAGE, value="Output directory", required=false) msg4
#@ File (label = "Output directory", style = "directory") 	output

#@ String (visibility=MESSAGE, value="Choose for a max of 5 output channels which of the input (C1-, C2-, etc.) to use", required=false) msg5

#@ String (value="", description="Name of Channel 1") name_for_Channel_1
#@ String (choices={"C1-", "C2-", "C3-", "C4-", "C5-", ""}, style="listBox", value="") Input_for_Channel_1

#@ String (value="", description="Name of Channel 2") name_for_Channel_2
#@ String (choices={"C1-", "C2-", "C3-", "C4-", "C5-", ""}, style="listBox", value="") Input_for_Channel_2

#@ String (value="", description="Name of Channel 3") name_for_Channel_3
#@ String (choices={"C1-", "C2-", "C3-", "C4-", "C5-", ""}, style="listBox", value="") Input_for_Channel_3

#@ String (value="", description="Name of Channel 4") name_for_Channel_4
#@ String (choices={"C1-", "C2-", "C3-", "C4-", "C5-", ""}, style="listBox", value="") Input_for_Channel_4

#@ String (value="", description="Name of Channel 5") name_for_Channel_5
#@ String (choices={"C1-", "C2-", "C3-", "C4-", "C5-", ""}, style="listBox", value="") Input_for_Channel_5


n_channels_to_make = howManyChannels();

print("Number of channels to project= "+n_channels_to_make);


if (Input_for_Channel_1!=""){
	Input_for_Channel_1_mode = getMode("Settings to project channel 1: ", name_for_Channel_1);
} 
if (Input_for_Channel_2!=""){
	Input_for_Channel_2_mode = getMode("Settings to project channel 2: ", name_for_Channel_2);
}
if (Input_for_Channel_3!=""){
	Input_for_Channel_3_mode = getMode("Settings to project channel 3: ", name_for_Channel_3);
}
if (Input_for_Channel_4!=""){
	Input_for_Channel_4_mode = getMode("Settings to project channel 4: ", name_for_Channel_4);
}
if (Input_for_Channel_5!=""){
	Input_for_Channel_5_mode = getMode("Settings to project channel 5: ", name_for_Channel_5);
}


function getMode(message, channel_name){
	
	options = newArray("_Max Intensity", "_Sum Slices", "_Single slice", "_Stack focusser", "_ECM granule enhancer", "_Min Intensity",  "_Standard Deviation", "_Median");
	Dialog.create("Choose projection type");
	Dialog.addMessage(message+channel_name);
	
	Dialog.addChoice("_select_mode:", options, "Max Intensity");
	Dialog.addCheckbox("Keep single slice as additionalchannel_name channel", false);
	Dialog.addNumber("_optional z-slice:", 1);
	Dialog.addCheckbox("Despeckle", false);
	Dialog.addCheckbox("Subtract background", false);
	Dialog.addCheckbox("Enhance contrast", false);
	Dialog.show();
	
	keep_original = false;
	mode = Dialog.getChoice();	
	mode = substring(mode, 1, lengthOf(mode));
	keep_original = Dialog.getCheckbox();
	integer = Dialog.getNumber();
	despeckle = Dialog.getCheckbox();
	subtract_background = Dialog.getCheckbox();
	enhance = Dialog.getCheckbox();
    if (mode == "ECM granule enhancer"){
    	
    	Dialog.create("Granule size");
	    Dialog.addNumber("Pixels:", 1);
	    Dialog.show();
	    granule_size = Dialog.getNumber();
	    print("Granule size selected ="+granule_size+" pixel");
	    
    }else{
    	granule_size = 0;
    }

	return newArray(mode, integer, keep_original, granule_size, enhance, subtract_background);
	
}


function processFile(input, file) {
	
	filename = File.getName(file);
	close("*");
	open(input+File.separator+filename);

	image_list = getList("image.titles");
	current_image = image_list[0];	
	current_image_basename = substring(current_image, 0, lengthOf(current_image)-lengthOf(suffix));
	
	selectImage(current_image);
	getDimensions(width, height, channels, slices, frames);
	if (channels>=2){
		run("Split Channels");
	}
	
	channels_to_merge = "";
	
	if (Input_for_Channel_1!=""){
		project("Input_for_Channel_1", Input_for_Channel_1, Input_for_Channel_1_mode[0], Input_for_Channel_1_mode[1], Input_for_Channel_1_mode[2], Input_for_Channel_1_mode[3], Input_for_Channel_1_mode[4], Input_for_Channel_1_mode[5]);
		channels_to_merge = channels_to_merge+"c1=[Input_for_Channel_1] ";
		
		if(Input_for_Channel_1_mode[2]==true){
			n_channels_to_make = n_channels_to_make+1;
			channels_to_merge = channels_to_merge+"c"+n_channels_to_make+"=["+Input_for_Channel_1+"RAW] ";
		}
	} 

	if (Input_for_Channel_2!=""){
		project("Input_for_Channel_2", Input_for_Channel_2, Input_for_Channel_2_mode[0], Input_for_Channel_2_mode[1], Input_for_Channel_2_mode[2], Input_for_Channel_2_mode[3], Input_for_Channel_2_mode[4], Input_for_Channel_2_mode[5]);
		channels_to_merge = channels_to_merge+"c2=[Input_for_Channel_2] ";
		
		if(Input_for_Channel_2_mode[2]==true){
			n_channels_to_make = n_channels_to_make+1;
			channels_to_merge = channels_to_merge+"c"+n_channels_to_make+"=["+Input_for_Channel_2+"RAW] ";
		}
	}
	
	if (Input_for_Channel_3!=""){
		project("Input_for_Channel_3", Input_for_Channel_3, Input_for_Channel_3_mode[0], Input_for_Channel_3_mode[1], Input_for_Channel_3_mode[2], Input_for_Channel_3_mode[3], Input_for_Channel_3_mode[4], Input_for_Channel_3_mode[5]);
		channels_to_merge = channels_to_merge+"c3=[Input_for_Channel_3] ";
		
		if(Input_for_Channel_3_mode[2]==true){
			n_channels_to_make = n_channels_to_make+1;
			channels_to_merge = channels_to_merge+"c"+n_channels_to_make+"=["+Input_for_Channel_3+"RAW] ";
		}
	}

	if (Input_for_Channel_4!=""){
		project("Input_for_Channel_4", Input_for_Channel_4, Input_for_Channel_4_mode[0], Input_for_Channel_4_mode[1], Input_for_Channel_4_mode[2], Input_for_Channel_4_mode[3], Input_for_Channel_4_mode[4], Input_for_Channel_4_mode[5]);
		channels_to_merge = channels_to_merge+"c4=[Input_for_Channel_4] ";
	
		if(Input_for_Channel_4_mode[2]==true){
			n_channels_to_make = n_channels_to_make+1;
			channels_to_merge = channels_to_merge+"c"+n_channels_to_make+"=["+Input_for_Channel_4+"RAW] ";
		}
	}
	
	if (Input_for_Channel_5!=""){
		project("Input_for_Channel_5", Input_for_Channel_5, Input_for_Channel_5_mode[0], Input_for_Channel_5_mode[1], Input_for_Channel_5_mode[2], Input_for_Channel_5_mode[3], Input_for_Channel_5_mode[4], Input_for_Channel_5_mode[5]);
		channels_to_merge = channels_to_merge+"c5=[Input_for_Channel_5] ";
		
		if(Input_for_Channel_5_mode[2]==true){
			n_channels_to_make = n_channels_to_make+1;
			channels_to_merge = channels_to_merge+"c"+n_channels_to_make+"=["+Input_for_Channel_5+"RAW] ";
		}
	}

	if (channels>=2){
		run("Merge Channels...", channels_to_merge+"create");
	}
	Property.set("CompositeProjection", "null");
	Stack.setDisplayMode("grayscale");
	saveAs("Tiff", output+File.separator+"stacked_"+filename);
	close("*");
	run("Close All");
	run("Collect Garbage");

}

function project(type, channel, mode, slice, keep, granule_size, enhances, subtract_background){
	
	if (channels>=2){
		selectImage(channel+current_image);
	}else{
		selectImage(current_image);
	}
	
	if (enhances == true){
		run("Enhance Contrast...", "saturated=0.35 normalize process_all");
	}
	
	if (subtract_background == true){
		run("Subtract Background...", "rolling=150 stack");
	}
	
	if(keep==true){
		
		run("Duplicate...", "duplicate slices="+slice+" title="+channel+"RAW");
		run("8-bit");
		if (channels>=2){
			selectImage(channel+current_image);
		}else{
			selectImage(current_image);
		}
		
	}
	
	if (mode=="ECM granule enhancer"){
		run("Normalize Local Contrast", "block_radius_x="+granule_size+" block_radius_y="+granule_size+" standard_deviations=3 center stretch stack");
		run("Z Project...", "projection=[Sum Slices] all");
		run("8-bit");
		run("Normalize Local Contrast", "block_radius_x="+granule_size+" block_radius_y="+granule_size+" standard_deviations=3 center stretch stack");
		rename(type);
	}
	
	if (mode=="Single slice"){
		run("Duplicate...", "duplicate slices="+slice);
		run("8-bit");
		rename(type);
	}
	
	if (mode=="Stack focusser"){
		run("Find Edges", "stack");
		run("Z Project...", "projection=[Max Intensity] all");
		run("8-bit");
		rename(type);
	}
	
	if ((mode!="Single slice")&&(mode!="Stack focusser")&&(mode!="ECM granule enhancer")){
		run("Z Project...", "projection=["+mode+"] all");
		run("8-bit");
		rename(type);

	}
	
	if (channels>=2){
		selectImage(channel+current_image);
	}else{
		selectImage(current_image);
	}
	//close();
}

function howManyChannels(){
	count = 0;
	if (Input_for_Channel_1!=""){
		count = count+1;
	} 
	if (Input_for_Channel_2!=""){
		count = count+1;
	}
	if (Input_for_Channel_3!=""){
		count = count+1;
	}
	if (Input_for_Channel_4!=""){
		count = count+1;
	}
	if (Input_for_Channel_5!=""){
		count = count+1;
	}
	return count;
}



if (File.exists(input)==true){	
	close("*");
	run("Close All");
	run("Collect Garbage");
	processFolder(input);
}else{
	print("The specified folder was not found");
}

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {

	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			print((i+1)+"/"+list.length);
			processFolder(input + File.separator + list[i]);
		if( ((lengthOf(suffix) == 0) || ((lengthOf(suffix) >= 1) && endsWith(list[i], suffix))) && ((lengthOf(prefix) == 0) || ((lengthOf(prefix) >= 1) && startsWith(list[i], prefix))) ){
			print((i+1)+"/"+list.length);
			processFile(input, list[i]);	
		}
	}
}