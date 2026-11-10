{ pkgs, lib, config, inputs, ... }:

let
  erlang = pkgs.beam.packages.erlang_28;
  elixir = erlang.elixir_1_19;
  expert = erlang.expert;
  postgres = pkgs.postgresql_18;
in
{
  packages = [ pkgs.biome pkgs.flyctl pkgs.beads ];

  languages = {
    nix.enable = true;

    elixir = {
      enable = true;
      package = elixir;
      lsp = {
        enable = true;
        package = expert;
      };
    };

    javascript = {
      enable = true;

      npm = {
        enable = true;
      };
    };
  };

  services = {
    postgres = {
      enable = true;
      package = postgres;
      createDatabase = false;
      initialScript = "create user postgres superuser password 'postgres'";
    };
  };
}
