-- lua/c.lua

local M = {}

-- True for C/C++ buffers only.
local function is_c_or_cpp(buf)
    local ft = vim.bo[buf].filetype
    return ft == "c" or ft == "cpp"
end

-- Apply custom syntax once per buffer unless forced.
local function apply_for_buffer(buf, force)
    if not force and vim.b[buf].custom_c_syntax_applied then
        return
    end
    vim.api.nvim_buf_call(buf, function()
        M.apply()
    end)
    vim.b[buf].custom_c_syntax_applied = true
end

function M.apply()
    vim.cmd([[
    " --- bounded syntax sync ---
    syntax sync minlines=64 maxlines=256

    " --- comment markers ---
    syn keyword cRed    contained TODO FIXME WRONG XXX Todo FixMe Wrong todo fixme wrong xxx
    syn keyword cYellow contained SPEED SLOW CLEANUP INCOMPLETE STUDY QUESTION FUTURE CONSIDER NOTCLEAR UNTESTED TESTING NOCHECKIN YUCK WARNING Speed Slow Cleanup Incomplete Study Question Future Consider NotClear Untested Testing NoCheckin Yuck Warning speed slow cleanup incomplete study question future consider notclear untested testing nocheckin yuck warning
    syn keyword cGreen  contained NOTE IMPORTANT Note Important note important

    silent! syn cluster cCommentGroup add=cRed,cYellow,cGreen

    hi def link cRed    SoftRed
    hi def link cYellow SoftYellow
    hi def link cGreen  SoftGreen

    " --- OPTIONAL (kept commented): function defs/calls/types ---
    " Performance notes:
    " 1) No containedin=ALLBUT global scans.
    " 2) No multiline regex (\_.{-}) for typedefs.
    " 3) Definitions stay line-local and require '{' to avoid call-like matches.

    " Function definitions (line-local, anchored):
    "syn match MyFuncDef /\v^\s*([_A-Za-z]\w*\s+)*\zs[_A-Za-z]\w*\ze\s*\([^;{}]*\)\s*\{/
    "hi def link MyFuncDef Function

    " Function calls (lightweight):
    "syn match MyFuncCall /\v<%(if|for|while|switch|return|sizeof)@![_A-Za-z]\w*\ze\s*\(/
    "hi def link MyFuncCall Function

    " Type-ish names by convention (requires uppercase start + at least one lowercase):
    "syn match MyTypeName /\v<\u[A-Za-z0-9_]*\l[A-Za-z0-9_]*>/
    "hi def link MyTypeName Type

    " Typedef alias on one line only (cheap):
    "syn match MyTypedefName /\v^\s*typedef.{-}\zs<[_A-Za-z]\w*>\ze\s*;/
    "hi def link MyTypedefName Type

    " --- explicit typedef aliases ---
    syn keyword cType i8 i16 i32 i64 s8 s16 s32 s64 u8 u16 u32 u64 f16 f32 f64 v2s32 v2 v3 v4 vec2 vec3 vec4 I8 I16 I32 I64 S8 S16 S32 S64 U8 U16 U32 U64 F16 F32 F64 V2S32 V2 V3 V4 VEC2 VEC3 VEC4 RGBA wchar global local_static local function def m2 m3 m4 M2 M3 M4 mat1 mat2 mat3 MAT1 MAT2 MAT3 Arena ScratchArena PoolArena PoolFreeNode String8 String16 String32 String8Node String8Join String8List
  ]])
end

function M.setup()
    local group = vim.api.nvim_create_augroup("CustomCSyntax", { clear = true })

    -- Primary path: apply when C/C++ syntax loads.
    vim.api.nvim_create_autocmd("Syntax", {
        group = group,
        pattern = { "c", "cpp" },
        callback = function(args)
            local buf = args.buf
            vim.schedule(function()
                if vim.api.nvim_buf_is_loaded(buf) and is_c_or_cpp(buf) then
                    apply_for_buffer(buf, false)
                end
            end)
        end,
    })

    -- Colorscheme reset clears syntax groups, so reapply once per open C/C++ buffer.
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) and is_c_or_cpp(buf) then
                    vim.b[buf].custom_c_syntax_applied = false
                    apply_for_buffer(buf, true)
                end
            end
        end,
    })
end

return M
