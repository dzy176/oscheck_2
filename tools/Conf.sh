#!/bin/bash
###########################################################################################
#######rongjq@inspur.com                 
######2016-7-10
#####CPU info On shuyu                         
############################################################################################

#debug=1 #display raw data to debug

debug=0


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

function cpuinfo_data()
{
  info=$*
  #exist?
  exist=`echo $info | awk '{print $4}'`
  if [ "x$exist" = "x01" ] ;then
     exist=yes
  else
     exist=no
  fi
 ##################################################################cpu encode####################################
  cpunu=`echo $info | awk '{print $2}'`
  Cpunu="CPU`hextodec $encode`"
 ################################################################serial num ######################################
 serial=`echo $info | awk '{for(i=55;i<=62;i++)print " "$i}'`
 Serialnum=`hextoasiic $serial`
 ################################################################serial num ######################################
 model=`echo $info | awk '{for(i=5;i<=54;i++)print " "$i}'`
 Cpumodel=`hextoasiic $model`

################################################################micro code ######################################
 micode=`echo $info | awk '{for(i=63;i<=72;i++)print " "$i}'`
 Microcode=`hextoasiic $micode`
 ################################################################maxFreq ######################################
 maxfreq=`echo $info | awk '{for(i=73;i<=82;i++)print " "$i}'`
 Maxfreq=`hextoasiic $maxfreq`
 ################################################################Core ######################################
 maxcore=`echo $info | awk '{print $83}'`
 Maxcore=`hextodec $maxcore`
 ################################################################using core ######################################
 usingcore=`echo $info | awk '{print $84}'`
 Usingcore=`hextodec $usingcore`
 ################################################################MaxPower ######################################
 power=`echo $info | awk '{print $92$91}'`
 Maxpower=`hextodec $power`


  if [  $exist = "no" ];then
    echo $exist
  else

    echo  $exist $Cpumodel   $Microcode  $Maxcore $Maxpower
  fi
 }

cpuinfo()
{
	i=0
	#main()
	maxnum=`ipmitool $* raw 0x3a 0x02 0x01 0xff 0xff|awk '{print $2}'`
	maxnum=`hextodec $maxnum`
	if [ $maxnum = 2 ]
	   then
	    cpunum=(0 1)
	elif [ $maxnum = 1 ];then
	    cpunum=(0)
	else 
	    cpunum=(0 1 2 3)
	fi
	       for cpu in ${cpunum[*]}
	          do
	            di=`dectohex $i`
	            echo -n "cpu$cpu "
	            cpuinfo=`ipmitool $* raw 0x3a 0x02 0x01 $di $di` 

	            if [ $debug -eq 1 ];then

	             echo "Cpudata: $cpuinfo"

	            fi     


	            cpuinfo_data $cpuinfo
                      
	           i=$(($i+1))        
	       done
}

############################################################################################
#			memoryinfo
###############################################################################################
function meminfo_data()
{
  info=$*
  #exist?
  exist=`echo $info | awk '{print $5}'`
  if [ "x$exist" = "x01" ] ;then
     exist=yes
  else
     exist=no
  fi
 ##################################################################manufacture####################################
  manufac=`echo $info | awk '{for(i=6;i<=15;i++)print " "$i}'`
  manufac=`hextoasiic $manufac`
 ################################################################serial num ######################################
 serial=`echo $info | awk '{for(i=16;i<=25;i++)print " "$i}'`
 Serialnum=`hextoasiic $serial`
  
 ################################################################Capti ######################################
 cap=`echo $info | awk '{print $27$26}'`
 capt=`hextodec $cap`

 ################################################################Capti ######################################
 cap=`echo $info | awk '{print $27$26}'`
 capt=`hextodec $cap`
 ################################################################Freq ######################################
 fre=`echo $info | awk '{print $29$28}'`
 freq=`hextodec $fre`

 ################################################################################################################
#  pnm=`ipmitool $args fru|grep "Product Name" | awk -F : '{print $2}' 2>/dev/null`
#  case $pnm in 
#	SA5212M4|SA5112M4) 
#    ddr="DDR4"
#	;;
#     *)
#waiting for more server...
        ddr="DDR4"
# esac

  if [  $exist = "no" ];then
    echo $exist
  else
    echo $exist $manufac $Serialnum $ddr  $capt"GB" $freq"MHz"
  fi
 }

function memoryinfo()
{
	channel=(CHA CHB CHC CHD CHE CHF CHG CHH)
	i=0
	#main()
	maxnum=`ipmitool $* raw 0x3a 0x02 0x02 0xff 0xff|awk '{print $2}'`
	maxnum=`hextodec $maxnum`
	if [ $maxnum = 16 ]
	   then
	   dimm=(0 1)
	else
	   dimm=(0 1 2)
	fi
	  for ch in ${channel[*]} 
	     do
	       for dim in ${dimm[*]}
	          do
	            di=`dectohex $i`
	            meminfo=`ipmitool $* raw 0x3a 0x02 0x02 $di $di` 
	            echo -n "$ch""_$dim " 
	            meminfo_data $meminfo
                      
	           i=$(($i+1))        
	       done
	  done

}

##########################################################################################
#    HDD info
##########################################################################################
function finddata()
{
  pdata=""
  for i in $*
   do
    {
     pdata=$pdata`hextodec $i`" "
   }
  done
 echo $pdata |awk '{
          for(i=1;i<=NF;i++) {
                j=i+1;
                #print i;
                a=$i$j;
               # print a;
                start=j+1;
                addnum=j+$j;
                if(a==1612||a==3412||a==3212){
                 print "x12-3.5";
                 backplen(start,addnum);}
                else if(a==174){
                  print "x4-3.5";
                  backplen(start,addnum);}
                else if(a==342||a==322){
                  print "x2-2.5";
                  backplen(start,addnum);}
		else if(a==168){
                  print "x8-2.5";
                  backplen(start,addnum);}
                else 
                  ;

	    } }                   
function backplen(start,addnum){
	     slot=0;
             for(i=start;i<=addnum;i++)
              {   
                  p=i;
                          if($p==0)print export"Disk"slot"  :Rebuilding or located when error";
                           
                           else if($p==1)print export"Disk"slot"  :Located";
                       
                           else if($p==2)print export"Disk"slot"  :Error";
                         
                           else if($p==3)print export"Disk"slot"  :OK";
                          
                           else if($p==4||($p==5)||($p==6)||($p==7))print export"Disk"slot"  :nodisk";
                           
                           else print export"Disk"slot"  :DataError";;
	          slot++;

               } 


      }'
}
 ##################################################################disk status####################################
#main() 
function hddinfo
{
	if [ $# -eq 0 ];then
    
	     diskinfo=`ipmitool raw 0x3a 0x46 0x03 2>/dev/null`
  
	 else
   
	    diskinfo=`ipmitool  -I lanplus $*  raw 0x3a 0x46 0x03 2>/dev/null` 
  
	 fi
 
	 if [ $debug -eq 1 ];then
	   echo "diskinfo: $diskinfo"
 
	 fi

	 ldinfo=`echo "$diskinfo"|awk '{for(i=3;i<=NF;i++)print $i" "}'|tr -d "\n"`


 	finddata "$diskinfo"
}

###########################################################################################################
##network....
############################################################################################################
#main
function netinfo()
{
   IPMI=$@
        numinfo=`ipmitool $IPMI raw 0x3a 0x02 0x04 0xff 0xff | awk '{print $2}'`
        netnum=`echo $numinfo | awk '{a=$1-1;print "0x"a;}'`
        #netnum="0x$netnum";
	netinfo=`ipmitool $IPMI raw 0x3a 0x02 0x04 0x00 $netnum `
        netnum=`echo $numinfo | awk '{a=$1-0;print a;}'`
	if [ $debug -eq 1 ];then
	   echo $netinfo

	fi
	netinfo="00 `echo $netinfo`"
	#netnum=`echo $netinfo|awk '{print $2}'`
	#netnum=`hextodec $netnum`

	#00 04 00 07 00 00 6c 92 bf 11 0a d4 00 00 00 00 01 00 6c 92 bf 11 0a d5 00 00 00 00 02 00 6c 92 bf 11 0a d6 00 00 00 00 03 00 6c 92 bf 11 0a d7 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff 00 00 00 00 00 00 00 00 00 00 00 ff 00 00 00 00 00 00 00 00 00 00
	if [ $netnum -gt 0 ];then
		echo -e "\tManf\tDlink\tModel\t\tMac\t\t\t LinkStatus"
	else
	  	exit

	fi
          NIC=`echo $netinfo|awk  '{ 
                                for(i=1;i<=NF;i+=6)
	           			{s1=i;s5=i+4;s6=i+5;
					 s2=i+1;	
					 s3=i+2;
					 s4=i+3;
					 signs=$s1$s2$s3$s4$s5$s6;                                        
  					 if(signs=="000400070000"|| signs=="000400010000")
						  NIC0=macread(s6);
                                         else if(signs=="000000000100")
					         NIC1=macread(s6);
                                         else if(signs=="000000000200")
						 NIC2=macread(s6);
                                         else if(signs=="000000000300")
						 NIC3=macread(s6);
                                         else if(signs=="000000000401")
						 NIC4=macread(s6);
                                         else if(signs=="000000000501")
						 NIC5=macread(s6);
                                         else 
  						;
                                              #print s1,s2,s3,s4,s5,s6,signs ; 
                                           
                                         #break;
                        	        }
                                   print  "",NIC0 ",",NIC1 ",",NIC2 ",",NIC3 ",",NIC4 ",",NIC5
				   
				   

 				 }
                                 function macread(s7){
                                         m1=(s7+1) 
                                         a=m1;a1=m1+1;a2=m1+2;a3=m1+3;a4=m1+4;a5=m1+5;
					 mac=$a":"$a1":"$a2":"$a3":"$a4":"$a5;
			                 return mac;
          
         				}'`
          
         
      #   echo "$NIC"
	for((i=0;i<$netnum;i++))
	 do    
               mac=`echo $NIC |awk -v b=$i -F ',' '{b=b+1;print $b;}'`
               
               if [ $i -lt 4 ];then
		nic="Intel     1 g      I350  "
	       else
		 nic="Intel     10g     82599ES"
	       fi
              
		n=`dectohex $i`
		status1=`ipmitool $IPMI raw 0x3a 0x15 0x01 $n 2>/dev/null |awk '{print $2}' `
        	
		if [ $debug -eq 1 ] 
 	         then
        
		   	echo $status1
        
		fi
	     	status1=`hextodec $status1`

		if [ $status1 -eq 0 ];then

			status="up"
		else
	 		status="down"
		fi
        
	# 	echo -e "\tMac\t LinkStatus"
                 str=`echo $mac|wc -L`
                  if [ $str -gt 5 ];then
	           echo -e "NIC$i\t$nic\t$mac\t $status"
                  fi
	done
 }

##########################################################################################################
# BIOS/BMC info
############################################################################################################
 function verinfo()
{
  strings=$1
  ascii=""
  len=`echo ${#strings}`
  for((i=0;i<$len;i++))
  do
      byte=${strings:$i:1}
      #byte=`echo $byte | tr -d "\n" | od -An -t dC`
      byte=`echo $byte | tr -d "\n" | od -An -t dC`
      ascii="$ascii "`dectohex $byte`
 
  done
  echo $ascii
}
 function verinfo()
{

#######################################################BMC version#####################
bmc=`ipmitool $* raw 0x3a 0x03 0x00 2>/dev/null`
bmc_ver=`echo $bmc|awk '{for(i=2;i<8;i++)print $i}'`

bmc_ver=`hextoasiic $bmc_ver`
########################################################BIOS version###################
bios=`ipmitool $* raw 0x3a 0x03 0x01 2>/dev/null`
bios_ver=`echo $bios|awk '{for(i=2;i<8;i++)print $i}'`
bios_ver=`hextoasiic $bios_ver`


########################################################BIOS ME###################
biosi=`ipmitool $* raw 0x3a 0x03 0x02 2>/dev/null`
bios_me=`echo $biosi|awk '{for(i=2;i<10;i++)print $i}'`

bios_me=`hextoasiic $bios_me`



if [ $debug -eq 1 ];then
  echo "BMCdata: $bmc
  Biosdata: $bios
  BiosME  : $biosi
 "
  
fi
echo BMC:$bmc_ver BIOS:$bios_ver ME:$bios_me

}


usage()
{
cat <<EOF  	
      
	$1  [\$bmcIP] [\$user] [\$password] -Conf [options]
	options:
                -h   get help
             	-all get cpu mem disk info
                -cpu get cpu info only
		-mem get memory info only
                -hdd get disk status only
                -net get mac addr onboard card but not pcie netcard
                
EOF
	exit
}

#######################################################################################################
#main()
       dir=`echo $0 |sed 's/\/Conf.sh//g'`
       echo $1 |grep instool.sh >/dev/null
       if [ ! $? -eq 0 ];then
        usage $dir/../instool.sh 
       fi
        args=`echo $args | awk '{for(i=2;i<20;i++)print $i;}'`
        if [ "x$2" = "x1" ]
           then
          	ARGstart="$4"
                args=""
        else
         	ARGstart="$7"
                args="-I lanplus -H $3 -U $4 -P $5"
        fi
        pst=`ipmitool $args chassis power status 2>/dev/null`
        pnm=`ipmitool $args fru|grep "Product Name" 2>/dev/null`

        echo $pst |grep -i "on" >/dev/null
        if [ ! $? -eq 0 ];then
	   echo "server in power off or. ip\passwd error..."
	   exit;
   
	fi
       
	case $ARGstart in
		-h|-H)
                     usage $0
                      ;;
		-all|-All)
		  echo "$pnm
##############BIOS-BMC version info#####################"
                  verinfo $args
                  echo "##############CPUinfo#####################"
		  cpuinfo $args	
                  echo "##############Meminfo#####################"
		  memoryinfo $args
                  echo "##############Hddinfo#####################"
		  hddinfo $args
                  echo "##############Net onboard mac info#####################"
                  netinfo $args
                      ;;
                -cpu|Cpu)
                     cpuinfo $args
          	      ;;
                -mem|Mem)
                     memoryinfo $args
		      ;;
                -hdd|Hdd)
                     hddinfo $args
                      ;;
                -net|Net)
                   # echo netinfo $args
                     netinfo $args
                    ;;
                 *)
                 usage $0
			;;
	esac


