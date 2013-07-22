#!/bin/bash

CHROOTDIR="/srv/chroot"

CHROOTCONF=/etc/schroot/schroot.conf
MIRROR=http://ftp.belnet.be/ubuntu.com/ubuntu/

USER_ID=""
CHROOT_ID=""
SUITE=""
INITIALIZE=1    # Default value

function print_help 
{
   echo "Usage: chrootdir -u <user-id> -n <chrootname> [-s <suite>] [-h] [-d] "
   echo "       -u <user-id>: the user which is allowed to access the chroot"
   echo "       -n <chrootname>: a unique id used to identify of the chroot"
   echo "       -s <suite>: the suite may be the release code name of the Debian/Ubuntu system"
   echo "       -d: delete the chroot environment identified by the chrootname" 
   echo "       -h: shows this help message"

}

function default_suite 
{
  SUITE=$(grep DISTRIB_CODENAME /etc/lsb-release | awk -F= '{print $2}')
}

function  initialize
{
   while getopts ":hdu:s:n:" opt; do
      case ${opt} in
         u) 
            USER_ID=${OPTARG}
            ;;
         n) 
            CHROOT_ID=${OPTARG}
            ;;
         s)
            SUITE=${OPTARG}
            ;;
         d)
            INITIALIZE=0
            ;;
         h)
            print_help
            exit 0
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
   
   if [ -z ${USER_ID} ]; then
      echo "The user argument is mandatory!" >&2
      exit 1
   fi
 
   if [ -z ${CHROOT_ID} ]; then
      echo "The name of the chroot is mandatory!" >&2
      exit 1
   fi

   if [ -z ${SUITE} ]; then
      default_suite
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
      echo "A chroot definition with the same name already exists (${CHROOTDEF})" >&2
      exit 1
   fi


   mkdir -p ${BASEDIR}
   if [ $? -ne 0 ]; then
      exit 1
   fi
   
   debootstrap --variant=buildd ${SUITE} ${BASEDIR} ${MIRROR}
   if [[ $? -ne 0 ]]; then
      rm -rf ${BASEDIR}
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
#groups=${USER_ID}
root-users=root
root-groups=root
preserve-environment=false
EOF


   # install sudo
   schroot -c ${CHROOTDEF} -u root apt-get install sudo
   if [ $? -ne 0 ]; then
      exit 1
   fi
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
      echo "Removing section ${CHROOTDEF} from ${CHROOTCONF}"
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



# script must be executed with root permissions
if [ "$(id -u)" != "0" ]; then
   echo "This script must be executed with root permissions!" >&2
   exit 1
fi

initialize "$@"
user_exists "${USER_ID}"
check_config


CHROOTDEF=${CHROOT_ID}     # CHROOT DEFINITION
BASEDIR=${CHROOTDIR}/${CHROOTDEF}   # DIRECTORY WHERE CHROOT WILL BE INSTALLED

if [[ ${INITIALIZE} -eq 0 ]]; then
  delete_chroot 
else
   init_chroot
fi

exit 0
