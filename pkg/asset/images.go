package asset

// DefaultImages are the defualt images bootkube components use.
var DefaultImages = ImageVersions{
	Etcd:            "quay.io/coreos/etcd:v3.1.8",
	EtcdOperator:    "quay.io/coreos/etcd-operator:v0.5.0",
	Flannel:         "quay.io/coreos/flannel:v0.8.0-amd64",
	FlannelCNI:      "quay.io/coreos/flannel-cni:v0.3.0",
	Calico:          "quay.io/calico/node:v2.5.1",
	CalicoCNI:       "quay.io/calico/cni:v1.10.0",
	Hyperkube:       "quay.io/ryan_phillips/hyperkube-amd64:rphillips",
	Kenc:            "quay.io/coreos/kenc:0.0.2",
	KubeDNS:         "gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.4",
	KubeDNSMasq:     "gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.4",
	KubeDNSSidecar:  "gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.4",
	PodCheckpointer: "quay.io/coreos/pod-checkpointer:0cd390e0bc1dcdcc714b20eda3435c3d00669d0e",
}
