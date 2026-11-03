# Infrastructure as Code Learning Project

This project contains practical Infrastructure as Code (IaC) examples and command references for provisioning AWS infrastructure with Terraform and operating Kubernetes clusters with `kubectl`.

## Guides

- [Terraform AWS Commands Guide](tf/README.md) — A basic to advanced Terraform reference focused on AWS and LocalStack. It covers setup, plans and applies, state, VPC and EKS operations, imports, remote backends, IAM, testing, and safe cleanup.
- [Kubernetes Commands Guide](k8s/README.md) — A basic to advanced `kubectl` reference covering cluster administration, workloads, networking, storage, security, debugging, Helm, and common operational scenarios.

## Project Structure

```text
.
├── alias/      # Shell aliases for Docker, kubectl, and Terraform
├── k8s/        # Kubernetes command guide
├── tf/         # Terraform AWS/LocalStack examples and command guide
├── main.go     # Small Go web server
├── Dockerfile  # Container image definition for the web server
└── .github/    # GitHub Actions workflow
```

## Shell Aliases

The [`alias/`](alias/) directory provides optional command shortcuts. Source the files in your shell session from the project root:

```bash
# Docker aliases: d, dr, dps, dl, and more
source alias/alias-docker

# kubectl aliases: k, kgp, ka, kl, and more
source alias/alias-kubectl

# Terraform aliases: tf, tfi, tfp, tfa, tfd, and more
source alias/alias-terraform
```

Add the same `source` commands to your shell configuration file, such as `~/.zshrc`, if you want the aliases to be available in every new terminal. Review aliases before loading them because they change how commands are interpreted in your shell.

## Small Web Server and GitHub Actions

[`main.go`](main.go) implements a small Go HTTP web server that responds on port `80` with the container hostname. [`Dockerfile`](Dockerfile) builds a lightweight container image for that server.

The [Docker publish workflow](.github/workflows/docker-publish.yml) runs when changes are pushed to `main` or when started manually. It:

1. Builds the small web server image for Linux AMD64.
2. Authenticates to Docker Hub using the `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` repository secrets.
3. Publishes `${DOCKERHUB_USERNAME}/small-web-container` with both the `latest` tag and the Git commit SHA tag.

After the image is published, run it on a host or deploy it with the Kubernetes manifests in [`k8s/`](k8s/) to create a running web server.

## Getting Started

Choose the guide that matches the platform you want to work with:

```bash
# Terraform and AWS/LocalStack
cd tf

# Kubernetes and kubectl
cd k8s
```

Review the safety notes in each guide before creating or destroying cloud resources.
