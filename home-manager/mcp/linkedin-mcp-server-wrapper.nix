{ pkgs, config, ... }:

pkgs.writeShellScriptBin "linkedin-mcp-server-wrapper" ''
  # Read the LinkedIn credentials from sops secrets
  export LINKEDIN_CLIENT_ID="$(cat ${config.sops.secrets.linkedin_client_id.path})"
  export LINKEDIN_CLIENT_SECRET="$(cat ${config.sops.secrets.linkedin_client_secret.path})"
  export LINKEDIN_ACCESS_TOKEN="$(cat ${config.sops.secrets.linkedin_access_token.path})"

  # Execute the actual linkedin-mcp-server with all passed arguments
  exec ${pkgs.linkedin-mcp-server}/bin/linkedin-mcp-server "$@"
''
