{ lib, config, pkgs, ... }:
let cfg = config.services.gostart;
in {
  options = with lib; {
    services.gostart = {
      enable = lib.mkEnableOption "Enable gostart";

      port = mkOption {
        type = types.int;
        default = 3000;
        description = ''
          Port to listen on
        '';
      };

      user = mkOption {
        type = with types; oneOf [ str int ];
        default = "gostart";
        description = ''
          The user the service will use.
        '';
      };

      group = mkOption {
        type = with types; oneOf [ str int ];
        default = "gostart";
        description = ''
          The group the service will use.
        '';
      };

      keyPath = mkOption {
        type = types.path;
        default = "";
        description = ''
          Path to the GitHub API key file
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/gostart";
        description = "Path gostart will use to store the sqlite database";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.gostart;
        defaultText = literalExpression "pkgs.gostart";
        description = "The package to use for gostart";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    users.groups.${cfg.group} = { };
    users.users.${cfg.user} = {
      description = "gostart service user";
      isSystemUser = true;
      home = "${cfg.dataDir}";
      createHome = true;
      group = "${cfg.group}";
    };

    systemd.services.gostart = {
      enable = true;
      description = "gostart server";
      wantedBy = [ "network-online.target" ];
      after = [ "network-online.target" ];

      environment = { HOME = "${cfg.dataDir}"; };

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;

        ExecStart =
          "${cfg.package}/bin/gostart -auth ${cfg.keyPath} -db ${cfg.dataDir}/gostart.db";
      };
    };
  };
}
