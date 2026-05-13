-- lua/plugins.lua

-- Load packer and declare plugins.
vim.cmd("packadd packer.nvim")
require("packer").startup(function(use)
    use("wbthomason/packer.nvim")

    -- Telescope core + native sorter.
    use({
        "nvim-telescope/telescope.nvim",
        tag = "*",
        requires = { { "nvim-lua/plenary.nvim" } },
        module = "telescope",
        cmd = "Telescope",
    })
    use({
        "nvim-telescope/telescope-fzf-native.nvim",
        run = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install",
        after = "telescope.nvim",
    })

    -- Optional file tree plugin (kept disabled).
    -- use({ "nvim-tree/nvim-tree.lua" })
end)

-- Telescope ignore patterns.
local dotdir_ignore = {
    "^%.[^/\\]+[/\\]",
    "[/\\]%.[^/\\]+[/\\]",
}

-- Lazy Telescope state.
local telescope_builtin = nil
local telescope_ready = false

-- Resolve selected entry to stable absolute path.
local function entry_abs_path(entry)
    local p = entry.path or entry.filename or entry.value
    if type(p) == "table" then
        p = p[1]
    end
    if not p then
        return nil
    end
    p = tostring(p)
    return vim.loop.fs_realpath(p) or vim.fn.fnamemodify(p, ":p")
end

-- One-time Telescope setup, called by keymaps.
local function setup_telescope_once()
    if telescope_ready then
        return
    end

    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local function open_with(cmd)
        return function(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)

            local p = entry_abs_path(entry)
            if not p or p == "" then
                return
            end

            vim.cmd(cmd .. " " .. vim.fn.fnameescape(p))
        end
    end

    require("telescope").setup({
        defaults = {
            mappings = {
                i = {
                    ["<CR>"] = open_with("edit"),
                    ["<C-v>"] = open_with("vsplit"),
                    ["<C-b>"] = open_with("split"),
                    ["<C-t>"] = open_with("tabedit"),
                },
                n = {
                    ["<CR>"] = open_with("edit"),
                    ["<C-v>"] = open_with("vsplit"),
                    ["<C-b>"] = open_with("split"),
                    ["<C-t>"] = open_with("tabedit"),
                },
            },
        },
        pickers = {
            find_files = { previewer = false },
            git_files = { previewer = false },
        },
    })

    telescope_builtin = require("telescope.builtin")
    telescope_ready = true
end

-- Project-aware file finder: git first, fallback to plain files.
local function find_project_files()
    setup_telescope_once()
    local ok = pcall(telescope_builtin.git_files, {
        show_untracked = true,
        file_ignore_patterns = dotdir_ignore,
    })
    if not ok then
        telescope_builtin.find_files({ file_ignore_patterns = dotdir_ignore })
    end
end

-- Telescope keymaps
vim.keymap.set("n", "<leader>g", find_project_files)
vim.keymap.set("n", "<C-p>", function()
    setup_telescope_once()
    telescope_builtin.find_files({
        hidden = true,
        no_ignore = true,
        no_ignore_parent = true,
    })
end)
vim.keymap.set("n", "<C-s>", function()
    setup_telescope_once()
    telescope_builtin.live_grep()
end)

-- Optional nvim-tree notes:
-- 1. Enable plugin declaration above.
-- 2. Configure nvim-tree here.
-- 3. Bind a tree toggle keymap if desired.
