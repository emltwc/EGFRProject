//Vescile quantification Step1

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//SETUP
//Threshold channel 1t to serve as a mask for the channel you quantify.
//Quanitfy channel q.
// Channel 0 = green
// Channel 1 = blue
// Channel 2 = red
t1=2; //Threshold and use as mask
q=0; //Quantify intensity in this channel
//Mask threshold modifier
mask_threshold_modifier=1.0; //This number was achieved by running all thresholding methods on ~30 images
                             //then averaging the threshold values without the Intermodes, Minimum and Shabang methods.
                             //Triangle thresholding method consistently followed trends in average threshold
                             //but was 2-3 fold lower for masking esg>GFP and DAPI.

//TEST MODE
test=0; //Activate test mode? Works with a single example image in a folder. Boolean 1=yes, 0=no.
//END OF SETUP
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//SCRIPT
run("Close All");
run("Clear Results");

setBatchMode(true);
//Test mode switch
if (test){
setBatchMode(false);
}

//Get directory
dir=getDirectory("Choose Source");
list=getFileList(dir);

for (i=0; i<list.length; i++){
	if (endsWith(list[i],".czi")){
		run("Close All");
	print(list[i]);
	//Create folder for results
	string=replace(list[i],"\\.czi","");
	newfolder=dir + string;
	File.makeDirectory(newfolder);
		
	//Open file
	run("Bio-Formats Importer", "open=" + dir + list[i] + " color_mode=Default rois_import=[ROI manager] split_channels view=Hyperstack stack_order=XYCZT");
	selectWindow(list[i] + " - C=" + t1);
	run("Duplicate...", "duplicate");
	
	//Get threshold and number of slices
	setAutoThreshold("Triangle dark stack");
	getThreshold(lower,upper);
	
	threshold=round(mask_threshold_modifier*lower);
	//print(list[i] + " Threshold:" + threshold);
		
	//Threshold image conventionally
	setThreshold(threshold, 65535);
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Triangle background=Dark black");
	rename("Mask");
	run("Options...", "iterations=1 count=1 black do=Nothing");
	run("Close-" , "stack");
	run("Fill Holes", "stack");
	run("Despeckle", "stack");
	run("Despeckle", "stack");
	run("Despeckle", "stack");


	//Get regions of interest
	run("3D OC Options", "  dots_size=5 font_size=10 redirect_to=none");
	run("3D Objects Counter", "threshold=1 slice=1 min.=1000 max.=27262976 objects");
	rename("Objects");
	Stack.getStatistics(nPixels, mean, min, max);

	//Go through all cells
	for (r=1; r<=max; r++){
		print("Cell number", max, r);
		selectWindow("Objects");
		run("Duplicate...", "duplicate");
		run("Set Measurements...", "integrated redirect=None decimal=3");
		rename("temp");
		run("Clear Results");
		
		//Get a single object
		for (n=1; n<=nSlices; n++){
			setSlice(n);
			//Lower
			changeValues(0, r-1, 0);
			//Higher
			changeValues(r+1, max, 0);
			run("Measure");
		}
	
		//Find boundaries
		a=1;
		for (w=0; w<nResults; w++){
			temp=getResult("RawIntDen",w);
			//Find z-boundaries
			if (temp>0){
				if(a){
					a=0;
					first=w+1;
				}
				last=w+1;
			}
		}
		print("Boundaries:", first, last);
		run("Clear Results");
		run("Make Substack...", "  slices=" + first + "-" + last);
		setThreshold(1, 255);
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Triangle background=Dark black");
		rename("substack");
		run("Z Project...", "projection=[Max Intensity]");
		selectWindow("MAX_substack");
		run("Set Measurements...", "bounding redirect=None decimal=3");
		run("Analyze Particles...", "display");
		getPixelSize(unit, pixelWidth, pixelHeight);
		selectWindow("substack");
		BX=getResult("BX");
		BY=getResult("BY");
		Width=getResult("Width");
		Height=getResult("Height");
		makeRectangle(BX/pixelWidth, BY/pixelHeight, Width/pixelWidth, Height/pixelHeight);
		run("Crop");
		rename("Cell_Mask" + r);
		close("temp");
		close("MAX_substack");

		//Get cell
		selectWindow(list[i] + " - C=" + t1);
		run("Make Substack...", "  slices=" + first + "-" + last);
		makeRectangle(BX/pixelWidth, BY/pixelHeight, Width/pixelWidth, Height/pixelHeight);
		run("Crop");
		rename("Cell" + r);
		//Get channel to quantify
		selectWindow(list[i] + " - C=" + q);
		run("Make Substack...", "  slices=" + first + "-" + last);
		makeRectangle(BX/pixelWidth, BY/pixelHeight, Width/pixelWidth, Height/pixelHeight);
		run("Crop");
		rename("Quantify" + r);

		newfolder=dir + string + File.separator + "Object" + r;
		File.makeDirectory(newfolder);
		selectWindow("Cell_Mask" + r);
		saveAs("Tiff", dir + string + File.separator + "Object"+ r + File.separator + "Cell_Mask" + ".tif");
		selectWindow("Cell" + r);
		saveAs("Tiff", dir + string + File.separator + "Object"+ r + File.separator + "Cell" + ".tif");
		selectWindow("Quantify" + r);
		saveAs("Tiff", dir + string + File.separator + "Object"+ r + File.separator + "Quantify" + ".tif");

		
		//run("16-bit");
		//run("Merge Channels...", "c1=Quantify" + r + " c2=Cell" + r + " c3=Vesicles" + r + " create keep ignore");
		
		//run("Merge Channels...", "c1=Quantify" + r + " c2=Cell" + r + " create keep ignore");
		//run("Squassh", "remove_background rolling_ball_window_size_(in_pixels)=10 regularization_(>0)_ch1=0.050 regularization_(>0)_ch2=0.050 minimum_object_intensity_channel_1_(0_to_1)=0.150 _channel_2_(0_to_1)=0.150 standard_deviation_xy=0.85 standard_deviation_z=0.79 remove_region_with_intensities_<=0 remove_region_with_size_<=2 local_intensity_estimation=Automatic noise_model=Poisson regularization_(>0)_ch1=0.050 regularization_(>0)_ch2=0.050 minimum_object_intensity_channel_1_(0_to_1)=0.150 _channel_2_(0_to_1)=0.150 standard_deviation_xy=0.85 standard_deviation_z=0.79 remove_region_with_intensities_<=0 remove_region_with_size_<=2 local_intensity_estimation=Automatic noise_model=Poisson");
		//run("Squassh", "remove_background rolling_ball_window_size_(in_pixels)=10 intermediate_steps colored_objects objects_intensities outlines_overlay number=1 input=[Input Image: Cell] select=" + dir);

	}
	}
}