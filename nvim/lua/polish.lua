-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here
if vim.g.neovide then
  vim.o.guifont = "Hurmit Nerd Font Mono:h12" -- text below applies for VimScript

  vim.g.neovide_cursor_trail_size = 0.3
  vim.g.neovide_cursor_vfx_mode = "railgun"

  vim.g.neovide_confirm_quit = true

  vim.g.neovide_remember_window_size = true

  -- codeium config
  -- vim.g.codeium_disable_bindings = 1
  -- vim.keymap.set('i', '<D-]>', "<Cmd>call codeium#CycleCompletions(1)<CR>")
  -- vim.keymap.set('i', '<D-[>', "<Cmd>call codeium#CycleCompletions(-1)<CR>")
  -- vim.keymap.set('i', '<D-CR>', function() return vim.fn['codeium#Accept']() end, { expr = true })
  -- vim.keymap.set('i', '<D-Bslash>', function() return vim.fn['codeium#Accept']() end, { expr = true })
  -- vim.keymap.set('i', '<D-BS>', "<Cmd>call codeium#Clear()<CR>")
  -- vim.keymap.set('i', '<D-Space>', "<Cmd>call codeium#Complete()<CR>")

  -- -- gh copilot config
  -- -- vim.g.copilot_filetypes = { ['*'] = false }
  -- vim.g.copilot_filetypes = { ["*"] = false, elixir = true, heex = true, markdown = true, javascript = true, lua = true }
  -- vim.g.copilot_no_tab_map = true
  -- vim.keymap.set('i', '<D-CR>', 'copilot#Accept("")', { expr = true, silent = true, replace_keycodes = false })

  -- -- correct lua keybindings to go to next and prev suggestions of copilot
  -- vim.keymap.set('i', '<D-]>', 'copilot#Next()', { expr = true, silent = true })
  -- vim.keymap.set('i', '<D-[>', 'copilot#Previous()', { expr = true, silent = true })
  -- vim.keymap.set('i', '<D-BS>', 'copilot#Dismiss()', { expr = true, silent = true })
  -- vim.keymap.set('i', '<D-Space>', 'copilot#Suggest()', { expr = true, silent = true })
end

vim.opt.foldenable = true
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 10

vim.opt.relativenumber = false

--
--
-- iabbr <?= <%=
-- iabbr <? <%
-- iabbr ?> %>
-- iabbr ?{ %{

-- " save
-- "inoremap <F2> <C-o>:up<CR>
-- inoremap <F2> <Esc>:w<CR>

-- " folding

-- inoremap <C-F3> <C-o>zO
-- inoremap <C-F4> <C-o>zC<Up><Down>

vim.keymap.set("n", "<F1>", ":w<cr>")
vim.keymap.set("n", "<F2>", ":w<cr>")
vim.keymap.set("n", "<F14>", ":noa w<cr>")
vim.keymap.set("n", "<F3>", "zo")
vim.keymap.set("n", "<C-F3>", "zO")
vim.keymap.set("n", "<F15>", "zR")
vim.keymap.set("n", "<F4>", "zc")
vim.keymap.set("n", "<F7>", ":Telescope grep_string<cr>")
vim.keymap.set("n", "<C-F4>", "zC")
vim.keymap.set("n", "<S-Tab>", ":b#<cr>")
vim.keymap.set("n", "\\\\", ":Telescope buffers<cr>")
vim.keymap.set("n", "<F10>", "<Space>gg")
vim.keymap.set("n", "<F9>", ":NvimTreeToggle<cr>")
-- lvim.keys.normal_mode["<F1>"] = ":w<cr>"
-- lvim.keys.normal_mode["<F2>"] = ":w<cr>"
-- lvim.keys.normal_mode["<F14>"] = ":noa w<cr>"
-- lvim.keys.normal_mode["<F3>"] = "zo"
-- lvim.keys.normal_mode["<C-F3>"] = "zO"
-- lvim.keys.normal_mode["<F15>"] = "zR"
-- lvim.keys.normal_mode["<F4>"] = "zc"
-- lvim.keys.normal_mode["<F7>"] = ":Telescope grep_string<cr>"
-- lvim.keys.normal_mode["<C-F4>"] = "zC"
-- -- lvim.keys.normal_mode["<F10>"] = ":bw<cr>"
-- lvim.keys.normal_mode["<S-Tab>"] = ":b#<cr>"
-- lvim.keys.normal_mode["\\\\"] = ":Telescope buffers<cr>"
-- lvim.keys.normal_mode["<F10>"] = ":LazyGit<cr>"
vim.keymap.set("n", "<F9>", ":NvimTreeToggle<cr>")
vim.keymap.set("n", "<F21>", ":NvimTreeFindFile<cr>")
vim.keymap.set("n", "<F13>", ":CodeiumChat<cr>")

vim.keymap.set("i", "<F1>", "<Esc>:w<CR>")
vim.keymap.set("i", "<F2>", "<Esc>:w<CR>")
vim.keymap.set("i", "<F3>", "<Esc>zo<Insert>")
vim.keymap.set("i", "<F4>", "<Esc>zc<Up><Insert><Down>")
vim.keymap.set("i", "<S-Tab>", "<Esc>:b#<cr>")

-- Set up custom filetypes
-- vim.filetype.add {
--   extension = {
--     foo = "fooscript",
--   },
--   filename = {
--     ["Foofile"] = "fooscript",
--   },
--   pattern = {
--     ["~/%.config/foo/.*"] = "fooscript",
--   },
-- }

vim.api.nvim_create_user_command('Windsurf', function()
  local file = vim.fn.expand('%:p')
  local line = vim.fn.line('.')
  local col = vim.fn.col('.')
  local goto_arg = file .. ':' .. line .. ':' .. col
  local cmd
  if vim.fn.has('mac') == 1 then
    cmd = { 'open', '-n', '-a', 'Windsurf', '--args', '--goto', goto_arg, '--reuse-window' }
  else
    cmd = { 'windsurf', '--goto', goto_arg, '--reuse-window' }
  end
  vim.fn.jobstart(cmd, { detach = true })
end, {})
