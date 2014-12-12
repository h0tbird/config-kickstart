install
url --url="http://repo01.demo.lan/centos/7/os/x86_64/"
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
repo --name="CentOS" --baseurl=http://repo01.demo.lan/centos/7/os/x86_64/
repo --name="Updates" --baseurl=http://repo01.demo.lan/centos/7/updates/
repo --name="EPEL" --baseurl=http://repo01.demo.lan/centos/7/epel/
repo --name="Misc" --baseurl=http://repo01.demo.lan/centos/7/misc/
repo --name="Puppet-products" --baseurl=http://repo01.demo.lan/puppet/puppetlabs-products/
repo --name="Puppet-deps" --baseurl=http://repo01.demo.lan/puppet/puppetlabs-deps/
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
kmod-forcedeth
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
rpm --import http://repo01.demo.lan/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
rpm --import http://repo01.demo.lan/centos/7/epel/RPM-GPG-KEY-EPEL-7
rpm --import http://repo01.demo.lan/puppet/RPM-GPG-KEY-puppetlabs

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br0
DEVICE=br0
NAME=br0
TYPE=Bridge
ONBOOT=yes
STP=yes
DELAY=0
BOOTPROTO=dhcp
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV6INIT=no
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-enp0s10
DEVICE=enp0s10
NAME=enp0s10
TYPE=Ethernet
ONBOOT=yes
BRIDGE=br0
EOF

rm -rf /etc/puppet
git clone https://github.com/h0tbird/puppet.git /etc/puppet

cat << EOF > /etc/puppet/hieradata/common.yaml
---

SshKeys:
 marc.villacorta: &SshKey_marc_villacorta 'AAAAB3NzaC1yc2EAAAADAQABAAABAQD4FtYAzzgjQWuR8yDa0XV+LGlUjuHvI9HXhAKGmkb2HsSNTcPOJmE5F1TxC761va4KRN+nTTJ5d1Ts+7TyupvmSJVM53I3nZBipCieF59uTQxFSFTTJbQh9+0EhhjFl5WL3tA8kgzlAC/ARAWiW0+GDVmo8IQ+RkKcNVebKbXHMH9lFzKxUmFN7pS7VfPOwxjEqZMEAnNb7K3adWQDf98w2qDQ2gfwDqbc45TiNf39+4OJIW4oPyvT9B/p0K6NGNu1SSct9uO+HDNuZlLcRd7yIbhL0IrcROHNwAmHxHo9Ki2G/mIoOCUyinLyg94XzW+D0QWIBN2oJA7CWOrr0TJn'
 deborah.aguilar: &SshKey_deborah_aguilar 'AAAB3NzaC1yc2EAAAADAQABAAABAQCVblqnZu6pnuHyIqrYIVfmIn4LLo98nQTcUiDTBuyo1k2fOeSlMz8tDIB0fZpyOaoTFASTIGF4pSNczNlv23kwYj5mIuctLmiNF0+VCEWeE0wj7LEA7s1/YXziKBczVkFhl06uPNQ/OHhEKy7LjPn9DTX2NFnWO00GQ+oyLhTMMe5O8OTmtT/ySNYhouhxR7jdMtOo4qw2wkGVXk123A+i1hCpvylUaS70MkM08he/q99pjT3f1VbZg6mw6bPXtM+de4RkkCFF3T53djy4Omil6yiAGODzVIVBXXUuZtU+YlsWtATac3Vs0nFcgujqMKRvvuMVy9/ZejLG4eQartzB'

Users:
 root: &User_root
  linux:
   uid: '0'
   gid: '0'
   comment: 'root'
   pass: '!!'
   home: '/root'
   shell: '/bin/bash'
   keys:
    marc.villacorta:
     key: *SshKey_marc_villacorta
    deborah.aguilar:
     key: *SshKey_deborah_aguilar
   profiles:
    - 'root'
    - 'marc.villacorta'
    - 'deborah.aguilar'

# users
r_base::users:
  root: *User_root

# ssh
r_base::ssh:
 ensure: 'running'
 enable: true
 version: 'latest'

# terminfo
r_base::terminfo:
 purge: false
 backup: false
 recurse: 'remote'

...
EOF

cat << EOF > /etc/puppet/environments/production/Puppetfile
mod 'r_kvm',
  :git => 'https://h0tbird@github.com/h0tbird/puppet-r_kvm.git'

mod 'r_base',
  :git => 'https://h0tbird@github.com/h0tbird/puppet-r_base.git'

mod 'stdlib',
  :git => 'https://github.com/puppetlabs/puppetlabs-stdlib.git',
  :tag => '4.3.2'

mod 'users',
  :git => 'https://h0tbird@github.com/h0tbird/puppet-users.git'

mod 'sshd',
  :git => 'https://h0tbird@github.com/h0tbird/puppet-sshd.git'

mod 'terminfo',
  :git => 'https://h0tbird@github.com/h0tbird/puppet-terminfo.git'
EOF

cd /etc/puppet/environments/production
/usr/local/bin/r10k puppetfile install
%end
