chrootdir: Create a (s)chroot environment easily
==================================================

The chrootdir script can be used to create a chroot environment easily.

schroot is a tool which allows you to securely enter a chroot environment.

What is a chroot?
-----------------

chroot is litteraly a change of the root (/) directory. It can be used to create a sandbox for either an application or a user.


Dependencies: 
-------------

Tested on Ubuntu 12.04.
You need to install the schroot en debootstrap packages

Usage:
------

    Usage: chrootdir -u <user-id> -n <chrootname> [-s <suite>] [-h] [-d]  
           -u <user-id>: the user which is allowed to access the chroot  
           -n <chrootname>: a unique id used to identify of the chroot   
           -s <suite>: the suite may be the release code name of the Debian/Ubuntu system   
           -d: delete the chroot environment identified by the chrootname  
           -h: shows this help message  

Examples:
---------

### Create a chroot environment of same suite of host system for user foo

Show the current suite (DISTRIB_CODENAME) of the host system:

    $ cat /etc/lsb-release  
    DISTRIB_ID=Ubuntu  
    DISTRIB_RELEASE=12.04  
    DISTRIB_CODENAME=precise   
    DISTRIB_DESCRIPTION="Ubuntu 12.04.2 LTS"  

Create the chroot environment:

    $ sudo ./chrootdir.sh -u foo -n test-precise


### Create a chroot environment of the lucid suite for user foo

    $ sudo ./chrootdir.sh -u foo -n test-lucid -s lucid


### Get a list of all environments

    foo@host:~$ schroot -l
    chroot:test-lucid
    chroot:test-precise

###  Connect to an environment

    foo@host:~$ schroot -c test-precise
    (test-precise)foo@host:~$ cat /etc/lsb-release 
    DISTRIB_ID=Ubuntu
    DISTRIB_RELEASE=12.04
    DISTRIB_CODENAME=precise
    DISTRIB_DESCRIPTION="Ubuntu 12.04 LTS"

or

    foo@host:~$ schroot -c test-lucid
    (test-lucid)foo@host:~$ cat /etc/lsb-release 
    DISTRIB_ID=Ubuntu
    DISTRIB_RELEASE=10.04
    DISTRIB_CODENAME=lucid
    DISTRIB_DESCRIPTION="Ubuntu 10.04 LTS"



