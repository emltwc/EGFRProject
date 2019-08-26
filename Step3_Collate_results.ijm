//Vescile quantification Step3
 
//SCRIPT
run("Close All");
run("Clear Results");

setBatchMode(true);

//Get directory
dir=getDirectory("Choose Source");
list=getFileList(dir);

lineseparator = "\n";
cellseparator = ";";

for (i=0; i<list.length; i++){
	print("list[" + i + "] = [" + list[i] + "]");
	if (endsWith(list[i],"/")){
		objects=getFileList(dir + list[i]);
		print("dir2 = [" + dir + list[i] + "]");
		for (o=0; o<objects.length; o++){

		if (File.exists(dir + list[i] + objects[o] + "__ImageColoc.csv" + File.separator + "Composite_ImageColoc.csv")){
     	a=nResults;
     	print("dir3 = [" + dir + list[i] + objects[o] + "]");
		// copies the whole RT to an array of lines
		lines=split(File.openAsString(dir + list[i] + objects[o] + "__ImageColoc.csv" + File.separator + "Composite_ImageColoc.csv"), lineseparator);
		// recreates the columns headers
		labels=split(lines[0], cellseparator);
		for (j=0; j<labels.length; j++)
		setResult(labels[j],0,0);
		
		// dispatches the data into the new RT
		//run("Clear Results");
		for (q=1; q<lines.length; q++) {
		items=split(lines[q], cellseparator);
		for (j=0; j<items.length; j++)
		   setResult(labels[j],q+a-1,items[j]);
		}
		updateResults();
		}		
		}
 }
}