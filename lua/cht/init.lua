local M = {}

vim.cmd('command! -nargs=1 Cht lua require("cht").queryCheatSheetAny(<f-args>)')

local function detectLanguage()
  local filetype = vim.bo.filetype
  return filetype
end

local function removeSpecialCharacters(input)
  local cleaned_input = input:gsub('\27%[[0-9;]*[JKmsu]', '') -- Match and remove ANSI escape codes

  return cleaned_input
end

local function displayContent(lines, isCentered)
   local max_height_percent = 0.8
    local win_height = vim.fn.winheight(0)
    local max_height = math.floor(win_height * max_height_percent)

    local max_line_width = 0
    for _, line in ipairs(lines) do
        local line_width = vim.fn.strdisplaywidth(line)
        if line_width > max_line_width then
            max_line_width = line_width
        end
    end

    local height = math.min(#lines, max_height)
    local width = max_line_width + 4

    local row, col

    if isCentered then
        row = (win_height - height) / 2
        col = (vim.fn.winwidth(0) - width) / 2
    else
        local cursor_line = vim.fn.line('.')
        local cursor_col = vim.fn.col('.')
        row = cursor_line - vim.fn.winline()
        col = cursor_col - (width / 2)
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    local win_id = vim.api.nvim_open_win(bufnr, true, {
        relative = isCentered and 'editor' or 'cursor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = 'single',
    })

    return bufnr, win_id
end

M.queryCheatSheetCodeOnly = function()
  local cursor_word = vim.fn.expand('<cword>')
  local language = detectLanguage()

  vim.api.nvim_out_write('Loading...')

  local command = 'curl -s "https://cht.sh/' .. language .. '/' .. cursor_word .. '?Q"'
  local response = vim.fn.system(command)
  local cleaned_response = removeSpecialCharacters(response)

  if string.match(cleaned_response, '^%s*$') then
    vim.api.nvim_out_write('No Result\n')
    return
  end


  local lines = vim.fn.split(cleaned_response, '\n')
  local bufnr, _ = displayContent(lines, false)

  vim.bo[bufnr].filetype = language

  vim.cmd('au InsertLeave <buffer> :q!<CR>')
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Esc>', ':q!<CR>', { noremap = true, silent = true })
end

M.queryCheatSheetAny = function(query)
  local language = detectLanguage()
  local formatted_query = string.gsub(query, ' ', '+')

  vim.api.nvim_out_write('Loading...')
  local command = 'curl -s "https://cht.sh/' .. language .. '/' .. formatted_query .. '"'
  local response = vim.fn.system(command)

  local cleaned_response = removeSpecialCharacters(response)

  if string.match(cleaned_response, '^%s*$') then
    vim.api.nvim_out_write('No Result\n')
    return
  end

  local lines = vim.fn.split(cleaned_response, '\n')

  local bufnr, _ = displayContent(lines, true)

  vim.bo[bufnr].filetype = language

  vim.cmd('au InsertLeave <buffer> :q!<CR>')
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Esc>', ':q!<CR>', { noremap = true, silent = true })
end

return M
