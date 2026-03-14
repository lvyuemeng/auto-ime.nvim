local M = {}

local core = require("ime-auto.core")

function M.setup(opts)
  core.setup(opts or {})
end

return M