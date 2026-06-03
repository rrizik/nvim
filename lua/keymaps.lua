-- lua/keymaps.lua

local map = vim.keymap.set
local nore_silent = { noremap = true, silent = true }

-- Quickfix error filters and cached movement targets.
local qf_error_indexes = {}
local qf_cache_id = nil
local qf_cache_changedtick = nil

local function qf_info()
    return vim.fn.getqflist({ id = 0, changedtick = 0, idx = 0, size = 0 })
end

local function qf_is_error(item)
    if item.valid ~= 1 then
        return false
    end
    local text = (item.text or ""):lower()
    if text:find("declaration of", 1, true) or text:find("note:", 1, true) then
        return false
    end
    return item.type == "E" or item.type == "e" or item.type == ""
end

local function qf_rebuild_error_cache()
    qf_error_indexes = {}
    for i, item in ipairs(vim.fn.getqflist()) do
        if qf_is_error(item) then
            qf_error_indexes[#qf_error_indexes + 1] = i
        end
    end

    local info = qf_info()
    qf_cache_id = info.id
    qf_cache_changedtick = info.changedtick
    return #qf_error_indexes
end

local function qf_ensure_error_cache()
    local info = qf_info()
    if info.size == 0 then
        qf_error_indexes = {}
        qf_cache_id = info.id
        qf_cache_changedtick = info.changedtick
        return false
    end

    if qf_cache_id ~= info.id or qf_cache_changedtick ~= info.changedtick then
        qf_rebuild_error_cache()
    end
    return #qf_error_indexes > 0
end

local function qf_jump_to_first_error()
    if not qf_ensure_error_cache() then
        return false
    end
    vim.cmd(("cc %d"):format(qf_error_indexes[1]))
    return true
end

local function qf_jump_to_next_error()
    if not qf_ensure_error_cache() then
        return
    end

    local start = qf_info().idx or 0
    for _, qf_index in ipairs(qf_error_indexes) do
        if qf_index > start then
            vim.cmd(("cc %d"):format(qf_index))
            return
        end
    end
    vim.cmd(("cc %d"):format(qf_error_indexes[1]))
end

local function qf_jump_to_prev_error()
    if not qf_ensure_error_cache() then
        return
    end

    local start = qf_info().idx or 0
    for i = #qf_error_indexes, 1, -1 do
        local qf_index = qf_error_indexes[i]
        if qf_index < start then
            vim.cmd(("cc %d"):format(qf_index))
            return
        end
    end
    vim.cmd(("cc %d"):format(qf_error_indexes[#qf_error_indexes]))
end

-- Async build and quickfix populate.
local function build_async()
    vim.cmd("wall")

    -- Stop an already running build before starting a new one.
    if vim.g._build_job_id and vim.fn.jobwait({ vim.g._build_job_id }, 0)[1] == -1 then
        vim.fn.jobstop(vim.g._build_job_id)
    end

    local output_chunks = {}
    local function on_data(_, data)
        if not data then
            return
        end
        for _, s in ipairs(data) do
            if s ~= "" then
                output_chunks[#output_chunks + 1] = s
            end
        end
    end

    vim.api.nvim_echo({ { "Building...", "None" } }, false, {})
    vim.g._build_job_id = vim.fn.jobstart({ "cmd.exe", "/c", [[misc\build.bat]] }, {
        cwd = vim.fn.getcwd(),
        stdout_buffered = false,
        stderr_buffered = false,
        on_stdout = on_data,
        on_stderr = on_data,
        on_exit = function(_, code)
            local lines = {}
            for _, s in ipairs(output_chunks) do
                lines[#lines + 1] = s:gsub("\r", "")
            end

            vim.fn.setqflist({}, "r", {
                title = ("build (exit %d)"):format(code),
                lines = lines,
                efm = vim.o.errorformat,
            })
            vim.g.qf_first_pending = 1

            vim.schedule(function()
                local errors = qf_rebuild_error_cache()
                vim.cmd("cwindow")
                vim.api.nvim_echo({
                    { ("Build finished - %d errors"):format(errors), "None" },
                }, false, {})
            end)
        end,
    })
end
map("n", "<C-k>", build_async, nore_silent)

map("n", "<C-n>", function()
    if not qf_ensure_error_cache() then
        return
    end
    if vim.g.qf_first_pending == 1 then
        vim.g.qf_first_pending = 0
        if qf_jump_to_first_error() then
            return
        end
    end
    qf_jump_to_next_error()
end, { silent = true })

map("n", "<C-b>", function()
    qf_jump_to_prev_error()
end, { silent = true })

map("n", "<C-j>", "<cmd>wall<CR>", nore_silent)
map("n", "<leader>q", "<cmd>copen<CR>", { silent = true })
map("n", "<leader>x", "<cmd>cclose<CR>", { silent = true })

-- Convenience command/file keymaps.
map("n", "<F4>", function()
    vim.cmd("tabedit " .. vim.fn.stdpath("config") .. "/colors/custom.lua")
end, { silent = true })

vim.api.nvim_create_user_command("Hex", "%!xxd", {})
vim.api.nvim_create_user_command("Hexb", "%!xxd -r", {})

-- LSP keymaps are buffer-local and only added after attach.
local lsp_keymap_group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
    group = lsp_keymap_group,
    callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }
        map("n", "<leader>d", vim.lsp.buf.definition, opts)
        map("n", "<leader>c", vim.lsp.buf.declaration, opts)
        map("n", "<leader>r", vim.lsp.buf.references, opts)
        map("n", "<leader>e", vim.lsp.buf.rename, opts)
    end,
})

-- Navigation/editing maps.
map("n", "<C-[>", "<C-o>", nore_silent)
map("n", "<C-]>", "<C-i>", nore_silent)
map("n", "<C-w>b", "<C-w>s", nore_silent)

map("n", "j", "gj", nore_silent)
map("n", "k", "gk", nore_silent)

map("n", "<leader>]", "<cmd>tabmove +1<CR>", nore_silent)
map("n", "<leader>[", "<cmd>tabmove -1<CR>", nore_silent)

map("n", "<C-d>", "<C-d>zz", nore_silent)
map("n", "<C-u>", "<C-u>zz", nore_silent)

map("n", "n", "nzz", nore_silent)
map("n", "N", "Nzz", nore_silent)
map("n", "*", "*zz", nore_silent)
map("n", "#", "#zz", nore_silent)
map("n", "g*", "g*zz", nore_silent)
map("n", "g#", "g#zz", nore_silent)

map("n", "<leader>s", ":%s/<C-r><C-w>//g<Left><Left>", nore_silent)
map("x", "<leader>s", "y:%s/<C-r>\"//g<Left><Left>", nore_silent)
map("x", "<leader>p", [["_dP]], nore_silent)
map("i", "<C-BS>", "<C-w>", nore_silent)

-- Window resize controls for normal/insert/visual.
local step_left_right = 20
local step_up_down = 10
local resize_opts = { noremap = true, silent = true }

local function winnr_cur()
    return vim.fn.winnr()
end
local function winnr_left()
    return vim.fn.winnr("h")
end
local function winnr_right()
    return vim.fn.winnr("l")
end
local function winnr_up()
    return vim.fn.winnr("k")
end
local function winnr_down()
    return vim.fn.winnr("j")
end

local function has_left()
    return winnr_left() ~= winnr_cur()
end
local function has_right()
    return winnr_right() ~= winnr_cur()
end
local function has_up()
    return winnr_up() ~= winnr_cur()
end
local function has_down()
    return winnr_down() ~= winnr_cur()
end

local function ctrl_left()
    if not has_left() then
        return
    end
    local cur = vim.api.nvim_get_current_win()
    vim.cmd("wincmd h")
    vim.cmd("vertical resize -" .. step_left_right)
    vim.api.nvim_set_current_win(cur)
end

local function ctrl_right()
    if not has_left() then
        return
    end
    local cur = vim.api.nvim_get_current_win()
    vim.cmd("wincmd h")
    vim.cmd("vertical resize +" .. step_left_right)
    vim.api.nvim_set_current_win(cur)
end

local function alt_left()
    if not has_right() then
        return
    end
    vim.cmd("vertical resize -" .. step_left_right)
end

local function alt_right()
    if not has_right() then
        return
    end
    vim.cmd("vertical resize +" .. step_left_right)
end

local function ctrl_up()
    if not has_up() then
        return
    end
    local cur = vim.api.nvim_get_current_win()
    vim.cmd("wincmd k")
    vim.cmd("resize -" .. step_up_down)
    vim.api.nvim_set_current_win(cur)
end

local function ctrl_down()
    if not has_up() then
        return
    end
    local cur = vim.api.nvim_get_current_win()
    vim.cmd("wincmd k")
    vim.cmd("resize +" .. step_up_down)
    vim.api.nvim_set_current_win(cur)
end

local function alt_up()
    if not has_down() then
        return
    end
    vim.cmd("resize -" .. step_up_down)
end

local function alt_down()
    if not has_down() then
        return
    end
    vim.cmd("resize +" .. step_up_down)
end

for _, mode in ipairs({ "n", "i", "v" }) do
    map(mode, "<C-Left>", ctrl_left, resize_opts)
    map(mode, "<C-Right>", ctrl_right, resize_opts)
    map(mode, "<A-Left>", alt_left, resize_opts)
    map(mode, "<A-Right>", alt_right, resize_opts)
    map(mode, "<C-Up>", ctrl_up, resize_opts)
    map(mode, "<C-Down>", ctrl_down, resize_opts)
    map(mode, "<A-Up>", alt_up, resize_opts)
    map(mode, "<A-Down>", alt_down, resize_opts)
end
