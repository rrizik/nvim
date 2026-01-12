-- lua/plugins.lua

-- Packer (plugin loading) cmd: PackerSync
vim.cmd [[packadd packer.nvim]]
require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install' }
  use { 'nvim-telescope/telescope.nvim', tag = '*', requires = { { 'nvim-lua/plenary.nvim' } } }
  use 'nvim-tree/nvim-tree.lua'
  use 'nvim-tree/nvim-web-devicons'
end)

--- Telescope ---
local actions = require("telescope.actions")
require("telescope").setup({
  defaults = {
    mappings = {
      i = {
        ["<C-b>"] = actions.select_horizontal,
        ["<C-x>"] = false, -- optional: remove default
      },
      n = {
        ["<C-b>"] = actions.select_horizontal,
        ["<C-x>"] = false, -- optional: remove default
      },
    },
  },
})

local tele = require('telescope.builtin')
vim.keymap.set('n', '<C-p>', tele.find_files)
vim.keymap.set('n', '<C-s>', tele.live_grep)
--- End ---

--- NVim Tree ---
require("nvim-tree").setup({
    filters = { dotfiles = false, custom = {} },
    filesystem_watchers = { enable = true },
    git = { ignore = false },

    view = {
        float = {
            enable = true,
            quit_on_focus_loss = true,
            open_win_config = function()
                local columns = vim.opt.columns:get()
                local lines = vim.opt.lines:get() - vim.opt.cmdheight:get()

                local w = math.floor(columns * 0.25)
                local h = math.floor(lines * 0.80)

                return {
                    border = "rounded",
                    relative = "editor",
                    width = w,
                    height = h,
                    row = math.floor((lines - h) * 0.5),
                    col = math.floor((columns - w) * 0.5),
                }
            end,
        },
    },

    renderer = {
        icons = {
            show = { file = false, folder = false, folder_arrow = false, git = false },
        },
    },
    actions = {
        open_file = {
            window_picker = {
                enable = false,
            },
        },
    },

    on_attach = function(bufnr)
        local api = require("nvim-tree.api")

        api.config.mappings.default_on_attach(bufnr)

        -- Cursorline only while focused in the tree; restore when leaving
        local function set_tree_cursorline()
            if vim.w._tree_prev_cursorline == nil then
                vim.w._tree_prev_cursorline = vim.wo.cursorline
                vim.w._tree_prev_cursorlineopt = vim.wo.cursorlineopt
            end

            vim.wo.cursorline = true
            vim.wo.cursorlineopt = "line"
        end

        local function restore_tree_cursorline()
            if vim.w._tree_prev_cursorline ~= nil then
                vim.wo.cursorline = vim.w._tree_prev_cursorline
                vim.w._tree_prev_cursorline = nil
            end
            if vim.w._tree_prev_cursorlineopt ~= nil then
                vim.wo.cursorlineopt = vim.w._tree_prev_cursorlineopt
                vim.w._tree_prev_cursorlineopt = nil
            end
        end

        set_tree_cursorline()
        vim.api.nvim_create_autocmd("BufEnter", { buffer = bufnr, callback = set_tree_cursorline })
        vim.api.nvim_create_autocmd("BufLeave", { buffer = bufnr, callback = restore_tree_cursorline })

        local function o(desc)
            return { buffer = bufnr, silent = true, noremap = true, nowait = true, desc = desc }
        end

        vim.keymap.set("n", "l", function()
            local node = api.tree.get_node_under_cursor()
            if node and node.type == "directory" then
                api.node.open.edit()
            end
        end, o("Expand dir"))

        vim.keymap.set("n", "<CR>", function()
            local node = api.tree.get_node_under_cursor()
            if node and node.type == "directory" then
                api.tree.change_root_to_node(node)
            else
                api.node.open.edit()
            end
        end, o("Enter dir / open file"))

        vim.keymap.set({ "n", "v" }, "<Tab>", "<cmd>NvimTreeToggle<CR>", o("Toggle tree"))

        -- (Your existing split/tab mappings unchanged below)
        vim.keymap.set("n", "<C-v>", function()
            local node = api.tree.get_node_under_cursor()
            if node and node.type == "directory" then
                api.node.open.edit()
                return
            end
            api.node.open.vertical()
            api.tree.focus()
        end, o("Open vertical (keep focus)"))

        vim.keymap.set("n", "<C-b>", function()
            local node = api.tree.get_node_under_cursor()
            if node and node.type == "directory" then
                api.node.open.edit()
                return
            end
            api.node.open.horizontal()
            api.tree.focus()
        end, o("Open horizontal (keep focus)"))

        vim.keymap.set("n", "<C-t>", function()
            local node = api.tree.get_node_under_cursor()
            if not node then return end
            if node.type == "directory" then
                api.node.open.edit()
                return
            end

            local curtab = vim.api.nvim_get_current_tabpage()
            api.node.open.tab()
            vim.api.nvim_set_current_tabpage(curtab)
            api.tree.focus()
        end, o("Open tab (keep focus)"))

        vim.keymap.set("n", "u", api.tree.change_root_to_parent, o("Up dir"))
        vim.keymap.set("n", "h", api.node.navigate.parent_close, o("Close dir"))
    end,
})
--- End ---

-- global tree toggle
vim.keymap.set({"n", "v"}, "<Tab>", "<cmd>NvimTreeToggle<CR>",  { silent = true, noremap = true, nowait = true })
--- End --- 
