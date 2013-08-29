local M = {}

local state = {
    tags = nil,   -- current set of tags
    tagstack = {},-- current tag stack: list of { i=num, tags={tag list} }
    tagidx = 0,   -- index into tagstack of current level
    lasttag = nil,-- last tag list
}
M.state = state

-- Load a tags file
local function load_tags()
    local tagf = io.open("tags") -- TODO: configurable tags file location
    local results = {}
    local pat = "^([^\t]*)\t([^\t]*)\t(.*)$"
    for line in tagf:lines() do
        local tname, fname, excmd = line:match(pat)
        local flags
        if tname then
          -- Initialise to an empty list if necessary
          if not results[tname] then results[tname] = {} end
          -- And append.
          local l = results[tname]  -- now guaranteed to be a table
          
          do
             -- Try to separate the ex command from extension fields
             local e,f = excmd:match('^(.-);"\t(.*)$')
             if e then
                 excmd = e
                 flags = f
             end
          end
          l[#l+1] = { filename=fname, excmd=excmd, flags=flags }
        end
    end
    tagf:close()
    state.tags = results
end

-- Return or load the tags
local function get_tags()
    -- TODO: check if tags file needs reloading
    if state.tags == nil then
        load_tags()
    end
    return state.tags
end

function M.find_tag_exact(name)
    local tags = get_tags()
    local result = tags[name]
    if result then
        state.tagstack[#state.tagstack+1] = { i=1, tags=result }
        state.lasttag = result
        state.tagidx = #state.tagstack
        return result[1]
    else
        return nil
    end
end

-- Go to a particular tag
function M.goto_tag(tag)
    io.open_file(tag.filename)
    local excmd = tag.excmd
    
    local _, pat = excmd:match("^([?/])(.*)%1$")
    if pat then
        -- TODO: properly handle regexes
        -- For now, assume it's a fixed string possibly with ^ and $ around it.
        pat = pat:match("^^?(.-)$?$")
        buffer.current_pos = 0
        buffer.search_anchor()
        local pos = buffer.search_next(0, pat)
        if pos >= 0 then
            buffer.goto_pos(pos)
        else
            gui.statusbar_text = "Not found: " .. pat
        end
    else
        -- May be a numeric pattern
    end
end

return M