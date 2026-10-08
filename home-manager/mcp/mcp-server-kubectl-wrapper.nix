{ pkgs, ... }:

pkgs.writeShellScriptBin "mcp-server-kubectl-wrapper" ''
  exec ${pkgs.gotha.kubectl-mcp-server}/bin/kubectl-mcp-server "$@"
''
