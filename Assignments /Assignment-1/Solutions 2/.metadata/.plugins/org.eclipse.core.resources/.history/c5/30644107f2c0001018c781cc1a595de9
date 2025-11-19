/**
* Name: Festival Simulation - Challenge 1: Memory System
* Author: Based on Assignment 1 Requirements
* Description: A festival simulation with guests that have memory (brain) and without
*/

model FestivalSimulation

global {
    int nb_guests <- 20;
    int nb_food_stores <- 2;
    int nb_water_stores <- 2;
    int nb_guests_with_brain <- 10; // Half with brain, half without
    
    geometry shape <- square(100);
    
    // Global tracking for comparison
    list<float> avg_distance_with_brain <- [];
    list<float> avg_distance_without_brain <- [];
    
    init {
        // Create the information center at the center of the world
        create InformationCenter number: 1 {
            location <- {50, 50};
        }
        
        // Create food stores at fixed locations on the left side
        create Store number: nb_food_stores {
            store_type <- "FOOD";
            color <- #orange;
            float spacing <- nb_food_stores > 1 ? 60 / (nb_food_stores - 1) : 0;
            location <- {20, 20 + (index * spacing)};
        }
        
        // Create water stores at fixed locations on the right side
        create Store number: nb_water_stores {
            store_type <- "WATER";
            color <- #blue;
            float spacing <- nb_water_stores > 1 ? 60 / (nb_water_stores - 1) : 0;
            location <- {80, -100 + (index * spacing)};
        }
        
        // Create guests WITH BRAIN (memory)
        create Guest number: nb_guests_with_brain {
            location <- {rnd(10.0, 90.0), rnd(10.0, 90.0)};
            has_brain <- true;
        }
        
        // Create guests WITHOUT BRAIN (no memory)
        create Guest number: (nb_guests - nb_guests_with_brain) {
            location <- {rnd(10.0, 90.0), rnd(10.0, 90.0)};
            has_brain <- false;
        }
    }
    
    // Update tracking data every cycle
    reflex update_tracking {
        list<Guest> guests_with_brain <- Guest where (each.has_brain = true);
        list<Guest> guests_without_brain <- Guest where (each.has_brain = false);
        
        if (!empty(guests_with_brain)) {
            add mean(guests_with_brain collect each.total_distance_traveled) to: avg_distance_with_brain;
        }
        
        if (!empty(guests_without_brain)) {
            add mean(guests_without_brain collect each.total_distance_traveled) to: avg_distance_without_brain;
        }
    }
}

species InformationCenter {
    rgb color <- #red;
    float size <- 3.0;
    
    // Find nearest store of a specific type
    Store find_nearest_store(string need_type) {
        list<Store> available_stores <- Store where (each.store_type = need_type);
        if (empty(available_stores)) {
            return nil;
        }
        return available_stores closest_to self;
    }
    
    aspect default {
        draw square(size) color: color border: #black;
    }
}

species Store {
    string store_type; // "FOOD" or "WATER"
    rgb color;
    float size <- 4.0;
    
    aspect default {
        draw triangle(size) color: color border: #black;
    }
}

species Guest skills: [moving] {
    float hunger <- rnd(50.0, 100.0);
    float thirst <- rnd(50.0, 100.0);
    float hunger_decrease_rate <- rnd(0.1, 0.3);
    float thirst_decrease_rate <- rnd(0.1, 0.3);
    float speed <- 2.0;
    
    rgb color <- #green;
    float size <- 1.5;
    
    point target_location <- nil;
    Store target_store <- nil;
    InformationCenter info_center <- nil;
    
    string state <- "idle";
    string current_need <- nil;
    string guest_name;
    
    // CHALLENGE 1: Brain/Memory System - Simple list of visited stores
    bool has_brain <- false;
    list<Store> visited_stores <- []; // List of stores this guest has visited
    float total_distance_traveled <- 0.0;
    int memory_uses <- 0;
    int info_center_visits <- 0;
    
    init {
        info_center <- first(InformationCenter);
        guest_name <- "Guest_" + string(index) + (has_brain ? "[BRAIN]" : "[NO-BRAIN]");
        write guest_name + " created at " + location;
    }
    
    reflex decrease_attributes when: state = "idle" {
        hunger <- hunger - hunger_decrease_rate;
        thirst <- thirst - thirst_decrease_rate;
        
        if (target_location = nil or location distance_to target_location < 1) {
            target_location <- {rnd(10.0, 90.0), rnd(10.0, 90.0)};
        }
        
        point old_location <- location;
        do goto target: target_location speed: speed * 0.5;
        total_distance_traveled <- total_distance_traveled + (location distance_to old_location);
        
        location <- {max(5, min(95, location.x)), max(5, min(95, location.y))};
    }
    
    reflex check_needs when: state = "idle" {
        if (hunger <= 20.0) {
            current_need <- "FOOD";
            
            // Check if guest has brain AND has visited a FOOD store before
            if (has_brain) {
                list<Store> known_food_stores <- visited_stores where (each.store_type = "FOOD");
                
                if (!empty(known_food_stores)) {
                    // Guest remembers a food store! Go directly there
                    target_store <- first(known_food_stores);
                    target_location <- target_store.location;
                    state <- "going_to_store";
                    memory_uses <- memory_uses + 1;
                    write "🧠 " + guest_name + " is HUNGRY! I remember the FOOD store location - going directly there!";
                } else {
                    // First time needing food, must ask info center
                    state <- "seeking_info";
                    target_location <- info_center.location;
                    info_center_visits <- info_center_visits + 1;
                    write "🍔 " + guest_name + " is HUNGRY! First time - going to Information Center";
                }
            } else {
                // No brain - always ask info center
                state <- "seeking_info";
                target_location <- info_center.location;
                info_center_visits <- info_center_visits + 1;
                write "🍔 " + guest_name + " is HUNGRY! No brain - must go to Information Center";
            }
            
        } else if (thirst <= 20.0) {
            current_need <- "WATER";
            
            // Check if guest has brain AND has visited a WATER store before
            if (has_brain) {
                list<Store> known_water_stores <- visited_stores where (each.store_type = "WATER");
                
                if (!empty(known_water_stores)) {
                    // Guest remembers a water store! Go directly there
                    target_store <- first(known_water_stores);
                    target_location <- target_store.location;
                    state <- "going_to_store";
                    memory_uses <- memory_uses + 1;
                    write "🧠 " + guest_name + " is THIRSTY! I remember the WATER store location - going directly there!";
                } else {
                    // First time needing water, must ask info center
                    state <- "seeking_info";
                    target_location <- info_center.location;
                    info_center_visits <- info_center_visits + 1;
                    write "💧 " + guest_name + " is THIRSTY! First time - going to Information Center";
                }
            } else {
                // No brain - always ask info center
                state <- "seeking_info";
                target_location <- info_center.location;
                info_center_visits <- info_center_visits + 1;
                write "💧 " + guest_name + " is THIRSTY! No brain - must go to Information Center";
            }
        }
    }
    
    reflex go_to_info_center when: state = "seeking_info" {
        point old_location <- location;
        do goto target: target_location speed: speed;
        total_distance_traveled <- total_distance_traveled + (location distance_to old_location);
        
        if (location distance_to target_location < 2) {
            write "ℹ️  " + guest_name + " arrived at Information Center - asking for " + current_need + " store";
            
            ask info_center {
                myself.target_store <- self.find_nearest_store(myself.current_need);
            }
            
            if (target_store != nil) {
                target_location <- target_store.location;
                state <- "going_to_store";
                write "📍 " + guest_name + " received directions to " + target_store.store_type + " store at " + target_location;
            } else {
                state <- "idle";
                current_need <- nil;
                target_location <- nil;
                write "❌ " + guest_name + " - No store available!";
            }
        }
    }
    
    reflex go_to_store when: state = "going_to_store" {
        point old_location <- location;
        do goto target: target_location speed: speed;
        total_distance_traveled <- total_distance_traveled + (location distance_to old_location);
        
        if (location distance_to target_location < 2) {
            state <- "at_store";
            write "🏪 " + guest_name + " arrived at " + target_store.store_type + " store";
        }
    }
    
    reflex replenish_at_store when: state = "at_store" {
        // If guest has brain, add this store to visited list (if not already there)
        if (has_brain and !(visited_stores contains target_store)) {
            add target_store to: visited_stores;
            write "💾 " + guest_name + " SAVED this " + target_store.store_type + " store location to memory! (Total stored: " + length(visited_stores) + ")";
        }
        
        if (current_need = "FOOD") {
            hunger <- 100.0;
            write "✅ " + guest_name + " replenished HUNGER [Total distance: " + total_distance_traveled + "]";
        } else if (current_need = "WATER") {
            thirst <- 100.0;
            write "✅ " + guest_name + " replenished THIRST [Total distance: " + total_distance_traveled + "]";
        }
        
        state <- "idle";
        current_need <- nil;
        target_store <- nil;
        target_location <- nil;
    }
    
    aspect default {
        rgb display_color <- color;
        
        if (state = "seeking_info") {
            display_color <- #yellow;
        } else if (state = "going_to_store") {
            display_color <- #purple;
        } else if (state = "at_store") {
            display_color <- #white;
        } else if (hunger <= 20.0 or thirst <= 20.0) {
            display_color <- #pink;
        }
        
        draw circle(size) color: display_color border: #black;
    }
}

experiment FestivalSimulation type: gui {
    parameter "Total Number of Guests" var: nb_guests min: 10 max: 50;
    parameter "Guests WITH Brain (Memory)" var: nb_guests_with_brain min: 0 max: 50;
    parameter "Number of Food Stores" var: nb_food_stores min: 1 max: 10;
    parameter "Number of Water Stores" var: nb_water_stores min: 1 max: 10;
    
    output {
        display main_display {
            graphics "background" {
                draw shape color: #lightgray;
            }
            
            species InformationCenter;
            species Store;
            species Guest;
        }
        
        // CHALLENGE 1: Distance Comparison Graph Over Time
        display "Distance Comparison Over Time" {
            chart "Average Distance Traveled: WITH Brain vs WITHOUT Brain" type: series {
                data "WITH BRAIN" value: length(avg_distance_with_brain) > 0 ? last(avg_distance_with_brain) : 0.0 color: #green marker: false;
                data "WITHOUT BRAIN" value: length(avg_distance_without_brain) > 0 ? last(avg_distance_without_brain) : 0.0 color: #red marker: false;
            }
        }
        
        monitor "=== GUEST TYPES ===" value: "";
        monitor "Guests WITH Brain" value: length(Guest where (each.has_brain = true));
        monitor "Guests WITHOUT Brain" value: length(Guest where (each.has_brain = false));
        
        monitor "=== DISTANCE COMPARISON ===" value: "";
        monitor "Avg Distance WITH Brain" value: length(Guest where (each.has_brain = true)) > 0 ? mean((Guest where (each.has_brain = true)) collect each.total_distance_traveled) : 0;
        monitor "Avg Distance WITHOUT Brain" value: length(Guest where (each.has_brain = false)) > 0 ? mean((Guest where (each.has_brain = false)) collect each.total_distance_traveled) : 0;
        monitor "Distance Saved (units)" value: length(Guest where (each.has_brain = false)) > 0 and length(Guest where (each.has_brain = true)) > 0 ? 
            mean((Guest where (each.has_brain = false)) collect each.total_distance_traveled) - mean((Guest where (each.has_brain = true)) collect each.total_distance_traveled) : 0;
        
        monitor "=== BRAIN USAGE STATS ===" value: "";
        monitor "Times Brain Used Memory" value: sum((Guest where (each.has_brain = true)) collect each.memory_uses);
        monitor "Times Visited Info Center" value: sum(Guest collect each.info_center_visits);
        monitor "Brains with Food Memory" value: length(Guest where (each.has_brain = true and !empty(each.visited_stores where (each.store_type = "FOOD"))));
        monitor "Brains with Water Memory" value: length(Guest where (each.has_brain = true and !empty(each.visited_stores where (each.store_type = "WATER"))));
        
        monitor "=== BASIC STATS ===" value: "";
        monitor "Guests Seeking Help" value: length(Guest where (each.state = "seeking_info"));
        monitor "Guests at Stores" value: length(Guest where (each.state = "at_store"));
        monitor "Average Hunger" value: mean(Guest collect each.hunger);
        monitor "Average Thirst" value: mean(Guest collect each.thirst);
    }
}