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
      s = s:gsub("\r", "")
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
      vim.g.qf_first_pending = 1

      -- open quickfix only if there are entries
      vim.schedule(function()
        local qf = vim.fn.getqflist()
        local total = #qf
        local errors = 0
        for _, item in ipairs(qf) do
          if item.valid == 1 then
            local text = (item.text or ""):lower()
            local is_note = text:find("declaration of", 1, true) or text:find("note:", 1, true)
            if not is_note and (item.type == "E" or item.type == "") then
              errors = errors + 1
            end
          end
        end
        vim.cmd("cwindow")
        vim.api.nvim_echo({ { ("Build finished (exit %d) - %d errors (%d items)"):format(code, errors, total), "None" } }, false, {})
      end)
    end,
  })
end
vim.keymap.set("n", "<C-k>", build_async, { silent = true, noremap = true })
--- End ---

--- Quickfix Mappings ---
local function qf_is_error(item)
  if item.valid ~= 1 then return false end
  local text = (item.text or ""):lower()
  if text:find("declaration of", 1, true) or text:find("note:", 1, true) then
    return false
  end
  return item.type == "E" or item.type == ""
end

local function qf_jump_to_first_error()
  local qf = vim.fn.getqflist()
  for i, item in ipairs(qf) do
    if qf_is_error(item) then
      vim.cmd(("cc %d"):format(i))
      return true
    end
  end
  return false
end

local function qf_jump_to_next_error()
  local qf = vim.fn.getqflist()
  if #qf == 0 then return end
  local info = vim.fn.getqflist({ idx = 0 })
  local start = info.idx or 0
  for i = start + 1, #qf do
    if qf_is_error(qf[i]) then
      vim.cmd(("cc %d"):format(i))
      return
    end
  end
  for i = 1, start do
    if qf_is_error(qf[i]) then
      vim.cmd(("cc %d"):format(i))
      return
    end
  end
  vim.cmd.cfirst()
end

vim.keymap.set("n", "<C-n>", function()
  local qf = vim.fn.getqflist()
  if #qf == 0 then return end
  if vim.g.qf_first_pending == 1 then
    vim.g.qf_first_pending = 0
    if qf_jump_to_first_error() then return end
  end
  qf_jump_to_next_error()
end, { silent = true })

vim.keymap.set("n", "<C-b>", function()
  local ok = pcall(vim.cmd.cprev)
  if not ok then vim.cmd.clast() end
end, { silent = true })

vim.keymap.set("n", "<C-j>", "<cmd>wall<CR>", { silent = true, noremap = true })

vim.keymap.set("n", "<leader>q", "<cmd>copen<CR>", { silent = true })
vim.keymap.set("n", "<leader>x", "<cmd>cclose<CR>", { silent = true })
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
-- vim.keymap.set("n", "<leader>s", [[:%s/<C-r><C-w>//g<Left><Left>]], { noremap = true, silent = true })
-- vim.keymap.set("x", "<leader>s", [["zy:%s#\V<C-r>z##g<Left><Left>]], { noremap = true, silent = true })
vim.keymap.set("n", "<leader>s", ":%s/<C-r><C-w>//g<Left><Left>", { noremap = true, silent = true })
vim.keymap.set("x", "<leader>s", "y:%s/<C-r>\"//g<Left><Left>", { noremap = true, silent = true })
-- paste over selection without yanking replaced text (NOTE: this is usually a VISUAL-mode map)
vim.keymap.set("x", "<leader>p", [["_dP]], { noremap = true, silent = true })
-- backspace word in insert mode
vim.keymap.set("i", "<C-BS>", "<C-w>", { silent = true, noremap = true })

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
