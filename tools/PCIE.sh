#!/bin/bash
solcmd=""
COOKIE=""
BMCHOST=$3
                BMCUSER=$4
                BMCPASS=$5

dir=`echo $0 |sed 's/\/PCIE.sh//g'`
function usage()
{
#cat<<EOF
echo -n $1 
echo ' [$bmcIP] [$user] [$password] -bios [options]
options:
       	-h       get help 
       	-psu     get &set PSU  info [options]
                 -get
		 -set [active-stanby|active-active]
		 
       	-fan     get & set fan [options]
		 -get all
		 -set $id $duty[10|20|30|40|50|60]
		 
'
exit 128

}
function hextoasiic()
{
 Hex=`echo $*|awk '{for(i=1;i<=NF;i++)print " "$i;}'`
 hexasiic="\\x"`echo $Hex|sed 's/ /\\\x/g'`
 echo -e "$hexasiic"

}
function hextodec()
{
  ((dec=16#$1))  
  echo $dec
}

function dectohex()
{
 hex=`echo "obase=16;$1"|bc`
 echo 0x$hex
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
                ARGstart="$4"
                args=""
                #usage $dir/../instool.sh
                #exit
 		gs="$5"
		gs1="$6"
		gs2="$7"
		gs3="$8"
		gs4="$9"
        else
                ARGstart="$7"
                args="-I lanplus -H $3 -U $4 -P $5"
		gs="$8"
                gs1="$9"
                gs2="${10}"
                gs3="${11}"
                gs4="${12}"

        fi

        case $ARGstart in
              "")
		 $dir/pcieinfo $args
	      ;;
             *)
	       echo $ARGstart
               usage $dir/../instool.sh
              ;;
       esac 

