{ pkgs, lib, config, inputs, ... }:

let
  erlang = pkgs.beam.packages.erlang_28;
  elixir = erlang.elixir_1_19;
  expert = erlang.expert;
  postgres = pkgs.postgresql_18;
in
{
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
