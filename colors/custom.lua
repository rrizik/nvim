-- custom.lua (Neovim colorscheme, GUI-only values)

vim.o.background = "dark"
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "custom"

local hi = function(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- General
hi("Cursor",     { fg = "#1c1c1c", bg = "#d7af87", bold = true })
hi("Normal",     { fg = "#d7af87", bg = "#1c1c1c" })
hi("VertSplit",  { fg = "#d7af87", bg = "#444444" })

-- Tabs / Title
hi("TabLineSel",  { fg = "#d7af87", bg = "#1c1c1c", bold = true })
hi("TabLine",     { fg = "#d7af87", bg = "#444444", bold = true })
hi("TabLineFill", { fg = "#d7af87", bg = "#444444", bold = true })
hi("Title",       { fg = "#d7af87", bg = "#1c1c1c", bold = true })

-- Statusline
hi("StatusLine",   { fg = "#d7af87", bg = "#444444" })
hi("StatusLineNC", { fg = "#d7af87", bg = "#444444" })

-- Line numbers / nontext
hi("LineNr",   { fg = "#d7af87", bg = "#000000" })
hi("LineNrNC", { fg = "#949494", bg = "#000000" })
hi("NonText",  { fg = "#767676", bg = "#1c1c1c" })

-- Selection / cursorline / search
hi("Visual",     { fg = "#1c1c1c", bg = "#d7af87", bold = true })
hi("CursorLine", { fg = "#d7af87", bg = "#444444" })
hi("MatchParen", { fg = "#1c1c1c", bg = "#949494", bold = true })
hi("Search",     { fg = "#1c1c1c", bg = "#d7af87", bold = true })
hi("IncSearch",  { fg = "#1c1c1c", bg = "#d7af87", bold = true })

-- Quickfix current line
hi("QuickFixLine", { fg = "#1c1c1c", bg = "#d7af87", bold = true })

-- Defining it here avoids a "dangling" link.)
hi("Folded", { fg = "#a0a8b0", bg = "#384048" })
vim.api.nvim_set_hl(0, "FoldColumn", { link = "Folded" })

-- Syntax highlighting
hi("Directory",  { fg = "#d7875f", bg = "#1c1c1c" })
hi("Files",      { fg = "#444444", bg = "#444444" })

hi("Keyword",    { fg = "#87afff" })
hi("Statement",  { fg = "#ffaf5f" })
hi("Constant",   { fg = "#d7875f" })
hi("Number",     { fg = "#d7875f" })
hi("PreProc",    { fg = "#d7af87" })
hi("Function",   { fg = "#d7875f" })
hi("Identifier", { fg = "#d7875f" })
hi("Type",       { fg = "#ffaf5f" })
hi("Special",    { fg = "#90a461" })
hi("String",     { fg = "#90a461" })
hi("Comment",    { fg = "#949494" })

-- Custom emphasis groups
hi("Red",        { fg = "#df4141", bg = "#1c1c1c", bold = true, underline = true })
hi("Todo",       { fg = "#df4141", bg = "#1c1c1c", bold = true, underline = true })
hi("Yellow",     { fg = "#d7d700", bg = "#1c1c1c", bold = true, underline = true })
hi("Green",      { fg = "#87af5f", bg = "#1c1c1c", bold = true, underline = true })
hi("SoftRed",    { fg = "#bf3c3c", bg = "#1c1c1c", bold = true, underline = true })
hi("SoftYellow", { fg = "#c2be53", bg = "#1c1c1c", bold = true, underline = true })
hi("SoftGreen",  { fg = "#87af5f", bg = "#1c1c1c", bold = true, underline = true })
