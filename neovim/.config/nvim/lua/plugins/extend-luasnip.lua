-- ~/.config/nvim/lua/plugins/luasnip-local.lua

return {
  "L3MON4D3/LuaSnip",
  opts = function(_, _)
    -- Ensure your local Lua snippets are loaded
    require("luasnip.loaders.from_lua").lazy_load({
      paths = vim.fn.stdpath("config") .. "/lua/snippets",
    })

    -- Safe keymaps that don't interfere with completion "Tab"
    local ls = require("luasnip")

    -- Set keymaps for expand functionality
    vim.keymap.set({ "i" }, "<C-K>", function()
      if ls.expandable() then
        ls.expand()
      end
    end, { silent = true, desc = "LuaSnip expand" })

    vim.keymap.set({ "i", "s" }, "<C-L>", function()
      if ls.expand_or_jumpable() then
        ls.expand_or_jump()
      end
    end, { silent = true, desc = "LuaSnip expand or jump" })
  end,

  -- Rest of your configuration...
}
