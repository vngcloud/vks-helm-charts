IMAGE = cilium:v1.17.9
# IMAGE = certgen:v0.2.1
# IMAGE = hubble-relay:v1.17.9
# IMAGE = hubble-ui-backend:v0.13.3
# IMAGE = hubble-ui:v0.13.3
# IMAGE = cilium-envoy:v1.34.10-1760767433-887ebe7d6ccc2a9dc8c73f6ae4927283283b507e
# IMAGE = operator:v1.17.9
# IMAGE = operator-generic:v1.17.9
# IMAGE = startup-script:1755531540-60ee83e
# IMAGE = clustermesh-apiserver:v1.17.9


push:
	docker pull quay.io/cilium/${IMAGE}
	docker tag quay.io/cilium/${IMAGE} vcr.vngcloud.vn/81-vks-public/cilium/${IMAGE}
	docker push vcr.vngcloud.vn/81-vks-public/cilium/${IMAGE}
	docker rmi vcr.vngcloud.vn/81-vks-public/cilium/${IMAGE}
	docker rmi quay.io/cilium/${IMAGE}

	# docker pull docker.io/library/busybox:1.37.0
	# docker tag docker.io/library/busybox:1.37.0 vcr.vngcloud.vn/81-vks-public/cilium/library/busybox:1.37.0
	# docker push vcr.vngcloud.vn/81-vks-public/cilium/library/busybox:1.37.0

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