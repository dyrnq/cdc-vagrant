# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/jammy64"
    config.vm.disk :disk, size: "500GB", primary: true
    # config.vm.box_version = "20221121.0.0"

    config.vm.box_check_update = false
    config.ssh.insert_key = false
    # insecure_private_key download from https://github.com/hashicorp/vagrant/blob/master/keys/vagrant
    config.ssh.private_key_path = "insecure_private_key"

#     zoo_m = {
#         'vm101'   => '192.168.56.101',
#         'vm102'   => '192.168.56.102',
#         'vm103'   => '192.168.56.103',
#     }

#     zoo_m.each do |name, ip|
#         config.vm.define name do |machine|
#             machine.vm.network "private_network", ip: ip

#             machine.vm.hostname = name
#             machine.vm.provider :virtualbox do |vb|
#                 vb.name = name  
#                 vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
#                 vb.customize ["modifyvm", :id, "--vram", "32"]
#                 vb.customize ["modifyvm", :id, "--ioapic", "on"]
#                 vb.customize ["modifyvm", :id, "--cpus", "2"]
#                 vb.customize ["modifyvm", :id, "--memory", "1536"]
#             end

#             machine.vm.provision "shell", path: "scripts/provision.sh"

#             machine.vm.provision "shell", inline: <<-SHELL
#             bash /vagrant/scripts/install-zookeeper.sh --iface enp0s8 --ips "192.168.56.101,192.168.56.102,192.168.56.103"
# SHELL

#         end
#     end


    hadoop_machines = {
        'vm116'   => '192.168.56.116',
        'vm117'   => '192.168.56.117',
        'vm118'   => '192.168.56.118',
        'vm119'   => '192.168.56.119',
        'vm211'   => '192.168.56.211',
        # 'vm120'   => '192.168.56.120',
        # 'vm121'   => '192.168.56.121',
        
    }

    hadoop_machines.each do |name, ip|
        config.vm.define name do |machine|
            machine.vm.network "private_network", ip: ip

            machine.vm.hostname = name
            machine.vm.provider :virtualbox do |vb|
                vb.name = name  
                vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
                vb.customize ["modifyvm", :id, "--vram", "32"]
                vb.customize ["modifyvm", :id, "--ioapic", "on"]
                vb.customize ["modifyvm", :id, "--cpus", "4"]
                vb.customize ["modifyvm", :id, "--memory", "6144"]
            end

            machine.vm.provision "shell", path: "scripts/provision.sh"

            if ["vm116", "vm117", "vm118", "vm119"].include?(name)
                machine.vm.provision "shell", inline: <<-SHELL
                bash /vagrant/scripts/install-zookeeper.sh --iface enp0s8 --ips "192.168.56.116,192.168.56.117,192.168.56.118"
                bash /vagrant/scripts/install-minio.sh
                bash /vagrant/scripts/install-minio-sidekick.sh --port "18000" --sites "http://vm{116...119}:9000"
                bash /vagrant/scripts/install-flink.sh --version 1.20.0 --flink-home /opt/flink
                bash /vagrant/scripts/install-flink-cdc.sh --version 3.2.0 --flink-cdc-home /opt/flink-cdc
SHELL

            end


#             if ["vm116", "vm117", "vm118", "vm119"].include?(name)
#                 machine.vm.provision "shell", inline: <<-SHELL
#                     bash /vagrant/scripts/ssh-copy-id.sh --iface enp0s8 --ips "192.168.56.116,192.168.56.117,192.168.56.118,192.168.56.119"
# SHELL
#             end


            if ["vm211"].include?(name)
                machine.vm.provision "shell", inline: <<-SHELL
                    bash /vagrant/scripts/install-doris.sh
SHELL
            end


        end
end

end

