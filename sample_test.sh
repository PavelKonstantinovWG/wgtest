#!/bin/bash 

####  It's sample test script just to try do simple measure
#
# Requirements:
# - This file is placed in manufacturing folder as usual test scripts
# - DC Power Supplies Model 9201 is powered up and ready for do tests (whatever it means)
# - BK9201 is connected to /dev/ttyUSB1 
# - MCU's power is connected to output of BK9201
# - MCU's card serial interface is connected to /dev/ttyUSB0
# - POD Server is working as daemon

####  Test plan


####### global code runs at startup

 : ${MFG_HOME=${HOME}/manufacturing}

# load main utils library
# it also creating test lock file in /tmp/${STATION_NAME}.lock
# exit_test should be called later to remove it
if [ -f $MFG_HOME/utils.sh ]; then
        . $MFG_HOME/utils.sh
else
        echo "Missing utils file - exiting"
        exit 1
fi

#load additional library to exchange with POD by POS Server FIFO.
#load_remote_procs

#load library to exchnage with BK9201 power supply 
load_bk_procs

# current measure finction
# measures current several times and compares result with test limits
# stares result to output as string 
mesure_current()
{
    
    #reset temp file content
    (> /tmp/current.log)

    local i mean res cur

    #measure current 5 times with 1 sec pause
    for((i=0;i<5;i++)); do

        #append current value as new string to current.log
        cur=$(bk_meas current)
        echo $cur >> /tmp/current.log

        # store each measure in log
        log $" MCU idle current probe $i) $cur"

        # echo a progress value for yad. It will move progress to this position
        echo $(expr $i \* 20) 

    # displays progress and eats output from loop to move progress (if yad fails -> exit_test)
    done  | yad --progress --center --width=300 --auto-close --title="Testing ..." 

    # calculates RMS? from results in current.log
	mean=$(cat /tmp/current.log | st -f "%.4f" -m)

    # check result against test limits and reurn result as string ( $RESULT_PASS, $RESULT_FAIL, $RESULT_WARN)
    res=$(get_result $mean $MCU_IDLE_CURRENT_MEAN $MCU_IDLE_CURRENT_STDEV)

	log $" MCU idle current: $mean - $res"

    #TODO: pass measure_type as argument to store it in log

    # common of log test result as CSV 
    # columns
    # device_serial, operator_serial, value_name, measure_type, value, check_result
	manual_log "$sn,$id,MCU_IDLE_CURRENT,0,$mean,$res" 

    echo $res   
}

# This is main test function
# - Conatains test code
# - Interact with operator
# - runs inside loop
# - return value should be 0 to pass test
#
# NB: some tests returns 1 as "warinig" that requires apropriate test result handling

run_test()
{
    # get serial number of operator, stored in $id
	get_operator_id || return $MES_QUERY_FAILED

    # get serial number of device. stored in $sn
	get_serial_num || return $MES_QUERY_FAILED

    # set name of detailed test-specific log file. 
    # Name depends on device serial number 
    logfile=$logs_dir/idle_current_${sn}.log

    # if log file absent - creates empty one
	[ ! -f $logfile ] && touch $logfile

    # log() - writing text to file prepared above
    log $"Idle MCU current - sample test"

    # check bk connection
    # set it to remote contrl mode
    # set power output off
    # set power output 6V 2A
    # wait ~12 seconds to reboot MCU
    bk_init    

   #measure current 5 times with 1 sec pause
    for((i=0;i<10;i++)); do
        # echo a progress value for yad. It will move progress to this position
        echo $(expr $i \* 10) 
        sleep 2
    # displays progress and eats output from loop to move progress (if yad fails -> exit_test)
    done  | yad --progress --center --width=300 --auto-close --title="Waiting to idle mode..."     

    echo "Going measure..."

    #measure urrent and put it to 
    test_res=$(mesure_current)

    case "$test_res" in
    $RESULT_FAIL)
        return 2;
        ;;

    $RESULT_WARN)
        return 1;
        ;;

    $RESULT_PASS)        
        return 0;
        ;;
    *)
        return 2; # something undefined
        ;;
    esac    
}

# Now run test in loop and check test result

# endless loop
while [ 1 ]; do

    #run test
	run_test

    #get rturn code
	rc=$?

    # if no problem with scaning serials 
	if [ "$rc" != $MES_QUERY_FAILED ]; then
		log "------------------------------------------"

	if [ "$rc" = 0 -o "$rc" = 1 ]; then 
			passed # writes test result to general test log
		else
			failed # writes test result to general test log
		fi
	fi

    #reset serial number and log file to avoid mistakes
	sn=    
	logfile=
done

# remove lock files
exit_test