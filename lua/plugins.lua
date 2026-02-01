-- lua/plugins.lua

-- Packer (plugin loading) cmd: PackerSync
vim.cmd [[packadd packer.nvim]]
require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'
    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install' }
    use { 'nvim-telescope/telescope.nvim', tag = '*', requires = { { 'nvim-lua/plenary.nvim' } } }
    -- use { 'nvim-tree/nvim-tree.lua' }
end)

--- Telescope ---
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function entry_abs_path(entry)
  -- Covers most telescope pickers
  local p = entry.path or entry.filename or entry.value
  if type(p) == "table" then p = p[1] end
  if not p then return nil end
  p = tostring(p)

  -- Canonicalize to a stable absolute path (identity)
  return vim.loop.fs_realpath(p) or vim.fn.fnamemodify(p, ":p")
end

local function open_with(cmd)
  return function(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    actions.close(prompt_bufnr)

    local p = entry_abs_path(entry)
    if not p or p == "" then return end

    -- Open using canonical absolute path
    vim.cmd(cmd .. " " .. vim.fn.fnameescape(p))
  end
end

require("telescope").setup({
    defaults = {
        mappings = {
            i = {
                ["<CR>"]  = open_with("edit"),
                ["<C-v>"] = open_with("vsplit"),
                ["<C-b>"] = open_with("split"),
                ["<C-t>"] = open_with("tabedit"),
            },
            n = {
                ["<CR>"]  = open_with("edit"),
                ["<C-v>"] = open_with("vsplit"),
                ["<C-b>"] = open_with("split"),
                ["<C-t>"] = open_with("tabedit"),
            },
        },
    },
    pickers = {
        find_files = { previewer = false },
        git_files = { previewer = false },
    }
})

local tele = require('telescope.builtin')
local DOTDIR_IGNORE = {
    "^%.[^/\\]+[/\\]",     -- leading dot dir
    "[/\\]%.[^/\\]+[/\\]", -- dot dir in path
}
local function find_project_files()
    local ok = pcall(tele.git_files, { show_untracked = true, file_ignore_patterns = DOTDIR_IGNORE })
    if not ok then
        tele.find_files({ file_ignore_patterns = DOTDIR_IGNORE })
    end
end
vim.keymap.set('n', '<C-p>', find_project_files)
-- vim.keymap.set('n', '<leader>g', tele.find_files)
vim.keymap.set('n', '<leader>g', function()
  tele.find_files({
    hidden = true,
    no_ignore = true,
    no_ignore_parent = true,
  })
end)
vim.keymap.set('n', '<C-s>', tele.live_grep)
--- End ---

--- NVim Tree ---
-- One function used both for initial open AND for resize updates
--local function tree_float_cfg()
--    local columns = vim.opt.columns:get() -- 240
--    local lines = vim.opt.lines:get() -- 56
--
--    local w = math.floor(columns * 0.25) -- 60
--    local h = math.floor(lines * 0.90) -- 50
--
--    return {
--        border = "rounded",
--        relative = "editor",
--        width = w,
--        height = h,
--        row = 1,
--        col = 4,
--    }
--end
--
--require("nvim-tree").setup({
--    filters = { dotfiles = false, custom = {} },
--    filesystem_watchers = { enable = true },
--    git = { enable = false },
--
--    view = {
--        float = {
--            enable = true,
--            quit_on_focus_loss = false,
--            open_win_config = tree_float_cfg,
--        },
--    },
--
--    renderer = {
--        icons = {
--            show = { file = false, folder = false, folder_arrow = false, git = false },
--        },
--    },
--    actions = {
--        open_file = {
--            window_picker = {
--                enable = false,
--            },
--        },
--    },
--
--    on_attach = function(bufnr)
--        local api = require("nvim-tree.api")
--        api.config.mappings.default_on_attach(bufnr)
--
--        -- Cursorline only inside the tree window
--        vim.opt_local.cursorlineopt = "line"
--
--        local function o(desc)
--            return { buffer = bufnr, silent = true, noremap = true, nowait = true, desc = desc }
--        end
--
--        local function with_tree_focus_loss_suppressed(fn)
--            tree_focus_loss_suppressed = true
--            local ok, err = pcall(fn)
--            vim.schedule(function()
--                tree_focus_loss_suppressed = false
--            end)
--            if not ok then
--                vim.notify(err, vim.log.levels.ERROR)
--            end
--        end
--
--        vim.keymap.set({ "n", "v" }, "<Tab>", "<cmd>NvimTreeToggle<CR>", o("Toggle tree"))
--
--        vim.keymap.set("n", "l", function()
--            local node = api.tree.get_node_under_cursor()
--            if node and node.type == "directory" then
--                api.node.open.edit()
--            end
--        end, o("Expand dir"))
--
--        vim.keymap.set("n", "<CR>", function()
--            local node = api.tree.get_node_under_cursor()
--            if node and node.type == "directory" then
--                api.tree.change_root_to_node(node)
--            else
--                api.node.open.edit()
--            end
--        end, o("Enter dir / open file"))
--
--        vim.keymap.set("n", "<C-v>", function()
--            local node = api.tree.get_node_under_cursor()
--            if node and node.type == "directory" then
--                api.node.open.edit()
--                return
--            end
--            with_tree_focus_loss_suppressed(function()
--                api.node.open.vertical(node, { focus = false })
--            end)
--        end, o("Open vertical (keep focus)"))
--
--        vim.keymap.set("n", "<C-b>", function()
--            local node = api.tree.get_node_under_cursor()
--            if node and node.type == "directory" then
--                api.node.open.edit()
--                return
--            end
--            with_tree_focus_loss_suppressed(function()
--                api.node.open.horizontal(node, { focus = false })
--            end)
--        end, o("Open horizontal (keep focus)"))
--
--        vim.keymap.set("n", "<C-t>", function()
--            local node = api.tree.get_node_under_cursor()
--            if not node then return end
--            if node.type == "directory" then
--                api.node.open.edit()
--                return
--            end
--            local path = node.absolute_path or node.name
--            vim.cmd("tabnew " .. vim.fn.fnameescape(path))
--            vim.schedule(function()
--                api.tree.find_file({ open = true, focus = true })
--            end)
--        end, o("Open tab (keep focus)"))
--
--        vim.keymap.set("n", "u", api.tree.change_root_to_parent, o("Up dir"))
--        vim.keymap.set("n", "h", api.node.navigate.parent_close, o("Close dir"))
--    end,
--})
--
--local focus_group = vim.api.nvim_create_augroup("UserNvimTreeFocusLoss", { clear = true })
--
--vim.api.nvim_create_autocmd("WinLeave", {
--    group = focus_group,
--    pattern = "NvimTree_*",
--    callback = function()
--        if tree_focus_loss_suppressed then
--            return
--        end
--        local view = require("nvim-tree.view")
--        if view.View.float and view.View.float.enable then
--            view.close()
--        end
--    end,
--})
--
---- Update the existing NvimTree float when the editor is resized
--vim.api.nvim_create_autocmd("VimResized", {
--    callback = function()
--        for _, win in ipairs(vim.api.nvim_list_wins()) do
--            local buf = vim.api.nvim_win_get_buf(win)
--            if vim.bo[buf].filetype == "NvimTree" then
--                local cfg = vim.api.nvim_win_get_config(win)
--                if cfg.relative ~= "" then -- only floats
--                    vim.api.nvim_win_set_config(win, tree_float_cfg())
--                end
--            end
--        end
--    end,
--})
--
---- vim.api.nvim_create_autocmd("BufEnter", {
--    --   pattern = "NvimTree_*",
--    --   callback = function()
--        --     vim.cmd("NvimTreeRefresh")
--        --   end,
--        -- })
--
--        -- global tree toggle
--        vim.keymap.set({"n", "v"}, "<Tab>", "<cmd>NvimTreeToggle<CR>",  { silent = true, noremap = true, nowait = true })
--        --- End --- 
