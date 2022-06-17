local utils = require'utils'

local xml2lua = require'internal.xml2lua'
local tree_handler = require'internal.xmlhandler.tree'
-- dont flatten single element vectors of tags
tree_handler.options.noreduce = true
local xml_parser = xml2lua.parser(tree_handler)
local suffix_tree = require'utils.suffix-tree'

local getCounter = function(source, type)
    source.counter = source.counter or {};

    local f = utils.filter(source.counter, function (counter)
        return counter._attr.type == type;
    end)

    return f[1] or {
            _attr = {
                covered = 0,
                missed = 0
            }
    };
end

local unpackage = function(report)

    local output = suffix_tree()

        utils.foreach(report.packages[1].package, function (package)
          utils.foreach(package.classes[1].class, function (class)
            local fullPath = class._attr.filename

            local classCov = {
                title = class._attr.name,
                file = fullPath,
                lines = {
                    -- details = {[1]={line=93,hit=10},[2]={line=94,hit=0}}
                    details = not class.lines[1].line and {} or utils.map(class.lines[1].line, function (l)
                        return {
                            line = tonumber( l._attr.number ),
                            hit = tonumber( l._attr.hits )
                        };
                    end)
                },
            }

            -- classCov.branches.converted = {}
            -- utils.foreach(classCov.branches.details, function(b)
            --     if classCov.branches.converted[b.line] == nil then
            --         classCov.branches.converted[b.line] = true;
            --     end

            --     classCov.branches.converted[b.line] = classCov.branches.converted[b.line] and b.taken;
            -- end)

            -- print(vim.inspect(classCov))
            output:set(classCov.file, classCov)

        end)
      end)

    return output
end

local parse = function(file_path)
  local xml_content = xml2lua.loadFile(file_path)
  xml_parser:parse(xml_content)
  return unpackage(tree_handler.root.coverage[1])
end

return {
    parse = parse,
}
