/**
* Name: FestivalSimulation
* Based on the internal skeleton template. 
* Author: md.sakibulislam
* Tags: 
*/

model festival_simulation

/********** WORLD **********/
global {
	int world_w <- 100;
	int world_h <- 100;

	init {
		create store number: 2 with: [serves_food:: true,  serves_water:: false];
		create store number: 2 with: [serves_food:: false, serves_water:: true];
		create information_center number: 1;
		create guest number: 10;
	}
}

/********** AGENTS **********/
species store {
	bool serves_food  <- false;
	bool serves_water <- false;
	aspect default { draw circle(2) color: rgb("green"); }
}

species information_center {
	float service_radius <- 8.0;

	// Return the LOCATION of the nearest valid store from a given point.
	// Signature uses only core types to avoid version differences.
	action get_store_location(string need, point from) {
	list<store> candidates <-
		(need = "food")
			? (store where (each.serves_food))
			: (store where (each.serves_water));
	if (length(candidates) = 0) { return from; }

	// distances of each candidate from 'from'
	list<float> ds <- (candidates collect (distance(from, each.location)));
	float m <- min(ds);

	// pick the store whose distance equals the minimum
	store s <- first (candidates where (distance(from, each.location) = m));
	return s.location;
}
	

	aspect default { draw square(3) color: rgb("blue"); }
}

species guest skills: [moving] {
	// needs
	float hunger <- rnd(1.0);
	float thirst <- rnd(1.0);
	float hunger_decay <- 0.002;
	float thirst_decay <- 0.002;
	float need_threshold <- 0.25;

	// state
	string need <- "";                  // "", "food", "water"
	string mode <- "idle";              // "idle","to_info","to_store","consume"
	point  target_pos <- {0,0};         // location of chosen store
	bool   has_target <- false;

	// references
	information_center info <- one_of(information_center);

	// movement
	float base_speed <- 0.6;

	// idle roam inside bounds
	reflex idle_roam when: mode = "idle" {
		point candidate <- location + point(rnd(-0.6,0.6), rnd(-0.6,0.6));
		if (candidate.x > 0 and candidate.x < world.shape.width and
		    candidate.y > 0 and candidate.y < world.shape.height) {
			location <- candidate;
		}
	}

	// decay needs
	reflex decay {
		hunger <- max(0.0, hunger - hunger_decay);
		thirst <- max(0.0, thirst - thirst_decay);

		if (mode = "idle" and need = "") {
			if (hunger < need_threshold) { need <- "food";  mode <- "to_info"; }
			else if (thirst < need_threshold) { need <- "water"; mode <- "to_info"; }
		}
	}

	// go to info center to ask directions
	reflex go_to_info when: mode = "to_info" {
		do goto target: info.location speed: base_speed;
		if (distance(self, info) < info.service_radius) {
			point p <- info.get_store_location(need, location);
			// if no candidates, p == current location → fallback to idle
			if (p != location) {
				target_pos <- p; has_target <- true; mode <- "to_store";
			} else {
				need <- ""; mode <- "idle";
			}
		}
	}

	// go to store
	reflex go_to_store when: mode = "to_store" and has_target {
		do goto target: target_pos speed: base_speed;
		if (distance(self, target_pos) < 1.5) { mode <- "consume"; }
	}

	// consume and reset
	reflex consume when: mode = "consume" {
		if (need = "food")  { hunger <- 1.0; }
		if (need = "water") { thirst <- 1.0; }
		need <- ""; has_target <- false; mode <- "idle";
	}

	aspect default { draw circle(1.5) color: rgb("red"); }
}

/********** GUI **********/
experiment main type: gui {
	output {
		display map_display {
			species guest;
			species store;
			species information_center;
		}
	}
}
