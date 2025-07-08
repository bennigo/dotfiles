return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  opts = {
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
    },
  },
  -- keymaps
  keys = function()
    local keys = {
      {
        "<m-a>",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Harpoon File",
      },
      {
        "<m-e>",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon Quick Menu",
      },
      {
        "<m-S-p>",
        function()
          require("harpoon"):list():prev()
        end,
        desc = "Harpoon previous file",
      },
      {
        "<m-S-n>",
        function()
          require("harpoon"):list():next()
        end,
        desc = "Harpoon next file",
      },
    }

    local names = { "j", "k", "l", ";" }
    for i, name in pairs(names) do
      table.insert(keys, {
        "<m-" .. name .. ">",
        function()
          require("harpoon"):list():select(i)
        end,
        desc = "Harpoon to File " .. i,
      })
    end
    return keys
  end,
}
