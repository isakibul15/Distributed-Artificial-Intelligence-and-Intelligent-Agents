model SimpleFestival

global {
    int nb_guests <- 10;
    
    init {
        create InformationCenter number: 1 {
            location <- {50, 50};
        }
        
        create Store number: 4 {
            location <- {20 + (index * 20), 30};
            store_type <- (index < 2) ? "FOOD" : "WATER";
        }
        
        create Guest number: nb_guests {
            location <- {rnd(10, 90), rnd(10, 90)};
            has_memory <- (index < 5);
        }
    }
}

species InformationCenter {
    aspect default {
        draw square(3) color: #red;
    }
}

species Store {
    string store_type;
    
    aspect default {
        draw circle(2) color: (store_type = "FOOD") ? #orange : #blue;
    }
}

species Guest skills: [moving] {
    float hunger <- rnd(50, 100);
    float thirst <- rnd(50, 100);
    bool has_memory <- false;
    
    point target_location;
    string current_need;
    string state <- "wandering";
    
    map<string, point> memory;
    float total_distance <- 0.0;
    point last_location <- location;
    
    reflex wander when: state = "wandering" {
        hunger <- hunger - 0.1;
        thirst <- thirst - 0.2;
        
        if (target_location = nil or distance_to(target_location) < 2) {
            target_location <- {rnd(10, 90), rnd(10, 90)};
        }
        
        last_location <- location;
        do goto target: target_location speed: 1.0;
        total_distance <- total_distance + distance_to(last_location);
        
        if (hunger < 30) {
            current_need <- "FOOD";
            state <- "seeking";
        } else if (thirst < 30) {
            current_need <- "WATER";
            state <- "seeking";
        }
    }
    
    reflex seek_help when: state = "seeking" {
        if (has_memory and memory contains_key current_need) {
            if (rnd(100) < 70) {
                target_location <- memory[current_need];
                state <- "going_to_store";
                return;
            }
        }
        
        InformationCenter info_center <- first(InformationCenter);
        target_location <- info_center.location;
        
        last_location <- location;
        do goto target: target_location speed: 2.0;
        total_distance <- total_distance + distance_to(last_location);
        
        if (distance_to(target_location) < 3) {
            Store nearest_store <- first(Store where (each.store_type = current_need));
            if (nearest_store != nil) {
                target_location <- nearest_store.location;
                state <- "going_to_store";
            }
        }
    }
    
    reflex go_to_store when: state = "going_to_store" {
        last_location <- location;
        do goto target: target_location speed: 2.0;
        total_distance <- total_distance + distance_to(last_location);
        
        if (distance_to(target_location) < 3) {
            state <- "at_store";
        }
    }
    
    reflex at_store when: state = "at_store" {
        if (has_memory) {
            memory[current_need] <- target_location;
        }
        
        if (current_need = "FOOD") {
            hunger <- 100.0;
        } else {
            thirst <- 100.0;
        }
        
        state <- "wandering";
        target_location <- nil;
        current_need <- nil;
    }
    
    aspect default {
        draw circle(1) color: (has_memory) ? #green : #red;
    }
}

experiment Festival type: gui {
    output {
        display Main {
            species InformationCenter;
            species Store;
            species Guest;
        }
        
        monitor "Memory Guests" value: length(Guest where (each.has_memory = true));
        monitor "No-Memory Guests" value: length(Guest where (each.has_memory = false));
        monitor "Memory Distance" value: mean((Guest where (each.has_memory = true)) collect each.total_distance);
        monitor "No-Memory Distance" value: mean((Guest where (each.has_memory = false)) collect each.total_distance);
    }
}