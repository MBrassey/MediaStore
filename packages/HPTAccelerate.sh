#HighPoint Accelerate Linux Open Source.
#Copyright (C) 2022 HighPoint Technologies, Inc. All rights reserved.
#HPTAccelerate.sh is used to improve the performance of HighPoint RAID devices by binding cpu cores.

ts=`date +%m%d_%H%M%S`

help(){
  echo "HPTAccelerate.sh is used to improve the performance of HighPoint RAID devices."
  echo "It can bind a specified number of CPU cores on a single CPU"
  echo "to the HighPoint RAID device to reduce losses and improve performance."
  echo "Can only accelerate operations that are running or about to"
  echo "start running on the HighPoint RAID devices."
  echo ""
  echo "Prerequisites:"
  echo "  1.Server platform with multiple cpus"
  echo "  2.Insert HighPoint RAID controller"
  echo "  3.Load HighPoint RAID driver"
  echo ""
  echo "./HPTAccelerate.sh [options] <command>"
  echo "  -c                          Specify the number of cpu cores."
  echo "  -d                          Specify device name(hptnvme, rr3740a)."
  echo "  -h, --help                  Print this message and exit."
  echo ""
  echo "For example:"
  echo "If you want to copy /test/a to /test/b(cp -r /test/a /test/b)"
  echo "and want to bind 4 cpu cores on hptnvme:"
  echo "./HPTAccelerate.sh -c 4 -d hptnvme cp -r /test/a /test/b"
  echo ""
  echo "If you want to run kdenlive"
  echo "and bind 8 cpu cores on rr3740a:"
  echo "./HPTAccelerate.sh -c 8 -d rr3740a kdenlive"
  echo ""
  echo "If you want to run kdenlive and bind all HighPoint RAID"
  echo "device's cpu cores on only one device type you have："
  echo "./HPTAccelerate.sh kdenlive"
}

hpt_irq=`grep hptnvme /proc/interrupts | cut -d: -f1`
rr37_irq=`grep rr37 /proc/interrupts | cut -d: -f1`
if [ "$hpt_irq" = "" ] && [ "$rr37_irq" = "" ]; then
  echo "HighPoint RAID controller does not load"
  echo ""
  help
  exit 1
elif [ "$hpt_irq" != "" ] && [ "$rr37_irq" = "" ]; then
  driver=hptnvme
elif [ "$hpt_irq" = "" ] && [ "$rr37_irq" != "" ]; then
  driver=rr3740a
elif [ "$hpt_irq" != "" ] && [ "$rr37_irq" != "" ]; then
  driver=all
fi

hptnvme_info(){
  echo "command:$str" > HPTAccelerate.$ts.log
  hptint=`grep hptnvme /proc/interrupts | tr -s ' '`
  echo "hptint:$hptint" >> HPTAccelerate.$ts.log
  hptirqnum=`grep hptnvme /proc/interrupts | tr -s ' ' | cut -d : -f 1`
  for i in $hptirqnum;do
    hptirqcore=`cat /proc/irq/$i/effective_affinity_list`
    echo "hpt_effective_affinity_list=$i:$hptirqcore" >> HPTAccelerate.$ts.log
  done
  
  hpt_local_cpulist=`cat /sys/bus/pci/drivers/hptnvme/0000\:*/local_cpulist | head -n 1`

  #Calculate the number of cores of a single cpu
  cpus=`lscpu | grep -i "CPU(s)" | head -n 1 | tr -s ' ' | cut -d ' ' -f 2`
  cpunum=`lscpu | grep -i "NUMA node(s)" | tr -s ' ' | cut -d ' ' -f 3`
  single_corenum=`expr $(($cpus/$cpunum))`

  #Extract the specified number of cpu core numbers
    hpt_numanode=`lscpu | grep "$hpt_local_cpulist" | cut -d ' ' -f 2 | cut -b 5`
    socket=`awk -F: '{
        if ($1 ~ /processor/) {
              gsub(/ /,"",$2);
              p_id=$2;
        }else if ($1 ~ /physical id/){
              gsub(/ /,"",$2);
              s_id=$2;
              arr[s_id]=arr[s_id] " " p_id
        }
    }
    END{
     for (i in arr)
        printf "NUMA node %s:%s\n", i, arr[i];
    }' /proc/cpuinfo`
    echo "$socket" >> HPTAccelerate.$ts.log
    hpt_cpulist=`echo ${socket#*$hpt_numanode:} | cut -d ' ' -f -$single_corenum | tr -s ' ' ','`
    echo "hpt_local_cpulist:$hpt_cpulist" >> HPTAccelerate.$ts.log
    
  if test "$opt" = "-c";then
    hpt_tasksetpid=`echo $hpt_cpulist | cut -d ',' -f -$num`
  else
    hpt_tasksetpid=$hpt_cpulist
  fi
  echo "hpt_tasksetpid:$hpt_tasksetpid" >> HPTAccelerate.$ts.log
}

rr3740a_info(){
  echo "command:$str" > HPTAccelerate.$ts.log
  rr37int=`grep rr37 /proc/interrupts | tr -s ' '`
  echo "rr37int:$rr37int" >> HPTAccelerate.$ts.log
  rr37irqnum=`grep rr37 /proc/interrupts | tr -s ' ' | cut -d : -f 1`
  for i in $rr37irqnum;do
    rr37irqcore=`cat /proc/irq/$i/effective_affinity_list`
    echo "rr37_effective_affinity_list=$i:$rr37irqcore" >> HPTAccelerate.$ts.log
  done

  rr37_local_cpulist=`cat /sys/bus/pci/drivers/rr3740a/0000\:*/local_cpulist | head -n 1`

  #Calculate the number of cores of a single cpu
  cpus=`lscpu | grep -i "CPU(s)" | head -n 1 | tr -s ' ' | cut -d ' ' -f 2`
  cpunum=`lscpu | grep -i "NUMA node(s)" | tr -s ' ' | cut -d ' ' -f 3`
  single_corenum=`expr $(($cpus/$cpunum))`

  #Extract the specified number of cpu core numbers
    rr37_numanode=`lscpu | grep "$rr37_local_cpulist" | cut -d ' ' -f 2 | cut -b 5`
    socket=`awk -F: '{
        if ($1 ~ /processor/) {
              gsub(/ /,"",$2);
              p_id=$2;
        }else if ($1 ~ /physical id/){
              gsub(/ /,"",$2);
              s_id=$2;
              arr[s_id]=arr[s_id] " " p_id
        }
    }
    END{
     for (i in arr)
        printf "NUMA node %s:%s\n", i, arr[i];
    }' /proc/cpuinfo`
    echo "$socket" >> HPTAccelerate.$ts.log
    rr37_cpulist=`echo ${socket#*$rr37_numanode:} | cut -d ' ' -f -$single_corenum | tr -s ' ' ','`
    echo "rr37_local_cpulist:$rr37_cpulist" >> HPTAccelerate.$ts.log
    
  if test "$opt" = "-c";then
    rr37_tasksetpid=`echo $rr37_cpulist | cut -d ',' -f -$num`
  else
    rr37_tasksetpid=$rr37_cpulist
  fi
  echo "rr37_tasksetpid:$rr37_tasksetpid" >> HPTAccelerate.$ts.log
}

bind(){
  #In some systems, cp|mv|rm comes with -i by default(e.g. in ubuntu, in /root/.bashrc, alias cp='cp -i', alias mv='mv -i', alias rm='rm -i')
  test=$(echo $temp | grep -E "cp|mv|rm")
  if test "$test" != "";then
    #Find parent process
    if test "$opt" = "-c";then
	    #If it is -c, the third parameter is followed by the command （e.g. ./HPTAccelerate -c 4 fio, fio is the command)
        s_str=`echo "$str" | cut -d ' ' -f 3-`
        pid=`ps -ef | grep "$s_str" | grep -v grep | tr -s ' ' | cut -d ' ' -f 2 | head -n 1`
		allpid=`ps -ef | grep "$s_str"`
		echo "allpid:$allpid" >> HPTAccelerate.$ts.log
		echo "PID:$pid" >> HPTAccelerate.$ts.log
    else
        pid=`ps -ef | grep "$str" | grep -v grep | tr -s ' ' | cut -d ' ' -f 2 | head -n 1`
		allpid=`ps -ef | grep "$str"`
		echo "allpid:$allpid" >> HPTAccelerate.$ts.log
		echo "PID:$pid" >> HPTAccelerate.$ts.log
    fi
        #Direct search did not find
        if test "$pid" = "";then
            #Add -i to find again
            if test "$opt" = "-c";then
			    #e.g. cp -r /test/a /test/b -> cp -i -r /test/a /test/b
                new=$(echo "`echo "$temp" | cut -d ' ' -f 3` -i `echo "$temp" | cut -d ' ' -f 4-`")
            else
                new=$(echo "`echo "$temp" | cut -d ' ' -f 1` -i `echo "$temp" | cut -d ' ' -f 2-`")
            fi
            s_pid=`ps -ef | grep "$new" | grep -v grep | tr -s ' ' | cut -d ' ' -f 2 | head -n 1`
			allpid=`ps -ef | grep "$new"`
		    echo "allpid:$allpid" >> HPTAccelerate.$ts.log
		    echo "PID:$s_pid" >> HPTAccelerate.$ts.log
            #Search again and nothing, the program is not running
            if test "$s_pid" = "";then
                if test "$opt" = "-c";then
                  if test "$driver" = "hptnvme";then
                    taskset -c $hpt_tasksetpid `echo "$temp" | cut -d ' ' -f 3-`
                  elif test "$driver" = "rr3740a";then
                    taskset -c $rr37_tasksetpid `echo "$temp" | cut -d ' ' -f 3-`
                  fi
                else
                  if test "$driver" = "hptnvme";then
                    taskset -c $hpt_tasksetpid $temp
                  elif test "$driver" = "rr3740a";then
                    taskset -c $rr37_tasksetpid $temp
                  fi
                fi
            #Program is running
            else
                #Find all child processes by parent process
                a_pid=`pstree -p $s_pid | cut -d "(" -f 2 | cut -d ")" -f 1`
				allpid=`pstree -p $s_pid`
		        echo "PID:$allpid" >> HPTAccelerate.$ts.log
                for i in $a_pid; do
                  if test "$driver" = "hptnvme";then
                    taskset -pc $hpt_tasksetpid $i
                  elif test "$driver" = "rr3740a";then
                    taskset -pc $rr37_tasksetpid $i
                  fi
                done
            fi
        #Program is running
        else
            #Find all child processes by parent process
            a_pid=`pstree -p $pid | cut -d "(" -f 2 | cut -d ")" -f 1`
			allpid=`pstree -p $pid`
		    echo "PID:$allpid" >> HPTAccelerate.$ts.log
            for j in $a_pid; do
              if test "$driver" = "hptnvme";then
                taskset -pc $hpt_tasksetpid $j
              elif test "$driver" = "rr3740a";then
                taskset -pc $rr37_tasksetpid $i
              fi
            done
        fi
  #Command without cp|mv|rm
  else
        #Find parent process
        if test "$opt" = "-c";then
            s_str=`echo "$str" | cut -d ' ' -f 3-`
            pid=`ps -ef | grep "$s_str" | grep -v grep | tr -s ' ' | cut -d ' ' -f 2 | head -n 1`
			allpid=`ps -ef | grep "$s_str"`
		    echo "allpid:$allpid" >> HPTAccelerate.$ts.log
		    echo "PID:$pid" >> HPTAccelerate.$ts.log
        else
            pid=`ps -ef | grep "$str" | grep -v grep | tr -s ' ' | cut -d ' ' -f 2 | head -n 1`
			allpid=`ps -ef | grep "$str"`
		    echo "allpid:$allpid" >> HPTAccelerate.$ts.log
		    echo "PID:$pid" >> HPTAccelerate.$ts.log
        fi
        #Program is not running
        if test "$pid" = "";then
            if test "$opt" = "-c";then
              if test "$driver" = "hptnvme";then
                taskset -c $hpt_tasksetpid `echo "$temp" | cut -d ' ' -f 3-`
              elif test "$driver" = "rr3740a";then
                taskset -c $rr37_tasksetpid `echo "$temp" | cut -d ' ' -f 3-`
              fi
            else
              if test "$driver" = "hptnvme";then
                taskset -c $hpt_tasksetpid $temp
              elif test "$driver" = "rr3740a";then
                taskset -c $rr37_tasksetpid $temp
              fi
            fi
        #Program is running
        else
            #Find all child processes by parent process
			a_pid=`pstree -p $pid | cut -d "(" -f 2 | cut -d ")" -f 1`
			allpid=`pstree -p $pid`
		    echo "PID:$allpid" >> HPTAccelerate.$ts.log
            for k in $a_pid; do
              if test "$driver" = "hptnvme";then
                taskset -pc $hpt_tasksetpid $k
              elif test "$driver" = "rr3740a";then
                taskset -pc $rr37_tasksetpid $k
              fi
            done
        fi
  fi
}

str=`echo $*`
temp=`echo $@`

case $1 in
  -h | --help)
  help
  exit 0
  ;;
  -c)
  opt=`echo $1`
  num=`echo $2`
  c_driver=`echo $3`
  if test "$c_driver" = "-d";then
    driver=`echo $4`
    str=`echo $* | cut -d ' ' -f 1-2,5-`
    temp=`echo $@ | cut -d ' ' -f 1-2,5-`
  fi
  
  if [ "$c_driver" != "-d" ] && [ "$driver" = "all" ];then
    echo "Multiple devices detected, use -d to select device type."
    echo ""
    help
    exit 1
  fi
    
    ${driver}_info
  if test "$num" -gt "$single_corenum";then
    echo "Out of range"
    echo "maximum number:$single_corenum"
    exit 1
  else   
    bind
  fi
  ;;
  -d)
  opt=`echo $3`
  num=`echo $4`
  driver=`echo $2`
  str=`echo $* | cut -d ' ' -f 3-`
  temp=`echo $@ | cut -d ' ' -f 3-`
    ${driver}_info
  if test "$num" -gt "$single_corenum";then
    echo "Out of range"
    echo "maximum number:$single_corenum"
    exit 1
  else   
    bind
  fi
  ;;
  *)
  if test "$str" = "";then
  help
  exit 1
  fi
  
  if test "`echo $opt | cut -b 1 | grep "-"`" != "";then
    help
    exit 1
  fi
  
  if test "$driver" = "all";then
    echo "Multiple devices detected, use -d to select device type."
    echo ""
    help
    exit 1
  fi
  
  ${driver}_info
  bind
  ;;
esac
