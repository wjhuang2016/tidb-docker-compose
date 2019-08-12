output(){
    write=$(sudo cat /proc/$pid/io | grep 'write_bytes' | awk 'NR==1{print $2}')
    read=$(sudo cat /proc/$pid/io | grep 'read_bytes' | awk 'NR==1{print $2}')
    write=$(awk 'BEGIN{printf "%.2f\n",('$write'/1048576/1024)}')G
    read=$(awk 'BEGIN{printf "%.2f\n",('$read'/1048576/1024)}')G
    data=$(sudo du -h ./data | awk 'END {print $1}')
    echo -e $1"\t"$read"\t"$write"\t"$data >> ${output_file}
}

dir=~/summer
output_file=$dir/test.txt 
yml=ycsb-docker-compose.yml
workload=workloada
echo '===================='>>${output_file}
echo `cat $yml | awk 'NR==25{print}'` >>${output_file}
echo 'workload: '$workload >> ${output_file}
echo -e "state\t\tread\twrite\tdata">>${output_file}
sudo rm -rf data
docker-compose -f ${yml} up -d
pid=$(ps -aux | grep 'tikv-server' |  grep -v grep | awk '{print $2}')
output 'before\t'
docker-compose -f ${yml} run ycsb load tikv -P workloads/${workload} -p tikv.pd=pd0:2379
output 'load\t'
docker-compose -f ${yml} run ycsb run tikv -P workloads/${workload} -p tikv.pd=pd0:2379
output 'load+run'
docker-compose -f ${yml} down
cat ${dir}/test.txt
