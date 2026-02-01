-- lua/options.lua

-- vim.g.loaded_netrw = 1        -- stop loading netrw
-- vim.g.loaded_netrwPlugin = 1  -- stop loading netrw's plugin features
vim.g.mapleader = " "

vim.opt.termguicolors = true     -- enable 24-bit (truecolor) highlighting
vim.cmd.syntax("on")             -- enable syntax highlighting
vim.cmd.colorscheme("custom")    -- set colorscheme
vim.opt.guifont = "Consolas:h11" -- set GUI font

vim.opt.magic = false         -- / search does literal matches
vim.opt.incsearch = true
vim.opt.hlsearch = false
vim.opt.ignorecase = false     -- case-sensitive searching by default

vim.opt.belloff = "all"       -- disable all bell/visual bell
vim.opt.autoindent = true     -- copy indent from current line to the next
vim.opt.smartindent = true    -- smarter autoindent for code-like files
vim.opt.tabstop = 4           -- display width of a literal <Tab> character
vim.opt.shiftwidth = 4        -- indent width for >> << and autoindent
vim.opt.softtabstop = 4       -- <Tab>/<BS> feel like 4 spaces in insert mode
vim.opt.shiftround = false    -- don't round indent to multiples of shiftwidth
vim.opt.expandtab = true      -- insert spaces instead of literal <Tab>

vim.opt.scrolloff = 0         -- vertical cursor margin from top/bottom
vim.opt.sidescrolloff = 4     -- horizontal cursor margin from left/right edge
vim.opt.backspace = { "indent", "eol", "start" } -- allow backspace over indent/EOL/start
vim.opt.compatible = false    -- disable old Vi compatibility behaviors
-- vim.opt.autoread = true       -- auto-reload files changed on disk (when safe)
vim.opt.clipboard = "unnamedplus" -- all copy paste is system level
vim.opt.splitright = true     -- :vsplit opens to the right
vim.opt.splitbelow = true     -- :split opens below
vim.opt.ruler = true          -- show cursor position info
vim.opt.paste = false         -- ensure 'paste' mode is off
vim.opt.number = false        -- line numbers OFF (your comment was backwards)
vim.opt.mouse = "a"           -- enable mouse in all modes
vim.opt.list = false          -- don't show whitespace chars

vim.opt.wrap = true           -- wrap long linekk/terms
vim.opt.linebreak = true      -- wrap at word boundaries

vim.opt.guicursor = "a:blinkon0"   -- disable cursor blinking (GUI-dependent)
vim.opt.foldcolumn = "0"      -- no fold column
vim.opt.cinoptions = "l1"     -- C indent tweak (case:{ style)
vim.opt.title = true          -- enable setting the window title
vim.opt.titlestring = "%t"    -- %t = tail (filename)

vim.o.tabline = "%!v:lua.TabLine()"
function _G.TabLine()
  local s = ""
  for t = 1, vim.fn.tabpagenr("$") do
    local b = vim.fn.tabpagebuflist(t)[vim.fn.tabpagewinnr(t)]
    local n = vim.fn.fnamemodify(vim.fn.bufname(b), ":t")
    if n == "" then n = "[No Name]" end
    s = s .. ((t==vim.fn.tabpagenr()) and "%#TabLineSel#" or "%#TabLine#")
      .. " %" .. t .. "T " .. n .. " %T"
  end
  return s .. "%#TabLineFill#%="
end
vim.o.tabline = "%!v:lua.TabLine()"

--- Setup make and error formats ---
vim.opt.makeprg = [[cmd.exe /c ..\misc\build.bat]]
vim.opt.errorformat = table.concat({
    -- clang/clang++/gcc style: file:line:col: <type>: message
    [[%f:%l:%c:\ %trror:\ %m]],
    [[%f:%l:%c:\ %tarning:\ %m]],
    [[%f:%l:%c:\ %tote:\ %m]],
    -- clang/gcc without column
    [[%f:%l:\ %trror:\ %m]],
    [[%f:%l:\ %tarning:\ %m]],
    [[%f:%l:\ %tote:\ %m]],

    -- clang-cl style: file(line,col): <type>: message
    [[%f(%l\\,%c):\ %trror:\ %m]],
    [[%f(%l\\,%c):\ %tarning:\ %m]],
    [[%f(%l\\,%c):\ %tote:\ %m]],

    -- MSVC cl.exe style: file(line): error C####: message (or warning/fatal error)
    [[%f(%l):\ %*[^ ]\ %*[^ ]\ %m]],     -- catches "fatal error C####:" etc. loosely
    [[%f(%l):\ %trror\ %m]],
    [[%f(%l):\ %tarning\ %m]],

    -- Linker-ish / no file:line (keep message)
    [[%*[^:]:\ %m]],
}, ",")
--- End ---

local aug = vim.api.nvim_create_augroup("LiveSearchHL", { clear = true })

vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = aug,
    callback = function()
        local t = vim.fn.getcmdtype()
        if t == "/" or t == "?" then
            vim.opt.hlsearch = true
        end
    end,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = aug,
    callback = function()
        local t = vim.fn.getcmdtype()
        if t == "/" or t == "?" then
            vim.opt.hlsearch = false
            vim.cmd("nohlsearch")
        end
    end,
})
--- End ---

--- LSP ---
-- Warn once per missing server executable
local _missing_lsp_exe_warned = {}
local function enable_if_exe(name, cfg)
    local exe = cfg.cmd and cfg.cmd[1]
    if not exe then return end

    if vim.fn.executable(exe) == 1 then
        vim.lsp.config(name, cfg)
        vim.lsp.enable(name)
        return
    end

    if not _missing_lsp_exe_warned[exe] then
        _missing_lsp_exe_warned[exe] = true
        vim.schedule(function()
            vim.notify(
                ("LSP '%s' not enabled: executable '%s' not found in PATH"):format(name, exe),
                vim.log.levels.WARN
            )
        end)
    end
end

local lsp_aug = vim.api.nvim_create_augroup("UserLspLazyEnable", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = lsp_aug,
    pattern = { "c", "cpp", "objc", "objcpp" },
    callback = function()
        enable_if_exe("clangd", {
            cmd = { "clangd" },
            filetypes = { "c", "cpp", "objc", "objcpp" },
            init_options = {
                fallbackFlags = { "-I" .. "C:/sh1tz/apesticks/cc++/base/code" },
            },
        })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = lsp_aug,
    pattern = { "python" },
    callback = function()
        enable_if_exe("pyright", {
            cmd = { "pyright-langserver", "--stdio" },
            filetypes = { "python" },
        })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = lsp_aug,
    pattern = { "odin" },
    callback = function()
        enable_if_exe("ols", {
            cmd = { "ols" },
            filetypes = { "odin" },
        })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = lsp_aug,
    pattern = { "jai" },
    callback = function()
        enable_if_exe("jails", {
            cmd = { "jails" },
            filetypes = { "jai" },
        })
    end,
})

-- turn off stupid LSP warning and error programming suggestions
vim.diagnostic.config({
    virtual_text = false,
    signs = false,
    underline = false,
    update_in_insert = false,
    severity_sort = false,
})

-- Disable LSP semantic token highlighting (prevents color changes after LSP attaches)
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
            client.server_capabilities.semanticTokensProvider = nil
        end
    end,
})
--- End ---
--- End --
