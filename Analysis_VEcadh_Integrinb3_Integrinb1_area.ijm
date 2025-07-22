// Kies inputmap
dir = getDirectory("Kies de map met afbeeldingen");

// Outputmap voor masks
outputMaskDir = dir + "Masks/";
File.makeDirectory(outputMaskDir);

// Pad naar CSV-bestand
resultsPath = dir + "Signaal_Oppervlakte.csv";

// Zet de kopregel (alleen één keer aan begin)
File.saveString("Bestandsnaam,Signaal_pixels\n", resultsPath);

// Bestandlijst ophalen
list = getFileList(dir);

for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff")) {
        open(dir + list[i]);
        title = getTitle();

        // 8-bit conversie
        run("8-bit");

        // Drempel toepassen
        setAutoThreshold("Otsu dark"); // eventueel "Triangle dark"
        run("Convert to Mask");

        // Mask dupliceren om op te slaan
        run("Duplicate...", "title=Mask");

        // Tellen van witte pixels (255 = signaal)
        getRawStatistics(area, mean, min, max, std, histogram);
        signaalPixels = histogram[255];

        // Mask opslaan
        saveAs("Tiff", outputMaskDir + replace(title, ".tif", "") + "_mask.tif");

        // Sluit alles netjes
        run("Close All");

        // Voeg resultaat toe aan CSV
        File.append(title + "," + signaalPixels + "\n", resultsPath);
    }
}
