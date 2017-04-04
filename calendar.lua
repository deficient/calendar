-- original code made by Bzed and published on http://awesome.naquadah.org/wiki/Calendar_widget
-- modified by Marc Dequènes (Duck) <Duck@DuckCorp.org> (2009-12-29), under the same licence,
-- and with the following changes:
--   + transformed to module
--   + the current day formating is customizable

local string = string
--local print = print
local tostring = tostring
local os = os
local capi = {
    mouse = mouse,
    screen = screen
}
local awful = require("awful")
local naughty = require("naughty")

local calendar = {}
local dformat = {
    today = '<b><span color="#00ff00">%2i</span></b>',
    anyday = '%2i'
}

local function fdate(format, table)
    return os.date(format, os.time(table))
end

local function displayMonth(month, year, weekStart)
    local highlightRequire = "%m-%d"
    local today = os.date(highlightRequire)
    -- weekStart=1 <=> monday; 2001 started with a monday
    local tA = os.time({year=year, month=month, day=1})
    local d0 = fdate("*t", {year=2001, month=1, day=weekStart})
    local dA = fdate("*t", {year=year, month=month, day=1})
    local dB = fdate("*t", {year=year, month=month+1, day=0})
    local colA = (dA.wday - d0.wday) % 7

    -- print header
    local page = os.date("%B %Y\n", tA)

    -- print week-day names (table head row)
    page = page .. "\n    "
    for x = 0,6 do
        page = page .. fdate("%a ", {year=d0.year, month=d0.month, day=d0.day+x})
    end

    -- print empty space before first day
    page = page .. "\n" .. os.date(" %V", tA)
    local column = 0
    while column < colA do
        page = page .. "   -"
        column = column + 1
    end

    -- iterate all days of the month
    local nLines = 1
    for day = 1,dB.day do
        if column == 7 then
            column = 0
            nLines = nLines + 1
            page = page .. "\n" .. fdate(" %V", {year=year, month=month, day=day})
        end
        if today == fdate(highlightRequire, {day=day, month=month, year=year}) then
            page = page .. "  " .. dformat.today:format(day)
        else
            page = page .. "  " .. dformat.anyday:format(day)
        end
        column = column + 1
    end
    while column < 7 do
        page = page .. "   -"
        column = column + 1
    end
    return page
end

local function switchNaughtyMonth(switchMonths)
    if (#calendar < 3) then return end
    local swMonths = switchMonths or 1

    local month = calendar[1] + swMonths
    local year = calendar[2]

    calendar[1] = month
    -- TODO: just redraw calendar instead of recreating entirely
    naughty.destroy(calendar[3])
    calendar[3] = naughty.notify({
                text = string.format('<span font_desc="%s">%s</span>', "monospace", displayMonth(month, year, 1)),
                timeout = 0,
                hover_timeout = 0.5,
                screen = capi.mouse.screen
            })

    -- the following does NOT work (doesnt recalculate boundaries):
    -- calendar[3].box.widgets[2].text = string.format('<span font_desc="%s">%s</span>', "monospace", displayMonth(calendar[1], calendar[2], 1))
end

local function addCalendarToWidget(mywidget, custom_current_day_format)
    if custom_current_day_format then
        dformat.today = custom_current_day_format
    end

    mywidget:connect_signal('mouse::enter', function ()
        local month, year = os.date('%m'), os.date('%Y')
        calendar = { month, year,
            naughty.notify({
                text = string.format('<span font_desc="%s">%s</span>', "monospace", displayMonth(month, year, 1)),
                timeout = 0,
                hover_timeout = 0.5,
                screen = capi.mouse.screen
            })
        }
    end)
    mywidget:connect_signal('mouse::leave', function () naughty.destroy(calendar[3]) end)

    mywidget:buttons(awful.util.table.join(
        awful.button({ }, 1, function()
            switchNaughtyMonth(-1)
        end),
        awful.button({ }, 3, function()
            switchNaughtyMonth(1)
        end),
        awful.button({ }, 4, function()
            switchNaughtyMonth(-1)
        end),
        awful.button({ }, 5, function()
            switchNaughtyMonth(1)
        end),
        awful.button({ 'Shift' }, 1, function()
            switchNaughtyMonth(-12)
        end),
        awful.button({ 'Shift' }, 3, function()
            switchNaughtyMonth(12)
        end),
        awful.button({ 'Shift' }, 4, function()
            switchNaughtyMonth(-12)
        end),
        awful.button({ 'Shift' }, 5, function()
            switchNaughtyMonth(12)
        end)
    ))
end

return {
  addCalendarToWidget=addCalendarToWidget,
}
