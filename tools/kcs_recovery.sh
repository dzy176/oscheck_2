#!/bin/sh

#check architecture
CMD=`uname -m | cut -c 1-6`
if [ "$CMD" = "x86_64" ]; then
   
	#echo "64bit"
	chmod +x Recovery_x64
	./Recovery_x64 p2a write 0x1e789044 0x00
else
   	#echo "32bit"
	chmod +x Recovery
   	./Recovery p2a write 0x1e789044 0x00
fi

