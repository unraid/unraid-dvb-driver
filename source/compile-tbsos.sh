# Create necessary directories and download source
cd ${DATA_DIR}
mkdir ${DATA_DIR}/TBS
mkdir -p /tbs/lib/firmware
mkdir -p /tbs/lib/modules/${UNAME}
cd ${DATA_DIR}/TBS

# Get package url and version
BASE_URL="https://www.tbsiptv.com/download/common/"
LATEST_FILE=$(curl -s 'https://www.tbsiptv.com/index.php?route=product/download/search&dkeyword=Linux+Driver+Beta' | grep -oE 'tbsdvb_v[0-9]+\.tar\.bz2')
FULL_URL="${BASE_URL}${LATEST_FILE}"
PLUGIN_VERSION="$(echo "$LATEST_FILE" | cut -d'_' -f2 | cut -d'.' -f1 | tr -d 'v')"

# Download package
wget -O ${DATA_DIR}/TBS/tbs.tar.bz2 "$FULL_URL"
tar -xf ${DATA_DIR}/TBS/tbs.tar.bz2
cd tbsdvb

# Build package and install modules
make -j${CPU_COUNT} CONFIG_DVB_STB6100=m KCFLAGS="-DCONFIG_MEDIA_TUNER_TDA18271_MODULE=1 -DCONFIG_MEDIA_TUNER_TDA8290_MODULE=1 -DCONFIG_DVB_STV6110x_MODULE=1 -DCONFIG_DVB_STV6111_MODULE=1"
make install -j${CPU_COUNT} MDIR=/tbs CONFIG_DVB_STB6100=m KCFLAGS="-DCONFIG_MEDIA_TUNER_TDA18271_MODULE=1 -DCONFIG_MEDIA_TUNER_TDA8290_MODULE=1 -DCONFIG_DVB_STV6110x_MODULE=1 -DCONFIG_DVB_STV6111_MODULE=1"

# Extract firmware files
tar -xf tbs-tuner-firmwares_*.tar.bz2 -C /tbs/lib/firmware/

# Remove unnecessary files from moudles directory
cd /tbs/lib/modules/${UNAME}/
rm /tbs/lib/modules/${UNAME}/* 2>/dev/null
find . -depth -exec rmdir {} \;  2>/dev/null

# Create Slackware package
PLUGIN_NAME="tbsos"
BASE_DIR="/tbs"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$PLUGIN_VERSION"

mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME DVB driver v$TBS_MEDIA_BUILD_V
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME DVB driver package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-$PLUGIN_VERSION-$UNAME-1.txz
md5sum $TMP_DIR/$PLUGIN_NAME-$PLUGIN_VERSION-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-$PLUGIN_VERSION-$UNAME-1.txz.md5
