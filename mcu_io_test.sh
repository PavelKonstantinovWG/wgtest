#!/bin/bash 

################################################################################
echo "Just test of MCU device IO"

#mcu_port_out=/dev/stdout
#mcu_port_in=/dev/stdin

mcu_port_out=/dev/ttyUSB0
mcu_port_in=/dev/ttyUSB0
################################################################################

 : ${MFG_HOME=${HOME}/manufacturing}

 echo "Load utils..."

# load main utils library
# it also creating test lock file in /tmp/${STATION_NAME}.lock
# exit_test should be called later to remove it
if [ -f $MFG_HOME/utils.sh ]; then
        . $MFG_HOME/utils.sh
else
        echo "Missing utils file - exiting"
        exit 1
fi

logfile=$logs_dir/MCU_io_test.log


echo "Load BK utils..."

#load BK library 
load_bk_procs

echo "Power on MCU"

#power on 
bk_init    

echo "Send @v to MCU on $mcu_port_out"

echo "@v" > $mcu_port_out
[ $? != 0 ] && die "Can not write to MCU"

echo "Read response from MCU $mcu_port_in"

read resp < $mcu_port_in
[ $? != 0 ] && die "Can not read from MCU"

echo "Response: $resp"

exit_test
