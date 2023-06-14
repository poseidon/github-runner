# github-runner
[![GoDoc](https://pkg.go.dev/badge/github.com/poseidon/github-runner.svg)](https://pkg.go.dev/github.com/poseidon/github-runner)
[![Quay](https://img.shields.io/badge/container-quay-green)](https://quay.io/repository/poseidon/github-runner)
[![Workflow](https://github.com/poseidon/github-runner/actions/workflows/build.yaml/badge.svg)](https://github.com/poseidon/github-runner/actions/workflows/build.yaml?query=branch%3Amain)
[![Sponsors](https://img.shields.io/github/sponsors/poseidon?logo=github)](https://github.com/sponsors/poseidon)
[![Mastodon](https://img.shields.io/badge/follow-news-6364ff?logo=mastodon)](https://fosstodon.org/@poseidon)

`github-runner` provides the GitHub Actions [self-hosted](https://docs.github.com/en/actions/hosting-your-own-runners) [runner](https://github.com/actions/runner) as a container image that registers itself with GitHub.

## Features

* Minimalist, runners register themselves (no controller, no CRDs)
* Acts as a GitHub App to generate registration tokens
* Add [org-level](https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners#adding-a-self-hosted-runner-to-an-organization) runners
* Use `github-runner` as a base image to customize
  * Install languages needed for GitHub Workflows
  * Add tools needed for GitHub Workflows
* Deregisters runner when the container/pod exits

## Background

GitHub [self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners) allow you to run GitHub Actions Workflows in environments you manage on your own infrastructure.

`github-runner` packages the GitHub [runner](https://github.com/actions/runner) along with a tool to fetch a runner registration token dynamically on container start by acting as a GitHub App. On Kubernetes, you can create a ``Deployment of `github-runner` (or descendant image) Pods, watch them register and run jobs. A runner Pod can run one job ("ephemeral") or be long-lived.

*Note: GitHub personal access tokens can also fetch runner registration tokens, but at most organizations, using a personal token or a robot user isn't an option.*

## Usage

Create a GitHub App for your account or organization. Use the links below to pre-fill fields where possible. Be sure to choose a unique app name (e.g. org-name/github-runner).

* [GitHub App for your account](https://github.com/settings/apps/new?url=http://github.com/poseidon/github-runner&webhook_active=false&public=false&organization_self_hosted_runners=write)
* [GitHub App for your Organization](https://github.com/organizations/:org/settings/apps/new?url=http://github.com/poseidon/github-runner&webhook_active=false&public=false&organization_self_hosted_runners=write)

Organization Permissions:

* Self-hosted runners (read/write)

Note the **App ID**.

<img src="https://storage.googleapis.com/poseidon/github-app-id.png">

Next, generate a **private key**.

<img src="https://storage.googleapis.com/poseidon/github-generate-key.png">

Finally, install your private GitHub App into your user or organization.

<img src="https://storage.googleapis.com/poseidon/github-app-install.png">

Note the **Install ID** found at the end of the URL.

* https://github.com/settings/installations/INSTALL_ID
* https://github.com/organizations/ORG/settings/installations/INSTALL_ID

Create a Kubernetes Deployment (or similar definition) to run the [`quay.io/poseidon/github-runner`](https://quay.io/repository/poseidon/github-runner?tab=tags) (or derivative) container image with the following required environment variables (see [configuration](#configuration)):

* `GH_APP_ID`
* `GH_APP_KEY_PATH`
* `GH_INSTALL_ID`
* `GH_ORG`

Typically `GH_APP_KEY_PATH` would be a path to a mounted Kubernetes Secret.

Finally, check that the runner(s) registered as [Org Runners](https://github.com/organizations/ORG/settings/actions/runners) with GitHub.

### Configuration

Configure github-runner to act as a GitHub App to obtain a self-hosted runner registration token.

| env variable    | description |
|-----------------|---------------|
| GH_APP_ID       | GitHub App ID |
| GH_APP_KEY_PATH | Path to GitHub App key .pem |
| GH_INSTALL_ID   | GitHub Installation ID |
| GH_ORG          | GitHub organization name |
| GROUP  | Runner group defaults to default |
| LABELS | Labels in addition to default: 'self-hosted,Linux,X64' |
| EPHEMERAL | Unregister a runner after a job |

## Tradeoffs

`github-runner` is minimalist and low maintenance.

* Runners registers themselves to GitHub (no controllers, CRDs, etc.)
* Manage runners using ordinary Kubernetes manifests
* Scale by scaling replicas (e.g. Kubernetes Deployment)
* Customize by using `github-runner` as a base image (e.g. `FROM`)

More complex needs may be handled by more complex [projects](https://github.com/actions-runner-controller/actions-runner-controller) (out of scope):

* Auto-scaling in runners
* Ephemeral runners

## Security

GitHub recommends [self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners#self-hosted-runner-security) should only be used with private repositories at your own organization, since they run code inside your infrastructure. Additionally, `github-runner` allows runners to conveniently register themselves by acting as a GitHub App, meaning it may be possible for a workload to obtain the same GitHub App permissions (which allow managing self-hosted workers). Compared to other automation platforms, GitHub runners are pretty reasonable.
