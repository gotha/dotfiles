{ pkgs, ... }:

# Wrapper for kubectl-mcp-server that filters stdout to only emit valid
# NDJSON-RPC lines. Upstream (rohitg00/kubectl-mcp-tool v1.2.0) leaks Python
# `logging` INFO output onto stdout, which corrupts the MCP stdio protocol
# and breaks strict clients such as Crush ("invalid trailing data at the end
# of stream"). JSON-RPC messages are JSON objects, so any line that does not
# begin with `{` is a stray log line and is dropped.
pkgs.writeShellScriptBin "mcp-server-kubectl-wrapper" ''
  exec ${pkgs.kubectl-mcp-server}/bin/kubectl-mcp-server "$@" \
    | ${pkgs.gnugrep}/bin/grep --line-buffered -E '^\{'
''
