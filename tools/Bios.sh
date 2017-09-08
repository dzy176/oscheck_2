#!/bin/bash
solcmd=""
COOKIE=""
BMCHOST=$3
                BMCUSER=$4
                BMCPASS=$5

dir=`echo $0 |sed 's/\/Bios.sh//g'`
function usage()
{
#cat<<EOF
echo -n $1 
echo ' [$bmcIP] [$user] [$password] -bios [options]
options:
       	-h       get help 
       	-get     get bios info [options]
                 "bios item name"
		 all
		 exp:
		 -get "Hyper Threading Technology"
		 -get all
       	-set     set bios [options]
		 [bios item name] [value]
		 exp:
		 -set "Hyper Threading Technology" disable
'
exit 128

}

#######################################################################################################
#main()
       echo $1 |grep instool.sh >/dev/null
       if [ ! $? -eq 0 ];then
        usage $dir/../instool.sh
       fi
        args=`echo $args | awk '{for(i=2;i<20;i++)print $i;}'`
        if [ "x$2" = "x1" ]
           then
                ARGstart="$3"
                args=""
                #usage $dir/../instool.sh
                #exit
 		biositem="$4"
		biosvalue="$5"
        else
                ARGstart="$6"
                args="-I lanplus -H $3 -U $4 -P $5"
		biositem="$7"
		biosvalue=$8
        fi
        case $ARGstart in
             -h)
              usage $0
                ;;
 	     -get)
		  if [  "x$biositem" = "x" ]
                        then
			echo "bios -get must be  all|\$VALUE"
			exit
		  fi
                  if [ ! "x$biositem" = "xall" ]
			then
                   	      $dir/biosinfo $args  "$biositem"
		  else
			for i in 0x00 0x12 0x13 0x16 0x17 0x18 0x19 0x1b 0x1c 0x20 0x24 0x65 0x05 0x06 0x07 0x08 0x2a 0x2b \
				 0x2d 0x2e 0x2f 0x60 0x61 0x64 0x67 0x68 0x69
		            do
			      $dir/biosinfo $args "$i"
			done   
		  fi
		;;
             -set)
		  if [ ! "x$biosvalue" = "x" ]
		     then
 		  	$dir/biosinfo  $args  "$biositem"  $biosvalue
		  else
		     echo "The $biositem Value needed!"                  		  
		  fi

		;;
             *)
               usage $dir/../instool.sh
              ;;
       esac 

