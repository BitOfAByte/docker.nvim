-- File: docker.lua
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local config = require("telescope.config").values
local previewers = require("telescope.previewers")
local utils = require("telescope.utils")
local log = require("plenary.log")
local actions = require("telescope.actions")
local actions_state = require('telescope.actions.state')

log.level = "debug"

local M = {}

-- Main function to show docker images
local function show_docker_images(opts)
  opts = opts or {}
  pickers.new(opts, {
    finder = finders.new_async_job({
      command_generator = function()
        return {"docker", "images", "--format", "json"}
      end,
      entry_maker = function(entry)
        local parsed = vim.json.decode(entry)
        if parsed then
          return {
            values = parsed,
            display = parsed.Repository,
            ordinal = parsed.Repository .. ':' .. parsed.Tag,
          }
        end
      end
    }),
    sorter = config.generic_sorter(opts),
    previewer = previewers.new_buffer_previewer({
      title = "Docker Image Details",
      define_preview = function(self, entry)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true,
        vim.tbl_flatten({"#" .. entry.values.ID, vim.split(vim.inspect(entry.values),'\n')}))
      end
    }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = actions_state.get_selected_entry()
        actions.close(prompt_bufnr)
        -- Open a new split with a terminal running the docker container
        vim.cmd('split')
        vim.cmd('terminal docker run -it ' .. selection.values.Repository)
      end)
      return true
    end
  }):find()
end

-- Setup function that will be called by lazy.nvim
function M.setup()
  -- Set up the keymap
  vim.keymap.set('n', '<Leader>di', function()
    show_docker_images()
  end, { desc = 'Docker Images' })
end

return M

