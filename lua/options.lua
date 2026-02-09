-- lua/options.lua

-- Basic startup globals.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.mapleader = " "

-- UI/bootstrap settings.
vim.opt.termguicolors = true
vim.opt.guifont = "Consolas:h11"
vim.cmd.syntax("on")
vim.cmd.colorscheme("custom")

-- Search behavior.
vim.opt.magic = false
vim.opt.incsearch = true
vim.opt.hlsearch = false
vim.opt.ignorecase = false

-- Editing/indent behavior.
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.shiftround = false
vim.opt.expandtab = true
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.cinoptions = "l1"

-- Window/navigation behavior.
vim.opt.scrolloff = 0
vim.opt.sidescrolloff = 4
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.wrap = true
vim.opt.linebreak = true

-- Misc editor behavior.
vim.opt.belloff = "all"
vim.opt.compatible = false
vim.opt.clipboard = "unnamedplus"
vim.opt.ruler = true
vim.opt.paste = false
vim.opt.number = false
vim.opt.mouse = "a"
vim.opt.list = false
vim.opt.guicursor = "a:blinkon0"
vim.opt.foldcolumn = "0"
vim.opt.title = true
vim.opt.titlestring = "%t"

-- Custom tabline (file name for each tab).
local function tab_line()
    local s = ""
    for t = 1, vim.fn.tabpagenr("$") do
        local b = vim.fn.tabpagebuflist(t)[vim.fn.tabpagewinnr(t)]
        local n = vim.fn.fnamemodify(vim.fn.bufname(b), ":t")
        if n == "" then
            n = "[No Name]"
        end
        s = s
            .. ((t == vim.fn.tabpagenr()) and "%#TabLineSel#" or "%#TabLine#")
            .. " %"
            .. t
            .. "T "
            .. n
            .. " %T"
    end
    return s .. "%#TabLineFill#%="
end
_G.TabLine = tab_line
vim.o.tabline = "%!v:lua.TabLine()"

-- Build command and quickfix error parser.
vim.opt.makeprg = [[cmd.exe /c misc\build.bat]]
vim.opt.errorformat = table.concat({
    -- clang/gcc style.
    [[%f:%l:%c:\ %trror:\ %m]],
    [[%f:%l:%c:\ %tarning:\ %m]],
    [[%f:%l:%c:\ %tote:\ %m]],
    [[%f:%l:\ %trror:\ %m]],
    [[%f:%l:\ %tarning:\ %m]],
    [[%f:%l:\ %tote:\ %m]],

    -- clang-cl style.
    [[%f(%l\\,%c):\ %trror:\ %m]],
    [[%f(%l\\,%c):\ %tarning:\ %m]],
    [[%f(%l\\,%c):\ %tote:\ %m]],

    -- cl.exe style.
    [[%f(%l):\ %*[^ ]\ %*[^ ]\ %m]],
    [[%f(%l):\ %trror\ %m]],
    [[%f(%l):\ %tarning\ %m]],

    -- Fallback linker-ish messages.
    [[%*[^:]:\ %m]],
}, ",")

-- Only show hlsearch while typing / or ?.
local live_search_hl_group = vim.api.nvim_create_augroup("LiveSearchHL", { clear = true })
vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = live_search_hl_group,
    callback = function()
        local t = vim.fn.getcmdtype()
        if t == "/" or t == "?" then
            vim.opt.hlsearch = true
        end
    end,
})
vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = live_search_hl_group,
    callback = function()
        local t = vim.fn.getcmdtype()
        if t == "/" or t == "?" then
            vim.opt.hlsearch = false
            vim.cmd("nohlsearch")
        end
    end,
})

-- LSP enable-once helper.
local missing_lsp_exe_warned = {}
local function enable_lsp_if_executable(name, cfg)
    local exe = cfg.cmd and cfg.cmd[1]
    if not exe then
        return
    end

    if vim.fn.executable(exe) == 1 then
        vim.lsp.config(name, cfg)
        vim.lsp.enable(name)
        return
    end

    if missing_lsp_exe_warned[exe] then
        return
    end
    missing_lsp_exe_warned[exe] = true
    vim.schedule(function()
        vim.notify(
            ("LSP '%s' not enabled: executable '%s' not found in PATH"):format(name, exe),
            vim.log.levels.WARN
        )
    end)
end

-- LSP server table.
local lsp_servers = {
    {
        name = "clangd",
        cfg = {
            cmd = { "clangd" },
            filetypes = { "c", "cpp", "objc", "objcpp" },
            init_options = { fallbackFlags = { "-I" .. "C:/sh1tz/apesticks/cc++/base/code" }, },
        },
    },
    {
        name = "pyright",
        cfg = { cmd = { "pyright-langserver", "--stdio" }, filetypes = { "python" }, },
    },
    {
        name = "ols",
        cfg = { cmd = { "ols" }, filetypes = { "odin" }, },
    },
    {
        name = "jails",
        cfg = { cmd = { "jails" }, filetypes = { "jai" }, },
    },
}
for _, server in ipairs(lsp_servers) do
    enable_lsp_if_executable(server.name, server.cfg)
end

-- Keep diagnostics quiet in-buffer.
vim.diagnostic.config({
    virtual_text = false,
    signs = false,
    underline = false,
    update_in_insert = false,
    severity_sort = false,
})

-- Disable semantic token colors so colorscheme stays stable.
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
            client.server_capabilities.semanticTokensProvider = nil
        end
    end,
})
