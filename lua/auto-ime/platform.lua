local M = {}

function M.detect()

  local sys = vim.loop.os_uname().sysname

  ------------------------------------------------
  -- Windows
  ------------------------------------------------
  if sys == "Windows_NT" then

    local ffi = require("ffi")

    ffi.cdef[[
      typedef unsigned int UINT;
      typedef void* HWND;
      typedef unsigned long WPARAM;
      typedef long LPARAM;
      typedef long LRESULT;

      HWND GetForegroundWindow(void);
      HWND ImmGetDefaultIMEWnd(HWND hWnd);
      LRESULT SendMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    ]]

    local user32 = ffi.load("user32")
    local imm32 = ffi.load("imm32")

    local WM_IME_CONTROL = 0x0283
    local IMC_GET = 0x001
    local IMC_SET = 0x002

    local ime_hwnd

    vim.api.nvim_create_autocmd("InsertEnter", {
      once = true,
      callback = function()
        local win = user32.GetForegroundWindow()
        if win ~= nil then
          ime_hwnd = imm32.ImmGetDefaultIMEWnd(win)
        end
      end,
    })

    return function()
      if not ime_hwnd then return end
      local mode = user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_GET, 0)
      if mode ~= 0 then
        user32.SendMessageA(ime_hwnd, WM_IME_CONTROL, IMC_SET, 0)
      end
    end
  end

  ------------------------------------------------
  -- Linux
  ------------------------------------------------
  if sys == "Linux" then

    if vim.fn.executable("fcitx5-remote") == 1 then
      return function()
        if tonumber(vim.fn.system("fcitx5-remote")) == 2 then
          vim.fn.system("fcitx5-remote -c")
        end
      end
    end

    if vim.fn.executable("ibus") == 1 then
      return function()
        vim.fn.system("ibus engine xkb:us::eng")
      end
    end
  end

  ------------------------------------------------
  -- macOS
  ------------------------------------------------
  if sys == "Darwin" then
    if vim.fn.executable("macism") == 1 then
      return function()
        vim.fn.system("macism com.apple.keylayout.ABC")
      end
    end
  end

end

return M