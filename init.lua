local csw = {}

local cur = 1
local initial_cur = cur
local cs = { {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }

---@diagnostic disable
local xplr = xplr
---@diagnostic enable

xplr.fn.custom.context_switch = {}

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
    return { (i == cur and '-> ' or '   ') .. tostring(i), pwd, fss }
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

csw.get_contexts = function()
    return cs
end

local layout_height = 32

csw.default_custom_content = {
    CustomContent = {
        title = 'Context Switch',
        body = {
            DynamicTable = {
                widths = {
                    { Percentage = 5 },
                    { Percentage = 60 },
                    { Percentage = 35 },
                },
                col_spacing = 1,
                render = 'custom.context_switch.render',
            },
        },
    },
}

csw.builtin_layouts = {
    without_help = {
        Vertical = {
            config = {
                constraints = {
                    { Percentage = 100 - layout_height },
                    { Percentage = layout_height },
                },
            },
            splits = {
                'Table',
                csw.default_custom_content,
            },
        },
    },
    default = {
        Vertical = {
            config = {
                constraints = {
                    { Percentage = 100 - layout_height },
                    { Percentage = layout_height },
                },
            },
            splits = {
                {
                    Horizontal = {
                        config = {
                            constraints = {
                                { Percentage = 70 },
                                { Percentage = 30 },
                            },
                        },
                        splits = {
                            'Table',
                            'HelpMenu',
                        },
                    },
                },
                csw.default_custom_content,
            },
        },
    },
}

csw.setup = function(args)
    args = args or {}
    args.mode = args.mode or 'default'
    args.key = args.key or 'ctrl-s'
    if not args.layout_height or args.layout_height < 1 or args.layout_height > 99 then
        args.layout_height = 32
    end
    layout_height = args.layout_height
    args.layout = args.layout or csw.builtin_layouts.default

    xplr.fn.custom.context_switch.render = function(_)
        local t = { { '   #', 'Path', 'Sort & Filter' } }
        for k, v in pairs(cs) do
            if k ~= 1 then
                table.insert(t, rend_ins(k - 1, v))
            end
        end
        table.insert(t, rend_ins(0, cs[1]))
        return t
    end

    xplr.fn.custom.context_switch.next = function(_)
        if cur == 9 then
            cur = 0
        else
            cur = cur + 1
        end
    end

    xplr.fn.custom.context_switch.prev = function(_)
        if cur == 0 then
            cur = 9
        else
            cur = cur - 1
        end
    end

    xplr.fn.custom.context_switch.next_initialized = function(_)
        while true do
            xplr.fn.custom.context_switch.next()
            if cs[cur + 1].pwd ~= nil then
                break
            end
        end
    end

    xplr.fn.custom.context_switch.prev_initialized = function(_)
        while true do
            xplr.fn.custom.context_switch.prev()
            if cs[cur + 1].pwd ~= nil then
                break
            end
        end
    end

    xplr.fn.custom.context_switch.reset_cur = function(_)
        cur = initial_cur
    end

    xplr.fn.custom.context_switch.clear_cur = function(_)
        cs[cur + 1] = {}
    end

    xplr.fn.custom.context_switch.to_cur = function(app)
        initial_cur = cur
        local c = cs[cur + 1]
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

    xplr.fn.custom.context_switch.to_input = function(app)
        local num = tonumber(app.input_buffer)
        if num ~= nil then
            cur = num
            return xplr.fn.custom.context_switch.to_cur(app)
        end
    end

    xplr.config.modes.custom.context_switch = {
        name = 'context switch',
        key_bindings = {
            on_key = {
                up = {
                    help = 'prev',
                    messages = {
                        { CallLuaSilently = 'custom.context_switch.prev' },
                    },
                },
                down = {
                    help = 'next',
                    messages = {
                        { CallLuaSilently = 'custom.context_switch.next' },
                    },
                },
                tab = {
                    help = 'next initialized',
                    messages = {
                        { CallLuaSilently = 'custom.context_switch.next_initialized' },
                    },
                },
                ['back-tab'] = {
                    help = 'prev initialized',
                    messages = {
                        { CallLuaSilently = 'custom.context_switch.prev_initialized' },
                    },
                },
                enter = {
                    help = 'switch',
                    messages = {
                        { CallLuaSilently = 'custom.context_switch.to_cur' },
                        'PopMode',
                    },
                },
                esc = {
                    help = 'cancel',
                    messages = {
                        { CallLuaSilently = 'custom.context_switch.reset_cur' },
                        'PopMode',
                    },
                },
                ['ctrl-c'] = {
                    help = 'terminate',
                    messages = { 'Terminate' },
                },
                ['z'] = {
                    help = 'clear context',
                    messages = {
                        { CallLuaSilently = 'custom.context_switch.clear_cur' },
                    },
                },
            },
            on_number = {
                help = 'switch to',
                messages = {
                    'BufferInputFromKey',
                    { CallLuaSilently = 'custom.context_switch.to_input' },
                    'PopMode',
                },
            },
            default = {},
        },
        layout = args.layout,
    }

    local on_key = xplr.config.modes.custom.context_switch.key_bindings.on_key
    on_key.j = on_key.down
    on_key.k = on_key.up
    on_key.q = on_key.esc
    on_key['ctrl-n'] = on_key.tab
    on_key['ctrl-p'] = on_key['back-tab']

    xplr.fn.custom.context_switch.capture = function(app)
        local c = cs[cur + 1]
        capture(c, app)
    end

    xplr.config.modes.builtin[args.mode].key_bindings.on_key[args.key] = {
        help = 'context switch',
        messages = {
            'PopMode',
            { CallLuaSilently = 'custom.context_switch.capture' },
            { SwitchModeCustom = 'context_switch' },
        },
    }
end

return csw
