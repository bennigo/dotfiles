return {
  {
    "saghen/blink.cmp",
    -- If you use LazyVim's Blink extra, keep optional=true. Otherwise remove it.
    optional = true,
    sources = {
      -- add lazydev to your completion providers
      default = { "lazydev" },
      providers = {
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100, -- show at a higher priority than lsp
        },

        timed_tasks = {
          name = "timed_tasks",
          module = "custom.blink_timed_tasks",
          score_offset = 8,
        },
      },
    },
  },
}
