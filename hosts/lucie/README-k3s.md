# k3s with NVIDIA GPU Support on NixOS

## Building and Deploying generic-cdi-plugin

The generic-cdi-plugin must be built from source due to container image platform issues.

### Step 1: Clone the Repository

```bash
git clone https://github.com/OlfillasOdikno/generic-cdi-plugin.git /tmp/generic-cdi-plugin
cd /tmp/generic-cdi-plugin
```

### Step 2: Build the Binary

```bash
CGO_ENABLED=0 GOOS=linux go build -o generic-cdi-plugin main.go
```

### Step 3: Build the Container Image

```bash
docker build -t generic-cdi-plugin:local .
```

### Step 4: Import into k3s

```bash
docker save generic-cdi-plugin:local | sudo k3s ctr images import -
```

### Step 5: Deploy the DaemonSet

Create `generic-cdi-plugin-daemonset.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: generic-cdi-plugin
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: generic-cdi-plugin-daemonset
  namespace: generic-cdi-plugin
spec:
  selector:
    matchLabels:
      name: generic-cdi-plugin
  template:
    metadata:
      labels:
        name: generic-cdi-plugin
        app.kubernetes.io/component: generic-cdi-plugin
        app.kubernetes.io/name: generic-cdi-plugin
    spec:
      containers:
      - image: docker.io/library/generic-cdi-plugin:local
        name: generic-cdi-plugin
        command:
          - /generic-cdi-plugin
          - /var/run/cdi/nvidia-container-toolkit.json
        imagePullPolicy: Never
        securityContext:
          privileged: true
        tty: true
        volumeMounts:
        - name: kubelet
          mountPath: /var/lib/kubelet
        - name: nvidia-container-toolkit
          mountPath: /var/run/cdi/nvidia-container-toolkit.json
      volumes:
      - name: kubelet
        hostPath:
          path: /var/lib/kubelet
      - name: nvidia-container-toolkit
        hostPath:
          path: /var/run/cdi/nvidia-container-toolkit.json
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: "nixos-nvidia-cdi"
                operator: In
                values:
                - "enabled"
```

Apply the DaemonSet:

```bash
sudo kubectl apply -f generic-cdi-plugin-daemonset.yaml
```

### Step 6: Verify Deployment

Check that the plugin is running:

```bash
sudo kubectl get pods -n generic-cdi-plugin
```

Expected output:
```
NAME                                 READY   STATUS    RESTARTS   AGE
generic-cdi-plugin-daemonset-xxxxx   1/1     Running   0          1m
```

Check the logs:

```bash
sudo kubectl logs -n generic-cdi-plugin generic-cdi-plugin-daemonset-xxxxx
```

Expected output:
```
2025/12/21 14:41:41 Registering plugin for nvidia.com/gpu=all
2025/12/21 14:41:41 Registering plugin for nvidia.com/gpu=0
2025/12/21 14:41:41 Registering plugin for nvidia.com/gpu=GPU-xxxxx
```

Verify GPU resources are advertised:

```bash
sudo kubectl describe node | grep -A 5 "Allocatable"
```

You should see:
```
nvidia.com/gpu-0:                                         1
nvidia.com/gpu-GPU-xxxxx:                                 1
nvidia.com/gpu-all:                                       1
```

## Using GPU in Pods

### Example Pod with GPU Access

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
spec:
  containers:
  - name: test
    image: busybox:latest
    command: ["sh", "-c", "ls -la /dev/nvidia* && sleep 3600"]
    resources:
      requests:
        nvidia.com/gpu-all: "1"
      limits:
        nvidia.com/gpu-all: "1"
  restartPolicy: Never
```

Apply and test:

```bash
sudo kubectl apply -f gpu-test.yaml
sudo kubectl logs gpu-test
```

Expected output showing NVIDIA devices:
```
crw-rw-rw-    1 root     root      195, 254 Dec 21 14:45 /dev/nvidia-modeset
crw-rw-rw-    1 root     root      236,   0 Dec 21 14:45 /dev/nvidia-uvm
crw-rw-rw-    1 root     root      236,   1 Dec 21 14:45 /dev/nvidia-uvm-tools
crw-rw-rw-    1 root     root      195,   0 Dec 21 14:45 /dev/nvidia0
crw-rw-rw-    1 root     root      195, 255 Dec 21 14:45 /dev/nvidiactl
```

### GPU Resource Types

You can request different GPU resources:

- `nvidia.com/gpu-all` - Access to all GPUs
- `nvidia.com/gpu-0` - Access to the first GPU (by index)
- `nvidia.com/gpu-GPU-<UUID>` - Access to a specific GPU by UUID


## Rebuilding After NixOS Updates

After running `nixos-rebuild switch`:

1. The CDI specs are automatically regenerated
2. k3s restarts with the new configuration
3. You may need to rebuild and reimport the generic-cdi-plugin image if the container runtime changes

To rebuild the plugin:

```bash
cd /tmp/generic-cdi-plugin
docker build -t generic-cdi-plugin:local .
docker save generic-cdi-plugin:local | sudo k3s ctr images import -
sudo kubectl delete pod -n generic-cdi-plugin --all
```

## References

- [generic-cdi-plugin GitHub](https://github.com/OlfillasOdikno/generic-cdi-plugin)
- [NixOS k3s GPU Support Documentation](https://nixos.wiki/wiki/K3s)
- [Container Device Interface (CDI) Specification](https://github.com/cncf-tags/container-device-interface)
- [NVIDIA Container Toolkit Documentation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)

