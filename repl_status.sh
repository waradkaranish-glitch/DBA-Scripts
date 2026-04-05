#!/bin/bash
#################################################
#         Script to check repl status           #
#         Ver: 1                                #    
#################################################

# Defining environment variables
ENV=`grep enviro /usr/local/etc/progress_agent*.cfg | awk -F "=" '{print $2}'`
QADENV=`grep qadenv /usr/local/etc/progress_agent*.cfg | awk -F "=" '{print $2}'`
if [ ${QADENV} == "prod" -o ${QADENV} == "PROD" ]
then 
export QADENVD=SOURCE
elif [ ${QADENV} == "dr" -o ${QADENV} == "DR" ]
then 
export QADENVD=DR
else 
export QADENVD=`echo ${QADENV}`
echo "This is a Non-PROD env, hence exiting..."
exit 1
fi

export DLC=/${ENV}/apps/dlc
export DBUTIL=${DLC}/bin/_dbutil
export DB_DIR=/${ENV}/db/${ENV}db

cd ${DB_DIR}
printf "\033[1;34m HOST: `hostname|tr [:lower:] [:upper:]` - ENV:${QADENVD} - DATE: `date` \033[0m\n"
printf "\n"
_DR=`grep "host=" ${DB_DIR}/admdb.repl.properties |cut -d"=" -f 2`
printf "\033[1;34m DR HOST: ${_DR} \033[0m\n"
printf "\n"

echo "+---------------+-----------------------+--------------------------------+"; \
echo -e "|Database\t|Replication Status\t|Replication Processing          |"; \
echo "+---------------+-----------------------+--------------------------------+"; \
for i in `ls *.db`
do
   if [ -f  ${i%.db}.repl.properties ]
     then 
     REPL_STATUS=$(${DLC}/bin/dsrutil ${i%.db} -C status 2> /dev/null) 
     if [ ${QADENVD} == "SOURCE" ]
     then 
     REPL_PROCESSING=$(echo -e "S\nQ" | ${DLC}/bin/dsrutil ${i%.db} -C monitor 2> /dev/null | grep -i 'Server is' | awk -F ":" '{print $NF}' | sed -e 's/^[ \t]*//')
     echo -e "| ${i%.db}   \t| \t ${REPL_STATUS} \t\t| ${REPL_PROCESSING} \t\t|"; \
     else
     echo -e "A\n\nQ\Q" | ${DLC}/bin/dsrutil ${i%.db} -C monitor > /tmp/${i%.db}.repl.txt 2> /dev/null 
     REPL_PROCESSING=`grep -i 'State' /tmp/${i%.db}.repl.txt | awk -F ":" '{print $NF}' | sed -e 's/^[ \t]*//'`
     REPL_SECS=`grep "Repl Server behind Source DB by" /tmp/${i%.db}.repl.txt | awk -F ":" '{print $NF}' | sed -e 's/^[ \t]*//' | awk -F " " '{print $1}'`
     #echo $REPL_SECS
     if [ ${REPL_SECS} -ne 0 ]
     then
     REPL_SRC_TRAN=`grep "Current Source Database Transaction" /tmp/${i%.db}.repl.txt | awk -F ":" '{print $NF}' | sed -e 's/^[ \t]*//'`
     REPL_TAR_TRAN=`grep "Last Transaction Applied to Target" /tmp/${i%.db}.repl.txt | awk -F ":" '{print $NF}' | sed -e 's/^[ \t]*//'`
     REPL_TAR_BEH=$(expr "$REPL_SRC_TRAN" - "$REPL_TAR_TRAN")
     echo -e "| ${i%.db}   \t| \t ${REPL_STATUS} \t\t| ${REPL_PROCESSING} \t\t| ${i%.db} on DR is behind SOURCE by: ${REPL_SECS} Sec's & ${REPL_TAR_BEH} Transactions."; \
     else 
     echo -e "| ${i%.db}   \t| \t ${REPL_STATUS} \t\t| ${REPL_PROCESSING} \t\t |"; \
     fi
     rm -f /tmp/${i%.db}.repl.txt 
     fi
     else 
     continue
   fi
done
echo "+---------------+-----------------------+--------------------------------+"; \

