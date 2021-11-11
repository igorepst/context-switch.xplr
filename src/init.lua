local csw = {}

local cur = 1
local cs = {}

---@diagnostic disable
local xplr = xplr
---@diagnostic enable

local rend_ins = function(i, v)
    local pwd, fss = '?', ''
    if v.pwd then
        pwd = v.pwd
        local appco = xplr.config.general
        local sep = appco.sort_and_filter_ui.separator.format
        sep = sep or ' '
        if v.filters then
            local fco = appco.sort_and_filter_ui.filter_identifiers
            for _, vf in pairs(v.filters) do
                local f = fco[vf.filter]
                if f then
                    fss = fss .. f.format .. vf.input .. sep
                end
            end
        end
        if v.sorters then
            local fco = appco.sort_and_filter_ui.sorter_identifiers
            local fw = appco.sort_and_filter_ui.sort_direction_identifiers.forward.format
            fw = fw or 'F'
            local rw = appco.sort_and_filter_ui.sort_direction_identifiers.reverse.format
            rw = rw or 'R'
            for _, vf in pairs(v.sorters) do
                local f = fco[vf.sorter]
                if f then
                    fss = fss .. f.format .. (vf.reverse and rw or fw) .. sep
                end
            end
        end
        fss = fss:gsub(sep .. '$', '')
    end
    return { i == cur and '->' or '', tostring(i), pwd, fss }
end

local capture = function(c, app)
    c.pwd = app.pwd
    c.focused_path = app.focused_node.absolute_path
    c.sorters = app.explorer_config.sorters
    c.filters = app.explorer_config.filters
end

csw.get_current_context_num = function()
    return cur
end

csw.setup = function(args)
    args = args or {}
    args.mode = args.mode or 'default'
    args.key = args.key or 'ctrl-s'
    if not args.layout_height or args.layout_height < 1 or args.layout_height > 99 then
        args.layout_height = 32
    end

    xplr.fn.custom.render_context_switch_layout = function(_)
        local t = { { 'Cur', '#', 'Path', 'Sort & Filter' } }
        for k, v in pairs(cs) do
            if k ~= 1 then
                table.insert(t, rend_ins(k - 1, v))
            end
        end
        table.insert(t, rend_ins(0, cs[1]))
        return t
    end

    xplr.config.modes.custom.context_switch = {
        name = 'context switch',
        key_bindings = {
            on_key = {
                ['ctrl-c'] = {
                    help = 'terminate',
                    messages = { 'Terminate' },
                },
                esc = {
                    help = 'escape',
                    messages = { 'PopMode' },
                },
                ['q'] = {
                    help = 'quit',
                    messages = { 'Quit' },
                },
            },
            default = { messages = {} },
        },
        layout = {
            Vertical = {
                config = {
                    constraints = {
                        { Percentage = 100 - args.layout_height },
                        { Percentage = args.layout_height },
                    },
                },
                splits = {
                    'Table',
                    {
                        CustomContent = {
                            title = 'Context Switch',
                            body = {
                                DynamicTable = {
                                    widths = {
                                        { Percentage = 5 },
                                        { Percentage = 5 },
                                        { Percentage = 60 },
                                        { Percentage = 30 },
                                    },
                                    col_spacing = 1,
                                    render = 'custom.render_context_switch_layout',
                                },
                            },
                        },
                    },
                },
            },
        },
    }

    xplr.fn.custom['context_switch_to_helper'] = function(app)
        local c = cs[cur + 1]
        capture(c, app)
    end

    xplr.config.modes.builtin[args.mode].key_bindings.on_key[args.key] = {
        help = 'context switch',
        messages = {
            'PopMode',
            { CallLuaSilently = 'custom.context_switch_to_helper' },
            { SwitchModeCustom = 'context_switch' },
        },
    }

    for i = 0, 9 do
        local c = {}
        table.insert(cs, c)
        xplr.fn.custom['context_switch_to_' .. i] = function(app)
            cur = i
            if c.pwd then
                local msgs = {
                    { ChangeDirectory = c.pwd },
                }
                if c.filters then
                    table.insert(msgs, 'ClearNodeFilters')
                    for _, v in pairs(c.filters) do
                        table.insert(msgs, { AddNodeFilter = { filter = v.filter, input = v.input } })
                    end
                end
                if c.sorters then
                    table.insert(msgs, 'ClearNodeSorters')
                    for _, v in pairs(c.sorters) do
                        table.insert(msgs, { AddNodeSorter = { sorter = v.sorter, reverse = v.reverse } })
                    end
                end
                if c.focused_path then
                    table.insert(msgs, { FocusPath = c.focused_path })
                end
                return msgs
            else
                capture(c, app)
            end
        end
        xplr.config.modes.custom.context_switch.key_bindings.on_key[tostring(i)] = {
            help = 'context switch ' .. i,
            messages = {
                { CallLuaSilently = 'custom.context_switch_to_' .. i },
                'PopMode',
            },
        }
    end
end

return csw
