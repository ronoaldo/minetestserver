print("Shutting down in 5 seconds")
minetest.after(5, function()
    minetest.request_shutdown("", false, 1)
end)