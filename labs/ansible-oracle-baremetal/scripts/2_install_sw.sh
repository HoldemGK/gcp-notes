#!/bin/bash
#install_sw.sh
cd $ORACLE_HOME
./runInstaller -ignorePrereq -waitforcompletion -silent \
 oracle.install.option=INSTALL_DB_SWONLY \
 ORACLE_HOSTNAME=${ORACLE_HOSTNAME} \
 UNIX_GROUP_NAME=oinstall \
 INVENTORY_LOCATION=${ORA_INVENTORY} \
 ORACLE_HOME=${ORACLE_HOME} \
 ORACLE_BASE=${ORACLE_BASE} \
 oracle.install.db.InstallEdition=EE \
 oracle.install.db.OSDBA_GROUP=dba \
 oracle.install.db.OSBACKUPDBA_GROUP=backupdba \
 oracle.install.db.OSDGDBA_GROUP=dgdba \
 oracle.install.db.OSKMDBA_GROUP=kmdba \
 oracle.install.db.OSRACDBA_GROUP=racdba \
 SECURITY_UPDATES_VIA_MYORACLESUPPORT=false \
 DECLINE_SECURITY_UPDATES=true
 
