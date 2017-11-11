VOLUME_NAME="global"
EXPORTS_DIR="/exports/docker-volume-global"
EXPORTS_CONFIG_FILE="/etc/exports"
EXPORTS_CONFIG_BACKUP_FILE="/etc/exports.bak"
NETSHARE_DEB_URL="https://github.com/ContainX/docker-volume-netshare/releases/download/v0.17/docker-volume-netshare_0.17_amd64.deb"

# enable error stop
set -e

# install requirements
apt-get install wget

# list nodes
NODES=`docker node ls --format "{{.Hostname}}"`
if [ -z "${NODES}" ]; then
        echo "docker command error, or no nodes in swarm."
        exit 1
fi
echo "nodes in swarm:"
echo "${NODES}"
echo ""

# node addresses
ADDRS=`docker inspect ${NODES} --format "{{.Status.Addr}}"`
if [ -z "${ADDRS}" ]; then
        echo "docker command error, or could not get ip addresses."
        exit 1
fi
echo "node ip addresses in swarm:"
echo "${ADDRS}"
echo ""

# manager node ip address
MANAGER_ADDR=""
for n in ${NODES}; do
        IS_MANAGER_NODE=`docker node inspect ${n} --format "{{.ManagerStatus.Leader}}"`
        if [ "${IS_MANAGER_NODE}" = "true" ]; then
                MANAGER_ADDR=`docker node inspect ${n} --format "{{.Status.Addr}}"`
                break
        fi
done
if [ -z "${MANAGER_ADDR}" ]; then
        echo "swarm manager did not found."
        exit 1
fi
echo "manager node ip address: ${MANAGER_ADDR}"
echo ""

# is manger?
IS_MANAGER=`docker node inspect self --format "{{.ManagerStatus.Leader}}"`
echo "is manager: ${IS_MANAGER}"
echo ""

###############################################################################
###############################################################################
###############################################################################
# install nfs server (if manager)
if [ "${IS_MANAGER}" = "true" ]; then
        echo ""
        echo "[install nfs server]"

        # create nfs exports
        EXPORTS=""
        for a in ${ADDRS}; do
                EXPORTS="${EXPORTS} ${a}(rw,sync,no_subtree_check,no_root_squash)"
        done
        echo "create ${EXPORTS_CONFIG_FILE} with ..."
        echo "${EXPORTS}"
        echo ""

        # check config
        if [ -f "${EXPORTS_CONFIG_FILE}" ]; then
                if [ ! -f "${EXPORTS_CONFIG_BACKUP_FILE}" ]; then
                        echo "${EXPORTS_CONFIG_FILE} already exists."
                        echo "backup to ${EXPORTS_CONFIG_BACKUP_FILE} ..."
                        cp -v "${EXPORTS_CONFIG_FILE}" "${EXPORTS_CONFIG_BACKUP_FILE}"
                fi
        fi

        # install server
        apt-get install nfs-server
        mkdir -pv "${EXPORTS_DIR}"
        echo "${EXPORTS_DIR} ${EXPORTS}" > "${EXPORTS_CONFIG_FILE}"
        /etc/init.d/nfs-kernel-server restart
fi

###############################################################################
###############################################################################
###############################################################################
# install nfs volume
echo ""
echo "[install nfs client]"

# netshare
wget -O /tmp/netshare.deb "${NETSHARE_DEB_URL}"
dpkg -i /tmp/netshare.deb
service docker-volume-netshare start
if [ -f "/tmp/netshare.deb" ]; then
        rm -f /tmp/netshare.deb
fi

# remove global volume
docker volume inspect ${VOLUME_NAME} && docker volume rm ${VOLUME_NAME}
docker volume inspect ${VOLUME_NAME} && echo "could not delete volume '${VOLUME_NAME}'?" && exit 1
echo "volume '${VOLUME_NAME}' seems removed or not found."
echo "creating volume '${VOLUME_NAME}' ..."

# create global volume
docker volume create \
   --driver local \
   --opt type=nfs4 \
   --opt o=addr=${MANAGER_ADDR},rw,hard,intr \
   --opt device=:${EXPORTS_DIR} \
   ${VOLUME_NAME}

# inspect global volume
docker volume inspect ${VOLUME_NAME}

# done!
echo ""
echo "done."

