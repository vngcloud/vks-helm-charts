# IMAGE = cilium:v1.16.5
# IMAGE = certgen:v0.2.0
# IMAGE = hubble-relay:v1.16.5
# IMAGE = hubble-ui-backend:v0.13.1
# IMAGE = hubble-ui:v0.13.1
# IMAGE = cilium-envoy:v1.30.8-1733837904-eaae5aca0fb988583e5617170a65ac5aa51c0aa8
# IMAGE = operator:v1.16.5
# IMAGE = operator-generic:v1.16.5
# IMAGE = startup-script:c54c7edeab7fde4da68e59acd319ab24af242c3f
# IMAGE = clustermesh-apiserver:v1.16.5
# IMAGE = aaaaaaaaaaaa:bbbbbbbbbbbbbbb


push:
	# docker pull quay.io/cilium/${IMAGE}
	# docker tag quay.io/cilium/${IMAGE} vcr.vngcloud.vn/81-vks-public/${IMAGE}
	# docker push vcr.vngcloud.vn/81-vks-public/${IMAGE}
	# docker tag quay.io/cilium/${IMAGE} vcr.vngcloud.vn/81-vks-public/cilium/${IMAGE}
	# docker push vcr.vngcloud.vn/81-vks-public/cilium/${IMAGE}

	# docker pull docker.io/library/busybox:1.36.1
	# docker tag docker.io/library/busybox:1.36.1 vcr.vngcloud.vn/81-vks-public/cilium/library/busybox:1.36.1
	# docker push vcr.vngcloud.vn/81-vks-public/cilium/library/busybox:1.36.1

	# docker pull ghcr.io/spiffe/spire-agent:1.9.6
	# docker tag ghcr.io/spiffe/spire-agent:1.9.6 vcr.vngcloud.vn/81-vks-public/cilium/spiffe/spire-agent:1.9.6
	# docker push vcr.vngcloud.vn/81-vks-public/cilium/spiffe/spire-agent:1.9.6

	# docker pull ghcr.io/spiffe/spire-server:1.9.6
	# docker tag ghcr.io/spiffe/spire-server:1.9.6 vcr.vngcloud.vn/81-vks-public/cilium/spiffe/spire-server:1.9.6
	# docker push vcr.vngcloud.vn/81-vks-public/cilium/spiffe/spire-server:1.9.6

template:
	rm -f ./*.tgz
	helm package .

	rm -rf ./helm/cilium/templates

	helm template cilium ./*.tgz \
		--debug --output-dir helm

build-test:
	rm -f ./*.tgz
	helm package . --version 0.0.0
	chmod +x *.tgz
	helm push ./*.tgz oci://vcr.vngcloud.vn/81-vks-public/vks-helm-charts