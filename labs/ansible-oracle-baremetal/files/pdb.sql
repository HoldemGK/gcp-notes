ALTER SYSTEM SET DB_CREATE_FILE_DEST='/u02/oradata' SCOPE=BOTH;
ALTER PLUGGABLE DATABASE PDBORCL SAVE STATE;
exit;