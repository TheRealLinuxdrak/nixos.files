return {
    setup = function()
        ps.sub("cd", function()
            local cwd = cx.active.current.cwd
            if cwd then
                Command("zoxide"):arg("add"):arg(tostring(cwd)):spawn()
            end
        end)
    end,
}
