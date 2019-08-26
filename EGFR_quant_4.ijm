//MEMBRANE_QUANTIFICATION
//Batch quantify .czi confocal images in a folder.
//It thresholds images on channel t and quantifies fluorescent intensity
//in channel q in the cytoplasm and the cell membrane compartments.
//Version 4.0 15/08/2019
//By Máté Nászai

//////////////////////////////////////////////////////////////////////////////////////
//Test mode, works with a single image in folder
//Shows membrane and cytoplasmic staining
test=0;
objects=1;
//Channel to mask
t=0;
//Channel to quantify
q=2;
//Threshold modifier
m=2.5; //Default 2.5
//Subtract nuclei subtracts the nuclei from the cytoplasm
subtract=1;
///////////////////////////////////////////////////////////////////////////////////////

run("Close All");
run("Clear Results");
if (!test){
setBatchMode(true);
}
//Get directory
dir=getDirectory("Choose Source");
list=getFileList(dir);

for (i=0; i<list.length; i++){
	if (endsWith(list[i],".czi")){
	//Open file
	run("Bio-Formats Importer", "open=" + dir + list[i] + " color_mode=Default rois_import=[ROI manager] split_channels view=Hyperstack stack_order=XYCZT");
	selectWindow(list[i] + " - C=" + t);
	run("Duplicate...", "duplicate");
	
	//Get threshold and number of slices
	setAutoThreshold("Triangle dark stack");
	getThreshold(lower,upper);
	//This number was achieved by running all thresholding methods on ~30 images then
	//averaging the threshold values without the Intermodes, Minimum and Shabang methods,
	//Triangle consistently followed trends in average threshold but was 2-3 fold lower 
	threshold=round(m*lower);
	print(list[i] + " Threshold:" + threshold);
	
	//Threshold image
	setThreshold(threshold, 65535);
	setOption("BlackBackground", true);
	run("Convert to Mask", "method=Triangle background=Dark black");
	rename("Objects");
	run("Options...", "iterations=1 count=1 black do=Nothing");
	run("Fill Holes", "stack");
	run("Despeckle", "stack");
	run("Despeckle", "stack");
	run("Despeckle", "stack");
	
	
	//Extracts nuclei from the cytoplasm if activated
	if (subtract){
		selectWindow(list[i] + " - C=1");
		run("Duplicate...", "duplicate");
		
		//Get threshold 
		setAutoThreshold("Triangle dark stack");
		getThreshold(lower,upper);
		threshold=round(2.5*lower);
		//print(list[i] + " Threshold:" + threshold);
		
		//Threshold image
		setThreshold(threshold, 65535);
		setOption("BlackBackground", true);
		run("Convert to Mask", "method=Triangle background=Dark black");
		rename("Nucleus_mask");
		run("Options...", "iterations=1 count=1 black do=Nothing");
		run("Fill Holes", "stack");
		run("Despeckle", "stack");
		run("Despeckle", "stack");
		run("Despeckle", "stack");
	}
	
	if (objects){
		//print("Object extraction started");
		//Perform measurements on an object by object basis
		//Get regions of interest
		selectWindow("Objects");
		rename("Original_Objects");
		run("3D OC Options", "  dots_size=5 font_size=10 redirect_to=none");
		run("3D Objects Counter", "threshold=1 slice=1 min.=1000 max.=27262976 objects");
		rename("All_Objects");
		Stack.getStatistics(nPixels, mean, min, max);
		//print("Object number" + max);
		//Go through all cells
		for (r=1; r<=max; r++){
	
			//print("Cell number", max, r);
			selectWindow("All_Objects");
			run("Duplicate...", "duplicate");
			rename("Object" + r);
			run("Clear Results");
			
			//Get a single object
			for (n=1; n<=nSlices; n++){
				setSlice(n);
				//Lower
				changeValues(0, r-1, 0);
				//Higher
				changeValues(r+1, max, 0);
			}
			setThreshold(1, 255);
			setOption("BlackBackground", true);
			run("Convert to Mask", "method=Triangle background=Dark black");
			rename("Objects");
			//print("Quantifying" + r);

			quantify();
		}
		if (!test){
		run("Close All");
		run("Clear Results");
		}
	}
	else{
		quantify();  
	}
	}
}

setBatchMode(false);



function quantify() {
	selectWindow("Objects");
	//Get membrane mask
	run("Erode", "stack");
	run("Duplicate...", "duplicate");
	run("Outline", "stack");
	run("Options...", "iterations=2 count=3 black do=Dilate stack");
	rename("Membrane_mask");
	//Get cytoplasm mask
	imageCalculator("Subtract create stack", "Objects","Membrane_mask");
	rename("Cytoplasm_mask");
	
	if (subtract){
		imageCalculator("Subtract create stack", "Cytoplasm_mask","Nucleus_mask");
		close("Cytoplasm_mask");
		selectWindow("Result of Cytoplasm_mask");
		rename("Cytoplasm_mask");
		//print("Nucleus subtracted");
	}
	
	//Apply masks CYTOPLAMS PROBLEM!
	selectWindow("Cytoplasm_mask");
	run("Invert", "stack");
	imageCalculator("Transparent-zero create stack", list[i] + " - C=" + q,"Cytoplasm_mask");
	imageCalculator("Subtract create stack", "Result of " + list[i] + " - C=" + q,"Cytoplasm_mask");
	rename("Cytoplasm");
	close("Result of " + list[i] + " - C=" + q);
	selectWindow("Membrane_mask");
	run("Invert", "stack");
	imageCalculator("Transparent-zero create stack", list[i] + " - C=" + q,"Membrane_mask");
	imageCalculator("Subtract create stack", "Result of " + list[i] + " - C=" + q,"Membrane_mask");
	selectWindow("Result of Result of " + list[i] + " - C=" + q);
	close("Result of " + list[i] + " - C=" + q);
	rename("Membrane");
	
	//Perform measurements
	run("Set Measurements...", "integrated redirect=None decimal=3");
	
	selectWindow("Cytoplasm");
	a=0;
	temp=0;
	for (n=1; n<=nSlices; n++){
		setSlice(n);
		run("Measure");
		temp+=getResult("RawIntDen",a);
		a++;
	}
	cytoplasm=temp;
	
	selectWindow("Cytoplasm_mask");
	run("Invert", "stack");
	temp=0;
	for (n=1; n<=nSlices; n++){
		setSlice(n);
		run("Measure");
		temp+=getResult("RawIntDen",a);
		a++;
	}
	cytoplasm_voxel=temp/255;
	cytoplasm_mean=cytoplasm/cytoplasm_voxel;
	
	selectWindow("Membrane");
	temp=0;
	for (n=1; n<=nSlices; n++){
		setSlice(n);
		run("Measure");
		temp+=getResult("RawIntDen",a);
		a++;
	}
	membrane=temp;
	
	selectWindow("Membrane_mask");
	run("Invert", "stack");
	temp=0;
	for (n=1; n<=nSlices; n++){
		setSlice(n);
		run("Measure");
		temp+=getResult("RawIntDen",a);
		a++;
	}
	membrane_voxel=temp/255;
	membrane_mean=membrane/membrane_voxel;
	
	if (objects){
		print(list[i] + "Object" + r + " Cytoplasm IntDens:",cytoplasm);
		print(list[i] + "Object" + r + " Cytoplasm VoxelNum:",cytoplasm_voxel);
		print(list[i] + "Object" + r + " Cytoplasm mean:",cytoplasm_mean);
		print(list[i] + "Object" + r + " Membrane IntDens:",membrane);
		print(list[i] + "Object" + r + " Membrane VoxelNum:",membrane_voxel);
		print(list[i] + "Object" + r + " Membrane mean:",membrane_mean);
		
	selectWindow("Cytoplasm");
	rename("Cytoplasm"+r);
			close("Objects");
			close("Cytoplasm_mask");
			close("Membrane_mask");
			close("Cytoplasm");
			close("Membrane");
	} else{
		print(list[i] + " Cytoplasm IntDens:",cytoplasm);
		print(list[i] + " Cytoplasm VoxelNum:",cytoplasm_voxel);
		print(list[i] + " Cytoplasm mean:",cytoplasm_mean);
		print(list[i] + " Membrane IntDens:",membrane);
		print(list[i] + " Membrane VoxelNum:",membrane_voxel);
		print(list[i] + " Membrane mean:",membrane_mean);
	}

}
