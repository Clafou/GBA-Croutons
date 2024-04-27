// This creates the font data

var nLetters = 41;

var srcFilename = "FontMinimal.bmp";
var dstFilename = "FontMinimal.txt";
var FSO = new ActiveXObject("Scripting.FileSystemObject");
var ForReading = 1, ForWriting = 2;



//---Opens both files
var srcFile = FSO.OpenTextFile(srcFilename, ForReading);
var dstFile = FSO.OpenTextFile(dstFilename, ForWriting, true);


//---Prepares the output
var code = new Array(nLetters*7)
var i,j,k,s,n;
for (i=0;i<code.length;i++)
	code[i] = "	.byte 0b";


//---Parses the file
srcFile.Skip(0x436);

for (j=6;j>=0;j--)
	{
	for (k=0;k<nLetters;k++)
		{
		for (i=0;i<8;i++)
			{
			s = srcFile.Read(1);
			n = s.charCodeAt(0);
			code[k*7+j] += (n==0)? "0":"1"
			}
		}
	}



//---Saves
for (k=0;k<nLetters;k++)
	{
	for (j=0;j<7;j++)
		{
		dstFile.WriteLine(code[k*7+j]);
		}
	dstFile.WriteLine("");
	}


//---Finishes
srcFile.Close();
dstFile.Close();
WScript.Echo("Finished.");





