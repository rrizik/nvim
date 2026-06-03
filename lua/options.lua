-- lua/options.lua

-- Disable unused built-in runtime plugins before runtime/plugin loads.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_matchit = 1
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_remote_plugins = 1
vim.g.editorconfig = false
vim.g.termfeatures = { osc52 = false }

-- Basic startup globals.
vim.g.mapleader = " "

-- UI/bootstrap settings.
vim.opt.termguicolors = true
vim.opt.guifont = "Consolas:h11"
vim.cmd.syntax("on")
vim.cmd.colorscheme("custom")

if vim.g.neovide then
    vim.g.neovide_cursor_animation_length = 0.05
    vim.g.neovide_cursor_trail_size = 0.5
end

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
vim.opt.synmaxcol = 300

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

vim.api.nvim_set_hl(0, "CursorCharBold", { bold = true })

local cursor_char_ns = vim.api.nvim_create_namespace("CursorCharBold")
local cursor_char_last_buf = nil

local function update_cursor_char_bold()
    if cursor_char_last_buf and vim.api.nvim_buf_is_loaded(cursor_char_last_buf) then
        vim.api.nvim_buf_clear_namespace(cursor_char_last_buf, cursor_char_ns, 0, -1)
    end

    local buf = vim.api.nvim_get_current_buf()
    cursor_char_last_buf = buf

    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1] - 1
    local col = pos[2]
    local line = vim.api.nvim_get_current_line()
    local len = #line
    if len == 0 then
        return
    end
    if col >= len then
        col = len - 1
    end

    vim.api.nvim_buf_set_extmark(buf, cursor_char_ns, row, col, {
        end_col = col + 1,
        hl_group = "CursorCharBold",
        hl_eol = false,
        hl_mode = "combine",
        priority = 10000,
    })
end

local cursor_char_group = vim.api.nvim_create_augroup("CursorCharBold", { clear = true })
vim.api.nvim_create_autocmd({
    "BufEnter",
    "ColorScheme",
    "CursorMoved",
    "CursorMovedI",
    "ModeChanged",
    "TextChanged",
    "TextChangedI",
    "VimEnter",
    "WinEnter",
}, {
    group = cursor_char_group,
    callback = function()
        vim.api.nvim_set_hl(0, "CursorCharBold", { bold = true })
        update_cursor_char_bold()
    end,
})

-- Custom tabline cache (file name for each tab).
local tabline_cache = nil

local function build_tab_line()
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

local function invalidate_tab_line()
    tabline_cache = nil
end

_G.TabLine = function()
    if not tabline_cache then
        tabline_cache = build_tab_line()
    end
    return tabline_cache
end

vim.o.tabline = "%!v:lua.TabLine()"
local tabline_group = vim.api.nvim_create_augroup("CustomTabLine", { clear = true })
vim.api.nvim_create_autocmd({
    "TabNew",
    "TabClosed",
    "TabEnter",
    "WinEnter",
    "BufEnter",
    "BufFilePost",
    "BufDelete",
}, {
    group = tabline_group,
    callback = invalidate_tab_line,
})

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
    [[%f(%l)\ :\ %trror\ %m]],
    [[%f(%l)\ :\ %tarning\ %m]],

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

-- LSP setup is deferred until a matching filetype appears.
local enabled_lsp_servers = {}
local missing_lsp_exes = {}
local function enable_lsp_for_filetype(name, cfg, args)
    if enabled_lsp_servers[name] then
        return
    end

    local exe = cfg.cmd and cfg.cmd[1]
    if not exe then
        return
    end

    if vim.fn.executable(exe) == 1 then
        vim.lsp.config(name, cfg)
        vim.lsp.enable(name)
        enabled_lsp_servers[name] = true

        -- During startup, vim.lsp.enable() does not replay the current FileType event.
        if vim.v.vim_did_enter == 0 and args and args.buf then
            pcall(vim.api.nvim_exec_autocmds, "FileType", {
                group = "nvim.lsp.enable",
                buffer = args.buf,
                modeline = false,
            })
        end
        return
    end

    if missing_lsp_exes[exe] then
        return
    end
    missing_lsp_exes[exe] = true
    vim.notify(
        ("LSP '%s' not enabled: executable '%s' not found in PATH"):format(name, exe),
        vim.log.levels.WARN
    )
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

local lsp_filetype_group = vim.api.nvim_create_augroup("DeferredLspEnable", { clear = true })
for _, server in ipairs(lsp_servers) do
    local name = server.name
    local cfg = server.cfg
    vim.api.nvim_create_autocmd("FileType", {
        group = lsp_filetype_group,
        pattern = cfg.filetypes,
        callback = function(args)
            enable_lsp_for_filetype(name, cfg, args)
        end,
    })
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
