//Vescile colocalisation quantification

///////////////////////////////////////////////////////
//SETUP
//Mask
mask=1; //Use the cell mask to only quantify the cell and no vesicles in the background
//Output
mask_voxel=0; //only if mask=1;
colocalisation_voxel=0;
green_voxels=0;
red_voxels=0;
coloc_red=1;
coloc_green=0;
///////////////////////////////////////////////////////


//SCRIPT
run("Close All");
run("Clear Results");

setBatchMode(true);

//Get directory
dir=getDirectory("Choose Source");
list=getFileList(dir);


for (i=0; i<list.length; i++){
	//print("list[" + i + "] = [" + list[i] + "]");
	if (endsWith(list[i],"/")){
		objects=getFileList(dir + list[i]);
		//print("dir2 = [" + dir + list[i] + "]");
		for (o=0; o<objects.length; o++){

			if (File.exists(dir + list[i] + objects[o] + "__coloc.zip" + File.separator + "Composite_ch_0_1_coloc.zip")){

			run("Clear Results");
	     	open(dir + list[i] + objects[o] + "__coloc.zip" + File.separator + "Composite_ch_0_1_coloc.zip");
			run("Split Channels");
	     	selectWindow("\\Composite_ch_0_1_coloc.tif (blue)");
	     	close();
	     	selectWindow("\\Composite_ch_0_1_coloc.tif (green)");
	     	rename("Green");
	     	selectWindow("\\Composite_ch_0_1_coloc.tif (red)");
	     	rename("Red");

			imageCalculator("AND create stack", "Green","Red");
			rename("Colocalisation");

			if (mask){
				open(dir + list[i] + objects[o] + "Cell_Mask.tif");
				imageCalculator("AND create stack", "Red","Cell_Mask.tif");
				close("Red");
				selectWindow("Result of Red");
				rename("Red");
				imageCalculator("AND create stack", "Green","Cell_Mask.tif");
				selectWindow("Result of Green");
				rename("Green");
				imageCalculator("AND create stack", "Colocalisation","Cell_Mask.tif");
				close("Colocalisation");
				selectWindow("Result of Colocalisation");
				rename("Colocalistaion");

				selectWindow("Cell_Mask.tif");
				a=0;
				temp=0;
				for (n=1; n<=nSlices; n++){
					setSlice(n);
					run("Measure");
					temp+=getResult("RawIntDen",a);
					a++;
				}
			cell_mask=temp/255;
			if (mask_voxel){
			print(list[i] + objects[o], "Cell mask voxels:",cell_mask);
			}
			}

			selectWindow("Colocalistaion");
			run("Set Measurements...", "integrated redirect=None decimal=3");
			if (!mask){
			a=0;
			}
			temp=0;
			for (n=1; n<=nSlices; n++){
				setSlice(n);
				run("Measure");
				temp+=getResult("RawIntDen",a);
				a++;
			}
			coloc=temp/255;
			if (colocalisation_voxel){
			print(list[i] + objects[o], "Colocalisation number of voxels:",coloc);
			}
			selectWindow("Green");
			temp=0;
			for (n=1; n<=nSlices; n++){
				setSlice(n);
				run("Measure");
				temp+=getResult("RawIntDen",a);
				a++;
			}
			green=temp/255;
			if (green_voxels){
			print(list[i] + objects[o], "Green voxels:",green);
			}
			selectWindow("Red");
			temp=0;
			for (n=1; n<=nSlices; n++){
				setSlice(n);
				run("Measure");
				temp+=getResult("RawIntDen",a);
				a++;
			}
			red=temp/255;
			if (red_voxels){
			print(list[i] + objects[o], "Red voxels:",red);
			}
			if (coloc_red){
			print(list[i] + objects[o], "Objects based coloc red:",coloc/red);
			}
			if (coloc_green){
			print(list[i] + objects[o], "Objects based coloc green:",coloc/green);
			}
			run("Clear Results");
			run("Close All");
			}
		}
	}
}