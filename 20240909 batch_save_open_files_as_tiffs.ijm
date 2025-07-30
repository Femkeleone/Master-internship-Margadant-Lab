#@ File (label = "Output directory", style = "directory") output
#@ String (value="", required=true) prefix
#@ String (value="", required=true) suffix

print("Output directory: " + output);

prefix_length = lengthOf(prefix);
suffix_length = lengthOf(suffix);


image_list = getList("image.titles");

if (image_list.length >= 1){
    print("There are " + image_list.length + " image(s) open");

    for (i = 0; i < image_list.length; i++) {
        filename = image_list[i];
        //print("Original filename: " + filename);
        new_name = substring(filename, prefix_length, (lengthOf(filename) - suffix_length));
        
        print((i+1) + "/" + image_list.length + ":"+  new_name);
        selectWindow(filename);
			
        // Adjust how new_name is derived
        
        print("Saving as: " + output + "/" + new_name + ".tif");
        
        // Save the image, use forward slash for the file path and quote it
		saveAs("Tiff", output + File.separator + new_name + ".tif");
        run("Close");;
    }
} else {
    print("There are no images open");
}
