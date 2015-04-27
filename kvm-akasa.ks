install
url --url="http://data01.demo.lan/centos/7/os/x86_64/"
text
keyboard es
lang en_US.UTF-8
eula --agreed
network --bootproto=dhcp --device=bootif --onboot=on
rootpw password
timezone Europe/Madrid --isUtc
services --disabled auditd,avahi-daemon,NetworkManager,postfix,microcode,tuned
services --enabled network,sshd
selinux --disabled
firewall --disabled
repo --name="CentOS" --baseurl=http://data01.demo.lan/centos/7/os/x86_64/
repo --name="Updates" --baseurl=http://data01.demo.lan/centos/7/updates/
repo --name="EPEL" --baseurl=http://data01.demo.lan/centos/7/epel/
repo --name="Misc" --baseurl=http://data01.demo.lan/centos/7/misc/
repo --name="Puppet-products" --baseurl=http://data01.demo.lan/puppet/puppetlabs-products/
repo --name="Puppet-deps" --baseurl=http://data01.demo.lan/puppet/puppetlabs-deps/
ignoredisk --only-use=sda
bootloader --location=mbr
zerombr
clearpart --all --initlabel
part swap --asprimary --fstype="swap" --size=1024
part /boot --fstype xfs --size=200
part / --fstype ext4 --size=1024 --grow
reboot

%packages --nobase --excludedocs
@Core
bridge-utils
rubygem-r10k
puppet
git
-*NetworkManager*
-*firmware*
-*firewalld*
%end

%post --nochroot --log=/mnt/sysimage/root/ks-post-nochroot.log
rm -f /mnt/sysimage/etc/yum.repos.d/* /tmp/yum.repos.d/anaconda.repo
cp /tmp/yum.repos.d/* /mnt/sysimage/etc/yum.repos.d/
%end

%post --log=/root/ks-post-chroot.log
rpm --import http://data01.demo.lan/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
rpm --import http://data01.demo.lan/centos/7/epel/RPM-GPG-KEY-EPEL-7
rpm --import http://data01.demo.lan/puppet/RPM-GPG-KEY-puppetlabs

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eno1
DEVICE=eno1
NAME=eno1
TYPE=Ethernet
ONBOOT=no
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eno2
DEVICE=eno2
NAME=eno2
TYPE=Ethernet
ONBOOT=yes
BRIDGE=core0
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eno1.3
DEVICE=eno1.3
NAME=eno1.3
TYPE=Ethernet
ONBOOT=yes
BRIDGE=core1
VLAN=yes
ONPARENT=yes
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eno1.6
DEVICE=eno1.6
NAME=eno1.6
TYPE=Ethernet
ONBOOT=yes
BRIDGE=core2
VLAN=yes
ONPARENT=yes
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-core0
DEVICE=core0
NAME=core0
TYPE=Bridge
ONBOOT=yes
STP=no
DELAY=0
BOOTPROTO=dhcp
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV6INIT=no
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-core1
DEVICE=core1
NAME=core1
TYPE=Bridge
ONBOOT=yes
STP=no
IPV6INIT=no
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-core2
DEVICE=core2
NAME=core2
TYPE=Bridge
ONBOOT=yes
STP=no
IPV6INIT=no
EOF

cat << EOF > /etc/r10k.yaml
cachedir: /var/cache/r10k
sources:
 puppet:
  remote: 'http://gito01.demo.lan/cgit/r10k-kvm'
  basedir: /etc/puppet/environments
EOF

cat << EOF > /usr/local/sbin/pupply
#!/bin/bash
r10k deploy environment -p
puppet apply /etc/puppet/environments/production/manifests/site.pp
EOF

chmod a+x /usr/local/sbin/pupply
rm -rf /etc/puppet
git clone http://gito01.demo.lan/cgit/puppet-config /etc/puppet
rm -rf /etc/puppet/environments/*
/usr/local/bin/r10k deploy environment -p
%end
