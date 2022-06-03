local libName, libVersion = "LibExecutionQueue", 200
local lib
lib = {}

function lib:new(_wait)
  lib:dm("Debug", "LibExecutionQueue New")
  -- This is a singleton

  self.Queue = self.Queue or {}
  if self.Paused == nil then self.Paused = true end
  self.Wait = _wait or self.Wait or 20

  return lib
end

function lib:Add(func, name)
  lib:dm("Debug", string.format("LibExecutionQueue Add: %s", name))
  table.insert(self.Queue, 1, { func, name })
end

function lib:ContinueWith(func, name)
  table.insert(self.Queue, { func, name })
  self:Start()
end

function lib:Start()
  lib:dm("Debug", "LibExecutionQueue Start")
  if self.Paused then
    self.Paused = false
    self:Next()
  end
end

function lib:Next()
  if not self.Paused then
    local nextFunc = table.remove(self.Queue)
    if nextFunc then
      nextFunc[1]()
      zo_callLater(function() self:Next() end, self.Wait)
    else
      -- Queue empty so pausing
      self.Paused = true;
    end
  end
end

function lib:Pause()
  self.Paused = true
end

LibExecutionQueue = lib

if LibDebugLogger then
  local logger = LibDebugLogger.Create(libName)
  lib.logger = logger
end

local function create_log(log_type, log_content)
  if not DebugLogViewer and log_type == "Info" then
    CHAT_ROUTER:AddSystemMessage(log_content)
    return
  end
  if not LibDebugLogger then return end
  if log_type == "Debug" then
    lib.logger:Debug(log_content)
  end
  if log_type == "Info" then
    lib.logger:Info(log_content)
  end
  if log_type == "Verbose" then
    lib.logger:Verbose(log_content)
  end
  if log_type == "Warn" then
    lib.logger:Warn(log_content)
  end
end

local function emit_message(log_type, text)
  if (text == "") then
    text = "[Empty String]"
  end
  create_log(log_type, text)
end

local function emit_table(log_type, t, indent, table_history)
  indent = indent or "."
  table_history = table_history or {}

  for k, v in pairs(t) do
    local vType = type(v)

    emit_message(log_type, indent .. "(" .. vType .. "): " .. tostring(k) .. " = " .. tostring(v))

    if (vType == "table") then
      if (table_history[v]) then
        emit_message(log_type, indent .. "Avoiding cycle on table...")
      else
        table_history[v] = true
        emit_table(log_type, v, indent .. "  ", table_history)
      end
    end
  end
end

function lib:dm(log_type, ...)
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if (type(value) == "table") then
      emit_table(log_type, value)
    else
      emit_message(log_type, tostring(value))
    end
  end
end
