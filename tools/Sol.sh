#!/bin/bash
solcmd=""
COOKIE=""
BMCHOST=$3
                BMCUSER=$4
                BMCPASS=$5

dir=`echo $0 |sed 's/\/Sol.sh//g'`
function usage()
{
cat <<EOF       
        
        $1  \$bmcIP \$user \$password -sol [options]
        options:
                -h       get help ,this option: ip user password must be needed all
                -info    get bios/bmc sol info
                -set      get bios/bmc kpbs sol para [options]
			  option:
                          -bios enable/disable
                          -bmc  115.2/19.2
                -act     activate sol with ipmitool
	        -dea   deactivate sol with ipmitool

       In OS:
	 1. edit "/boot/grub/grub.conf"
	    in kernel row at last add	"console=tty0 console=ttyS0,115200n8"
	 2. edit "/etc/inittab" add new row:
	    " S0:2345:respawn:/sbin/agetty  -L 115200 ttyS0"
	 3. edit "/etc/securetty" add new row
	    "ttyS0"
EOF
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
                ARGstart="$4"
                args=""
                usage $dir/../instool.sh
                exit
        else
                ARGstart="$7"
                args="-I lanplus -H $3 -U $4 -P $5"
        fi
        case $ARGstart in
             -h)
              usage $0
                ;;
             -info)
 		 echo "BIOS sol" : `$dir/biosinfo  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS redirection | awk  '{print $6}'`
                 echo "BMC  sol" : `ipmitool -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol info | grep -E "Enabled|Non-Volatile" \
			| awk -F : '{print $2}'`|sed 's/true/Enabled/g'|sed 's/false/Disabled/g'
                 
                ;;
             -set)
		    case $8 in
			-bios|-BIOS|-Bios)
				case $9 in
				 enable|Enabled|ENABLE|enabled|Enable)
		   	 	$dir/biosinfo  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS redirection  enable
                 	         ;;
			  	  disable|Disabled|DISABLE|DISABLED|Disable)
				   $dir/biosinfo  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS redirection disable
				 ;;
				 *)
                                   echo error..... SOL must be in "enable or disable"!!
					;;
 				esac
                        ;;
                        -BMC|-bmc|-Bmc)
			        case $9 in
					115.2|115200)
					 ipmitool  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol set non-volatile-bit-rate 115.2
					 ipmitool  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol set volatile-bit-rate 115.2	
					;;
					19200|19.2)
					  ipmitool  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol set non-volatile-bit-rate 19.2
                                         ipmitool  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol set volatile-bit-rate 19.2
					;;
					*)
      					 echo "BMC kpbs must be in 115.2 or 19.2 or Derect use follow cmd to set:
ipmitool  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol set non-volatile-bit-rate 'Serial | 9.6 | 19.2 | 38.4 | 57.6 | 115.2'
ipmitool  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol set volatile-bit-rate 'Serial | 9.6 | 19.2 | 38.4 | 57.6 | 115.2'
 					  "
exit
					;;
				esac	
				echo "BMC  sol" : `ipmitool -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol info | grep -E "Enabled|Non-Volatile" \
                        | awk -F : '{print $2}'`|sed 's/true/Enabled/g'|sed 's/false/Disabled/g'

			;;
                        *)
			usage $0
                   esac
 		;;
             -act)
	          echo BIOS sol : `$dir/biosinfo  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS redirection | awk  '{print $6}'`
		  echo "Quit:  ~."
                  ipmitool  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol deactivate
                  ipmitool  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol activate
         
		;;
              -dea)
		 ipmitool  -I lanplus -H $BMCHOST -U $BMCUSER -P $BMCPASS sol deactivate
		;;
             *)
               usage $dir/../instool.sh
              ;;
       esac 

