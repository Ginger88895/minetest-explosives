local tnt_tables = {["neutrontnt:tnt1"] = {r=2},
					["neutrontnt:tnt2"] = {r=4},
					["neutrontnt:tnt3"] = {r=6},
					["neutrontnt:tnt4"] = {r=8},
					["neutrontnt:tnt5"] = {r=10},
					["neutrontnt:tnt6"] = {r=12},
					["neutrontnt:tnt7"] = {r=14},
					["neutrontnt:tnt8"] = {r=16},
					["neutrontnt:tnt9"] = {r=18},
					["neutrontnt:tnt10"] = {r=20},
					["neutrontnt:tnt11"] = {r=22},
					["neutrontnt:tnt12"] = {r=25},
					["neutrontnt:tnt13"] = {r=30},
					["neutrontnt:tnt14"] = {r=35},
					["neutrontnt:tnt15"] = {r=40},
					["neutrontnt:tnt16"] = {r=45},
					["neutrontnt:tnt17"] = {r=50},
					["neutrontnt:tnt18"] = {r=55},
					["neutrontnt:tnt19"] = {r=60},
					["neutrontnt:tnt20"] = {r=65},
}
				

tnt = {}
tnt.force = {}
tnt.accl = {} 

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

local animated_tnt_texture = combine_texture(16, 4, "default_tnt_top.png", "neutrontnt_top_burning_animated.png")
	
tnt_c_tnt = {}
tnt_c_tnt_burning = {}
tnt_types_int = {}

for name,data in pairs(tnt_tables) do
	
	tnt_types_int[#tnt_types_int] = name

	minetest.register_node(name, {
		description = "TNT ("..name..")",
		tiles = {"default_tnt_top.png", "default_tnt_bottom.png", "default_tnt_side.png"},
		groups = {dig_immediate=2, mesecon=2},
		sounds = default.node_sound_wood_defaults(),
		
		on_punch = function(pos, node, puncher)
			if puncher:get_wielded_item():get_name() == "default:torch" then
				if minetest.is_protected(pos, puncher:get_player_name()) then
					print(puncher:get_player_name() .. " tried to light TNT at " .. minetest.pos_to_string(pos))
					minetest.record_protection_violation(pos, puncher:get_player_name())
					return
				end
				minetest.sound_play("neutrontnt_ignite", {pos=pos})
				boom_neutrontnt(pos, 4, puncher)
				minetest.set_node(pos, {name=name.."_burning"})
			end
		end,
		
		mesecons = {
			effector = {
				action_on = function(pos, node)
					boom_neutrontnt(pos, 0)
				end
			},
		},
	})
	
	minetest.register_node(name.."_burning", {
	        tiles = {{name=animated_tnt_texture, animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=1}},
	        "default_tnt_bottom.png", "default_tnt_side.png"},
	        light_source = 5,
	        drop = "",
	        sounds = default.node_sound_wood_defaults(),
	})
	
	local prev = "neutrontnt:tnt"..tonumber(strs:rem_from_start(name, "neutrontnt:tnt"))-1
	if prev=="neutrontnt:tnt0" then prev="" end
	--print(name .. " is made from " .. prev)
	
	minetest.register_craft({
		output = name,
		recipe = {
			{"",prev,""},
			{"","neutrontnt:gunpowder",""},
			{"",prev,""},
		}
	})
	
	tnt_c_tnt[#tnt_c_tnt + 1] = minetest.get_content_id(name)
	tnt_c_tnt_burning[#tnt_c_tnt_burning + 1] = minetest.get_content_id(name.."_burning")

end


local function get_tnt_random(pos)
        return PseudoRandom(math.abs(pos.x+pos.y*3+pos.z*5)+15)
end





function boom_neutrontnt(pos, time, player)
	local id = minetest.get_node(pos).name
	boom_neutrontnt_id(pos, time, player, id)
end

function boom_neutrontnt_id(pos, time, player, id)
	minetest.after(time, function(pos)
		
		local tnt_range = tnt_tables[id].r * 2
	
		local t1 = os.clock()
		pr = get_tnt_random(pos)
		minetest.sound_play("neutrontnt_explode", {pos=pos, gain=1.5, max_hear_distance=tnt_range*64})
		
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
		minetest.add_particle(pos, {x=0,y=0,z=0}, {x=0,y=0,z=0}, 0.5, 16, false, "neutrontnt_explode.png")
		--minetest.set_node(pos, {name="tnt:boom_neutrontnt"})
		
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
		
		minetest.add_particlespawner(
			100, --amount
			1, --time
			{x=pos.x-(tnt_range / 2), y=pos.y-(tnt_range / 2), z=pos.z-(tnt_range / 2)}, --minpos
			{x=pos.x+(tnt_range / 2), y=pos.y+(tnt_range / 2), z=pos.z+(tnt_range / 2)}, --maxpos
			{x=-0, y=-0, z=-0}, --minvel
			{x=0, y=0, z=0}, --maxvel
			{x=-0.5,y=5,z=-0.5}, --minacc
			{x=0.5,y=5,z=0.5}, --maxacc
			0.1, --minexptime
			1, --maxexptime
			8, --minsize
			15, --maxsize
			true, --collisiondetection
			"neutrontnt_smoke.png" --texture
		)
		print(string.format("[tnt] exploded in: %.2fs", os.clock() - t1))
	end, pos)
end



---------------------  GUNPOWDER  -------------------


function burn(pos, player)
        local nodename = minetest.get_node(pos).name
        if  strs:starts(nodename, "neutrontnt:tnt") then
                minetest.sound_play("neutrontnt_ignite", {pos=pos})
                boom_neutrontnt(pos, 1, player)
                minetest.set_node(pos, {name=minetest.get_node(pos).name.."_burning"})
                return
        end
        if nodename ~= "neutrontnt:gunpowder" then
                return
        end
        minetest.sound_play("neutrontnt_gunpowder_burning", {pos=pos, gain=2})
        minetest.set_node(pos, {name="neutrontnt:gunpowder_burning"})
        
        minetest.after(1, function(pos)
                if minetest.get_node(pos).name ~= "neutrontnt:gunpowder_burning" then
                        return
                end
                minetest.after(0.5, function(pos)
                        minetest.remove_node(pos)
                end, {x=pos.x, y=pos.y, z=pos.z})
                for dx=-1,1 do
                        for dz=-1,1 do
                                for dy=-1,1 do
                                        pos.x = pos.x+dx
                                        pos.y = pos.y+dy
                                        pos.z = pos.z+dz
                                        
                                        if not (math.abs(dx) == 1 and math.abs(dz) == 1) then
                                                if dy == 0 then
                                                        burn({x=pos.x, y=pos.y, z=pos.z}, player)
                                                else
                                                        if math.abs(dx) == 1 or math.abs(dz) == 1 then
                                                                burn({x=pos.x, y=pos.y, z=pos.z}, player)
                                                        end
                                                end
                                        end
                                        
                                        pos.x = pos.x-dx
                                        pos.y = pos.y-dy
                                        pos.z = pos.z-dz
                                end
                        end
                end
        end, pos)
end


minetest.register_node("neutrontnt:gunpowder", {
        description = "Gun Powder",
        drawtype = "raillike",
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        tiles = {"neutrontnt_gunpowder.png",},
        inventory_image = "neutrontnt_gunpowder_inventory.png",
        wield_image = "neutrontnt_gunpowder_inventory.png",
        selection_box = {
                type = "fixed",
                fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
        },
        groups = {dig_immediate=2,attached_node=1},
        sounds = default.node_sound_leaves_defaults(),
        
        on_punch = function(pos, node, puncher)
                if puncher:get_wielded_item():get_name() == "default:torch" then
                        burn(pos, puncher)
                end
        end,
})

minetest.register_node("neutrontnt:gunpowder_burning", {
        drawtype = "raillike",
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        light_source = 5,
        tiles = {{name="neutrontnt_gunpowder_burning_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=1}}},
        selection_box = {
                type = "fixed",
                fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
        },
        drop = "",
        groups = {dig_immediate=2,attached_node=1},
        sounds = default.node_sound_leaves_defaults(),
})

local tnt_plus_gunpowder = {"neutrontnt:gunpowder"}
for name,data in pairs(tnt_tables) do
	tnt_plus_gunpowder[#tnt_plus_gunpowder+1] = name
end


minetest.register_abm({
        nodenames = tnt_plus_gunpowder,
        neighbors = {"fire:basic_flame"},
        interval = 2,
        chance = 10,
        action = function(pos, node)
                if tnt_tables[node.name]~=nil then
                        boom_neutrontnt({x=pos.x, y=pos.y, z=pos.z}, 0)
                else
                        burn(pos)
                end
        end
})

minetest.register_abm({
        nodenames = tnt_plus_gunpowder,
        neighbors = {"tnt:gunpowder"},
        interval = 2,
        chance = 10,
        action = function(pos, node)
                if tnt_tables[node.name]~=nil then
                        boom_neutrontnt({x=pos.x, y=pos.y, z=pos.z}, 0)
                else
                        burn(pos)
                end
        end
})

minetest.register_craft({
        output = "neutrontnt:gunpowder",
        type = "shapeless",
        recipe = {"default:coal_lump", "default:gravel", "default:dirt"}
})


tnt_c_air = minetest.get_content_id("air")
tnt_c_fire = minetest.get_content_id("fire:basic_flame")

