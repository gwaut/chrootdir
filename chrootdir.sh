#!/bin/bash

CHROOTDIR="/srv/chroot"

CHROOTCONF=/etc/schroot/schroot.conf
MIRROR=http://ftp.belnet.be/ubuntu.com/ubuntu/

USER_ID=""
SUITE=""
INITIALIZE=0
DELETE=0


function  initialize
{
   while getopts ":idu:s:" opt; do
      case ${opt} in
         u) 
            USER_ID=${OPTARG}
            ;;
         s)
            SUITE=${OPTARG}
            ;;
         i) 
            INITIALIZE=1
            ;;
         d)
            DELETE=1
            ;;
         \?)
            echo "Invalid option: -${OPTARG}" >&2
            exit 1
            ;;
         :)
            echo "Option -${OPTARG} requires an argument" >&2
            exit 1
            ;; 
      esac
   done
   
   if [ ! ${USER_ID} ]; then
      echo "The user argument is mandatory!" >&2
      exit 1
   fi

   if [[ ${DELETE} -eq 1 && ${INITIALIZE} -eq 1 ]]; then
      echo "It is impossible to delete and initialize at the same time!" >&2
      exit 1
   fi

   if [ ! ${SUITE} ]; then
      SUITE="precise"
   fi
}


function user_exists
{
   if ! getent passwd $1 >> /dev/null 2>&1; then
      echo "User $1 does not exist" >&2
      exit 1
   fi
}

function check_config
{
   if [ ! -f ${CHROOTCONF} ]; then
      echo "Could not find config file: ${CHROOTCONF}" >&2
      exit 1
   fi
}

function init_chroot
{
   if [ -d ${BASEDIR} ]; then
      echo "A directory with the same name already exists (${BASEDIR})!" >&2
      exit 1
   fi
   if grep ${CHROOTDEF} ${CHROOTCONF}; then
      echo "A chroot definition with the same name already exists (${CHROOTDEF}" >&2
      exit 1
   fi


   mkdir -p ${BASEDIR}
   if [ $? -ne 0 ]; then
      exit 1
   fi
   
   # config file todo
   TIMESTAMP=$(date +%Y%m%d%H%M%S)
   cp ${CHROOTCONF} ${CHROOTCONF}.${TIMESTAMP}
   if [ $? -ne 0 ]; then
      exit 1
   fi

# READ: man schroot.conf
   cat <<EOF >> ${CHROOTCONF}

[${CHROOTDEF}]
type=directory
description=Chroot of ${USER_ID} on ${BASEDIR}
message-verbosity=normal
directory=${BASEDIR}
users=${USER_ID}
groups=sbuild
root-users=root
root-groups=root
preserve-environment=false
EOF

   debootstrap --variant=buildd ${SUITE} ${BASEDIR} ${MIRROR}

   # install sudo
   chroot ${BASEDIR} apt-get install sudo
   echo $?
}


function delete_chroot 
{
   if ps -ef | grep schroot | grep ${CHROOTDEF} >> /dev/null 2>&1 
   then
      echo "Chroot (${CHROOTDEF}) is running!"
      exit 1
   fi

   if egrep "^\[${CHROOTDEF}\]" ${CHROOTCONF} >> /dev/null 2>&1; 
   then
      # Remove section from config file
      perl -i -pe "BEGIN{undef $/;} s/^\[${CHROOTDEF}\][^\[]*//smg" ${CHROOTCONF}
   fi

   if egrep "^\[${CHROOTDEF}\]" ${CHROOTCONF} >> /dev/null 2>&1; 
   then
      echo "Section ${CHROOTDEF} is not removed from ${CHROOTCONF}!"
      exit 1
   fi
  
   # Remove the BASEDIR
   if [ ! -z ${BASEDIR} ]; then
      echo "Removing ${BASEDIR}!"
      rm -rf ${BASEDIR}
   fi
}

initialize "$@"
user_exists "${USER_ID}"
check_config

CHROOTDEF=${USER_ID}-${SUITE}
BASEDIR=${CHROOTDIR}/${CHROOTDEF}

if [ ${DELETE} -eq 1 ]; then
  delete_chroot 
elif [ ${INITIALIZE} -eq 1 ]; then
   init_chroot
fi

exit 0
