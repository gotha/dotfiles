{ pkgs, config, ... }:

pkgs.writeShellScriptBin "mcp-server-github-wrapper" ''
  # Read the GitHub Personal Access Token from sops secret (extract value after '=')
  export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat ${config.sops.secrets.mcp_server_github_pac.path} | cut -d'=' -f2)"

  # Execute the actual github-mcp-server with all passed arguments
  exec ${pkgs.github-mcp-server}/bin/github-mcp-server stdio "$@"
''
