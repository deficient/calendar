-- original code made by Bzed and published on http://awesome.naquadah.org/wiki/Calendar_widget
-- modified by Marc Dequènes (Duck) <Duck@DuckCorp.org> (2009-12-29), under the same licence,
-- and with the following changes:
--   + transformed to module
--   + the current day formating is customizable

-- captures
local os = os
local capi = {
    mouse = mouse,
    screen = screen,
}
local awful = require("awful")
local naughty = require("naughty")


------------------------------------------
-- utility functions
------------------------------------------

-- string
local function format_date(format, date)
    return os.date(format, os.time(date))
end

local function fakelen(s, n)
  return setmetatable({}, {
    __tostring = function() return s end,
    __len      = function() return n end,
  })
end

local function highlight(s, attr)
  if not attr then return s end
  local span = "<span %s>%s</span>"
  return fakelen(span:format(attr, s), #s)
end

-- functional
local function table_transpose(rows)
  local cols = {}
  for i, row in ipairs(rows) do
    for j, val in ipairs(row) do
      cols[j] = cols[j] or {}
      cols[j][i] = val
    end
  end
  return cols
end

local function length(x)
  return #x
end

local function table_map(func, tab)
  local result = {}
  for i, v in ipairs(tab) do
    result[i] = func(v, i)
  end
  return result
end

local function table_reduce(func, start, tab)
  local result = start
  for _, v in ipairs(tab) do
    result = func(result, v)
  end
  return result
end

-- table -> string
local function tabulate(rows, gap)
  local fill = ' '
  local function format_col(col, i)
    local len = table_reduce(math.max, 0, table_map(length, col))
    return table_map(function(v) return fill:rep(len-#v) .. tostring(v) end, col)
  end
  local function format_row(row)
    return table.concat(row, gap)
  end
  local cols = table_map(format_col, table_transpose(rows))
  local rows = table_map(format_row, table_transpose(cols))
  return table.concat(rows, "\n")
end


------------------------------------------
-- calendar popup widget
------------------------------------------

local calendar = {}

function calendar:new(args)
    return setmetatable({}, {__index = self}):init(args)
end

function calendar:init(args)
    -- first day of week: monday=1, …, sunday=7
    self.fdow       = args.fdow       or 1
    -- notification area:
    self.html       = args.html       or '<span font_desc="monospace">\n%s</span>'
    -- highlight current date:
    self.day_fmt    = args.day_fmt    or '%i'
    self.highlight  = args.highlight  or 'color="#00ff00"'
    self.page_title = args.page_title or '%B %Y'    -- month year
    self.col_title  = args.col_title  or '%a'       -- weekday
    -- Date equality check is based on day_id. We deliberately ignore the year
    -- to highlight the same day in different years:
    self.day_id     = args.day_id     or '%m-%d'
    return self
end

function calendar:page(month, year)

    local today = format_date(self.day_id)

    -- 2001 started with a monday:
    local d0 = format_date("*t", {year=2001, month=1,       day=self.fdow })
    local dA = format_date("*t", {year=year, month=month,   day=1         })
    local dB = format_date("*t", {year=year, month=month+1, day=0         })
    local tA =                   {year=year, month=month,   day=1         }
    local colA = (dA.wday - d0.wday) % 7

    local page_title = format_date(self.page_title, tA)

    local function wday(d)
        return format_date(self.col_title, {
            year  = d0.year,
            month = d0.month,
            day   = d0.day + d,
        })
    end

    local rows = {}

    -- column titles (weekday)
    table.insert(rows, {"", wday(0), wday(1), wday(2), wday(3), wday(4), wday(5), wday(6)})

    -- empty space before first day
    local week = {format_date("%V", tA)}
    while #week < 1+colA do
        table.insert(week, "-")
    end

    -- iterate all days of the month
    for day = 1, dB.day do
        if #week == 8 then
            table.insert(rows, week)
            week = {format_date("%V", {year=year, month=month, day=day})}
        end
        local text = self.day_fmt:format(day)
        if today == format_date(self.day_id, {day=day, month=month, year=year}) then
            text = highlight(text, self.highlight)
        end
        table.insert(week, text)
    end

    while #week < 8 do
        table.insert(week, "-")
    end
    table.insert(rows, week)

    local page = tabulate(rows, " ")

    return page_title, self.html:format(page)
end

function calendar:switch(months)
    self:show(self.year, self.month+months)
end

function calendar:show(year, month)
    local today = os.time()
    self.month  = month or os.date('%m', today)
    self.year   = year  or os.date('%Y', today)
    local title, text = self:page(self.month, self.year)

    self:hide()
    self.notification = naughty.notify({
        title = title,
        text = text,
        timeout = 0,
        hover_timeout = 0.5,
        screen = capi.mouse.screen,
    })
end

function calendar:hide()
    if self.notification then
        naughty.destroy(self.notification)
        self.notification = nil
    end
end

function calendar:attach(widget)
    widget:connect_signal('mouse::enter', function() self:show() end)
    widget:connect_signal('mouse::leave', function() self:hide() end)
    widget:buttons(awful.util.table.join(
        awful.button({         }, 1, function() self:switch( -1) end),
        awful.button({         }, 3, function() self:switch(  1) end),
        awful.button({         }, 4, function() self:switch( -1) end),
        awful.button({         }, 5, function() self:switch(  1) end),
        awful.button({ 'Shift' }, 1, function() self:switch(-12) end),
        awful.button({ 'Shift' }, 3, function() self:switch( 12) end),
        awful.button({ 'Shift' }, 4, function() self:switch(-12) end),
        awful.button({ 'Shift' }, 5, function() self:switch( 12) end)
    ))
end

return setmetatable(calendar, {
    __call = calendar.new,
})
