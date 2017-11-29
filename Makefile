#
# $Id: Makefile,v 1.11 2012/11/27 00:49:12 phil Exp $
#
# @Copyright@
# 
# 				Rocks(r)
# 		         www.rocksclusters.org
# 		         version 6.2 (SideWindwer)
# 		         version 7.0 (Manzanita)
# 
# Copyright (c) 2000 - 2017 The Regents of the University of California.
# All rights reserved.	
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice unmodified and in its entirety, this list of conditions and the
# following disclaimer in the documentation and/or other materials provided 
# with the distribution.
# 
# 3. All advertising and press materials, printed or electronic, mentioning
# features or use of this software must display the following acknowledgement: 
# 
# 	"This product includes software developed by the Rocks(r)
# 	Cluster Group at the San Diego Supercomputer Center at the
# 	University of California, San Diego and its contributors."
# 
# 4. Except as permitted for the purposes of acknowledgment in paragraph 3,
# neither the name or logo of this software nor the names of its
# authors may be used to endorse or promote products derived from this
# software without specific prior written permission.  The name of the
# software includes the following terms, and any derivatives thereof:
# "Rocks", "Rocks Clusters", and "Avalanche Installer".  For licensing of 
# the associated name, interested parties should contact Technology 
# Transfer & Intellectual Property Services, University of California, 
# San Diego, 9500 Gilman Drive, Mail Code 0910, La Jolla, CA 92093-0910, 
# Ph: (858) 534-5815, FAX: (858) 534-7345, E-MAIL:invent@ucsd.edu
# 
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS''
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# @Copyright@
#
# $Log: Makefile,v $
# Revision 1.11  2012/11/27 00:49:12  phil
# Copyright Storm for Emerald Boa
#
# Revision 1.10  2012/05/06 05:49:20  phil
# Copyright Storm for Mamba
#
# Revision 1.9  2012/03/29 03:25:20  phil
# rrdtool is now foundation-rrdtool
#
# Revision 1.8  2012/03/20 21:48:28  phil
# Set arch to i386 when building on a 32bit machine
#
# Revision 1.7  2012/01/04 23:18:45  phil
# Add confuse and rrdtool so that monitor-core can build properly
#
# Revision 1.6  2012/01/04 19:37:00  phil
# Small tweaks for build
#
# Revision 1.5  2011/11/05 04:15:22  phil
# need ganglia-monitor-core to be installed to build ganglia-pylib in the base
#
# Revision 1.4  2011/11/03 01:04:24  phil
# Build directories not already built
#
# Revision 1.3  2011/07/23 02:31:16  phil
# Viper Copyright
#
# Revision 1.2  2011/07/23 01:43:42  phil
# make RPMS directory -- needed when rocks-devel rpm is not yet built
#
# Revision 1.1  2011/07/19 20:02:00  phil
# A small helper roll.
#
#

# just enough information if rocks-devel rpm is not installed
TSTARCH=$(shell /bin/arch)
ifeq ($(strip $(TSTARCH)),i686)
ARCH=i386
else
ARCH=$(TSTARCH)
endif

OSVERSION=$(shell lsb_release -r | cut -f 2 | cut -d . -f 1)
SRCROLL=base
ifeq ($(strip $(OSVERSION)),7)
SRCROLL=core
endif

-include $(ROLLSROOT)/etc/Rolls.mk
-include Rolls.mk

roll:: buildrpms

dirs:	
	if [ ! -d RPMS/$(ARCH) ]; then mkdir -p RPMS/$(ARCH); fi
	if [ ! -d RPMS/noarch ]; then mkdir -p RPMS/noarch; fi


buildrpms: dirs rocks-devel
	
rocks-devel:
	(cd ../$(SRCROLL);				\
	make -C src/devel rpm;			\
	rpm -e rocks-devel;			\
	rpm -Uvh --force RPMS/$(ARCH)/rocks-devel*rpm;	\
	cp RPMS/$(ARCH)/rocks-devel*rpm ../rocksbuild/RPMS/$(ARCH); \
	)

