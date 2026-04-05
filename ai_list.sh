#/bin/bash

export DLC=/${1}/apps/dlc
export DBUTIL=${DLC}/bin/_dbutil
export DB_DIR=/${1}/db/${1}db
export RED='\033[0;31m'
export NO_COLOR='\033[0m'
export BOLD_YELLOW='\033[1;33m'
export BOLD_CYAN='\033[1;36m'

cd ${DB_DIR}

echo "+---------------+-------+-------+--------+------+--------+--------------+----------+"; \
echo -e "| Database\t| Empty\t| Busy\t| Locked | Full\t| % Util | Size (GB)\t| ARC INTL |"; \
echo "+---------------+-------+-------+--------+------+--------+--------------+----------+"; \
for i in `ls *.db`
do
   ${DLC}/bin/rfutil ${i%.db} -C aimage list -T /tmp > /tmp/${i%.db}_ai.list
   grep Status /tmp/${i%.db}_ai.list | ( while read AI_LIST
   do
      [ "`echo $AI_LIST | grep Empty`" != "" ] && EMPTY=`expr $EMPTY + 1`
      [ "`echo $AI_LIST | grep Busy`" != "" ] && BUSY=`expr $BUSY + 1`
      [ "`echo $AI_LIST | grep Locked`" != "" ] && LOCKED=`expr $LOCKED + 1`
      [ "`echo $AI_LIST | grep Full`" != "" ] && FULL=`expr $FULL + 1`
   done
   TOTAL_SIZE=`awk '/~*Size:/ { size_sum += $NF } END { printf "%.1f\n", size_sum / 1024 / 1024 }' /tmp/${i%.db}_ai.list 2> /dev/null`
   PERCENT_UTIL=`awk '/~*Size:/ { size_sum += $NF } /~*Used:/ { used_sum += $NF } END { printf "%.2f\n", used_sum * 100 / size_sum }' /tmp/${i%.db}_ai.list 2> /dev/null`
   AI_ARC_INTRVL=`${DLC}/bin/proutil ${i%.db} -C describe 2> /dev/null | grep "After Image Man" | awk '{ print $7 }'`
   if [ "${AI_ARC_INTRVL}" == "" ]
   then
      AI_ARC_INTRVL=`egrep "\(13872\)|\(13213\)" ${i%.db}.lg | tail -1`
      if [ "`echo ${AI_ARC_INTRVL} | grep \"\(13872\)\"`" != "" ]
      then
         AI_ARC_INTRVL=`echo ${AI_ARC_INTRVL} | awk '{ print $NF }' | sed 's/\.$//g'`
      elif [ "`echo ${AI_ARC_INTRVL} | grep \"\(13213\)\"`" != "" ]
      then
         AI_ARC_INTRVL=`echo ${AI_ARC_INTRVL} | awk '{ print $( NF - 3 ) }'`
      fi
   fi
   if [ "$( grep -i "After imaging is not enabled for this database" /tmp/${i%.db}_ai.list )" == "" ]
   then
   [ "$EMPTY" == "" ] && EMPTY=0
   [ "$BUSY" == "" ] && BUSY=0
   [ "$LOCKED" == "" ] && LOCKED=0
   [ "$FULL" == "" ] && FULL=0
   [ "$PERCENT_UTIL" == "" ] && PERCENT_UTIL=0.00
   [ "$AI_ARC_INTRVL" == "" ] && AI_ARC_INTRVL="#"
   else
      TOTAL_SIZE=""
#      AI_ARC_INTRVL="\t"
      echo -e "${BOLD_CYAN}\c"
   fi
   echo -e "| ${i%.db}   \t| $EMPTY\t| $BUSY\t| $LOCKED\t | $FULL\t| \c"
   if [ "`echo $PERCENT_UTIL | awk '{ if ( $1 >= 85 ) print $0 }'`" != "" ]
   then
      printf "${RED}${PERCENT_UTIL}${NO_COLOR}"
   else
      echo -e "${PERCENT_UTIL}\c"
   fi
   [ "${AI_ARC_INTRVL}" != "" ] && [ "${AI_ARC_INTRVL}" != "\t" ] && [ "${AI_ARC_INTRVL}" != "#" ] && [ ${AI_ARC_INTRVL} -ne 600 ] && AI_ARC_INTRVL="${BOLD_YELLOW}${AI_ARC_INTRVL}${NO_COLOR}"
   [ $(echo ${TOTAL_SIZE} | wc -m) -gt 5 ] && echo -e "\t | $TOTAL_SIZE\t| $AI_ARC_INTRVL\t   |"
   [ $(echo ${TOTAL_SIZE} | wc -m) -le 5 ] && echo -e "\t | $TOTAL_SIZE\t\t| $AI_ARC_INTRVL\t   |"
   )
   echo -e "${NO_COLOR}\c"
   rm -f /tmp/${i%.db}_ai.list
done
echo "+---------------+-------+-------+--------+------+--------+--------------+----------+"
