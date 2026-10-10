# vks-helm-charts

Agent guide for this repository. Operational context (tasks, evidence, review, deploy) lives in the team harness
(`vks-harness`).

Helm chart monorepo for VKS add-ons. Every chart under `charts/` that is merged to `main` with a new `version` is
published as a GitHub release + `gh-pages` index (`helm repo add vks-helm-charts https://vngcloud.github.io/vks-helm-charts`)
and pushed as OCI to vCR in two regions (HCM and HAN). No release-please, no CHANGELOG automation, no CONTRIBUTING.md.

## Commands
- Verify (what the harness runs): `python3 tools/verify.py` in `vks-harness` = `helm lint charts/<name>` for every
  `charts/*/Chart.yaml`. Run the one you touched directly: `helm lint charts/<name>`
- Render: `helm template <name> charts/<name> --namespace kube-system --debug`
  (add `-f <values file>` / `--set` for the paths you changed; e.g. `-f charts/calico/values-test.yaml` for calico)
- Diff the rendering against the last release: `git show <chart>-<oldver>:charts/<chart>/values.yaml` and render
  both; a values key removed or renamed is a breaking change (see Traps).
- coredns unit tests (helm-unittest plugin, only chart with `tests/`): `helm unittest charts/coredns`
- Package exactly like CI (then delete the .tgz): `helm package charts/<name>`
- Pick the next version: `git tag -l '<chart>-*' | sort -V | tail -3` (tags are `<chart>-<version>`, created by
  chart-releaser).
- Secret scan (CI runs gitleaks on every push/PR): `gitleaks detect --source . --log-opts origin/main..HEAD`
- CI (`.github/workflows/`): `check-gitleaks.yml` (gitleaks on all pushes/PRs) and `release.yml` (push to `main`
  only: `helm/chart-releaser-action@v1.6.0` -> GitHub release + gh-pages, then `./push_tgz.sh` pushes each changed
  chart to `oci://<VCR_REPO>/vks-helm-charts` and `oci://<VCR_REPO_HAN>/vks-helm-charts`). CI does NOT run
  `helm lint`/`helm template` - lint locally before merging.

## Map
- `charts/` — one directory per chart; only this directory is released (chart-releaser default `charts_dir`).
- VKS-owned (edit freely, we are upstream):
  - `vngcloud-blockstorage-csi-driver` (CSI; most active chart, versions 1.x, appVersion = driver release),
    `vngcloud-snapshot-controller`, `vngcloud-controller-manager` + `vngcloud-ingress-controller` (released in lockstep,
    0.2.x), `vngcloud-cluster-autoscaler`, `vcontainer-storage-interface`, `etcd-manager`.
  - `vmonitor-metric-agent` — VKS chart that vendors `kube-state-metrics` as a local subchart (`file://charts/...`).
  - `calico` — VKS-authored chart around Calico manifests (own version line 1.1.x; appVersion = Calico v3.28.2).
- Vendored upstream (copied with `helm pull --untar`, see README; keep diffs minimal, mostly image -> vCR and
  tolerations): `cilium`, `coredns` (local patches use suffix `-vks.N`, e.g. `1.45.0-vks.1`), `tigera-operator`,
  `cert-manager` (vendored upstream v1.17.2), `vault`, Bitnami `postgresql`, `postgresql-ha`, `redis`
  (their `charts/common` subcharts are committed; `postgresql`/`postgresql-ha` have a `Chart.lock` pointing at Docker Hub
  OCI, `redis` uses `file://charts/common`).
- `external-secrets/` — vendored upstream chart at repo ROOT, not under `charts/`: never released by CI and not
  linted by the harness. Run `helm lint external-secrets` by hand if you touch it.
- `push_tgz.sh <oci-url> <comma-separated chart dirs>` — CI helper: `helm package` + `helm push` per changed chart.
- `charts/*/makefile` (calico, vngcloud-controller-manager, vngcloud-ingress-controller) — local render helpers;
  `build-test`/`install-test` targets push to a personal registry and install to a live cluster: do not run.
- Images default to `vcr.vngcloud.vn/81-vks-public/...`; keep new image refs on vCR, not public upstream registries.

## Sensitive paths (review carefully, cover with tests)
- `.github/workflows/release.yml`, `push_tgz.sh` — anything merged to `main` ships to both vCR regions immediately.
- `.github/workflows/check-gitleaks.yml` — the only CI gate; do not weaken it.
- `charts/*/Chart.yaml` `version`/`appVersion` — the release trigger and the public contract.
- `charts/vngcloud-blockstorage-csi-driver/templates/` (25 files) and `values.yaml` — CSI on every tenant cluster;
  RBAC (ClusterRoleBinding `roleRef` is immutable), node DaemonSet, Helm hooks.
- `charts/vngcloud-controller-manager/templates/`, `charts/vngcloud-ingress-controller/templates/`,
  `charts/vngcloud-snapshot-controller/templates/`, `charts/vngcloud-cluster-autoscaler/templates/`
- CNI / DNS on every cluster: `charts/calico/templates/` (incl. `kdd-crds.yaml`), `charts/cilium/templates/`
  (137 files), `charts/tigera-operator/` (`crds/`), `charts/coredns/` (`crds/`, `tests/`)
- `charts/etcd-manager/templates/`, `charts/vmonitor-metric-agent/`, `charts/cert-manager/templates/crds.yaml`
- Vendored data-store charts: `charts/postgresql*/`, `charts/redis/`, `charts/vault/`, `external-secrets/`
- Full list: `python3 tools/review_pkg.py` (in `vks-harness`).

## Traps
- Every chart change needs a `version` bump in `Chart.yaml`, and the new version must not already exist as a tag
  (`git tag -l '<chart>-<ver>'`). A version that already has a release is not re-published: calico/cilium/coredns were
  "reverted" to older version numbers (Dec 2025) that already had tags, so main's `calico` 1.1.7 differs from the
  published `calico-1.1.7`. To roll back, re-release old content under a NEW, higher version.
- Removing or renaming a values key is a breaking change: bump minor (or major), not patch. The CSI chart went
  1.1.7 -> 1.2.0 (not 1.1.8) because `node.reservedVolumeAttachments` was removed (it rendered a flag the driver
  rejects -> CrashLooping DaemonSet).
- Never render a CLI flag the binary may not have at that `appVersion`; check the driver's flags for the pinned
  image tag before adding a values key that becomes an arg.
- ClusterRoleBinding `roleRef` is immutable: renaming a ClusterRole breaks `helm upgrade` ("cannot change roleRef").
  A pre-upgrade hook that deleted CRBs was added in 1.1.4 and dropped in 1.1.8; hooks run with their own image,
  tolerations and RBAC and add their own failure modes. Avoid renaming RBAC objects instead.
- Commit subjects are not reliable: `920eb6e` says "chart 1.2.1" but bumps 1.2.1 -> 1.2.2 / appVersion 1.5.2.
  Read `Chart.yaml` and `git tag`, not the log.
- Vendored charts: re-pull from upstream rather than hand-editing templates; keep local edits to values (images,
  tolerations) and mark patched releases with `-vks.N`. Do not run `helm dependency update` for Bitnami charts
  (network + rewrites committed subcharts).
- Toleration edits for CNI/DNS (envoy, calico, coredns) took several follow-up commits in Dec 2025; render with
  `helm template` and check every DaemonSet/Deployment for both `NoSchedule` and `NoExecute` effects.
- `make template` in calico / controller-manager writes `charts/<name>/helm/` output and a `.tgz`; `*.tgz` is
  ignored but `helm/` is not - do not commit it.
- Feature work goes on a branch + PR to `main` (`dev` branch exists but is not used by CI); merging = release.
