#!/bin/bash

VERSION='3.8.2'
PKGNAME="puppet-enterprise-${VERSION}-el-6-x86_64"
TARFILE="${PKGNAME}.tar.gz"
URL="https://pm.puppetlabs.com/puppet-enterprise/${VERSION}/${TARFILE}"

TMPDIR='/tmp'
HOSTNAME=`hostname`
cd $TMPDIR
echo "Fetching ${TARFILE}"
[ -e $TARFILE ] || curl -fLO $URL
echo "Extracting ${TARFILE}"
[ -d $PKGNAME ] || tar -xf $TARFILE
cd $PKGNAME

cat > agent.ans <<EOF
q_all_in_one_install=n
q_database_install=n
q_pe_database=n
q_puppetca_install=n
q_puppetdb_install=n
q_puppetmaster_install=n
q_puppet_enterpriseconsole_install=n
q_run_updtvpkg=n
q_continue_or_reenter_master_hostname=c
q_fail_on_unsuccessful_master_lookup=n
q_puppetagent_certname=$HOSTNAME
q_puppetagent_install=y
q_puppetagent_server=puppet
q_puppet_cloud_install=y
q_puppet_symlinks_install=y
q_vendor_packages_install=y
q_install=y
EOF

./puppet-enterprise-installer -a agent.ans

# Remove certname so the system will use host FQDN
sed -i '/certname =/d' /etc/puppetlabs/puppet/puppet.conf

# add /opt/puppet/bin/ to the path of all users
echo "export PATH=$PATH:/opt/puppet/bin/" >> /etc/profile
