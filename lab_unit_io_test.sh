#!/bin/bash 

################################################################################
echo "Just test of Lab unit device IO"

#mcu_port_out=/dev/stdout
#mcu_port_in=/dev/stdin
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

logfile=$logs_dir/lab_unit_io_test.log

echo "Load BK utils..."

#load BK library 
load_bk_procs

echo "Load POD Server FIFO exchange utils ..."
#load util to excnage with PosdServer FIFO
load_remote_procs

echo "Check for POD Server is running ..."
[ ! -f $podserver_lockfile ] && die $"POD Server not running (no lock $podserver_lockfile)"
[ ! -p /tmp/rx_fifo -o ! -p /tmp/tx_fifo ] && die $"POD Server not running (no FIFO)"

#clear fifo
echo "Clear fifo ..."
drain_fifo

echo "Power on MCU"

#power on 
bk_init    

echo "Switch ON all LEDs"
set_led 0 $OPTIC_VALIDATE_INTENSITY || die $"failed 0"
set_led 1 $OPTIC_VALIDATE_INTENSITY || die $"failed 1"
set_led 2 $OPTIC_VALIDATE_INTENSITY || die $"failed 2"

echo "Sleep for 3 secs..."
sleep 3

echo "Switch LEDs off"

led_off || die $"Off failed 2"

echo "Done"

exit_test
