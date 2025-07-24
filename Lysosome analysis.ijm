// === Step 1: Open Image File ===
open();  // Prompt user to open the image
fileName = getTitle();  // Get the title of the opened image

// === Step 2: Set Save Directory ===
// Prompt user to select the save directory
saveDirectory = getDirectory("choose");  // Use "choose" to prompt user for a folder

// === Step 3: Create Nuclear Mask ===
run("Split Channels");

// Select nuclear channel (C1) and threshold it
selectImage("C1-" + fileName);
setAutoThreshold("Default dark");
setThreshold(30, 255, "raw");
run("Convert to Mask");
saveAs("Tiff", saveDirectory + "/nuclear_mask.tif");

// === Step 3.1: Analyze Nuclear Mask (Particle Counting) and Create Filtered Mask ===
selectImage("nuclear_mask.tif");
run("Analyze Particles...", "size=30-Infinity circularity=0-1.00 show=Nothing display clear add");

// Create new mask from valid nuclei only
roiManager("Deselect");
roiManager("Combine");
run("Create Mask");

// Dynamically get and rename the new mask image
newMaskTitle = getTitle();
selectImage(newMaskTitle);
rename("filtered_nuclear_mask");
saveAs("Tiff", saveDirectory + "/filtered_nuclear_mask.tif");

// Save nuclear analysis results
saveAs("Results", saveDirectory + "/Table_nuclei.csv");
run("Clear Results");

// === Step 4: Dilate Filtered Nuclear Mask by 5 µm ===
selectImage("filtered_nuclear_mask.tif");
getPixelSize(unit, pixelWidth, pixelHeight, voxelDepth);
pixelsPerMicron = 1 / pixelWidth;
dilationRadius = 5 * pixelsPerMicron;

print("Pixel size: " + pixelWidth + " " + unit);
print("Dilation radius for 5 µm: " + dilationRadius + " pixels");

run("Morphological Filters", "operation=Dilation element=Disk radius=" + dilationRadius);
rename("nuclearmask_Dilation5um");
selectImage("nuclearmask_Dilation5um");
run("Analyze Particles...", "size=30-Infinity circularity=0.60-1.00 show=Nothing display clear add");
saveAs("Tiff", saveDirectory + "/nuclearmask_Dilation5um.tif");

// === Step 5: Create Lysosome Mask ===
selectImage("C2-" + fileName);
run("Enhance Contrast...", "saturated=0.35");
setThreshold(60, 255);
run("Convert to Mask");
saveAs("Tiff", saveDirectory + "/lysosome_mask.tif");

// === Step 6: Count Total Lysosomes ===
selectImage("lysosome_mask.tif");
run("Analyze Particles...", "size=0.1-2 circularity=0.10-5.00 display add");
saveAs("Results", saveDirectory + "/Table_total_lysosomes.csv");
run("Clear Results");

// === Step 7: Subtract Dilated Nuclear Mask from Lysosome Mask (Nonperinuclear Lysosomes) ===
selectImage("lysosome_mask.tif");
imageCalculator("Subtract create", "lysosome_mask.tif", "nuclearmask_Dilation5um.tif");
selectImage("Result of lysosome_mask.tif");
rename("nonperinuclear_lysosome_mask");
saveAs("Tiff", saveDirectory + "/nonperinuclear_lysosome_mask.tif");

// Analyze nonperinuclear lysosomes
run("Analyze Particles...", "size=0.1-2 circularity=0.10-5.00 display add");
saveAs("Results", saveDirectory + "/Table_nonperinuclear_lysosomes.csv");
run("Clear Results");

// === Step 8: Subtract nonperinuclear Lysosomes from Total (Perinuclear Lysosomes) ===
selectImage("lysosome_mask.tif");
imageCalculator("Subtract create", "lysosome_mask.tif", "nonperinuclear_lysosome_mask.tif");
selectImage("Result of lysosome_mask.tif");
rename("perinuclear_lysosome_mask");
saveAs("Tiff", saveDirectory + "/perinuclear_lysosome_mask.tif");

// Analyze perinuclear lysosomes
run("Analyze Particles...", "size=0.1-2 circularity=0.10-5.00 display add");
saveAs("Results", saveDirectory + "/Table_perinuclear_lysosomes.csv");
run("Clear Results");

// === Step 9: Close All Open Images and Tables ===
run("Close All");
