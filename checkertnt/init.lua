local tnt_tables = {["checkertnt:tnt1"] = {r=1},
					["checkertnt:tnt2"] = {r=2},
					["checkertnt:tnt3"] = {r=3},
					["checkertnt:tnt4"] = {r=4},
					["checkertnt:tnt5"] = {r=5},
					["checkertnt:tnt6"] = {r=7},
					["checkertnt:tnt7"] = {r=9},
					["checkertnt:tnt8"] = {r=11},
					["checkertnt:tnt9"] = {r=13},
					["checkertnt:tnt10"] = {r=15},
					["checkertnt:tnt11"] = {r=20},
					["checkertnt:tnt12"] = {r=25},
					["checkertnt:tnt13"] = {r=30},
					["checkertnt:tnt14"] = {r=35},
					["checkertnt:tnt15"] = {r=40},
					["checkertnt:tnt16"] = {r=50},
					["checkertnt:tnt17"] = {r=60},
					["checkertnt:tnt18"] = {r=70},
					["checkertnt:tnt19"] = {r=85},
					["checkertnt:tnt20"] = {r=100},
}
				
local function is_tnt(name)
	if tnt_tables[name]~=nil then return true end
	return false
end

local function combine_texture(texture_size, frame_count, texture, ani_texture)
        local l = frame_count
        local px = 0
        local combine_textures = ":0,"..px.."="..texture
        while l ~= 0 do
                combine_textures = combine_textures..":0,"..px.."="..texture
                px = px+texture_size
                l = l-1
        end
        return ani_texture.."^[combine:"..texture_size.."x"..texture_size*frame_count..":"..combine_textures.."^"..ani_texture
end

local animated_tnt_texture = combine_texture(16, 4, "tnt_top.png", "checkertnt_top_burning_animated.png")

for name,data in pairs(tnt_tables) do

	minetest.register_node(name, {
		description = "TNT ("..name..")",
		tiles = {"tnt_top.png", "tnt_bottom.png", "tnt_side.png"},
		groups = {dig_immediate=2, mesecon=2, not_in_creative_inventory=1},
		sounds = default.node_sound_wood_defaults(),
		
		on_punch = function(pos, node, puncher)
			if puncher:get_wielded_item():get_name() == "default:torch" then
				if minetest.is_protected(pos, puncher:get_player_name()) then
					print(puncher:get_player_name() .. " tried to light TNT at " .. minetest.pos_to_string(pos))
					minetest.record_protection_violation(pos, puncher:get_player_name())
					return
				end
				minetest.sound_play("checkertnt_ignite", {pos=pos})
				boom_checkertnt(pos, 4)
				minetest.set_node(pos, {name=name.."_burning"})
			end
		end,
		
		mesecons = {
			effector = {
				action_on = function(pos, node)
					boom_checkertnt(pos, 0)
				end
			},
		},
	})
	
	minetest.register_node(name.."_burning", {
	        tiles = {{name=animated_tnt_texture, animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=1}},
	        "tnt_bottom.png", "tnt_side.png"},
	        light_source = 5,
	        drop = "",
	        sounds = default.node_sound_wood_defaults(),
	})
	
	local prev = "checkertnt:tnt"..tonumber(strs:rem_from_start(name, "checkertnt:tnt"))-1
	if prev=="checkertnt:tnt0" then prev="" end
	--print(name .. " is made from " .. prev)
	
	minetest.register_craft({
		output = name,
		recipe = {
			{"",prev,""},
			{"","checkertnt:gunpowder",""},
			{"",prev,""},
		}
	})
	
end

function boom_checkertnt(pos, time)
	local id = minetest.get_node(pos).name
	boom_checkertnt_id(pos, time, id)
end

function boom_checkertnt_id(pos, time, id)
	minetest.after(time, function(pos)
		
		local tnt_range = tnt_tables[id].r * 2
	
		local t1 = os.clock()
		minetest.sound_play("checkertnt_explode", {pos=pos, gain=1.5, max_hear_distance=tnt_range*64})
		
		minetest.remove_node(pos)
		
--		local manip = minetest.get_voxel_manip()
--		local width = tnt_range
--		local emerged_pos1, emerged_pos2 = manip:read_from_map({x=pos.x-width, y=pos.y-width, z=pos.z-width},
--		{x=pos.x+width, y=pos.y+width, z=pos.z+width})
--		area = VoxelArea:new{MinEdge=emerged_pos1, MaxEdge=emerged_pos2}
--		nodes = manip:get_data()
--		
--		local p_pos = area:index(pos.x, pos.y, pos.z)
--		nodes[p_pos] = tnt_c_air
		minetest.add_particle(pos, {x=0,y=0,z=0}, {x=0,y=0,z=0}, 0.5, 16, false, "checkertnt_explode.png")
		--minetest.set_node(pos, {name="tnt:boom_checkertnt"})
		
		local objects = minetest.get_objects_inside_radius(pos, tnt_range/2)
		for _,obj in ipairs(objects) do
			if obj:is_player() or (obj:get_luaentity() and obj:get_luaentity().name ~= "__builtin:item") then
				local obj_p = obj:getpos()
				local vec = {x=obj_p.x-pos.x, y=obj_p.y-pos.y, z=obj_p.z-pos.z}
				local dist = (vec.x^2+vec.y^2+vec.z^2)^0.5
				local damage = 0
				if dist < tnt_range/3.0 then damage = tnt_range end
				obj:punch(obj, 1.0, {
					full_punch_interval=1.0,
					damage_groups={fleshy=damage},
				}, vec)
			end
		end
		
		local storedPoses = {}
		
		for dx=-tnt_range,tnt_range do
			for dz=-tnt_range,tnt_range do
				for dy=-tnt_range,tnt_range do
					local p = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
					local nodename = minetest.get_node(p).name
					if is_tnt(nodename)==true then
						minetest.remove_node(p)
						boom_checkertnt_id(p, 0.5, nodename) -- was {x=p.x, y=p.y, z=p.z}
					elseif (dx+dz+dy) % 2 == 0 then
						minetest.remove_node(p)
					end
				end
			end
		end
		
		print(string.format("[tnt] exploded in: %.2fs", os.clock() - t1))
	end, pos)
end

---------------------  GUNPOWDER  -------------------

minetest.register_craftitem("checkertnt:gunpowder", {
        description = "Gun Powder",
        inventory_image = "checkertnt_gunpowder_inventory.png",
})

minetest.register_craft({
        output = "checkertnt:gunpowder",
        type = "shapeless",
        recipe = {"default:coal_lump", "default:gravel", "default:cobble"}
})

