#!/bin/sh
#  Helper to bootstrap and build a roll. Prints out timing and
#  Number RPMS built 
#@Copyright@
#
#				Rocks(r)
#		         www.rocksclusters.org
#		         version 5.6 (Emerald Boa)
#		         version 6.1 (Emerald Boa)
#
#Copyright (c) 2000 - 2013 The Regents of the University of California.
#All rights reserved.	
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions are
#met:
#
#1. Redistributions of source code must retain the above copyright
#notice, this list of conditions and the following disclaimer.
#
#2. Redistributions in binary form must reproduce the above copyright
#notice unmodified and in its entirety, this list of conditions and the
#following disclaimer in the documentation and/or other materials provided 
#with the distribution.
#
#3. All advertising and press materials, printed or electronic, mentioning
#features or use of this software must display the following acknowledgement: 
#
#	"This product includes software developed by the Rocks(r)
#	Cluster Group at the San Diego Supercomputer Center at the
#	University of California, San Diego and its contributors."
#
#4. Except as permitted for the purposes of acknowledgment in paragraph 3,
#neither the name or logo of this software nor the names of its
#authors may be used to endorse or promote products derived from this
#software without specific prior written permission.  The name of the
#software includes the following terms, and any derivatives thereof:
#"Rocks", "Rocks Clusters", and "Avalanche Installer".  For licensing of 
#the associated name, interested parties should contact Technology 
#Transfer & Intellectual Property Services, University of California, 
#San Diego, 9500 Gilman Drive, Mail Code 0910, La Jolla, CA 92093-0910, 
#Ph: (858) 534-5815, FAX: (858) 534-7345, E-MAIL:invent@ucsd.edu
#
#THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS''
#AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS
#BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
#BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
#IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
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
	echo " -s      subshell. run make roll via subshell. Source /etc/bashrc"  
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
SUBSHELL=0

while getopts hk:no:p:su:xz opt
do
    case "$opt" in
      h)  usage; exit 1;;
      k)  KEYFILE="$OPTARG";;
      n)  BOOTSTRAP=0;;
      o)  OUTDIR="$OPTARG";;
      p)  PREFIX="$OPTARG";;
      s)  SUBSHELL=1;;
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
	sh ./bootstrap.sh &> $OUTDIR/make-${ROLLNAME}-bootstrap.out
	echo "Bootstrap Completed:  `date`"
fi
echo "Starting Build of Roll $ROLLNAME:  `date`"

if [ $SUBSHELL -eq 1 ]; then
/bin/bash -c ". /etc/bashrc; make roll" &> $OUTDIR/make-${ROLLNAME}-roll.out
else
make roll &> $OUTDIR/make-${ROLLNAME}-roll.out
fi

echo "Roll Build Completed: `date`"

# Version.mk might have declared a ROLLNAME different than the directory
ISONAME=$(grep ROLLNAME version.mk | awk '{print $NF}')
[[ "$ISONAME" != "" ]] ||  ISONAME=$ROLLNAME

if [ -e ${ISONAME}*iso ]; then
	echo "SUCCESS: ISO image built"
	ls -l ${ISONAME}*iso
	if [ -d src/usersguide ]; then
		echo "Building usersguide: `date`"
		rocks add roll ${ISONAME}*iso
		addrpms=`find RPMS -name '*command*' -print`
		for i in $addrpms; do rpm -Uvh --force --nodeps $i; done
		pushd src/usersguide
		make rpm >> /tmp/make-${ROLLNAME}-roll.out 2>&1
		popd
		make reroll >> /tmp/make-${ROLLNAME}-roll.out 2>&1 		 
		if [ $DOREMOVE -eq 1 ]; then rocks remove roll ${ISONAME}; fi
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
