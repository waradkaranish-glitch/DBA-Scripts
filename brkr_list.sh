[ $# -ne 3 ] && echo -e "SYNTAX: brkr_list.sh <ENV> <AdminServer Port> <NameServer>\ne.g. brkr_list.sh qond 18000 NS1" && exit

export DLC=/${1}/apps/dlc
export PATH=$DLC:$DLC/bin:$PATH
export ADMSR_PORT=${2}
export NM_SRVR=${3}

echo "+-----------------------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+"; \
echo -e "| AppServer / WebSpeed\t| MXSRV\t| TOTAL\t| AVLBL\t| BUSY\t| RUNNG\t| SENDG\t| LOCKD\t| MXCLT\t| CLTNW\t| CLTPK\t|"; \
echo "+-----------------------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+"; \
# for i in `nsman -i ${NM_SRVR} -port ${ADMSR_PORT} -q | grep \`hostname\` | grep -v "^NameServer" | awk '{ print $2 }' | awk -F"." '{ print $2 }'`

for i in `nsman -i ${NM_SRVR} -port ${ADMSR_PORT} -q | grep -i \`hostname\` | grep -v "^NameServer" | awk '{ print $(NF-4) }' | awk -F"." '{ print $2 }'`
do
   _cmd="asbman -i ${i} -port ${ADMSR_PORT}"
   [ "`echo ${i} | grep \"_WS$\"`" != "" ] && _cmd="wtbman -i ${i} -port ${ADMSR_PORT}"
OUT_FL="/tmp/${i}_status"
${_cmd} -q | egrep "AVAILABLE|BUSY|RUNNING|SENDING|LOCKED|Active Clients" > ${OUT_FL}
${_cmd} -listallprops | egrep "^maxSrvrInstance|^maxClientInstance" >> ${OUT_FL}
if [ `echo ${i} | wc -c` -gt 14 ]
then
echo -e "| ${i}\t|\c"
elif [ `echo ${i} | wc -c` -lt 7 ]
then
echo -e "| ${i}\t\t\t|\c"
else
echo -e "| ${i}\t\t|\c"
fi
MXSRVINST=`awk -F"=" '/^maxSrvrInstance/{ print $NF }' ${OUT_FL}`
AVLBL=`grep AVAILABLE ${OUT_FL} | wc -l`
BSY=`grep BUSY ${OUT_FL} | wc -l`
RNG=`grep RUNNING ${OUT_FL} | wc -l`
SNDG=`grep SENDING ${OUT_FL} | wc -l`
LKD=`grep LOCKED ${OUT_FL} | wc -l`
MAXCLIENTINSTANCE=`awk -F"=" '/^maxClientInstance/{ print $NF }' ${OUT_FL}`
ACT_CLIENTS=`grep "Active Clients" ${OUT_FL} | awk -F":" '{ print $NF }' | sed 's/(//g' | sed 's/)//g' | sed 's/,//g'`
ACT_CLIENTS_NOW=`echo ${ACT_CLIENTS} | awk '{ print $1 }'`
ACT_CLIENTS_PEAK=`echo ${ACT_CLIENTS} | awk '{ print $2 }'`
echo -e " ${MXSRVINST}\t| `expr ${AVLBL} + ${BSY} + ${RNG} + ${SNDG} + ${LKD}`\t| ${AVLBL}\t| ${BSY}\t| ${RNG}\t| ${SNDG}\t| ${LKD}\t| ${MAXCLIENTINSTANCE}\t| ${ACT_CLIENTS_NOW}\t| ${ACT_CLIENTS_PEAK}\t|"
rm -f ${OUT_FL}
done; echo "+-----------------------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+"

# echo

# /usr/remote/odutils/dba/brkr_list_a.sh ${1} ${2} ${3}
