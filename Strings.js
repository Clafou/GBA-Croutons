// This creates the binary data containing all the text, in 5-bit format

/*
5-bit format:

76543210 76543210 76543210 76543210
aaaaabbb bbcccccd ddddeeee efffffgg

  bit P  p > shifting needed

a  0  0  0 > 11
b  5  0  5 >  6 
c 10  1  2 >  9
d 15  1  7 >  4 
e 20  2  4 >  7   
(etc.)

With P = bit / 5
     p = bit % 5

"Shifting needed" being the right-shifting needed on a two-byte
value made of (byte at P)<<8 + (byte at P+1), which would result
in obtaining the value needed into the least significant bits.
*/



var srcFilename = "Strings Ascii.txt";
var dstFilename = "Strings.txt";
var FSO = new ActiveXObject("Scripting.FileSystemObject");
var ForReading = 1, ForWriting = 2;
var i,j,s;
var Values = new Array();
var Strings = new Array();


//---Opens the source file and reads it
var srcFile = FSO.OpenTextFile(srcFilename, ForReading, true);

while (!srcFile.AtEndOfStream)
    Strings[Strings.length] = srcFile.ReadLine();

srcFile.Close();





//---Creates the storage in bytes

var NumEntries = 0;
var Comments = new Array();
for (j=0;j<Strings.length;j++)
{
	if (Strings[j]=="~")
		Values[NumEntries++] = 31
	else if (Strings[j].charAt(0)=="_")
		Comments[Comments.length] = "	.equ _Text" + Strings[j] + ", " + NumEntries;
	else
	{
		Values[NumEntries++] = Strings[j].length;
		for (i=0;i<Strings[j].length;i++)
			Values[NumEntries++] = getCode(Strings[j].charAt(i));
	}
}


//---Creates the storage in 5-bit values

var CompressedSize = Math.ceil((NumEntries*5)/8);
var Compressed = new Array(CompressedSize);
for (i=0;i<CompressedSize;i++)
	Compressed[i] = 0;

var shift, P, p;
for (i=0;i<NumEntries;i++)
	{
	p = i*5 % 8;
	PP = (i*5 - p)/8;
	shift = 11 - p;
	Compressed[PP] = Compressed[PP] | (((Values[i]<<shift)>>8) & 255)
	Compressed[PP+1] = Compressed[PP+1] | ((Values[i]<<shift) & 255)
	}


//---Opens the file
var dstFile = FSO.OpenTextFile(dstFilename, ForWriting, true);

//---Saves


for (j=0;j<Comments.length;j++)
{
	dstFile.WriteLine(Comments[j]);
}


i = 0;
while (i<CompressedSize)
{
	s = "	.byte ";
	for (j=0;(j<10)&&(i<CompressedSize);j++)
	{
		s += Compressed[i++];
		if ((j!=9)&&(i<CompressedSize))
			s += ",";
	}
	dstFile.WriteLine(s);

}


//---Finishes
dstFile.Close();
WScript.Echo("Finished.");




//---Text to font index conversion

function getCode(s)
{
	var c = s.toUpperCase().charCodeAt(0);
	switch (c)
	{
		case " ".charCodeAt(0):
			return 0
		case ",".charCodeAt(0):
			return 27
		case ".".charCodeAt(0):
			return 28
		case "'".charCodeAt(0):
			return 29
		case "!".charCodeAt(0):
			return 30
		case "-".charCodeAt(0):
			return 31
		default:
			return (c - "A".charCodeAt(0) + 1)%32;

	}
}