local conform = require("conform")

conform.setup({
  -- Run these formatters per filetype (order matters)
  formatters_by_ft = {
    lua = { "stylua" },

    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    javascript = { "prettier" },
    json = { "prettier" },

    rust = { "rustfmt" },
    c = { "clang-format" },
    go = { "gofumpt" },

    graphql = { "prettier_graphql" }, -- custom below

    python = { "autopep8" },

    php = { "php-cs-fixer" },
    twig = { "djlint" },
    nix = { "nixfmt" },
    kotlin = { "ktlint" },

    -- apply to all filetypes in addition to the above
    ["*"] = { "trim_whitespace" },
  },

  -- Formatter customizations / conditions
  formatters = {
    -- skip formatting for a specific file
    stylua = {
      condition = function(ctx)
        return vim.fn.fnamemodify(ctx.filename, ":t") ~= "special.lua"
      end,
      -- mimic your explicit args
      prepend_args = { "--search-parent-directories" },
    },

    -- add --single-quote everywhere you use prettier
    prettier = {
      prepend_args = { "--single-quote" },
    },

    -- graphql needed some dynamic args in your setup
    prettier_graphql = {
      command = "prettier",
      args = function(ctx)
        local width = vim.bo[ctx.buf].textwidth
        local args = { "--config-precedence", "prefer-file" }
        if width and width > 0 then
          vim.list_extend(args, { "--print-width", tostring(width) })
        end
        vim.list_extend(args, { "--stdin-filepath", ctx.filename })
        return args
      end,
    },

    ["clang-format"] = {
      -- ensure style detection uses the current filename
      args = { "-assume-filename", "$FILENAME" },
    },

    ["php-cs-fixer"] = {
      stdin = false, -- php-cs-fixer edits files directly
      args = { "fix", "--rules=@Symfony", "--using-cache=no", "--no-interaction", "$FILENAME" },
    },

    djlint = {
      stdin = false,
      args = { "--quiet", "--reformat", "$FILENAME" },
      -- treat common non-zero as non-fatal (mirrors ignore_exitcode)
      exit_codes = { 0, 1 },
    },

    nixfmt = {
      stdin = false,
    },

    ktlint = {
      prepend_args = { "-F", "--stdin", "--log-level", "error" },
    },
  },

  -- If you prefer LSP fallback when no external formatter is available:
  format_on_save = {
    timeout_ms = 2000,
    lsp_fallback = true
  },
})

-- Format on save (pre-write)
local grp = vim.api.nvim_create_augroup("ConformFormatOnSave", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = grp,
  pattern = {
    "*.js","*.jsx","*.ts","*.tsx","*.rs","*.lua","*.c","*.go",
    "*.graphql","*.gql","*.py","*.php","*.twig","*.nix","*.kt","*.json",
  },
  callback = function(args)
    require("conform").format({
      bufnr = args.buf,
      lsp_fallback = true, -- set to true if you want LSP formatting when no tool is set
      timeout_ms = 3000,
    })
  end,
})

