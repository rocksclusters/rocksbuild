#!/bin/sh
#  Helper to bootstrap and build a roll. Prints out timing and
#  Number RPMS built 
#@Copyright@
#@Copyright@

function usage () 

{
 	echo "$0 [-h][-k keyfile][-n][-o output dir][-p prefix][-x] <roll>"
	echo "Bootstrap and build Roll"  
	echo " -h      help"  
	echo " -k      keyfile for ssh-agent (default = ./rocksbuild.id_rsa)"  
	echo " -n      don't boostrap"  
	echo " -o      build log output directry (default = /tmp)"  
	echo " -p      prefix of roll directory (default = .)"  
	echo " -x      don't do ssh-agent (ignores -u and -k)"  
	echo " -z      don't remove roll/command rpm(s) after build"
}

# Defaults
PREFIX=.
BOOTSTRAP=1
OUTDIR=/tmp
KEYFILE=rocksbuild.id_rsa
DOAGENT=1
DOREMOVE=1

while getopts hk:no:p:u:xz opt
do
    case "$opt" in
      h)  usage; exit 1;;
      k)  KEYFILE="$OPTARG";;
      n)  BOOTSTRAP=0;;
      o)  OUTDIR="$OPTARG";;
      p)  PREFIX="$OPTARG";;
      x)  DOAGENT=0;;
      z)  DOREMOVE=0;;
      \?)		# unknown flag
      	  echo >&2 \
	  usage 
	  exit 1;;
    esac
done
shift $(($OPTIND - 1))

ROLLNAME=$1

if [ $DOAGENT -eq 1 -a -e $KEYFILE ]; then 
	eval `ssh-agent -s`
	ssh-add  $KEYFILE
fi

if [ ! -d $PREFIX/$ROLLNAME ]; then
	echo >&2 "Roll directory does not exist: $PREFIX/$ROLLNAME"
	usage	
	exit 1
fi 

cd $PREFIX/$ROLLNAME

make clean &> $OUTDIR/clean-${ROLLNAME}.out
/bin/rm -rf RPMS >> $OUTDIR/clean-${ROLLNAME}.out 2>&1

if [ -e bootstrap.sh -a $BOOTSTRAP -eq 1 ]; then
	echo "Starting $ROLLNAME Roll Bootstrap: `date`"
	./bootstrap.sh &> $OUTDIR/make-${ROLLNAME}-bootstrap.out
	echo "Bootstrap Completed:  `date`"
fi
echo "Starting Build of Roll $ROLLNAME:  `date`"

make roll &> $OUTDIR/make-${ROLLNAME}-roll.out

echo "Roll Build Completed: `date`"

if [ -e ${ROLLNAME}*iso ]; then
	echo "SUCCESS: ISO image built"
	ls -l ${ROLLNAME}*iso
	if [ -d src/usersguide ]; then
		echo "Building usersguide: `date`"
		rocks add roll ${ROLLNAME}*iso
		addrpms=`find RPMS -name '*command*' -print`
		for i in $addrpms; do rpm -Uvh --force --nodeps $i; done
		pushd src/usersguide
		make rpm >> /tmp/make-${ROLLNAME}-roll.out 2>&1
		popd
		make reroll >> /tmp/make-${ROLLNAME}-roll.out 2>&1 		 
		if [ $DOREMOVE -eq 1 ]; then rocks remove roll ${ROLLNAME}; fi
		for i in $addrpms; do
			p=`basename $i`
			rmcmd=`python -c "import string;print string.join(str.split(str.split(\"$p\",'.')[0],'-')[:-1],'-')"`
			if [ $DOREMOVE -eq 1 ]; then 
				echo "Removing command: $rmcmd"
				rpm -e $rmcmd
			fi
		done
		echo "Rebuild of Roll Complete: `date`"
	fi
		
	
else
	echo "FAIL: No ISO image built"
fi

# Record the made RPMS
tmpfile=`mktemp`
find RPMS -name '*rpm' -exec basename {} \; | sort > $tmpfile

# If there is a manifest file 
if [ -e manifest ]; then
	echo "RPMS expected: `cat manifest | grep -v '^#' | wc -l`"
	echo "RPMS built: `cat $tmpfile | wc -l`"
	echo "DETAILS:"
	cat manifest $tmpfile | grep -v '^#' |  sort
else
	echo "RPMS built: `cat $tmpfile | wc -l`"
	echo "DETAILS:"
	cat $tmpfile 
fi

# Clean up
rm $tmpfile
if [ $DOAGENT -eq 1 ]; then 
	ssh-agent -k
fi
exit 0
