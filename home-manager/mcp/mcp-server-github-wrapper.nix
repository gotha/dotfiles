{ pkgs, config, ... }:

pkgs.writeShellScriptBin "mcp-server-github-wrapper" ''
  # Read the GitHub Personal Access Token from sops secret
  export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat ${config.sops.secrets.mcp_server_github_pac.path})"
  
  # Execute the actual mcp-server-github with all passed arguments
  exec ${pkgs.mcp-server-github}/bin/mcp-server-github "$@"
''
