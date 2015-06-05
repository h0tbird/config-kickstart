install
url --url="http://data01/centos/7/os/x86_64/"
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
repo --name="CentOS" --baseurl=http://data01/centos/7/os/x86_64/
repo --name="Updates" --baseurl=http://data01/centos/7/updates/
repo --name="Extras" --baseurl=http://data01/centos/7/extras/
repo --name="EPEL" --baseurl=http://data01/centos/7/epel/
repo --name="Misc" --baseurl=http://data01/centos/7/misc/
repo --name="Puppet-products" --baseurl=http://data01/puppet/puppetlabs-products/
repo --name="Puppet-deps" --baseurl=http://data01/puppet/puppetlabs-deps/
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
rpm --import http://data01/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
rpm --import http://data01/centos/7/epel/RPM-GPG-KEY-EPEL-7
rpm --import http://data01/puppet/RPM-GPG-KEY-puppetlabs

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em1
DEVICE=em1
NAME=em1
TYPE=Ethernet
ONBOOT=yes
BRIDGE=core0
HWADDR=$(cat /sys/class/net/em1/address)
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
HWADDR=$(cat /sys/class/net/em1/address)
EOF

cat << EOF > /etc/r10k.yaml
cachedir: /var/cache/r10k
sources:
 puppet:
  remote: 'http://gito01/cgit/r10k-kvm'
  basedir: /etc/puppet/environments
EOF

cat << EOF > /usr/local/sbin/pupply
#!/bin/bash
r10k deploy environment -p
puppet apply /etc/puppet/environments/production/manifests/site.pp
EOF

chmod a+x /usr/local/sbin/pupply
rm -rf /etc/puppet
git clone http://gito01/cgit/puppet-config /etc/puppet
rm -rf /etc/puppet/environments/*
/usr/local/bin/r10k deploy environment -p
%end
