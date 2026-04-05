export DLC=/${1}/apps/dlc
export BOLD_YELLOW='\033[1;33m'
export BOLD_CYAN='\033[1;36m'
export NC='\033[0m'

cd /${1}/db/${1}db

echo "+---------------+---------------+---------------+---------------+---------------+---------------+---------------+---------------+"
echo -e "| Database\t| % Buffer Hits\t| Current (-B)\t| Used (-B)\t| 10% of DB HWM\t| DB Size (GB)\t| -B Size (GB)\t| SHM (GB)\t|"
echo "+---------------+---------------+---------------+---------------+---------------+---------------+---------------+---------------+"
for i in `ls *.db`
do
   TMP_FILE=/tmp/${i%.db}_promon.txt
   [ -f ${TMP_FILE} ] && echo "old file found...${TMP_FILE}..." && exit
   echo -e "M\n1\n9999\nQ\n5\nQ\n6\nQ\n7\nQ\nR&D\n5\n1\n9999\nP\n1\n7\nX" | $DLC/bin/promon ${i%.db} 2> /dev/null > ${TMP_FILE}
   if [ `echo ${i%.db} | wc -m` -lt 7 ]
   then
      echo -e "| ${i%.db}\t\t\c"
   else
      echo -e "| ${i%.db}\t\c"
   fi
#   PER_CENT_BUFF_HIT=`echo -e "5\nQ\nQ" | $DLC/bin/promon ${i%.db} 2> /dev/null | awk '/^Buffer Hits/{ print $3 }'`
   PER_CENT_BUFF_HIT=$( awk '/^Buffer Hits/{ print $3 }' ${TMP_FILE} )
   if [ `echo ${PER_CENT_BUFF_HIT} | wc -m` -lt 7 ]
   then
      [ ! -z ${PER_CENT_BUFF_HIT} ] && [ ${PER_CENT_BUFF_HIT} -lt 99 ] && PER_CENT_BUFF_HIT="${BOLD_YELLOW}${PER_CENT_BUFF_HIT}${NC}"
      echo -e "| ${PER_CENT_BUFF_HIT}\t\t\c"
   else
      [ ! -z ${PER_CENT_BUFF_HIT} ] && [ ${PER_CENT_BUFF_HIT} -lt 99 ] && PER_CENT_BUFF_HIT="${BOLD_YELLOW}${PER_CENT_BUFF_HIT}${NC}"
      echo -e "| ${PER_CENT_BUFF_HIT}\t\c"
   fi
#   CURR_BUFF_PL_SZ=`echo -e "M\n1\n999\nQ\n6\nQ\nQ" | $DLC/bin/promon ${i%.db} 2> /dev/null | grep -i 'Number of database buffers' | awk '{ print $NF }' | sort -u`
   CURR_BUFF_PL_SZ=$( awk -v IGNORECASE=1 '/Number of database buffers/{ print $NF }' ${TMP_FILE} | sort -u )
   if [ `echo ${CURR_BUFF_PL_SZ} | wc -m` -lt 7 ]
   then
      echo -e "| ${CURR_BUFF_PL_SZ}\t\t\c"
   else
      echo -e "| ${CURR_BUFF_PL_SZ}\t\c"
   fi
#   USED_BUFF_PL=`echo -e "R&D\n5\n1\n9999\nP\n1\n7\nX" | $DLC/bin/promon ${i%.db} 2> /dev/null | grep -i "Used buffers" | awk '{ print $NF }'`
   USED_BUFF_PL=$( awk -v IGNORECASE=1 '/Used buffers/{ print $NF }' ${TMP_FILE} )
   if [ `echo ${USED_BUFF_PL} | wc -m` -lt 7 ]
   then
      [ ${USED_BUFF_PL} -lt ${CURR_BUFF_PL_SZ} ] && USED_BUFF_PL="${BOLD_CYAN}${USED_BUFF_PL}"
      echo -e "| ${USED_BUFF_PL}\t\t\c"
   else
      [ ${USED_BUFF_PL} -lt ${CURR_BUFF_PL_SZ} ] && USED_BUFF_PL="${BOLD_CYAN}${USED_BUFF_PL}"
      echo -e "| ${USED_BUFF_PL}\t\c"
   fi
   echo -e "${NC}\c"
#   DB_HWM=`echo -e "M\n1\n999\nQ\n7\nQ\nQ" | $DLC/bin/promon ${i%.db} 2> /dev/null | grep "Database blocks high water mark" | awk '{ print $NF }'`
   DB_HWM=$( awk '/Database blocks high water mark/{ print $NF }' ${TMP_FILE} )
   if [ `expr ${DB_HWM} / 10 2> /dev/null | wc -m` -lt 7 ]
   then
      echo -e "| \c"; echo -e "`expr ${DB_HWM} / 10 2> /dev/null`\t\t\c"
   else
      echo -e "| \c"; echo -e "`expr ${DB_HWM} / 10 2> /dev/null`\t\c"
   fi
#   DB_BLK_SZ=$(echo -e "M\n1\n9999\nQ\n7\nQ\nQ" | $DLC/bin/promon ${i%.db} 2> /dev/null | awk '/Database block size/{ print $NF }')
   DB_BLK_SZ=$( awk '/Database block size/{ print $NF }' ${TMP_FILE} )
   [ "${DB_HWM}" != "" ] && [ "${DB_BLK_SZ}" != "" ] && DB_SZ=$(echo "${DB_HWM} ${DB_BLK_SZ}" | awk '{ printf "%0.2f\n", $1 * $2 / 1024 / 1024 / 1024 }')
   if [ `echo ${DB_SZ} | wc -m` -lt 7 ]
   then
      echo -e "| ${DB_SZ}\t\t\c"
   else
      echo -e "| ${DB_SZ}\t\c"
   fi
   DB_SZ=""
   [ "${CURR_BUFF_PL_SZ}" != "" ] && [ "${DB_BLK_SZ}" != "" ] && BUFF_PL_SZ=$(echo "${CURR_BUFF_PL_SZ} ${DB_BLK_SZ}" | awk '{ printf "%0.2f\n", $1 * $2 / 1024 / 1024 / 1024 }')
   if [ `echo ${BUFF_PL_SZ} | wc -m` -lt 7 ]
   then
      echo -e "| ${BUFF_PL_SZ}\t\t\c"
   else
      echo -e "| ${BUFF_PL_SZ}\t\c"
   fi
   BUFF_PL_SZ=""

   SHM_SZ="$(echo -e "5\nQ\nQ" | $DLC/bin/promon ${i%.db} 2> /dev/null | awk '/^Shared Memory /{ print $3 }')"
   SHM_SZ_NUM="$(echo "${SHM_SZ}" | sed 's/\([0-9.]*\)\([KMG]\?\)/\1/')"
   SHM_SZ_UNIT="$(echo "${SHM_SZ}" | sed 's/[0-9.]*\([KMG]\?\)/\1/')"
   case "${SHM_SZ_UNIT}" in
   K) SHM_SZ_GB=$(echo ${SHM_SZ_NUM} | awk '{ printf "%.2f", $1 / ( 1024 * 1024) }') ;;
   M) SHM_SZ_GB=$(echo ${SHM_SZ_NUM} | awk '{ printf "%.2f", $1 / 1024 }') ;;
   G) SHM_SZ_GB=${SHM_SZ_NUM}
   esac
   echo -e "| ${SHM_SZ_GB}\t\t|"
   SHM_SZ_GB=""

   [ -f ${TMP_FILE} ] && rm -f ${TMP_FILE}
done
echo "+---------------+---------------+---------------+---------------+---------------+---------------+---------------+---------------+"
