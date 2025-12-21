{ pkgs, username, config, lib, ... }:
let
  # NVIDIA runtime configuration for k3s containerd 2.0 with CDI support
  # Uses the base template to extend k3s's default config
  # Note: containerd 2.0 uses v3 config format with different plugin paths
  containerdConfigTemplate = pkgs.writeText "config-v3.toml.tmpl" ''
    {{ template "base" . }}

    # Enable CDI support for GPU access (containerd 2.0 format)
    [plugins.'io.containerd.cri.v1.runtime'.cdi]
      enable = true
      spec_dirs = ["/var/run/cdi"]
  '';
in {

  # Enable k3s service
  services.k3s = {
    enable = true;
    role = "server";

    # Extra flags for k3s server
    extraFlags = toString [
      # Use containerd snapshotter
      "--snapshotter=native"
      # Add node label for generic-cdi-plugin
      "--node-label=nixos-nvidia-cdi=enabled"
    ];
  };

  # Add NVIDIA runtime configuration to k3s containerd
  # For containerd 2.0, use config-v3.toml.tmpl instead of config.toml.tmpl
  systemd.tmpfiles.rules = [
    "d /var/lib/rancher/k3s/agent/etc/containerd 0755 root root -"
    "L+ /var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.tmpl - - - - ${containerdConfigTemplate}"
  ];

  # Open firewall ports for k3s
  networking.firewall = {
    allowedTCPPorts = [
      80 # Traefik HTTP
      443 # Traefik HTTPS
      6443 # Kubernetes API server
      10250 # Kubelet metrics
    ];
    allowedUDPPorts = [
      8472 # Flannel VXLAN
    ];
  };

  users.users.${username} = {
    # Add k3s tools to user packages
    packages = with pkgs; [ k3s kubectl kubernetes-helm ];
    # Add user to k3s group for kubectl access
    extraGroups = [ "k3s" ];
  };

  # Add nvidia-container-toolkit to system packages
  environment.systemPackages = [ config.hardware.nvidia-container-toolkit.package ];

  # Generate NVIDIA CDI specs for container runtime
  systemd.services.nvidia-cdi-generate = {
    description = "Generate NVIDIA CDI specs";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "generate-nvidia-cdi" ''
        set -e
        mkdir -p /var/run/cdi
        # Generate CDI specs with correct hook path for NixOS
        # nvidia-ctk is the actual binary, nvidia-cdi-hook is just an alias
        ${config.hardware.nvidia-container-toolkit.package}/bin/nvidia-ctk cdi generate \
          --output=/var/run/cdi/nvidia-container-toolkit.json \
          --format=json \
          --nvidia-cdi-hook-path=${config.hardware.nvidia-container-toolkit.package}/bin/nvidia-ctk
        echo "NVIDIA CDI specs generated at /var/run/cdi/nvidia-container-toolkit.json"
      '';
    };
  };

  # Setup RuntimeClass for GPU support
  systemd.services.k3s-gpu-setup = {
    description = "Setup k3s GPU RuntimeClass";
    wantedBy = [ "multi-user.target" ];
    after = [ "k3s.service" "nvidia-cdi-generate.service" ];
    requires = [ "k3s.service" "nvidia-cdi-generate.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "k3s-gpu-setup" ''
        set -e

        # Wait for k3s to be ready
        until ${pkgs.k3s}/bin/kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get nodes &>/dev/null; do
          echo "Waiting for k3s to be ready..."
          sleep 5
        done

        # Apply RuntimeClass for NVIDIA
        echo "Creating NVIDIA RuntimeClass..."
        ${pkgs.k3s}/bin/kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml apply -f - <<EOF
        apiVersion: node.k8s.io/v1
        handler: nvidia
        kind: RuntimeClass
        metadata:
          labels:
            app.kubernetes.io/component: gpu-operator
          name: nvidia
        EOF

        echo "GPU RuntimeClass created!"
        echo "GPU support is now enabled via CDI"
        echo "You can use 'runtimeClassName: nvidia' and CDI device annotations in your pods"
      '';
    };
  };

}
