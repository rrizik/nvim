-- lua/c.lua
--
local M = {}

function M.apply()
  vim.cmd([[
    " --- comment markers ---
    syn keyword cRed    contained TODO FIXME WRONG XXX Todo FixMe Wrong todo fixme wrong xxx
    syn keyword cYellow contained SPEED SLOW CLEANUP INCOMPLETE STUDY QUESTION FUTURE CONSIDER NOTCLEAR UNTESTED TESTING NOCHECKIN YUCK WARNING Speed Slow Cleanup Incomplete Study Question Future Consider NotClear Untested Testing NoCheckin Yuck Warning speed slow cleanup incomplete study question future consider notclear untested testing nocheckin yuck warning
    syn keyword cGreen  contained NOTE IMPORTANT Note Important note important

    silent! syn cluster cCommentGroup add=cRed,cYellow,cGreen

    hi def link cRed    SoftRed
    hi def link cYellow SoftYellow
    hi def link cGreen  SoftGreen

    " --- function-ish tokens: foo( ---
    "syn match MyFuncCall /\v<[_A-Za-z]\w*\ze\s*\(/ containedin=ALLBUT,cComment,cCommentL,cString,cCppString,cCharacter
    "hi def link MyFuncCall Function

    "" --- type-ish tokens by naming convention ---
    "" Matches: Type, ThisKindOfType, This_Kind_Of_Type (requires at least one lowercase, avoids ALL_CAPS)
    "syn match MyTypeName /\v<\u\w*\l\w*>/ containedin=ALLBUT,cComment,cCommentL,cString,cCppString,cCharacter
    "hi def link MyTypeName Type

    "" --- typedef: highlight the alias being defined ---
    "" typedef <stuff> NAME;
    "syn match MyTypedefName /\v<typedef>\_.{-}\zs<[_A-Za-z]\w*>\ze\s*;/ containedin=ALLBUT,cComment,cCommentL,cString,cCppString,cCharacter
    "hi def link MyTypedefName Type

    " --- explicit typedef aliases (you can remove later if you want) ---
    syn keyword cType i8 i16 i32 i64 s8 s16 s32 s64 u8 u16 u32 u64 f16 f32 f64 v2s32 v2 v3 v4 vec2 vec3 vec4 I8 I16 I32 I64 S8 S16 S32 S64 U8 U16 U32 U64 F16 F32 F64 V2S32 V2 V3 V4 VEC2 VEC3 VEC4 RGBA wchar global local_static local function def m2 m3 m4 M2 M3 M4 mat1 mat2 mat3 MAT1 MAT2 MAT3 Arena ScratchArena PoolArena PoolFreeNode String8 String16 String32 String8Node String8Join String8List
  ]])
end

function M.setup()
    local group = vim.api.nvim_create_augroup("CustomCSyntax", { clear = true })

    -- When you enter a C/C++ buffer, apply after other ft/syntax stuff runs.
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "c", "cpp" },
        callback = function()
            vim.schedule(function()
                M.apply()
            end)
        end,
    })

    -- When syntax is (re)loaded, apply again.
    vim.api.nvim_create_autocmd("Syntax", {
        group = group,
        pattern = { "c", "cpp" }, -- <amatch> is the syntax name
        callback = function()
            vim.schedule(function()
                M.apply()
            end)
        end,
    })

    -- Re-apply on buffer enter to avoid missed timing in some sessions.
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
        callback = function()
            vim.schedule(function()
                M.apply()
            end)
        end,
    })

    -- Your colorscheme runs :syntax reset, so re-apply across open C/C++ buffers.
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) then
                    local ft = vim.bo[buf].filetype
                    if ft == "c" or ft == "cpp" then
                        vim.api.nvim_buf_call(buf, function()
                            M.apply()
                        end)
                    end
                end
            end
        end,
    })

end

return M
