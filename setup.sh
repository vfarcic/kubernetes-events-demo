#!/bin/sh
set -e

gum style \
	--foreground 212 --border-foreground 212 --border double \
	--margin "1 2" --padding "2 4" \
	'Setup for the demo'

gum confirm '
Are you ready to start?
Select "Yes" only if you did NOT follow the story from the start (if you jumped straight into this chapter).
Feel free to say "No" and inspect the script if you prefer setting up resources manually.
' || exit 0

echo "
## You will need following tools installed:
|Name            |Required             |More info                                          |
|----------------|---------------------|---------------------------------------------------|
|Linux Shell     |Yes                  |Use WSL if you are running Windows                 |
|Docker          |Yes                  |'https://docs.docker.com/engine/install'           |
|kind CLI        |Yes                  |'https://kind.sigs.k8s.io/docs/user/quick-start/#installation'|
|kubectl CLI     |Yes                  |'https://kubernetes.io/docs/tasks/tools/#kubectl'  |
|helm CLI        |Yes                  |'https://helm.sh/docs/intro/install/'              |
|crossplane CLI  |Yes                  |'https://docs.crossplane.io/latest/cli'            |

If you are running this script from **Nix shell**, most of the requirements are already set with the exception of **Docker**.
" | gum format

gum confirm "
Do you have those tools installed?
" || exit 0

rm -f .env

###########
# Cluster #
###########

kind create cluster

kubectl create namespace a-team

kubectl --namespace a-team apply --filename app.yaml

helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

kubectl apply --filename providers

gum spin --spinner dot \
    --title "Waiting for Crossplane providers..." -- sleep 60

kubectl wait --for=condition=healthy provider.pkg.crossplane.io \
    --all --timeout=600s
