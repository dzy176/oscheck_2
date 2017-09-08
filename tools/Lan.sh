#!/bin/bash
solcmd=""
COOKIE=""
BMCHOST=$3
                BMCUSER=$4
                BMCPASS=$5

dir=`echo $0 |sed 's/\/Lan.sh//g'`

function usage()
{
cat <<EOF       
        
        $1  \$bmcIP \$user \$password -lan [options]
        options:
                -h       get help ,this option: ip user password must be needed all
         
		-ip      get or set ip info
			 -info
			 -set [\$lan] [\$ip] [\$mask] [\$gateway]
                          lan options: 1|8|dhcp  
			  #lan1-dedicated lan8-sharelink,dhcp-lan1 and lan8 default
                -ssh     ssh login [options]
		   	 -login
			 -enable
			 -disable
                -ntp      ntp get and set [options]
                         -get
                         -set ip
                -snic    get or set sharelinke NIC
	                 -info
			 -set [\$nic] [\$port]
			      nic options: 1g|10g|pcie
			      port options: 0/1   
			 -dis/en  disabled/enable nic-sharelink
			 -bond [enable/disable] 
			     dedicated and sharelink use the same mac and ip on lan 1

                -hn      get or set bmc hostname
			 -info
			 -set [\$hostname]
		-user    get or set bmc user [options]
			 -list
			 -addm [\$userid]  \$newusr \$password [\$privilege]  			      
		               userid options:[3-16]
			       privilege options: admin| user|operater		
			 -del  [\$userid]
		-fdi     get or set  failure diagnosis info [option]
			 -bootcode  
			    get BIOS boot Ascii code
			 -ldfa       
			    set BMC to factory default
			 -pic [enable|disable|get|cget]
                            
		         -sel [list|clr]
			
			 -sdr [list|error]

			 -blksel   
			       get blacklog,will download 2 files blackbox.log and blackboxpcie.log
EOF
        exit 128

}

auto_login_ssh () {
    expect -c "set timeout -1;
                spawn -noecho ssh -o StrictHostKeyChecking=no $2 ${@:3};
                expect *assword:*;
                send -- $1\r;
                interact;";
}
user_add () {
  
   if [ ! $# -gt 3 ];then
     echo "add user must be options: -add [\$userid]  \$newusr \$password [\$privilege] "
     exit 127;
   fi
   userid=$1;
   username=$2
   userpasswd=$3
   #userpau=`echo $4|awk '{if($0=="admin")print "4";else print $0}'`
   userpau=`echo $4|awk '{if($0=="admin")print "4";else if($0=="user")print "2";else if($0=="operater")print "3";else print "0";}'`
   if [ "x$userpau" = "x0" ] ;then 
	 echo "$4 error...privilege options: admin| user|operater"
         exit 128;
   fi
   ipmiargs="$5"
#add lan 8 ifpanduan
 	 for i in 1 8
    		do
       #	echo "	
		      ipmitool $ipmiargs user set name $userid $username 
		      if [ ! $? -eq 0 ];then  
                                echo error..
                                break;
                      fi

		      ipmitool $ipmiargs user set password  $userid $userpasswd
		      if [ ! $? -eq 0 ];then  
                                echo error..
                                break;
                      fi

		      ipmitool $ipmiargs user priv $userid $userpau $i
  		      if [ ! $? -eq 0 ];then  
				echo error..
				break;
		      fi
		      ipmitool $ipmiargs channel  setaccess $i $userid callin=on ipmi=on link=on privilege=$userpau
		      ipmitool $ipmiargs sol payload enable $i $userid
		      ipmitool $ipmiargs user enable $userid
		      
	#	"
  	done
        exit 0

 # echo "add user must be options: [\$userid]  \$newusr \$password [\$privilege] "
 #exit 127
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

function stingstoasscii()
{
  strings=$1
  ascii=""
  len=`echo ${#strings}`
  for((i=0;i<$len;i++))
  do
      byte=${strings:$i:1}
      byte=`echo $byte | tr -d "\n" | od -An -t dC`
      ascii="$ascii "`dectohex $byte`

  done
  echo $ascii
}

sethostname () {

 if [ "x$1" = "x" ]; then
    echo "error ,-hn hostname be required!"
    exit;
 fi
 ipmiargs="$2"
 hostname=`stingstoasscii $1`
 #echo $hostname
 ipmitool $ipmiargs raw 0x32 0x6c 0x01 0x00 0x00 0x08 
 ipmitool $ipmiargs raw 0x32 0x6c 0x01 0x00 0x00 0x08 $hostname
 if [ $? -eq 0 ];then
    echo "Hostname $1 is ok"
 else
    echo "error!!"
 fi

 ipmitool $ipmiargs raw 0x32 0x6c 0x07 0x00
   if [ $? -eq 0 ];then
    echo "DNS is restarting,please wait 1 min "
 else
    echo "error!!when enable DNS"
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
               # usage $dir/../instool.sh
               # exit
	        gs="$5"
		gs1="$6"
		gs2="$7"
		gs3="$8"
		gs4="$9"

        else
                ARGstart="$7"
		gs="$8"
		gs1="$9"
		gs2="${10}"
		gs3="${11}"
		gs4="${12}"

                args="-I lanplus -H $3 -U $4 -P $5"
        fi
        case $ARGstart in
             -h)
              usage $0
                ;;
	     -fdi)
		   case $gs in
			-bootcode)
			    ipmitool $args raw 0x32 0x73 0x00
			    if [ $? -eq 0 ];then
                               echo "load success"
                             else
                                echo "error.."
                            fi
    
			  ;;
			-ldfa)
			    echo "bmc will load deafult and reset "
			    ipmitool $args raw 0x32 0x66
                            if [ $? -eq 0 ];then
			       echo "load success,and please wait 1 min wait for bmc reset"
			     else
			        echo "error.."
			    fi
			  ;;
			-blksel)
			    wget http://$BMCHOST/blackbox/record/blackbox.log
                            if [ $? -eq 0 ];then
				chmod 777 $dir/blackbox_decrypt
			    	$dir/blackbox_decrypt  `pwd`/blackbox.log
			        echo "Please suppluy the new.log to Inspur BMC engenner"
                                echo "or use cmd :$dir/blackbox_decrypt  `pwd`blackbox.log"

			    else
                              echo "get log error.."
			    fi
			    blackboxpeci.log
			    wget http://$BMCHOST/blackbox/record/blackboxpeci.log
                            if [ $? -eq 0 ];then
                                chmod 777 $dir/blackbox_decrypt
                                echo "Please suppluy the blackboxpeci.log to Inspur BMC engenner"
				echo "or use cmd :$dir/blackbox_decrypt  `pwd`blackboxpeci.log"

                            else
                              echo "get log error.."
                            fi

			  ;;
			-sel)
			      case $gs1 in
				list|elist)
				   ipmitool $args sel elist 
				 ;;
				clr|clear)
				   ipmitool $args sel clear
				;;
				*)
				 echo "-sel args in list|clr"
				;;
			      esac
			  ;;
		        -sdr)
			 case $gs1 in
                                list|elist)
                                   ipmitool $args sdr elist | grep -v ns
                                 ;;
                                error)
                                   ipmitool $args sdr 
                                ;;
                                *)
                                 echo "-sel args in list"
                                ;;
                              esac
                          ;;

			-pic)
                              case $gs1 in
			        enable)
				  echo "please waiting.."
				;;
			        disable)
       			          echo "please wating..."                            
				;;
				get)
				   for i in 1 2 3
				      do
					 wget http://$BMCHOST/blackbox/record/screen$i.jpeg 
	                                  if [ $? -eq 0 ];then
        	                            echo "$BMCHOST-$i.jpg ok"
                	                  else
                        	            echo "failed download..screen$i.jpeg."
                                	  fi

				   done
				;;
				cget)
				
				  ipmitool $args raw 0x3a 0xaa 0x0
   				  if [ $? -eq 0 ];then
                                    echo "Manul capture ok"
                                  else
                                    echo "error.."
				    exit;
                                  fi
				  sleep 2
				  echo "prepare to download the pic"
				  sleep 3
				  wget http://$BMCHOST/blackbox/record/screen0.jpeg 
				  if [ $? -eq 0 ];then
				    echo "$BMCHOST-0.jpg ok"
				  else
				    echo "failed download..."
				  fi
				;;
				*)
				 echo "disable|enable|get  autocapture screen jpg
cget  -manul to capture screen jpg"
				;;
			      esac  
			  ;;
			*)
			 echo "-fail dia args : -bootcode|-ldfa|-pic|-sel|-blksel"
			;;
		   esac
		;;
             -ip)
		   case $gs in
                      -info)
		   	 lan1=`ipmitool $args lan print 1 | grep -E \
			 "IP Address Source|IP Address|Subnet Mask|MAC Address|Default Gateway IP"`
#add lan 8 ifpanduan
                   	  lan8=`ipmitool $args lan print 8 | grep -E \
			  "IP Address Source|IP Address|Subnet Mask|MAC Address|Default Gateway IP"`
		    	 echo "Channel 1 -dicated $lan1"
                    	 echo "Channel 8 -Sharelink $lan8"
                    ;;
		      -set)
			  if [ "x$gs1" = "xdhcp" ];then  
			       ipmitool $args lan set 1 ipsrc dhcp 2>/dev/null  >/dev/null
			       ipmitool $args lan set 8 ipsrc dhcp 2>/dev/null  >/dev/null
				
			  else
				ipmitool $args lan set $gs1 ipsrc static
				ipmitool $args lan set $gs1 ipaddr $gs2
				ipmitool $args lan set $gs1 netmsk $gs3
		        	ipmitool $args lan set $gs1 defgw ipaddr $gs4
                       		exit
                            
			fi
		       ;;
		     *)
                        echo "-ip args must be -info|-set"
		   esac
                ;;
             -ssh)
		    #echo $gs;
                    case "$gs" in
		     -login|-Login|-LOGIN|-lo|-LO)
			   auto_login_ssh $BMCPASS $BMCUSER@$BMCHOST
                       ;;
		      -enable|-En|-en|-Enabled|-enabled)
			 ipmitool $args  raw 0x32 0x6a 0x20 0x00 0x00 0x00 0x01 0x46 0x46 0x46 0x46 \
				 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x00 0xff 0xff \
				 0xff 0xff 0x16 0x00 0x00 0x00 0x58 0x02 0x00 0x00 0xff 0xff
		          if [ $? -eq 0 ];then
				echo "ok,ssh enabled"
		
			  fi
			 ;;
		      -disable|-dis|-DIS|-Disable|-disabled|-Disabled)
			  ipmitool $args  raw 0x32 0x6a 0x20 0x00 0x00 0x00 0x00 0x46 0x46 0x46 0x46 \
                                 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x00 0xff 0xff \
                                 0xff 0xff 0x16 0x00 0x00 0x00 0x58 0x02 0x00 0x00 0xff 0xff
                          if [ $? -eq 0 ];then
                                echo "ok,ssh disabled!"
                         
                          fi
		       ;;	
		       *)
 		      echo "ssh args must be in -login|-enable|-disable"
 			;;
		   esac
		  #ipmitool raw 0x32 0x6a 0x20 0x00 0x00 0x00 0x01 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x46 0x00 0xff 0xff 0xff 0xff 0x16 0x00 0x00 0x00 0x58 0x02 0x00 0x00 0xff 0xff
 		;;
             -user)
		  
                    case "$gs" in
		          -list)
			     ipmitool $args user list 1	
		        ;;
			  -addm)
                             userid=`ipmitool $args user list 1 | awk -v user=$gs2 '{if(user==$2)print $1}'`
                              if [ "x$userid" == "x$gs1" ] ;then
                                  if [ ! "x$gs2" == "x$BMCUSER" ];then
                                      user_add  $gs1 $gs2 $gs3 $gs4 "$args"
                                      user_add  $gs1 $gs2 $BMCPASS $gs4 "$args"
                                      exit
                                  fi
			      fi
                              echo "$gs1 $gs2 $gs3 $gs4 ---$BMCUSER"
			      user_add  $gs1 $gs2 $gs3 $gs4 "$args"
			   ;;
			  -del)
			       userid=$gs1
			       ipmitool $args raw 0x06 0x45 $userid 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0x00 
                               
			   ;;

			  *)
			    echo "user args must be in -list|-addm|del"
			   ;;
		     esac	
		;; 
	     -hn)
		  case "$gs" in
 		     -set)
                           if [ "x$gs1" = "x" ]; then
   				 echo "error ,-hn hostname be required!"
    				 exit;
 			   fi

			  sethostname $gs1 "$args"
		          #ipmitool raw 0x32 0x6c 0x01 0x00 0x00 0x08 $hostname
			;;
		     -info)
			  hninfo=`ipmitool $args raw 0x32 0x6b 0x01 0x00 2>/dev/null`
		          hextoasiic $hninfo
			;;
 		     *)
		      echo "hostname args must be in -set|-info"
		     ;;
		  esac
		;;
             -ntp)
                    case $gs in
                                -get|-GET)
                                  ntpdata=`ipmitool $args raw 0x3a 0x86 0x00 |awk '{for(i=3;i<=NF;i++)print $i}'`
                                  ntpip=`echo $ntpdata`
                                  ip=`hextoasiic $ntpip`
                                  ntpstatus=`ipmitool $args raw 0x3a 0x86 0x01 |awk '{print $2}'`
                                  if [ "x$ntpstatus" = "x01"  ] 
                                    then
                                      ntpstaus="disabled or network error !"  
                                  elif [ "x$ntpstatus" = "x00"  ]
                                    then
			               ntpstaus="ok"
                                  else
				    { 
                                     echo "get ntp status error,exit"
                                     exit;   
                                     }
                                  fi
                                  ip=`hextoasiic $ntpip`
                                  echo "ntp status: $ntpstaus"
                                  echo ntp:$ip
                                 ;;
                                -set|-SET)
                                      case $gs1 in 
                                        ip|IP)
                                          if [ "x$gs2" = "x"  ];then
					    echo "error!..\$ip is needed"
                                          else
					    ip=`stingstoasscii $gs2`
					    cnt=`echo $ip |wc -w`
				            #echo "a=$cnt"
					    cnt=`dectohex $cnt`
                                            #echo "b=$cnt" 
					    ipmitool $args raw 0x3a 0x85 0x00 $cnt $ip
                                            if [ $? -eq 0 ]
                                              then
					          echo "$gs2 set ok"
					    else
						 echo "$gs2 set error!"
					    fi
					  fi
					;;
					en|enable|EN|En)
                                          ipmitool $args raw 0x3a 0x85 0x01 0x00
			                  if [ $? -eq 0 ];then
                                             echo "ntp enable ok"
                                          else
                                             echo "ntp enable error"

					  fi
					  ;;
				        disable|dis|disa|Dis)
					 ipmitool $args raw 0x3a 0x85 0x01 0x01
					  if [ $? -eq 0 ];then
				             echo "ntp disable ok"
					  else
                                             echo "ntp disable error"

					  fi
					;;
                                        *)
                                           echo "ntp -set args must in en|dis | ip [\$ip]"
                                        ;;   
				      esac
                                 ;;
                                 *)
                                 echo "-ntp args in -get|-set [\$ip]"
                                ;;
                              esac
                           ;;
	     -snic)
		  case $gs in
		       -info)
		              nidata=`ipmitool $args raw 0x3a 0x13 2>/dev/null`
			      echo $nidata | awk '{if($2=="00")print "sharelink on nic1G";else\
						   if($2=="01")print "sharelink on nic10G";else\
						   if($2=="02")print "sharelink on Pcie nic";else\
						    print $0;	 }'
		    ;;
		       -set)
			     case $gs1 in
			        1g)
				  ipmitool $args raw 0x3a 0x12 0x00
				   if [ $? -eq 0 ] ;then
                                        echo "BMC  sharelink on then board 1G nic  OK"
                                   else
                                        echo "error..."
					exit 129;
                                   fi
				  ;;
				10g)
 				   ipmitool $args raw 0x3a 0x12 0x01
				   if [ $? -eq 0 ] ;then
                                        echo "BMC  sharelink on then board 10G nic  OK"
                                   else
                                        echo "error..."
					exit 129;
                                   fi
				  ;;
				pcie)
				   ipmitool $args raw 0x3a 0x12 0x02
				    if [ $? -eq 0 ] ;then
                                        echo "BMC  sharelink on then PCIE NIC  OK"
                                    else
                                        echo "error..."
					exit 129;
                                    fi
				  ;;
				*)
				  echo "sharelink nic -set args must be in 1g|10g|pcie"
				  exit
				 ;;
			     esac 
			     case $gs2 in
			         0)
				  ipmitool $args raw 0x0c 0x01 0x08 0xd2 0x00 0x00
				  if [ $? -eq 0 ] ;then
                                        echo "BMC  sharelink manual port OK"
                                  else
                                        echo "manual set error..."
					exit
                                  fi

				  ipmitool $args raw 0x0c 0x01 0x08 0xcd 0x00 0x00 0x00
				  if [ $? -eq 0 ] ;then
                                	echo "BMC  sharelink on nic the first port OK"
		                  else
                           		echo "error..."

                        	  fi

				  ;;
				 1)
				  ipmitool $args raw 0x0c 0x01 0x08 0xd2 0x00 0x00
                                  if [ $? -eq 0 ] ;then
                                        echo "BMC  sharelink manual port OK"
                                  else
                                        echo "manual set error..."
                                  	exit
                                  fi
				  #echo "ipmitool $args raw 0x0c 0x01 0x08 0xcd 0x00 0x00 0x01"
				  ipmitool $args raw 0x0c 0x01 0x08 0xcd 0x00 0x00 0x01
				    if [ $? -eq 0 ] ;then
                                        echo "BMC  sharelink on nic the second port OK"
                                  else
                                        echo "error...port set"

                                  fi

				  ;;
				 "fo")
				    ipmitool $args raw 0x0c 0x01 0x08 0xd2 0x00 0x01
				    if [ $? -eq 0 ] ;then
                                        echo "BMC  sharelink on fail over both port OK"
                                  else
                                        echo "error..."

                                  fi

				  ;;
				 *)
				  echo "nic port must be 0|1|fo"
				  ;;
			     esac
		    ;;
		       -dis|-disable|-Disable|-disabled|-Disabled)
                        
			ipmitool $args raw 0x3A 0x10 0x00 0x01
			if [ $? -eq 0 ] ;then
                                echo "BMC disable  sharelink on nic OK"
                                $dir/biosinfo $args sharelink disable
                        else
                           echo "error..."

                        fi

		    ;;
		       -en|-enable|-EN|-En|-Enable)
			ipmitool $args raw 0x3A 0x10 0x00 0x00
			if [ $? -eq 0 ] ;then
				echo "BMC open  sharelink on nic OK"
                        	$dir/biosinfo $args sharelink enable
			else
			   echo "error..."
			   	
			fi
		    ;;
		       -bon)
			    case $gs1 in
			       enable|en|En|EN|Enable)
				 ipmitool $args raw 0x32 0x71 0x01 0x01 0x00 0x00 0x64 0x00 0x03 0x00 
				 ipmitool $args raw 0x32 0x71 0x06 0x00 0x02
				 if [ $? -eq 0 ];then
				   echo "Bmc NIC Bond ok";
				 else
                                    echo "Bmc NIC Bond failed"
				 fi
				;;
			       disable|dis|Dis|Disable)
				  ipmitool $args raw 0x32 0x71 0x01 0x00 0x00 0x00 0x64 0x00 0x03 0x00
				  if [ $? -eq 0 ];then
                                   echo "Bmc NIC Bond del ok";
                                 else
                                    echo "Bmc NIC Bond del failed"
                                 fi

				;;
				*)
				 echo "-bon args must be in enable|disable";
				;;
			    esac
		    ;;
		       *)
			echo "-snic args must bu in -info|-set|-dis|-en|-bon"
		    ;;
		  esac
		;;
             *)
               usage $dir/../instool.sh
              ;;
       esac 

