#!/bin/bash
#lsnr_dbca.sh
cd $ORACLE_HOME 
lsnrctl start
export ORACLE_SID=orcl
export PDB_NAME=pdborcl
dbca -silent -createDatabase \
-templateName General_Purpose.dbc \
-gdbname ${ORACLE_SID} -sid  ${ORACLE_SID} \
-responseFile NO_VALUE \
-characterSet AL32UTF8 \
-sysPassword Admin123 \
-systemPassword Admin123 \
-createAsContainerDatabase true \
-numberOfPDBs 1 \
-pdbName ${PDB_NAME} \
-pdbAdminPassword Admin123 \
-databaseType MULTIPURPOSE \
-automaticMemoryManagement false \
-totalMemory 9000 \
-storageType FS \
-datafileDestination "${DATA_DIR}" \
-redoLogFileSize 50 \
-emConfiguration NONE \
-ignorePreReqs

