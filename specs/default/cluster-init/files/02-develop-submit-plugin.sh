#!/bin/bash -e
cd ~
SLURM_VERSION="18.08.7"
SLURM_FOLDER="slurm-${SLURM_VERSION}"
SLURM_PKG="slurm-${SLURM_VERSION}.tar.bz2"
DOWNLOAD_URL="https://download.schedmd.com/slurm"

if [ ! -e ~/${SLURM_FOLDER} ]; then
    # munge is in EPEL
    yum -y install epel-release && yum -q makecache

    # Install other build deps
    yum install -y rsync rpm-build munge-devel munge-libs readline-devel openssl openssl-devel pam-devel perl-ExtUtils-MakeMaker gcc mysql mysql-devel wget gtk2-devel.x86_64 glib2-devel.x86_64 libtool-2.4.2 m4 automake
    wget "${DOWNLOAD_URL}/${SLURM_PKG}"
    tar xjf ${SLURM_PKG}
    mkdir -p ${SLURM_FOLDER}/src/plugins/job_submit/cyclecloud/
    
    cp /source/JobSubmitPlugin/Makefile.am ${SLURM_FOLDER}/src/plugins/job_submit/cyclecloud/
    sed -i 's/src\/plugins\/job_submit\/Makefile/src\/plugins\/job_submit\/Makefile\n                 src\/plugins\/job_submit\/cyclecloud\/Makefile/g'  ${SLURM_FOLDER}/configure.ac
    cd ${SLURM_FOLDER}
    # slurm 19 branch has no autogen; fix by using autoreconf first
    if [ -e ./autogen.sh ]; then
      autoreconf
    else
      ./autogen.sh
    fi
    ./configure
    make
    cd ..
fi;

cd ~/${SLURM_FOLDER}/src/plugins/job_submit/cyclecloud/
rsync -a /source/JobSubmitPlugin/ .
#only make library for plugin
#cd ~/${SLURM_FOLDER}
make
cd ~/${SLURM_FOLDER}/src/plugins/job_submit/cyclecloud/
#CYCLECLOUD_TOPOLOGY_FILE=test.csv python topology_cyclecloud_test.py
rsync .libs/job_submit_cyclecloud.so  /root/rpmbuild/RPMS/x86_64/

#ssh -i /opt/cycle_server/.ssh/cyclecloud.pem $node 'sudo bash /mnt/cluster-init/slurm/default/scripts/99-install-topology.sh'
