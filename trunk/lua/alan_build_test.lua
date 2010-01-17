
alan:Build{
	name = "Contraption test #1",
	author = "The creators of Alan",
	{	type = "spawn",
		name = "barrel", -- unique id for future steps
		class = "prop_physics", -- it will default to prop_physics anyway... but meh
		model = "models/props_borealis/bluebarrel001.mdl",
		offset = Vector(0, 50, 50), -- this is just a temporary solution, but is needed for now
	},
	{	type = "spawn",
		name = "ball1",
		class = "sent_ball",
		offset = Vector(0, 50, 50),
	},
	{	type = "indirect_constraint",
		constraint = "weld", -- only weld is supported ATM
		ent1 = "barrel",
		ent2 = "ball1",
	},
	{	type = "indirect_constraint",
		constraint = "nocollide", -- only weld is supported ATM
		ent1 = "barrel",
		ent2 = "ball1",
	},
	{	type = "spawn",
		name = "ball2",
		class = "sent_ball",
		offset = Vector(0, 50, 50),
	},
	{	type = "tool",
		tool = "keepupright",
		ent = "ball2",
	},
	{	type = "spawn",
		name = "thing", -- unique id for future steps
		offset = Vector(50, 50, 50), -- this is just a temporary solution, but is needed for now
	},
	{	type = "tool",
		tool = "keepupright",
		ent = "thing",
	},
}
