//MEMBRANE_QUANTIFICATION
//Batch quantify .czi confocal images in a folder.
//It thresholds images on channel t and quantifies fluorescent intensity
//in channel q in the cytoplasm and the cell membrane compartments.
//Version 3.0 06/08/2018
//By Máté Nászai

run("Close All");
run("Clear Results");

//Test mode, works with a single image in folder
//Shows membrane and cytoplasmic staining
test=0;
//Channel to mask
t=0;
//Channel to quantify
q=2;
//Threshold modifier
m=2.5; //Default 2.5
setBatchMode(true);
//Subtract nuclei subtracts the nuclei from the cytoplasm
subtract=1;

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
//Get membrane mask
run("Erode", "stack");
run("Duplicate...", "duplicate");
run("Outline", "stack");
run("Options...", "iterations=2 count=3 black do=Dilate stack");
rename("Membrane_mask");
//Get cytoplasm mask
imageCalculator("Subtract create stack", "Objects","Membrane_mask");
rename("Cytoplasm_mask");

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
	imageCalculator("Subtract create stack", "Cytoplasm_mask","Nucleus_mask");
	close("Cytoplasm_mask");
	selectWindow("Result of Cytoplasm_mask");
	rename("Cytoplasm_mask");
}

//Apply masks
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
print(list[i] + " Cytoplasm IntDens:",cytoplasm);

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
print(list[i] + " Cytoplasm VoxelNum:",cytoplasm_voxel);

cytoplasm_mean=cytoplasm/cytoplasm_voxel;
print(list[i] + " Cytoplasm mean:",cytoplasm_mean);

selectWindow("Membrane");
temp=0;
for (n=1; n<=nSlices; n++){
	setSlice(n);
	run("Measure");
	temp+=getResult("RawIntDen",a);
	a++;
}
membrane=temp;
print(list[i] + " Membrane IntDens:",membrane);

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
print(list[i] + " Membrane VoxelNum:",membrane_voxel);

membrane_mean=membrane/membrane_voxel;
print(list[i] + " Membrane mean:",membrane_mean);

//If the option is enabled shows the processed image
if (test){
	run("Merge Channels...", "c1=[" + list[i] + " - C=" + q +"] c2=[" + list[i] + " - C=" + t +"] c3=Cytoplasm c4=Membrane create keep ignore");
}else{
	run("Close All");
	run("Clear Results");
}
}
}
setBatchMode(false);
