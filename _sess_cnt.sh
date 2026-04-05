echo "+---------------+-------+"
echo -e "| Process Group\t| Count\t|"
echo "+---------------+-------+"
ps -ef | awk '{ if ( $8 ~ "/apps/dlc/bin/" ) print $8 }' | awk -F"/" '{ print $NF }' | sort -u | while read _ptype
do
   echo -e "| ${_ptype}\t| $(ps -ef | awk '{ if ( $8 ~ "/apps/dlc/bin/" ) print $8 }' | grep ${_ptype} | wc -l)\t|"
done | sort -nrk 4
echo "+---------------+-------+"

echo
echo "Top 10 _progres session count by OS users - `date`"
echo "+---------------+-------+"
echo -e "| User  \t| Count\t|"
echo "+---------------+-------+"
ps -ef | awk '{ if ( $8 ~ "/apps/dlc/bin/_progres" ) print $1 }' | sort -u | while read _usr
do
   echo -e "| ${_usr}   \t| $(ps -ef | awk -v _usr=${_usr} '{ if ( ( $8 ~ "/apps/dlc/bin/_progres" ) && ( $1 == _usr ) ) print $1 }' | wc -l)\t|"
done | sort -nrk 4 | head
echo "+---------------+-------+"
