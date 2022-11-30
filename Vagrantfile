# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/focal64"
    config.vm.box_version = "20221121.0.0"

    config.vm.box_check_update = false
    config.ssh.insert_key = false
    # insecure_private_key download from https://github.com/hashicorp/vagrant/blob/master/keys/vagrant
    config.ssh.private_key_path = "insecure_private_key"

    my_machines = {
        'vm111'   => '192.168.56.111',
        'vm112'   => '192.168.56.112',
        'vm113'   => '192.168.56.113',
        'vm114'   => '192.168.56.114',
        'vm115'   => '192.168.56.115',
        'vm116'   => '192.168.56.116',
        'vm117'   => '192.168.56.117',
        'vm118'   => '192.168.56.118',
        'vm119'   => '192.168.56.119',
        'vm120'   => '192.168.56.120',
        'vm121'   => '192.168.56.121',
    }

    my_machines.each do |name, ip|
        config.vm.define name do |machine|
            machine.vm.network "private_network", ip: ip

            machine.vm.hostname = name
            machine.vm.provider :virtualbox do |vb|
                vb.name = name  
                vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
                vb.customize ["modifyvm", :id, "--vram", "32"]
                vb.customize ["modifyvm", :id, "--ioapic", "on"]
                vb.customize ["modifyvm", :id, "--cpus", "4"]
                vb.customize ["modifyvm", :id, "--memory", "8096"]
            end

            machine.vm.provision "shell", inline: <<-SHELL
                echo "root:vagrant" | sudo chpasswd
                timedatectl set-timezone "Asia/Shanghai"
            SHELL

            if name == "vm111"
                machine.vm.provision "shell", inline: <<-SHELL
                    bash /vagrant/scripts/install-doris.sh --fe --iface enp0s8 --fe-role "leader"
                SHELL
            elsif name == "vm112"
                machine.vm.provision "shell", inline: <<-SHELL
                    bash /vagrant/scripts/install-doris.sh --fe --iface enp0s8 --fe-leader "192.168.56.111" --fe-role "observer"
                SHELL
            elsif name == "vm113" or name == "vm114" or name == "vm115"
                machine.vm.provision "shell", inline: <<-SHELL
                    bash /vagrant/scripts/install-doris.sh --be --iface enp0s8 --fe-leader "192.168.56.111"
                SHELL
            elsif name == "vm116" or name == "vm117" or name == "vm118"
                machine.vm.provision "shell", inline: <<-SHELL
                    bash /vagrant/scripts/install-zookeeper.sh --iface enp0s8 --ips "192.168.56.116,192.168.56.117,192.168.56.118"
                    bash /vagrant/scripts/install-hadoop.sh --iface enp0s8 --ips "192.168.56.116,192.168.56.117,192.168.56.118,192.168.56.119,192.168.56.120,192.168.56.121"
                SHELL
            elsif name == "vm119" or name == "vm120" or name == "vm121"
                machine.vm.provision "shell", inline: <<-SHELL
                    bash /vagrant/scripts/install-hadoop.sh --iface enp0s8 --ips "192.168.56.116,192.168.56.117,192.168.56.118,192.168.56.119,192.168.56.120,192.168.56.121"
                SHELL
            else
                machine.vm.provision "shell", inline: <<-SHELL
                SHELL
            end

        end
    end




end