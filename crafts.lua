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

--Gun components
if not (pipeworks or waterworks) then
	minetest.register_craftitem("projectile:steel_pipe", {
		description = "Steel Pipe",
		inventory_image = "projectile_steel_pipe.png"
	})
end

--Basic slingshot ammo
if not hardtrees then
	minetest.register_craftitem("projectile:rock", {
		description = "Rock",
		inventory_image = "projectile_rock.png"
	})
end

--A basic arrow
minetest.register_craftitem("projectile:arrow", {
	description = "Arrow",
	inventory_image = "projectile_arrow.png",
})

--An arrow that burns flammable nodes that it touches
minetest.register_craftitem("projectile:arrow_fire", {
	description = "Fire Arrow",
	inventory_image = "projectile_arrow_fire.png",
})

--An arrow with exceptionally high velocity
minetest.register_craftitem("projectile:arrow_high_velocity", {
	description = "High Velocity Arrow",
	inventory_image = "projectile_arrow_high_velocity.png",
})

--An arrow that explodes on contact, rather than dealing direct damage.
minetest.register_craftitem("projectile:arrow_bomb", {
	description = "Bomb Arrow",
	inventory_image = "projectile_arrow_bomb.png",
})

--Basic flintlock ammo, small steel balls
minetest.register_craftitem("projectile:musket_ball", {
	description = "Musket Ball",
	inventory_image = "projectile_musket_ball.png",
})

--Easily shattered ammo with less direct damage than a musket ball, but much greater crowd control abilities.
minetest.register_craftitem("projectile:musket_ball_diamond", {
	description = "Diamond Musket Ball",
	inventory_image = "projectile_musket_ball_diamond.png",
})

--An upgrade to regular musket balls
minetest.register_craftitem("projectile:musket_ball_mithril", {
	description = "Mithril Musket Ball",
	inventory_image = "projectile_musket_ball_mithril.png",
})

--Standard shotgun ammo, a pile of 9 tiny balls
minetest.register_craftitem("projectile:shot_pile", {
	description = "Shot Pile",
	inventory_image = "projectile_shot_pile.png",
})

--Easily shattered ammo with less direct damage than shot, but each ball splits into 2 in the initial blast, causing a total of 18 pellets to be spewed.
minetest.register_craftitem("projectile:shot_pile_diamond", {
	description = "Diamond Shot Pile",
	inventory_image = "projectile_shot_pile_diamond.png",
})

--An upgrade to regular shot.
minetest.register_craftitem("projectile:shot_pile_mithril", {
	description = "Mithril Shot Pile",
	inventory_image = "projectile_shot_pile_mithril.png",
})



if hardtrees then
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
else
	--Two cobblestone blocks can shapelessly be used to craft 18 rocks.
	--Two are used since it's very possible that other mods use one rock to make other things.
	minetest.register_craft({
		type = "shapeless",
		output = "projectile:rock 18",
		recipe = {"default:cobble", "default:cobble"}
	})

	--If the player no longer needs rocks, 9 can be crafted back into a cobblestone block.
	minetest.register_craft({
		output = "default:cobble",
		recipe = {
			{"projectile:rock", "projectile:rock", "projectile:rock"},
			{"projectile:rock", "projectile:rock", "projectile:rock"},
			{"projectile:rock", "projectile:rock", "projectile:rock"}
		}
	})
end

--Four sticks in a diagonal Y, with a string on top, makes a slingshot.
minetest.register_craft({
	output = "projectile:slingshot",
	recipe = {
		{"", "group:stick", "farming:string"},
		{"", "group:stick", "group:stick"},
		{"group:stick", "", ""}
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
		{"group:stick", "group:stick", "farming:string"},
		{"group:stick", "farming:string", ""},
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

if pipeworks then
	--Flintlocks are made from metal and steel, with a steel pipe for the barrel and a lever for the trigger.
	minetest.register_craft({
		output = "projectile:flintlock_pistol",
		recipe = {
			{"pipeworks:pipe_1_empty", ""},
			{"basic_materials:steel_strip", "default:steel_ingot"},
			{"group:stick", "default:flint"}
		}
	})

	--Muskets add an extra pipe because they're long.
	minetest.register_craft({
		output = "projectile:musket",
		recipe = {
			{"pipeworks:pipe_1_empty", "", ""},
			{"", "pipeworks:pipe_1_empty", "default:steel_ingot"},
			{"basic_materials:steel_strip", "group:stick", "default:flint"}
		}
	})
end

if waterworks then
	--Flintlocks are made from metal and steel, with a steel pipe for the barrel and a lever for the trigger.
	minetest.register_craft({
		output = "projectile:flintlock_pistol",
		recipe = {
			{"waterworks:pipe", ""},
			{"basic_materials:steel_strip", "default:steel_ingot"},
			{"group:stick", "default:flint"}
		}
	})

	--Muskets add an extra pipe because they're long.
	minetest.register_craft({
		output = "projectile:musket",
		recipe = {
			{"waterworks:pipe", "", ""},
			{"", "waterworks:pipe", "default:steel_ingot"},
			{"basic_materials:steel_strip", "group:stick", "default:flint"}
		}
	})
end

if not (pipeworks or waterworks) then
	--6 steel ingots in an = shape can make any kind of pipe.
	minetest.register_craft({
		output = "projectile:steel_pipe 12",
		recipe = {
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
			{"", "", ""},
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"}
		}
	})

	--Flintlocks are made from metal and steel, with a steel pipe for the barrel and a lever for the trigger.
	minetest.register_craft({
		output = "projectile:flintlock_pistol",
		recipe = {
			{"projectile:steel_pipe", ""},
			{"basic_materials:steel_strip", "default:steel_ingot"},
			{"group:stick", "default:flint"}
		}
	})

	--Muskets add an extra pipe because they're long.
	minetest.register_craft({
		output = "projectile:musket",
		recipe = {
			{"projectile:steel_pipe", "", ""},
			{"", "projectile:steel_pipe", "default:steel_ingot"},
			{"basic_materials:steel_strip", "group:stick", "default:flint"}
		}
	})
end

--Blunderbusses are thucker, so a second steel ingot is used in place of a steel pipe.
minetest.register_craft({
	output = "projectile:blunderbuss",
	recipe = {
		{"default:steel_ingot", ""},
		{"basic_materials:steel_strip", "default:steel_ingot"},
		{"group:stick", "default:flint"}
	}
})



--Regular arrows are made from flint, a stick, and a feather.
--The feather can be provided by multiple mob mods.
--Arrows are also materials in the stronger ammo options for bows.
minetest.register_craft({
	output = "projectile:arrow",
	recipe = {
		{"default:flint", "", ""},
		{"", "group:stick", ""},
		{"", "", "mobs:chicken_feather"}
	}
})
minetest.register_craft({
	output = "projectile:arrow",
	recipe = {
		{"default:flint", "", ""},
		{"", "group:stick", ""},
		{"", "", "animalmaterials:feather"}
	}
})
minetest.register_craft({
	output = "projectile:arrow",
	recipe = {
		{"default:flint", "", ""},
		{"", "group:stick", ""},
		{"", "", "creatures:feather"}
	}
})

--Combining an arrow with a torch lights it on fire.
minetest.register_craft({
	type = "shapeless",
	output = "projectile:arrow_fire",
	recipe = {"projectile:arrow", "default:torch"}
})

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

--Converting applicable materials to 12 musket balls requires putting 4 of those materials into a ball-esque shape.
minetest.register_craft({
	output = "projectile:musket_ball 12",
	recipe = {
		{"", "default:steel_ingot", ""},
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"", "default:steel_ingot", ""},
	}
})
minetest.register_craft({
	output = "projectile:musket_ball_diamond 12",
	recipe = {
		{"", "default:diamond", ""},
		{"default:diamond", "", "default:diamond"},
		{"", "default:diamond", ""},
	}
})
minetest.register_craft({
	output = "projectile:musket_ball_mithril 12",
	recipe = {
		{"", "moreores:mithril_ingot", ""},
		{"moreores:mithril_ingot", "", "moreores:mithril_ingot"},
		{"", "moreores:mithril_ingot", ""},
	}
})

--3 of any musket ball can be split into 9 smaller balls, known as a shot pile.
minetest.register_craft({
	type = "shapeless",
	output = "projectile:shot_pile",
	recipe = {"projectile:musket_ball", "projectile:musket_ball", "projectile:musket_ball"}
})
minetest.register_craft({
	type = "shapeless",
	output = "projectile:shot_pile_diamond",
	recipe = {"projectile:musket_ball_diamond", "projectile:musket_ball_diamond", "projectile:musket_ball_diamond"}
})
minetest.register_craft({
	type = "shapeless",
	output = "projectile:shot_pile_mithril",
	recipe = {"projectile:musket_ball_mithril", "projectile:musket_ball_mithril", "projectile:musket_ball_mithril"}
})
