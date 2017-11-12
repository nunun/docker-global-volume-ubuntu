IP="${1}"
VOLUME_NAME="global"
VOLUME_EXPORT_DIR="/exports/docker-global-volume"
EXPORTS_CONFIG_FILE="/etc/exports"
EXPORTS_CONFIG_BACKUP_FILE="/etc/exports.bak"
NETSHARE_DEB_URL="https://raw.githubusercontent.com/nunun/docker-global-volume/master/docker-volume-netshare_0.17_amd64.deb"
INSTALL_SH_URL="https://raw.githubusercontent.com/nunun/docker-global-volume/master/install.sh"
SHOW_SERVER_GUIDE="0"

# enable error stop
set -e

# install requirements
apt-get install wget

# install nfs-server (node must be docker swarm manager)
if [ -z "${IP}" ]; then
        echo ""
        echo "[install nfs-server]"

        # list nodes
        NODES=`docker node ls --format "{{.Hostname}}"`
        if [ -z "${NODES}" ]; then
                echo "node is not docker manager, or no nodes in swarm."
                exit 1
        fi
        echo "nodes:"
        echo "${NODES}"
        echo ""

        # list node addresses
        ADDRS=`docker inspect ${NODES} --format "{{.Status.Addr}}"`
        if [ -z "${ADDRS}" ]; then
                echo "node is not docker manager, or could not get ip addresses."
                exit 1
        fi
        echo "node addresses:"
        echo "${ADDRS}"
        echo ""

        # list node addresses
        IP=`docker node inspect self --format "{{.Status.Addr}}"`
        if [ -z "${IP}" ]; then
                echo "node is not docker manager, or could not get ip address."
                exit 1
        fi
        echo "ip: ${IP}"
        echo ""

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
        mkdir -pv "${VOLUME_EXPORT_DIR}"
        echo "${VOLUME_EXPORT_DIR} ${EXPORTS}" > "${EXPORTS_CONFIG_FILE}"
        /etc/init.d/nfs-kernel-server restart

        # show server guide
        SHOW_SERVER_GUIDE="1"
fi

# install global volume
if [ -n "${IP}" ]; then
        echo ""
        echo "[install global volume]"

        # netshare
        wget -O /tmp/netshare.deb "${NETSHARE_DEB_URL}"
        dpkg -i /tmp/netshare.deb
        service docker-volume-netshare start
        rm -f /tmp/netshare.deb

        # remove global volume
        docker volume inspect ${VOLUME_NAME} && docker volume rm ${VOLUME_NAME}
        docker volume inspect ${VOLUME_NAME} && echo "could not delete volume '${VOLUME_NAME}'?" && exit 1
        echo "volume '${VOLUME_NAME}' seems removed or not found."
        echo "creating volume '${VOLUME_NAME}' ..."

        # create global volume
        docker volume create \
           --driver local \
           --opt type=nfs4 \
           --opt o=addr=${IP},rw,hard,intr \
           --opt device=:${VOLUME_EXPORT_DIR} \
           ${VOLUME_NAME}

        # inspect global volume
        docker volume inspect ${VOLUME_NAME}
fi

# show server guide
if [ "${SHOW_SERVER_GUIDE}" = "1" ]; then
        echo ""
        echo "copy and paste this command to client node for install global volume:"
        echo "  curl -sSL ${INSTALL_SH_URL} | sudo sh -s ${IP}"
fi

# done!
echo ""
echo "done."
