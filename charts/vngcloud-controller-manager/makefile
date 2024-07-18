template:
	rm -f ./*.tgz
	helm package .

	cd ./helm/vngcloud-controller-manager && rm -rf templates

	helm template vngcloud-controller-manager ./*.tgz \
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
	helm install vngcloud-controller-manager oci://vcr.vngcloud.vn/60108-annd2-ingress/vks-helm-charts/vngcloud-controller-manager --replace \
		--namespace kube-system \
		--set cloudConfig.global.clientID=_____________________ \
		--set cloudConfig.global.clientSecret=_____________________ \
		--set cluster.clusterID=_____________________

un:
	helm uninstall -n kube-system vngcloud-controller-manager --ignore-not-found