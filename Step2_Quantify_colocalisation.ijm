//Vescile quantification Step2

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//TEST MODE
test=0;
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
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print("Start:",year, month+1 ,dayOfMonth, hour, minute, second);
for (i=0; i<list.length; i++){
	print("list[" + i + "] = [" + list[i] + "]");
	if (endsWith(list[i],"/")){
		objects=getFileList(dir + list[i]);
		//print("dir2 = [" + dir + list[i] + "]");
		for (o=0; o<objects.length; o++){
			print("dir3 = [" + dir + list[i] + objects[o]  + "]");
			//print("list[" + i + "] = [" + list[i] + "]");
			open(dir + list[i] + objects[o] + "Cell.tif");
			open(dir + list[i] + objects[o] + "Quantify.tif");
			run("Merge Channels...", "c1=Quantify.tif c2=Cell.tif create keep ignore");
			rename("Composite");
			selectWindow("Composite");
			run("Squassh", "remove_background rolling_ball_window_size_(in_pixels)=10 regularization_(>0)_ch1=0.050 regularization_(>0)_ch2=0.050 minimum_object_intensity_channel_1_(0_to_1)=0.150 _channel_2_(0_to_1)=0.150 standard_deviation_xy=0.85 standard_deviation_z=0.79 remove_region_with_intensities_<=0 remove_region_with_size_<=2 local_intensity_estimation=Automatic noise_model=Poisson threshold_channel_1=0.0212 threshold_channel_2=0.0245 intermediate_steps colored_objects objects_intensities labeled_objects outlines_overlay soft_mask save_objects_characteristics number=1 select=" + dir + list[i] + objects[o]);
			run("Close All");
			//print("Finished object:", o+1);
			
		}
	}
}
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
print("End:",year, month+1 ,dayOfMonth, hour, minute, second);