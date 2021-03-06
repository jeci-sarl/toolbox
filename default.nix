{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
}:

let

  pkgs = import nixpkgs {};

  terraform-provider-keycloak = pkgs.callPackage ./pkgs/terraform-provider-keycloak.nix
    { source = sources.terraform-provider-keycloak; };

  terraform-provider-concourse = pkgs.callPackage ./pkgs/terraform-provider-concourse
    { source = sources.terraform-provider-concourse; };

  terraform-provider-vault = pkgs.terraform-providers.vault.overrideAttrs (old: with sources.terraform-provider-vault; {
    inherit version;
    name = "${repo}-${version}";
    src = outPath;
    postBuild = "mv go/bin/${repo}{,_v${version}}";
  });

in {

  inherit (pkgs) ansible kubectl stern vault docker-compose cfssl
                 yq jq gopass kubectx aws direnv cue go gnupg curl;

  helm = pkgs.kubernetes-helm;

  terraform = pkgs.terraform_0_12.withPlugins (p: [
    terraform-provider-keycloak
    terraform-provider-concourse
    terraform-provider-vault
    p.aws p.openstack p.kubernetes
    p.local p.null p.random p.tls p.template
    p.flexibleengine
  ]);

  safe = pkgs.callPackage ./pkgs/safe.nix
    { source = sources.safe; };

  fly = pkgs.callPackage ./pkgs/fly.nix
    { source = sources.concourse; };

}
