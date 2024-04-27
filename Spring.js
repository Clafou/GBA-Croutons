// This creates the bounce coordinates used in the blow-up effect

var dstFilename = "Spring.txt";
var FSO = new ActiveXObject("Scripting.FileSystemObject");
var ForReading = 1, ForWriting = 2;

var NFrames = 16;			// Number of values we want
var Offsets = new Array(NFrames);
var PI = Math.PI;


//---Calculates the values
var i;
for (i=0; i<NFrames; i++)
	Offsets[i] = Math.round(128 - 128 * ((NFrames-i)/NFrames) * Math.sin(2*PI*(i+1)/NFrames));


//---Opens the file
var dstFile = FSO.OpenTextFile(dstFilename, ForWriting, true);

//---Saves
for (i=0; i<NFrames; i++)
	dstFile.WriteLine("	.byte " + Offsets[i]);

//---Finishes
dstFile.Close();
WScript.Echo("Finished.");
