#!/bin/bash

source /root/.bashrc

echo "starting packer build of $PACKER_VM_NAME"
packer build -var-file=packer-remote-info.json /root/packer-templates/templates/$PACKER_VM_NAME.json

echo "registering ${PACKER_VM_NAME} virtual machine on ${PACKER_REMOTE_HOST}"
/usr/bin/sshpass -p ${PACKER_REMOTE_PASSWORD} ssh root@${PACKER_REMOTE_HOST} "vim-cmd solo/registervm /vmfs/volumes/${PACKER_REMOTE_DATASTORE}/output-${PACKER_VM_NAME}/*.vmx"

mkdir -p /root/box_files/ovf/empty_dir/
mkdir -p /root/box_files/vmx/empty_dir/

rm -rf /root/box_files/ovf/${PACKER_VM_NAME}
rm -rf /root/box_files/vmx/${PACKER_VM_NAME}

echo "output of /vmfs/volumes/${PACKER_REMOTE_DATASTORE}/output-${PACKER_VM_NAME}/*.vmxf:"
/usr/bin/sshpass -p ${PACKER_REMOTE_PASSWORD} ssh root@${PACKER_REMOTE_HOST} "cat /vmfs/volumes/${PACKER_REMOTE_DATASTORE}/output-${PACKER_VM_NAME}/*.vmxf"

ovftool vi://root:${PACKER_REMOTE_PASSWORD}@${PACKER_REMOTE_HOST}/${PACKER_VM_NAME} /root/box_files/ovf/
ovftool -tt=vmx vi://root:${PACKER_REMOTE_PASSWORD}@${PACKER_REMOTE_HOST}/${PACKER_VM_NAME} /root/box_files/vmx/

echo "creating metadata.json and Vagrantfile files in ovf virtual machine directory"
echo '{"provider":"vmware_ovf"}' >> /root/box_files/ovf/${PACKER_VM_NAME}/metadata.json
touch /root/box_files/ovf/${PACKER_VM_NAME}/Vagrantfile
cd /root/box_files/ovf/empty_dir/
cd /root/box_files/ovf/${PACKER_VM_NAME}/

echo "compressing ovf virtual machine files to /var/www/html/box-files/${PACKER_VM_NAME}-vmware_ovf-1.0.box" 
tar cvzf /var/www/html/box-files/$PACKER_VM_NAME-vmware_ovf-1.0.box ./*

echo "creating metadata.json and Vagrantfile files in vmx virtual machine directory"
echo '{"provider":"vmware_desktop"}' >> /root/box_files/vmx/${PACKER_VM_NAME}/metadata.json
touch /root/box_files/vmx/${PACKER_VM_NAME}/Vagrantfile
cd /root/box_files/vmx/empty_dir/
cd /root/box_files/vmx/${PACKER_VM_NAME}/

echo "compressing vmx virtual machine files to /var/www/html/box-files/${PACKER_VM_NAME}-vmware_desktop-1.0.box"
tar cvzf /var/www/html/box-files/$PACKER_VM_NAME-vmware_desktop-1.0.box ./*

echo "cleaning up /root/box_files directories"
rm -rf /root/box_files/ovf/$PACKER_VM_NAME
rm -rf /root/box_files/vmx/$PACKER_VM_NAME

echo "deleting $PACKER_VM_NAME from $PACKER_REMOTE_HOST"
/usr/bin/sshpass -p ${PACKER_REMOTE_PASSWORD} ssh root@${PACKER_REMOTE_HOST}  "vim-cmd vmsvc/getallvms | grep ${PACKER_VM_NAME} | cut -d ' ' -f 1 | xargs vim-cmd vmsvc/destroy"

echo "packer build of $PACKER_VM_NAME has been  completed"

