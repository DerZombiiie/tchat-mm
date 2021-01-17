---
-- teamchat-maxmsg v-0.1 by DerZombiiie
-- addon to coras teamchat, so requires that clientmod to work.
--[[
--- Methods/vars ---
mtchat.send(msg) // sends msg in teamchat

--- Commands ---
.m to send a message

]]--
local function split (inputstr, sep) -- copied from stackoverflow
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end
local function has_value (tab, val) -- copied from stackoverflow (again)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end
local function debug (msg) -- only prints if setting debug is on
    if minetest.settings:get("tc_mm_debug") then
        print (msg)
    end
end
---

--- [[ Settings ]] ---
mtchat = {}
local msg_prefix = minetest.settings:get("tc_mm_msg_prefix")
local prefix = minetest.settings:get("tc_mm_prefix")

minetest.register_on_receiving_chat_message(
    function(message)
        if message:match("^"..msg_prefix) then
            local contents = string.split(message, ": ")
            local source = table.remove(contents, 1)
            source = source:gsub(msg_prefix, ""):gsub(" ","")
            contents = table.concat(contents, ": ")
            debug("[DEBUG] Content: '" .. contents.."' | From: '"..source.."'") 
            if contents:match("^"..prefix) then
                if has_value(tchat.team_online, source) then
                    local tmsg = string.sub(contents, string.len(prefix)+1)
                    --tmsg = 'return {["queue"] = {"p1", "p2"}, ["msg"] = "<DZ>: test"}'
                    debug("[DEBUG] Teammsg: "..tmsg)
                    local data = minetest.deserialize(tmsg)

                    if not data or not data.queue or not data.msg then return end
                    debug("[DEBUG] From: "..source..";  Queue: "..table.concat(data.queue, ", ").."; Message: "..data.msg..";")
                    if not data.queue[1] then
                        debug("[DEBUG] last in chain not releying to anyone")
                        tchat.chat_append(data.msg)
                    else
                        local nextplayer = data.queue[1]
                        table.remove(data.queue, 1) 
                        local send_msg = "/msg "..nextplayer.." "..prefix..minetest.serialize(data);
                        tchat.chat_append(data.msg)
                        
                        debug("[DEBUG] executing"..send_msg)
                        minetest.send_chat_message(send_msg)
                    end
                end



            end
            --[[
            [T0.1]p1|p2|p3|p4:MSG

            ]]--
        end
    end
)

--[[ -------------------- Public methods -------------------]]--
function mtchat.send(message)
    local send_msg = "/msg "..tchat.team_online[1].." "..prefix
    local data = {}
    data.msg = "<"..minetest.localplayer:get_name()..">: "..message
    local queue = tchat.team_online
    table.remove(queue, 1)
    if(queue[1]) then
        data.queue = queue
    else
        data.queue = {}
    end
    send_msg = send_msg .. minetest.serialize(data)    

    debug("[DEBUG] Sending msg by executing: "..send_msg)
    minetest.send_chat_message(send_msg)
end
--[[ ------------------------ CMDs ------------------------ ]]--
minetest.register_chatcommand("m", {
    params = "<message>",
    description = "Send a message to your Team.",
    func = function(message)
        if not message then
            print("No message")
            return
        end
        mtchat.send(message)
    end
})