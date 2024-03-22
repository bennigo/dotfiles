return {
    'goolord/alpha-nvim',
    enabled = true,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function ()
        require('alpha').setup(
                -- require('alpha.themes.dashboard').config
                require('alpha.themes.startify').config
        )
    end
}
