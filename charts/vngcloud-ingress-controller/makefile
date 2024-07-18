template:
	rm -f ./*.tgz
	helm package .

	cd ./helm/vngcloud-ingress-controller && rm -rf templates

	helm template vngcloud-ingress-controller ./*.tgz \
		--namespace kube-system \
		--set cluster.clusterName=annd3 \
		--set cluster.clusterID=annd2 \
		--debug --output-dir helm
build-test:
	rm -f ./*.tgz
	helm package . --version 0.2.0
	chmod +x *.tgz
	helm push ./*.tgz oci://vcr.vngcloud.vn/60108-annd2-ingress/vks-helm-charts

install-test: build-test
	helm install vngcloud-ingress-controller oci://vcr.vngcloud.vn/60108-annd2-ingress/vks-helm-charts/vngcloud-ingress-controller --replace \
		--namespace kube-system \
		--set cloudConfig.global.clientID=_____________________ \
		--set cloudConfig.global.clientSecret=_____________________ \
		--set cluster.clusterID=_____________________

un:
	helm uninstall -n kube-system vngcloud-ingress-controller --ignore-not-found