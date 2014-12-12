install
url --url="http://repo01.demo.lan/centos/7/os/x86_64/"
text
keyboard es
lang en_US.UTF-8
eula --agreed
network --bootproto=dhcp --device=bootif --onboot=on
rootpw password
timezone Europe/Madrid --isUtc
services --enabled sshd
selinux --disabled
firewall --disabled
repo --name="CentOS" --baseurl=http://repo01.demo.lan/centos/7/os/x86_64/
repo --name="Updates" --baseurl=http://repo01.demo.lan/centos/7/updates/
repo --name="EPEL" --baseurl=http://repo01.demo.lan/centos/7/epel/
repo --name="Misc" --baseurl=http://repo01.demo.lan/centos/7/misc/
repo --name="Puppet-products" --baseurl=http://repo01.demo.lan/puppet/puppetlabs-products/
repo --name="Puppet-deps" --baseurl=http://repo01.demo.lan/puppet/puppetlabs-deps/
ignoredisk --only-use=vda
bootloader --location=mbr
zerombr
clearpart --all --initlabel
part swap --asprimary --fstype="swap" --size=1024
part /boot --fstype xfs --size=200
part / --fstype ext4 --size=1024 --grow
reboot

%packages --excludedocs --ignoremissing
@Core
rubygem-r10k
puppet
git
%end

%post --nochroot --log=/mnt/sysimage/root/ks-post-nochroot.log
rm -f /mnt/sysimage/etc/yum.repos.d/* /tmp/yum.repos.d/anaconda.repo
cp /tmp/yum.repos.d/* /mnt/sysimage/etc/yum.repos.d/
%end

%post --log=/root/ks-post-chroot.log
rpm --import http://repo01.demo.lan/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
rpm --import http://repo01.demo.lan/centos/7/epel/RPM-GPG-KEY-EPEL-7
rpm --import http://repo01.demo.lan/puppet/RPM-GPG-KEY-puppetlabs
%end
