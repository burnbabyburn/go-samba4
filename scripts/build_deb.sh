#!/bin/bash
#https://git.samba.org/?p=samba.git;a=blob_plain;f=bootstrap/generated-dists/debian9/bootstrap.sh;hb=v4-12-test

gem install fpm

cd /tmp/

get_samba4=https://download.samba.org/pub/samba/stable/samba-4.13.0.tar.gz

PKG=$(basename ${get_samba4}|sed "s/.tar.gz//")
PKG_NAME=$(basename ${get_samba4}|sed "s/.tar.gz//"|cut -d- -f1)
PKG_VERSION=$(basename ${get_samba4}|sed "s/.tar.gz//"|cut -d- -f2)

wget -c ${get_samba4}
tar xvfz $(basename ${get_samba4})
cd $(basename ${get_samba4}|sed "s/.tar.gz//")
./configure --with-ads --systemd-install-services --with-shared-modules=ALL --with-gpgme --enable-debug --enable-selftest --with-json --with-systemd --enable-spotlight --with-regedit --prefix=/opt/samba4

make -j$(nproc)
make install install DESTDIR=/tmp/installdir

mkdir -p /tmp/installdir/etc/systemd/system

echo '[Unit]
Description=Samba4 AD Daemon
After=syslog.target network.target
 
[Service]
Type=forking
PIDFile=/opt/samba4/var/run/samba.pid
LimitNOFILE=16384
EnvironmentFile=-/etc/sysconfig/samba4
ExecStart=/opt/samba4/sbin/samba $SAMBAOPTIONS
ExecReload=/usr/bin/kill -HUP $MAINPID
 
[Install]
WantedBy=multi-user.target' > /tmp/installdir/etc/systemd/system/samba4.service

fpm -s dir -t deb -n ${PKG_NAME} -v ${PKG_VERSION} -C /tmp/installdir \
  -d "python3-minimal" \
  -d "libpython3.8" \
  -d "libbsd0" \
  -d "libpopt0" \
  -d "libgnutls30" \
  -d "libldap-2.4-2" \
  -d "libcups2" \
  -d "libjansson4" \
  -d "libgpgme11" \
  -d "liblmdb0" \
  -p samba.deb .

mv samba.deb /opt/

apt-get clean autoclean
apt-get autoremove --yes
rm -fr /tmp/* /var/tmp/*

#cd /
#apt-get clean
#rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archive/*.deb /build


## Install DEB
## apt-get update
## apt-get -yq install python-minimal libpython2.7 libbsd0 libpopt0 libgnutls30 libldap-2.4-2 libcups2 libjansson4 libgpgme11
## dpkg -i /root/samba-4.9.0+dfsg-1.amd64.deb

### Add PATH
# echo 'export PATH=$PATH:/opt/samba4/bin:/opt/samba4/sbin' >> /etc/profile
# source /etc/profile


### Create Domain Samba4 like AD
# hostnamectl set-hostname samba4.linuxpro.net 
# samba-tool domain provision --server-role=dc --use-rfc2307 --dns-backend=SAMBA_INTERNAL --realm=LINUXPRO.NET --domain=LINUXPRO --adminpass=Linuxpro123456
# or
# samba-tool domain provision --server-role=dc --use-rfc2307 --function-level=2008_R2 --use-xattrs=yes --dns-backend=SAMBA_INTERNAL --realm=LINUXPRO.NET --domain=LINUXPRO --adminpass=Linuxpro123456

### Add start script on boot
# systemctl daemon-reload
# systemctl enable samba4.service
# systemctl start samba4.service
