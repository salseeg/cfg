-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  -- import/override with your plugins folder
  { import = "astrocommunity.colorscheme.dracula-nvim" },
  { import = "astrocommunity.completion.codeium-vim" },
  { import = "astrocommunity.pack.elixir-phoenix" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.motion.before-nvim" },
  { import = "astrocommunity.git.diffview-nvim" },
  { import = "astrocommunity.git.gitgraph-nvim" },
  { import = "astrocommunity.git.neogit" },
  { import = "astrocommunity.scrolling.satellite-nvim" },
}

