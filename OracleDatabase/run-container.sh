ORACLE_SID=CDB01
ORACLE_DB_UNIQUE_NAME=CDB01_SITE1
ORACLE_PDB=ORCL
CONTAINER_NAME=${ORACLE_DB_UNIQUE_NAME,,}


sudo mkdir -p /u01/volumes/$ORACLE_DB_UNIQUE_NAME
sudo chown 54321:54322 /u01/volumes/$ORACLE_DB_UNIQUE_NAME

sudo podman run -ti --name  $CONTAINER_NAME \
-p 1521:1521 \
-e ORACLE_SID=$ORACLE_SID \
-e ORACLE_DB_UNIQUE_NAME=$ORACLE_DB_UNIQUE_NAME
-e ORACLE_PDB=$ORACLE_PDB \
-e CDB_PWD=WElcome##123 \
-e PDB_PWD=WElcome##123 \
-e TOTAL_MEMORY_MB=2048 \
-e ORACLE_EDITION=EE \
-e ORACLE_CHARACTERSET=AL32UTF8 \
-e INSTALL_APEX=false \
-v /u01/volumes/$ORACLE_DB_UNIQUE_NAME:/u02/oradata \
localhost/ol8-19-sw /home/oracle/start.sh
