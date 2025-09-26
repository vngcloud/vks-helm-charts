template:
	rm -rf ./*.tgz
	helm package .

	rm -rf ./helm/calico/templates

	helm template calico ./*.tgz \
		--namespace kube-system \
		--debug --output-dir helm -f values-test.yaml