return {
  "neovim-idea/switcher-nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("switcher-nvim").setup({
      --[[General]]
      traverse_forwards = {
        mode = { "n" },
        -- keymap = "<leader>sw", -- leader + sw (switcher forward)
        keymap = "<C-Tab>", -- leader + sw (switcher forward)
        opts = { noremap = true, desc = "Switcher: Traverse buffers forward (most recent first)" },
      },
      traverse_backwards = {
        mode = { "n" },
        -- keymap = "<leader>sW", -- leader + sW (switcher backward)
        keymap = "<C-S-Tab>", -- leader + sW (switcher backward)
        opts = { noremap = true, desc = "Switcher: Traverse buffers backward (oldest first)" },
      },
      --[[Selection]]
      selection = {
        timeout_ms = 500,
        icon_margin_left = "", -- or "[", "<<<" ... any string, really :)
        icon_margin_right = "", -- or "]", ">>>" ...
        chevron = "󰅂", -- or "󰅂" , "󱞩", "-->" ...
      },
      --[[Borders]]
      borders = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }, -- or { "═", "║", "═", "║", "╔", "╗", "╝", "╚" }
    })

    -- Set up highlights for better visibility
    vim.api.nvim_set_hl(0, "NeovimIdeaSwitcherNormal", { bg = "#2d2d2d", fg = "#d4d4d4" })
    vim.api.nvim_set_hl(0, "NeovimIdeaSwitcherNormalNC", { bg = "#2d2d2d", fg = "#d4d4d4" })
    vim.api.nvim_set_hl(0, "NeovimIdeaSwitcherFloatBorder", { fg = "#61afef", bold = true })
    vim.api.nvim_set_hl(0, "NeovimIdeaSwitcherCursorLine", { bg = "#4d4d4d", fg = "#ffffff", bold = true })
    vim.api.nvim_set_hl(0, "NeovimIdeaSwitcherActiveSelection", { fg = "#98c379", bold = true })
    vim.api.nvim_set_hl(0, "NeovimIdeaSwitcherInactiveSelection", { fg = "#5c6370" })
  end,
}
