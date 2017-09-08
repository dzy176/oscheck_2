#!/bin/bash
solcmd=""
COOKIE=""
BMCHOST=$3
                BMCUSER=$4
                BMCPASS=$5

dir=`echo $0 |sed 's/\/Power.sh//g'`
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


fan_speed()
{ #echo $@
  if [ "x$1" = "xget" ];then
	 IPMIA=$2
  	for((i=0;i<16;i++))
   	do
     	id=`dectohex $i`
     	#echo ipmitool $1 raw 0x3a 0x79 $id
     	faninfo=`ipmitool $IPMIA raw 0x3a 0x79 $id 2>/dev/null`   
     	pres=`echo $faninfo |awk '{print $2}'`
     	status=`echo $faninfo |awk '{if($3=="01")print "ok";else print "error"}'`
     	sp=`echo $faninfo |awk '{print $4}'`
     	#echo $sp
     	sp=`hextodec $sp`"%";
     	speed=`echo $faninfo |awk '{print $6$5}'`
     	speed=`hextodec $speed`;
       
	    
    	if [ "x$pres" = "x01" ];then 
     	echo fanid=$i , status=$status ,duty= $sp ,speed= $speed RPM;
    	fi
  	done
  elif [ "x$1" = "xset" ] ;then
        duty=`dectohex $3`
  	fanid=$2
  	IPMIA=$4
          ipmitool $IPMIA raw 0x3a 0x78 $fanid $duty
          if [ $? -eq 0 ];then
	     echo fan $id set to duty=$3 ok
          else
	    echo "error..set duty failed"
          fi
  fi
 
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
             -h)
              usage $0
                ;;
 	     -psu) 
		    case $gs in
		    -get)
                      sh $dir/powerinfo $args
			;;
	            -set)
			  case $gs1 in
			 	ac-st|active-stanby)
			          ipmitool $args raw 0x3a 0x70 0x01 0x01
				  if [ $? -eq 0 ];then
				    echo "PSU0 active and PSU1 Standby ok ,please wait 1 min."
				  else
				    echo "ac-st set error.."
				  fi
				;;
			 	ac-ac|active-active)
			           ipmitool $args raw 0x3a 0x70 0x01 0x00
				   if [ $? -eq 0 ];then
                                    echo "PSU0 active and PSU1 active ok ,please wait 1 min."
                                  else
                                    echo "ac-ac set error.."
                                  fi

			       ;;
			       *)
			       echo "psu set must in ac-ac|ac-st|active-stanby|active-active"
			       ;;
		 	  esac
		     ;;
		    *)
		      echo "-psu info args must be in -get|-set"
		    ;;
		   esac
		;;
             -fan)
		   case $gs in
			
		   	-get)
			   fan_speed get "$args"
			  # ipmitool $args sdr elist | grep FAN |grep -v ns  
			;;
		   	-set)
			      case $gs1 in
				auto|Auto|AUTO)
				    ipmitool $args raw 0x3a 0x7a 0x00
			            if [ $? -eq 0 ];then
					echo "set auto ok"
				    else
					echo "error,auto failed!"
					exit
				    fi
				    case $gs2 in
				       [0-5])
					  autoid=`dectohex $gs2`
					  ipmitool $args raw 0x3a 0x90 $autoid
					  if [ $? -eq 0  ];then
					    echo "aoto id set is ok"
					  else
					    echo "auto id set error.."
					  fi
					 ;;
				        *)
					  echo $gs2
					;;
				    esac
				 ;;
				manu|manual|Man|man)
                                                                       
                                    a1=`echo $gs2 |awk '{ if(($0>=0) && ($0<116)) print "ture";else print "error";}'`
                                    a2=`echo $gs3 |awk '{ if(($0>=0) && ($0<116)) print "ture";else print "error";}'`
				    echo $a1$a2 | grep tureture >/dev/null 
				    if [ ! $? -eq 0 ];then
					echo "fan set manual mode need \$fanid \$duty"
					exit 132
	 			    fi


				    am=`ipmitool $args raw 0x3a 0x7B 2>/dev/null | awk '{print $1}'` 
				    if [ "x$am" = "x00"  ];then   
 				    
				    	ipmitool $args raw 0x3a 0x7a 0x01
				    	if [ ! $? -eq 0 ];then
				       		echo "error set manual failed!"
	                                        exit 129
				    	fi
				    elif  [ "x$am" = "x01"  ];then
					 echo "manual is ok"
				    else
					 echo "error...get mode failed"
					 exit 130
				    fi
 					echo "set manual ok"
                                        fan_speed set  $gs2  $gs3 "$args"

                                    
				    
					;;
			       *)
				 echo "fanset -set auto|[ manu $\fanID $\duty ]"
				;;
			      esac
			;;
 		 	*)
			echo "-fan info args must be in -get|-set"
		   ;;
		   esac
	      ;;
             *)
	       echo $ARGstart
               usage $dir/../instool.sh
              ;;
       esac 

