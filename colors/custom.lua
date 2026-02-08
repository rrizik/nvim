-- colors/custom.lua

-- Reset and register colorscheme.
vim.o.background = "dark"
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
end
vim.g.colors_name = "custom"

-- Small highlight helper.
local function hi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

-- Shared palette.
local background   = "#1c1c1c"
local normal       = "#d7af87"
local graybar      = "#444444"
local number       = "#d7875f"
local type_color   = "#ffaf5f"
local string_color = "#90a461"
local comment      = "#949494"

-- NvimTree/float background consistency.
local function set_tree_bg()
    hi("NormalFloat",          { bg = background })
    hi("FloatBorder",          { bg = background })

    hi("NvimTreeNormal",       { bg = background })
    hi("NvimTreeNormalFloat",  { bg = background })
    hi("NvimTreeEndOfBuffer",  { bg = background })
    hi("NvimTreeWinSeparator", { bg = background })
    hi("NvimTreeVertSplit",    { bg = background })
    hi("NvimTreeCursorLine",   { bg = background })
    hi("NvimTreeRootFolder",   { fg = comment,    bg = background })
    hi("NvimTreeEndOfBuffer",  { fg = comment,    bg = background })
    hi("NvimTreeCursorLine",   { fg = background, bg = normal, bold = true })
end
set_tree_bg()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_tree_bg })

-- Core UI groups.
hi("Cursor",       { fg = "#111111",    bg = "#ffffff",   bold = true })
hi("Normal",       { fg = normal,       bg = background })
hi("Operator",     { link = "Type" })
hi("VertSplit",    { fg = normal,       bg = graybar })

hi("TabLineSel",   { fg = normal,       bg = background,   bold = true })
hi("TabLine",      { fg = normal,       bg = graybar,      bold = true })
hi("TabLineFill",  { fg = normal,       bg = graybar,      bold = true })
hi("Title",        { fg = normal,       bg = background,   bold = true })

hi("StatusLine",   { fg = normal,       bg = graybar })
hi("StatusLineNC", { fg = normal,       bg = graybar })

hi("LineNr",       { fg = normal,       bg = "#000000" })
hi("LineNrNC",     { fg = comment,      bg = "#000000" })
hi("NonText",      { fg = "#767676",    bg = background })

hi("Visual",       { fg = background,   bg = normal,       bold = true })
hi("CursorLine",   { fg = normal,       bg = graybar,      bold = true })
hi("MatchParen",   { fg = background,   bg = comment,      bold = true })
hi("Search",       { fg = background,   bg = normal,       bold = true })
hi("IncSearch",    { fg = background,   bg = normal,       bold = true })
hi("QuickFixLine", { fg = background,   bg = normal,       bold = true })

-- Fold column link target.
hi("Folded",       { fg = "#a0a8b0",    bg = "#384048" })
hi("FoldColumn",   { link = "Folded" })

-- Syntax groups.
hi("Directory",    { fg = number,       bg = background })
hi("Files",        { fg = graybar,      bg = graybar })

hi("Keyword",      { fg = "#87afff",    bg = background })
hi("Statement",    { fg = type_color,   bg = background })
hi("Constant",     { fg = number,       bg = background })
hi("Number",       { fg = number,       bg = background })
hi("PreProc",      { fg = normal,       bg = background })
hi("Function",     { fg = number,       bg = background })
hi("Identifier",   { fg = number,       bg = background })
hi("Type",         { fg = type_color,   bg = background })
hi("Special",      { fg = string_color, bg = background })
hi("String",       { fg = string_color, bg = background })
hi("Comment",      { fg = comment,      bg = background })

-- Custom emphasis groups.
hi("Red",          { fg = "#df4141",    bg = background,   bold = true, underline = false })
hi("Todo",         { fg = "#df4141",    bg = background,   bold = true, underline = false })
hi("Yellow",       { fg = "#d7d700",    bg = background,   bold = true, underline = false })
hi("Green",        { fg = "#87af5f",    bg = background,   bold = true, underline = false })
hi("SoftRed",      { fg = "#bf3c3c",    bg = background,   bold = true, underline = false })
hi("SoftYellow",   { fg = "#c2be53",    bg = background,   bold = true, underline = false })
hi("SoftGreen",    { fg = "#87af5f",    bg = background,   bold = true, underline = false })
