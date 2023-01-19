#!/bin/bash
#@author: Taha
if [ "$EUID" -ne 0 ]
  then echo "Permission Denied Please Run as Super User!!"
  exit
fi

clear
is_installed=$(which curl)
if [ -z $is_installed ] ;
then
    sudo apt-get install curl
fi
clear
is_installed=$(which sysbench)
if [ -z $is_installed ] ;
then
    curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
    sudo apt -y install sysbench
fi
clear
is_installed=$(which dmidecode)
if [ -z $is_installed ] ;
then
	sudo apt-get install dmidecode
fi
clear
lscpu | grep -E '^Thread|^Core|^Socket|^CPU\(' > util_cpu.txt
tail util_cpu.txt | awk '{print $NF}' > numbers.txt
rm util_cpu.txt

num_of_threads="1"
counter="0"
while read line;
 do	
	if [ $counter -eq 0 ]
	then
		CPU=$line
		echo "CPU = $CPU"
	elif [ $counter -eq 1 ]
	then
		thread=$line
		echo "thread  = $thread"
	elif [ $counter -eq 2 ]
	then
		Core=$line
		echo "Core = $Core"
	elif [ $counter -eq 3 ]
	then
		Socket=$line
		echo "Socket = $Socket"
	fi	
	((counter=counter+1))
	
 done < numbers.txt
((num_of_threads=Core*Socket*thread))
rm numbers.txt
echo "NUM_OF_THREADS = $num_of_threads"
echo "**********CPU STATISTICS****************" > bench.txt
echo "	CPU vs Thread: $num_of_threads - $CPU" >> bench.txt
sudo dmidecode --type processor | egrep "Manufacturer|Version|Core Count|Thread Count|Max Speed" >> bench.txt
sysbench cpu --cpu-max-prime=200000 --threads=$num_of_threads run |egrep 'General statistics|total time|Latency|    min|    avg|    max|execution time ' >> bench.txt
echo "**********MEMORY STATISTICS*************" >> bench.txt
sudo dmidecode --type 17 | egrep 'Type:|Size:' >> bench.txt
echo "SPEED :" >> bench.txt
sysbench memory --memory-block-size=1M --memory-total-size=100G --threads=$num_of_threads run |egrep 'MiB transferred |General statistics|total time|    min|    avg|    max|execution time ' >> bench.txt
echo "Done please open the bench.txt from your Desktop"
