-- lua/plugins.lua

-- Plugin management is opt-in; normal editing does not require packer.
local function plugin_spec(use)
    use("wbthomason/packer.nvim")

    -- Telescope core + native sorter.
    use({
        "nvim-telescope/telescope.nvim",
        tag = "*",
        opt = true,
        requires = { { "nvim-lua/plenary.nvim", opt = true } },
        module = "telescope",
        cmd = "Telescope",
    })
    use({
        "nvim-telescope/telescope-fzf-native.nvim",
        opt = true,
        run = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install",
        after = "telescope.nvim",
    })

    -- Optional file tree plugin (kept disabled).
    -- use({ "nvim-tree/nvim-tree.lua" })
end

local packer_loaded = false
local function load_packer()
    vim.cmd("packadd packer.nvim")

    local packer = require("packer")
    if not packer_loaded then
        packer.startup({
            plugin_spec,
            config = {
                compile_path = vim.fn.stdpath("cache") .. "/packer_compiled.lua",
                compile_on_sync = false,
                auto_reload_compiled = false,
                disable_commands = true,
            },
        })
        packer_loaded = true
    end

    return packer
end

local unpack_args = table.unpack or unpack
local function packer_command(method)
    return function(opts)
        local packer = load_packer()
        packer[method](unpack_args(opts.fargs))
    end
end

vim.api.nvim_create_user_command("PackerInstall", packer_command("install"), { nargs = "*" })
vim.api.nvim_create_user_command("PackerUpdate", packer_command("update"), { nargs = "*" })
vim.api.nvim_create_user_command("PackerSync", packer_command("sync"), { nargs = "*" })
vim.api.nvim_create_user_command("PackerClean", function()
    load_packer().clean()
end, {})
vim.api.nvim_create_user_command("PackerCompile", function()
    load_packer().compile()
end, {})

-- Telescope ignore patterns.
local dotdir_ignore = {
    "^%.[^/\\]+[/\\]",
    "[/\\]%.[^/\\]+[/\\]",
}

-- Lazy Telescope state.
local telescope_builtin = nil
local telescope_packadd_done = false
local telescope_ready = false

local function load_telescope_packages()
    if telescope_packadd_done then
        return true
    end

    for _, name in ipairs({ "plenary.nvim", "telescope.nvim", "telescope-fzf-native.nvim" }) do
        local ok, err = pcall(vim.cmd.packadd, name)
        if not ok then
            vim.notify(("Could not load Telescope package '%s': %s"):format(name, err), vim.log.levels.WARN)
            return false
        end
    end

    telescope_packadd_done = true
    return true
end

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
        return true
    end
    if not load_telescope_packages() then
        return false
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
    pcall(require("telescope").load_extension, "fzf")

    telescope_builtin = require("telescope.builtin")
    telescope_ready = true
    return true
end

-- Project-aware file finder: git first, fallback to plain files.
local function find_project_files()
    if not setup_telescope_once() then
        return
    end
    local ok = pcall(telescope_builtin.git_files, {
        show_untracked = true,
        file_ignore_patterns = dotdir_ignore,
    })
    if not ok then
        telescope_builtin.find_files({ file_ignore_patterns = dotdir_ignore })
    end
end

-- Telescope keymaps
vim.keymap.set("n", "<C-p>", find_project_files)
vim.keymap.set("n", "<C-g>", function()
    if not setup_telescope_once() then
        return
    end
    telescope_builtin.find_files({
        hidden = true,
        no_ignore = true,
        no_ignore_parent = true,
    })
end)
vim.keymap.set("n", "<C-s>", function()
    if not setup_telescope_once() then
        return
    end
    telescope_builtin.live_grep()
end)

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        vim.defer_fn(setup_telescope_once, 300)
    end,
})

-- Optional nvim-tree notes:
-- 1. Enable plugin declaration above.
-- 2. Configure nvim-tree here.
-- 3. Bind a tree toggle keymap if desired.
