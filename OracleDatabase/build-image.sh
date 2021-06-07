echo Setting Variables

ORACLE_HOME=/u01/app/oracle/product/db_19_9_0
ORACLE_BASE=/u01/app/oracle
orainv=/u01/app/oraInventory
install_zip=./LINUX.X64_193000_db_home.zip
oh_name=db_19_9_0

echo 
container=$(sudo buildah from oraclelinux:8-slim)


sudo buildah run $container -- microdnf install -y zip unzip oracle-database-preinstall-19c 

sudo buildah commit $container ol8-prereqs
      
	  
mountpoint=$(sudo buildah mount ${container})


echo "Unzipping the installation binaries..."
sudo mkdir -p ${mountpoint}${ORACLE_HOME}
sudo unzip -q -d ${mountpoint}${ORACLE_HOME}  $install_zip
echo "Done"

tmpfile=`mktemp`
cat <<EOF > $tmpfile
inventory_loc=$orainv
inst_group=oinstall
EOF

sudo mv $tmpfile ${mountpoint}/etc/oraInst.loc
sudo mkdir -p ${mountpoint}${orainv}

tmpfile=`mktemp`
cat <<EOF > $tmpfile
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=dba
INVENTORY_LOCATION=
ORACLE_HOME=$ORACLE_HOME
ORACLE_BASE=$ORACLE_BASE
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=oper
oracle.install.db.OSBACKUPDBA_GROUP=backupdba
oracle.install.db.OSDGDBA_GROUP=dgdba
oracle.install.db.OSKMDBA_GROUP=kmdba
oracle.install.db.OSRACDBA_GROUP=racdba
EOF

sudo mv $tmpfile ${mountpoint}${ORACLE_HOME}/install.rsp
sudo buildah run $container -- chown -R oracle:dba /u01 
sudo buildah run $container -- chown oracle:oinstall /etc/oraInst.loc


sudo buildah run --user oracle ${container} -- $ORACLE_HOME/runInstaller -waitForCompletion -silent -responseFile $ORACLE_HOME/install.rsp ORACLE_HOME_NAME=$oh_name

sudo buildah run ${container} -- $ORACLE_HOME/root.sh

sudo 

sudo buildah umount ${container}

sudo buildah config --author "Ludovico Caldara <ludovico.caldara@oracle.com>" $container
sudo buildah config \
    -e ORACLE_HOME=$ORACLE_HOME \
    -e ORACLE_BASE=$ORACLE_BASE \
    -e CDB_PWD="WElcome##123" \
    -e PDB_PWD="WElcome##123" \
    -e TOTAL_MEMORY_MB=2048 \
    -e ORACLE_CHARACTERSET=AL32UTF8 \
    -e INSTALL_APEX=false \
    -u oracle \
    --healthcheck /home/oracle/healthcheck.sh \
    --healthcheck-interval 5m \
    --healthcheck-retries 3 \
    --healthcheck-start-period 15m \
    --healthcheck-timeout 10m \
    --cmd "bash /home/oracle/start.sh" \
    $container

sudo buildah copy --chown oracle:dba $container scripts/start.sh /home/oracle/start.sh
sudo buildah copy --chown oracle:dba $container scripts/healthcheck.sh /home/oracle/healthcheck.sh
sudo buildah commit $container ol8-19-sw
sudo buildah run $container mkdir /u02
sudo buildah run $container chown oracle:dba /u02

#sudo rm -rf \
#  $mountpoint$ORACLE_HOME/.patch_storage \
#  $mountpoint$ORACLE_HOME/apex \
#  $mountpoint$ORACLE_HOME/ords \
#  $mountpoint$ORACLE_HOME/sqldeveloper  \
#  $mountpoint$ORACLE_HOME/ucp  \
#  $mountpoint$ORACLE_HOME/lib/*.zip  \
#  $mountpoint$ORACLE_HOME/inventory/backup/*  \
#  $mountpoint$ORACLE_HOME/network/tools/help  \
#  $mountpoint$ORACLE_HOME/assistants/dbua  \
#  $mountpoint$ORACLE_HOME/dmu  \
#  $mountpoint$ORACLE_HOME/install/pilot  \
#  $mountpoint$ORACLE_HOME/suptools  \
#  $mountpoint/tmp/* 
#
#sudo buildah commit $container ol8-19-sw-slim
