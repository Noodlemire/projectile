--[[
Research N' Duplication
Copyright (C) 2020 Noodlemire

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
--]]

--A basic arrow
minetest.register_craftitem("projectile:arrow", {
	description = "Arrow",
	inventory_image = "projectile_arrow.png",
})

--An arrow that burns flammable nodes that it touches
if fire then
	minetest.register_craftitem("projectile:arrow_fire", {
		description = "Fire Arrow",
		inventory_image = "projectile_arrow_fire.png",
	})
end

--An arrow with exceptionally high velocity
minetest.register_craftitem("projectile:arrow_high_velocity", {
	description = "High Velocity Arrow",
	inventory_image = "projectile_arrow_high_velocity.png",
})

--An arrow that explodes on contact, rather than dealing direct damage.
if tnt then
	minetest.register_craftitem("projectile:arrow_bomb", {
		description = "Bomb Arrow",
		inventory_image = "projectile_arrow_bomb.png",
	})
end



--Two cobblestone blocks can shapelessly be used to craft 18 rocks.
--Two are used since it's very possible that other mods use one rock to make other things.
minetest.register_craft({
	type = "shapeless",
	output = "hardtrees:rock 18",
	recipe = {"default:cobble", "default:cobble"}
})

--If the player no longer needs rocks, 9 can be crafted back into a cobblestone block.
minetest.register_craft({
	output = "default:cobble",
	recipe = {
		{"hardtrees:rock", "hardtrees:rock", "hardtrees:rock"},
		{"hardtrees:rock", "hardtrees:rock", "hardtrees:rock"},
		{"hardtrees:rock", "hardtrees:rock", "hardtrees:rock"}
	}
})

--Four sticks in a diagonal Y, with a string on top, makes a slingshot.
minetest.register_craft({
	output = "projectile:slingshot",
	recipe = {
		{"", "default:stick", "farming:string"},
		{"", "default:stick", "default:stick"},
		{"default:stick", "", ""}
	}
})

--Four steel bars in a diagonal Y, with a steel wire on top, makes a steel slingshot.
--Requires basic_materials
minetest.register_craft({
	output = "projectile:steel_slingshot",
	recipe = {
		{"", "basic_materials:steel_bar", "basic_materials:steel_wire"},
		{"", "basic_materials:steel_bar", "basic_materials:steel_bar"},
		{"basic_materials:steel_bar", "", ""}
	}
})

--Three sticks, to create the shape of the bow itself, and three strings in a diagonal line, makes a bow.
minetest.register_craft({
	output = "projectile:bow",
	recipe = {
		{"default:stick", "default:stick", "farming:string"},
		{"default:stick", "farming:string", ""},
		{"farming:string", "", ""}
	}
})

--Three steel bars, to create the shape of the bow itself, and three steel wires in a diagonal line, makes a bow.
--Requires basic_materials
minetest.register_craft({
	output = "projectile:steel_bow",
	recipe = {
		{"basic_materials:steel_bar", "basic_materials:steel_bar", "basic_materials:steel_wire"},
		{"basic_materials:steel_bar", "basic_materials:steel_wire", ""},
		{"basic_materials:steel_wire", "", ""}
	}
})

--Regular arrows are made from flint, a stick, and a feather.
--The feather can be provided by multiple mob mods.
--Arrows are also materials in the stronger ammo options for bows.
minetest.register_craft({
	output = "projectile:arrow",
	recipe = {
		{"default:flint", "", ""},
		{"", "default:stick", ""},
		{"", "", "mobs:chicken_feather"}
	}
})
minetest.register_craft({
	output = "projectile:arrow",
	recipe = {
		{"default:flint", "", ""},
		{"", "default:stick", ""},
		{"", "", "animalmaterials:feather"}
	}
})
minetest.register_craft({
	output = "projectile:arrow",
	recipe = {
		{"default:flint", "", ""},
		{"", "default:stick", ""},
		{"", "", "creatures:feather"}
	}
})

--Combining an arrow with a torch lights it on fire.
if fire then
	minetest.register_craft({
		type = "shapeless",
		output = "projectile:arrow_fire",
		recipe = {"projectile:arrow", "default:torch"}
	})
end

--Gold tools are often fast, so gold arrows focus on being fast.
--A gold ingot can turn four arrows gold.
minetest.register_craft({
	type = "shapeless",
	output = "projectile:arrow_high_velocity 4",
	recipe = {"projectile:arrow", "projectile:arrow", "projectile:arrow", "projectile:arrow", "default:gold_ingot"}
})

--Stabbing an arrow into a TNT stick creates a bomb arrow.
minetest.register_craft({
	type = "shapeless",
	output = "projectile:arrow_bomb",
	recipe = {"projectile:arrow", "tnt:tnt_stick"}
})
