vim.defer_fn(function()
    vim.lsp.handlers["$/progress"] = function() end
end, 1000)
