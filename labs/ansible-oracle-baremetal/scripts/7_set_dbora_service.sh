#!/bin/bash
#set_dbora_service.sh
cp /u01/oracle-toolkit/files/dbora.service /usr/lib/systemd/system/dbora.service
systemctl daemon-reload
systemctl enable dbora.service
systemctl start dbora.service
systemctl status dbora.service
 

