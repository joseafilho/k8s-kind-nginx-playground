Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.network "public_network", use_dhcp_assigned_default_route: true, bridge: "wlp3s0"
  # config.vm.network "forwarded_port", guest: 30001, host: 8080, id: "k8s-http"
  # config.vm.network "forwarded_port", guest: 30002, host: 8443, id: "k8s-https"

  config.vm.provider "VirtualBox" do |vb|
    vb.name = "kind-nginx"
    vb.memory = 4096
    vb.cpus = 4
  end

  # Declare environment variables.
  with_gui = ENV["WITH_GUI"] == "1"
  install_browser = ENV["INSTALL_BROWSER"] == "1"
  setup_kind_k8s = ENV["SETUP_KIND_K8S"] == "1"

  # Install docker and running simple hello-world.
  config.vm.provision "docker" do |d|
    d.run "hello-world"
  end

  if with_gui
    config.vm.provision "shell", inline: <<-SHELL
      echo "[GUI] Installing Xubuntu Core + LightDM..."
      echo "lightdm shared/default-x-display-manager select lightdm" | sudo debconf-set-selections
      sudo DEBIAN_FRONTEND=noninteractive apt install -y xubuntu-core lightdm
      sudo systemctl enable lightdm
      sudo systemctl set-default graphical.target
    SHELL
  end

  if install_browser
    config.vm.provision "shell", inline: <<-SHELL
      echo "[Browser] Installing firefox..."
      sudo apt install -y firefox
    SHELL
  end

  if setup_kind_k8s
    # Copy files.
    config.vm.provision "shell", inline: <<-SHELL
      mkdir -p $HOME/playground
    SHELL

    config.vm.provision "file", source: "./apache-hello", destination: "$HOME/playground/"
    config.vm.provision "file", source: "./ingress-nginx", destination: "$HOME/playground/"
    config.vm.provision "file", source: "./kubernetes-dashboard", destination: "$HOME/playground/"
    config.vm.provision "file", source: "./projects", destination: "$HOME/playground/"

    # Run install tools.
    config.vm.provision :shell, path: "bootstrap.sh"
  end
end 
  