-- lua/keymaps.lua

--- Async build -> quickfix (non-blocking) ---
local function build_async()
  vim.cmd("wall")

  -- kill previous build if still running
  if vim.g._build_job_id and vim.fn.jobwait({ vim.g._build_job_id }, 0)[1] == -1 then
    vim.fn.jobstop(vim.g._build_job_id)
  end

  local lines = {}
  local function on_data(_, data)
    if not data then return end
    for _, s in ipairs(data) do
      if s ~= "" then table.insert(lines, s) end
    end
  end

  vim.api.nvim_echo({ { "Building...", "None" } }, false, {})

  vim.g._build_job_id = vim.fn.jobstart({ "cmd.exe", "/c", [[..\misc\build.bat]] }, {
    cwd = vim.fn.getcwd(), -- assumes you're in project\code (your current setup)
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = on_data,
    on_stderr = on_data,
    on_exit = function(_, code)
      -- parse output using your current errorformat into quickfix
      vim.fn.setqflist({}, "r", {
        title = ("build (exit %d)"):format(code),
        lines = lines,
        efm = vim.o.errorformat,
      })

      -- open quickfix only if there are entries
      vim.schedule(function()
        vim.cmd("cwindow")
        vim.api.nvim_echo({ { ("Build finished (exit %d)"):format(code), "None" } }, false, {})
      end)
    end,
  })
end
vim.keymap.set("n", "<C-k>", build_async, { silent = true, noremap = true })
--- End ---

--- Quickfix Mappings ---
vim.keymap.set("n", "<C-n>", function()
  local ok = pcall(vim.cmd.cnext)
  if not ok then vim.cmd.cfirst() end
end, { silent = true })

vim.keymap.set("n", "<C-b>", function()
  local ok = pcall(vim.cmd.cprev)
  if not ok then vim.cmd.clast() end
end, { silent = true })

vim.keymap.set("n", "<leader>q", "<cmd>copen<CR>", { silent = true })
vim.keymap.set("n", "<leader>x", "<cmd>cclose<CR>", { silent = true })
--- End ---

--- F3: open init.lua ---
vim.keymap.set("n", "<F3>", function()
  vim.cmd("tabedit " .. vim.fn.stdpath("config") .. "/init.lua")
end, { silent = true })
--- End ---

--- F4: open your colorscheme file ---
vim.keymap.set("n", "<F4>", function()
  vim.cmd("tabedit " .. vim.fn.stdpath("config") .. "/colors/custom.lua")
end, { silent = true })
--- End ---

--- LSP keymaps (buffer-local on attach) ---
local aug = vim.api.nvim_create_augroup("LspKeymaps", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = aug,
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true }

    vim.keymap.set("n", "<leader>d", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<leader>c", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>e", vim.lsp.buf.rename, opts)
  end,
})
-- Jumplist back/forward on Ctrl-[ / Ctrl-]
vim.keymap.set("n", "<C-[>", "<C-o>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-]>", "<C-i>", { noremap = true, silent = true })
--- End ---

-- Remap <C-w>b to horizontal split (overrides built-in "go to bottom window")
vim.keymap.set("n", "<C-w>b", "<C-w>s", { noremap = true, silent = true })

-- (optional) If you still want a "go to bottom window" key, pick something else:
-- vim.keymap.set("n", "<C-w>B", "<C-w>b", { noremap = true, silent = true })
-- j/k traverse screen lines when wrap is on
vim.keymap.set("n", "j", "gj", { noremap = true, silent = true })
vim.keymap.set("n", "k", "gk", { noremap = true, silent = true })

-- move current tab left/right
vim.keymap.set("n", "<leader>]", "<cmd>tabmove +1<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>[", "<cmd>tabmove -1<CR>", { noremap = true, silent = true })

-- move lines up/down (normal/insert/visual) -- timer, if I don't use it much its being replaced with someting else
-- vim.keymap.set("n", "<C-Down>", "<cmd>m .+1<CR>==", { noremap = true, silent = true })
-- vim.keymap.set("n", "<C-Up>",   "<cmd>m .-2<CR>==", { noremap = true, silent = true })
-- vim.keymap.set("i", "<C-Down>", "<Esc><cmd>m .+1<CR>==gi", { noremap = true, silent = true })
-- vim.keymap.set("i", "<C-Up>",   "<Esc><cmd>m .-2<CR>==gi", { noremap = true, silent = true })
-- vim.keymap.set("v", "<C-Down>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
-- vim.keymap.set("v", "<C-Up>",   ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

-- keep cursor centered on half-page jumps
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })

-- keep search results centered
vim.keymap.set("n", "n",  "nzz",  { noremap = true, silent = true })
vim.keymap.set("n", "N",  "Nzz",  { noremap = true, silent = true })
vim.keymap.set("n", "*",  "*zz",  { noremap = true, silent = true })
vim.keymap.set("n", "#",  "#zz",  { noremap = true, silent = true })
vim.keymap.set("n", "g*", "g*zz", { noremap = true, silent = true })
vim.keymap.set("n", "g#", "g#zz", { noremap = true, silent = true })

-- search/replace word under cursor (cursor placed before replacement)
vim.keymap.set("n", "<leader>s", [[:%s/<C-r><C-w>//gc<Left><Left><Left>]], { noremap = true, silent = true })

-- paste over selection without yanking replaced text (NOTE: this is usually a VISUAL-mode map)
vim.keymap.set("x", "<leader>p", [["_dP]], { noremap = true, silent = true })

-- Commands: Hex / Hexb
vim.api.nvim_create_user_command("Hex",  "%!xxd",   {})
vim.api.nvim_create_user_command("Hexb", "%!xxd -r", {})


--- VERTICAL/HORIZONTAL UP/DOWN/LEFT/RIGHT RESIZING ---
local step_left_right = 20
local step_up_down = 10
local opts = { noremap = true, silent = true }

local function winnr_cur()   return vim.fn.winnr() end
local function winnr_left()  return vim.fn.winnr("h") end
local function winnr_right() return vim.fn.winnr("l") end
local function winnr_up()    return vim.fn.winnr("k") end
local function winnr_down()  return vim.fn.winnr("j") end

local function has_left()  return winnr_left()  ~= winnr_cur() end
local function has_right() return winnr_right() ~= winnr_cur() end
local function has_up()    return winnr_up()    ~= winnr_cur() end
local function has_down()  return winnr_down()  ~= winnr_cur() end

-- Ctrl: move LEFT bar (between left neighbor and current) by resizing LEFT neighbor
local function ctrl_left()   -- move left bar LEFT (give current more space)
  if not has_left() then return end
  local cur = vim.api.nvim_get_current_win()
  vim.cmd("wincmd h")
  vim.cmd("vertical resize -" .. step_left_right) -- shrink left neighbor => bar moves left
  vim.api.nvim_set_current_win(cur)
end

local function ctrl_right()  -- move left bar RIGHT (give left neighbor more space)
  if not has_left() then return end
  local cur = vim.api.nvim_get_current_win()
  vim.cmd("wincmd h")
  vim.cmd("vertical resize +" .. step_left_right) -- grow left neighbor => bar moves right
  vim.api.nvim_set_current_win(cur)
end

-- Alt: move RIGHT bar (between current and right neighbor) by resizing CURRENT
local function alt_left()    -- move right bar LEFT (give right neighbor more space)
  if not has_right() then return end
  vim.cmd("vertical resize -" .. step_left_right) -- shrink current => bar moves left
end

local function alt_right()   -- move right bar RIGHT (give current more space)
  if not has_right() then return end
  vim.cmd("vertical resize +" .. step_left_right) -- grow current => bar moves right
end

-- Ctrl: move TOP bar (between above neighbor and current) by resizing ABOVE neighbor
local function ctrl_up()     -- move top bar UP (give current more space)
  if not has_up() then return end
  local cur = vim.api.nvim_get_current_win()
  vim.cmd("wincmd k")
  vim.cmd("resize -" .. step_up_down) -- shrink above => bar moves up
  vim.api.nvim_set_current_win(cur)
end

local function ctrl_down()   -- move top bar DOWN (give above more space)
  if not has_up() then return end
  local cur = vim.api.nvim_get_current_win()
  vim.cmd("wincmd k")
  vim.cmd("resize +" .. step_up_down) -- grow above => bar moves down
  vim.api.nvim_set_current_win(cur)
end

-- Alt: move BOTTOM bar (between current and below neighbor) by resizing CURRENT
local function alt_up()      -- move bottom bar UP (give below more space)
  if not has_down() then return end
  vim.cmd("resize -" .. step_up_down) -- shrink current => bar moves up
end

local function alt_down()    -- move bottom bar DOWN (give current more space)
  if not has_down() then return end
  vim.cmd("resize +" .. step_up_down) -- grow current => bar moves down
end

for _, mode in ipairs({ "n", "i", "v" }) do
  -- left/right bars
  vim.keymap.set(mode, "<C-Left>",  ctrl_left,  opts)
  vim.keymap.set(mode, "<C-Right>", ctrl_right, opts)
  vim.keymap.set(mode, "<A-Left>",  alt_left,   opts)
  vim.keymap.set(mode, "<A-Right>", alt_right,  opts)

  -- up/down bars
  vim.keymap.set(mode, "<C-Up>",    ctrl_up,    opts)
  vim.keymap.set(mode, "<C-Down>",  ctrl_down,  opts)
  vim.keymap.set(mode, "<A-Up>",    alt_up,     opts)
  vim.keymap.set(mode, "<A-Down>",  alt_down,   opts)
end
--- END ---
