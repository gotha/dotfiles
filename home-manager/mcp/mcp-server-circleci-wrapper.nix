{ pkgs, config, ... }:

pkgs.writeShellScriptBin "mcp-server-circleci-wrapper" ''
  # Read the CircleCI API token from the sops secret (extract value after '=')
  export CIRCLECI_TOKEN="$(cat ${config.sops.secrets.mcp_server_circleci_token.path} | cut -d'=' -f2)"
  export CIRCLECI_BASE_URL="https://circleci.com"

  # Execute the CircleCI MCP server with all passed arguments
  exec ${pkgs.nodejs}/bin/npx -y @circleci/mcp-server-circleci@latest "$@"
''
