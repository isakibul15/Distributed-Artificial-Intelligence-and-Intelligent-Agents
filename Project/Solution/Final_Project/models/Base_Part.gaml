/**
 * Social Agents Simulation - Final Project
 * Minimum Requirements Implementation
 */

model SocialAgentsSimulation

global {
    // Simulation parameters
    int nb_party_people <- 12;
    int nb_introverts <- 10;
    int nb_music_lovers <- 10;
    int nb_foodies <- 10;
    int nb_sports_fans <- 8;
    
    // Location parameters
    int nb_bars <- 2;
    int nb_concerts <- 2;
    int nb_restaurants <- 2;
    int nb_sports_venues <- 2;
    
    // Track all locations
    list<Location> all_locations <- [];
    
    // Global monitoring values
    float global_happiness <- 0.0;
    list<float> happiness_history <- [];
    int total_positive_interactions <- 0;
    int total_negative_interactions <- 0;
    int total_interactions <- 0;
    
    // Environment bounds
    geometry shape <- square(100);
    
    init {
        // Create locations first
        create Bar number: nb_bars {
            all_locations << self;
        }
        create Concert number: nb_concerts {
            all_locations << self;
        }
        create Restaurant number: nb_restaurants {
            all_locations << self;
        }
        create SportsVenue number: nb_sports_venues {
            all_locations << self;
        }
        
        // Create guests AFTER locations exist
        create PartyPerson number: nb_party_people;
        create Introvert number: nb_introverts;
        create MusicLover number: nb_music_lovers;
        create Foodie number: nb_foodies;
        create SportsFan number: nb_sports_fans;
        
        int total_guests <- length(PartyPerson) + length(Introvert) + length(MusicLover) + length(Foodie) + length(SportsFan);
        write "✓ Simulation started: " + total_guests + " guests, " + length(all_locations) + " locations";
    }
    
    reflex update_global_happiness {
        if length(Guest) > 0 {
            global_happiness <- mean(Guest collect each.happiness);
            happiness_history << global_happiness;
        }
    }
    
    reflex monitor_stats when: every(50#cycle) {
        write "=== Cycle " + cycle + " Stats ===";
        write "Global Happiness: " + global_happiness;
        write "Total Interactions: " + total_interactions;
        write "Positive: " + total_positive_interactions + " | Negative: " + total_negative_interactions;
    }
}

// Base species for all locations
species Location {
    rgb color;
    float noise_level <- rnd(0.3, 1.0);
    list<Guest> current_guests <- [];
    
    aspect default {
        draw circle(5) color: color border: #black;
        // Show number of guests at location
        draw string(length(current_guests)) color: #white size: 3 at: location;
    }
}

species Bar parent: Location {
    init {
        location <- {rnd(10.0, 90.0), rnd(10.0, 90.0)};
        color <- #blue;
        noise_level <- rnd(0.6, 1.0);
    }
}

species Concert parent: Location {
    string music_genre <- one_of(["rock", "pop", "jazz", "electronic"]);
    
    init {
        location <- {rnd(10.0, 90.0), rnd(10.0, 90.0)};
        color <- #purple;
        noise_level <- rnd(0.7, 1.0);
    }
}

species Restaurant parent: Location {
    string cuisine_type <- one_of(["italian", "asian", "vegan", "steakhouse"]);
    
    init {
        location <- {rnd(10.0, 90.0), rnd(10.0, 90.0)};
        color <- #orange;
        noise_level <- rnd(0.2, 0.5);
    }
}

species SportsVenue parent: Location {
    string sport_type <- one_of(["football", "basketball", "tennis"]);
    
    init {
        location <- {rnd(10.0, 90.0), rnd(10.0, 90.0)};
        color <- #green;
        noise_level <- rnd(0.5, 0.9);
    }
}

// Base Guest species
species Guest skills: [fipa, moving] {
    // Personal traits (at least 3)
    float generosity <- rnd(0.0, 1.0);
    float sociability <- rnd(0.0, 1.0);
    float tolerance <- rnd(0.0, 1.0);
    
    // State variables
    float happiness <- 0.5;
    Location target_location <- nil;
    rgb color;
    
    // Movement and timing
    int time_at_location <- 0;
    int min_stay_time <- 30;
    int max_stay_time <- 100;
    int stay_duration <- rnd(30, 100);
    
    // Interaction tracking
    list<Guest> interacted_this_visit <- [];
    list<Guest> friends <- [];
    list<Guest> known_agents <- [];
    
    init {
        if length(all_locations) > 0 {
            do choose_new_location;
        }
    }
    
    // FIPA Messaging - Send invitations to friends at different locations
    reflex send_invitation when: target_location != nil and time_at_location > 10 and flip(0.1) and length(friends) > 0 {
        Guest friend <- one_of(friends);
        
        // Only send if friend is at a different location
        if friend.target_location != nil and friend.target_location != target_location {
            do start_conversation to: [friend] protocol: 'fipa-request' 
               performative: 'inform' 
               contents: ['invitation', target_location];
            
            if cycle mod 50 = 0 {
                write "📧 " + name + " → " + friend.name + ": Come to " + target_location;
            }
        }
    }
    
    // FIPA Messaging - Receive and process messages
    reflex receive_messages when: !empty(informs) {
        loop msg over: informs {
            // If highly sociable, might accept invitation
            if sociability > 0.6 and flip(0.5) {
                Guest sender <- Guest(msg.sender);
                if sender != nil and sender.target_location != nil {
                    // Accept invitation - go to friend's location
                    do leave_and_choose_new_location;
                    target_location <- sender.target_location;
                    stay_duration <- rnd(min_stay_time, max_stay_time);
                    
                    if cycle mod 50 = 0 {
                        write "  ✓ " + name + " accepted invitation to " + target_location;
                    }
                    
                    // Reply back
                    do start_conversation to: [sender] protocol: 'fipa-request' 
                       performative: 'agree' 
                       contents: ['accepted'];
                }
            }
        }
    }
    
    // Receive agreement messages
    reflex receive_agreements when: !empty(agrees) {
        loop msg over: agrees {
            do update_happiness(0.02);
        }
    }
    
    reflex move_to_location when: target_location != nil and location distance_to target_location.location > 1.0 {
        float dist <- location distance_to target_location.location;
        do goto target: target_location.location speed: 2.0;
    }
    
    reflex arrive_at_location when: target_location != nil and location distance_to target_location.location <= 1.0 {
        // Snap to location
        location <- target_location.location;
        
        // Register arrival
        if !(self in target_location.current_guests) {
            target_location.current_guests << self;
        }
        
        time_at_location <- 0;
        interacted_this_visit <- [];
    }
    
    reflex stay_and_interact when: target_location != nil and location = target_location.location {
        time_at_location <- time_at_location + 1;
        
        // Try to interact with others at this location
        list<Guest> others <- target_location.current_guests - self - interacted_this_visit;
        
        if length(others) > 0 and flip(0.3) {
            Guest other <- one_of(others);
            if cycle mod 100 = 0 {
                write "INTERACTION: " + name + " <-> " + other.name + " at " + target_location;
            }
            do interact_with(other);
            interacted_this_visit << other;
            
            // Build friendships through positive interactions
            if flip(0.3) and !(other in friends) {
                friends << other;
                ask other {
                    if !(myself in friends) {
                        friends << myself;
                    }
                }
            }
        }
        
        // Leave after stay duration
        if time_at_location >= stay_duration {
            do leave_and_choose_new_location;
        }
    }
    
    action choose_new_location {
        if length(all_locations) > 0 {
            target_location <- one_of(all_locations);
            stay_duration <- rnd(min_stay_time, max_stay_time);
        }
    }
    
    action leave_and_choose_new_location {
        // Leave current location
        if target_location != nil {
            target_location.current_guests >> self;
        }
        
        // Choose new destination
        do choose_new_location;
        time_at_location <- 0;
        interacted_this_visit <- [];
    }
    
    action interact_with(Guest other) {
        // To be overridden by subclasses
    }
    
    action update_happiness(float delta) {
        happiness <- happiness + delta;
        happiness <- max(0.0, min(1.0, happiness));
    }
    
    aspect default {
        draw circle(1.5) color: color border: #black;
        // Happiness indicator
        rgb happiness_color <- rgb(255 * (1 - happiness), 255 * happiness, 0);
        draw circle(0.7) color: happiness_color at: location + {0, 2.5};
    }
}

// Party Person: Loves noise, socializing, and bars
species PartyPerson parent: Guest {
    init {
        color <- #red;
        sociability <- rnd(0.7, 1.0);
        generosity <- rnd(0.5, 1.0);
        tolerance <- rnd(0.4, 0.8);
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        
        if target_location.noise_level > 0.6 {
            do update_happiness(0.02);
            
            if other is Introvert {
                ask other {
                    do update_happiness(-0.05);
                }
                total_negative_interactions <- total_negative_interactions + 1;
            } else if other is PartyPerson or other is MusicLover {
                do update_happiness(0.03);
                ask other {
                    do update_happiness(0.03);
                }
                total_positive_interactions <- total_positive_interactions + 1;
                
                if generosity > 0.7 and flip(0.3) {
                    ask other {
                        do update_happiness(0.02);
                    }
                }
            }
        } else {
            do update_happiness(0.01);
        }
    }
}

// Introvert: Prefers quiet places
species Introvert parent: Guest {
    init {
        color <- #lightblue;
        sociability <- rnd(0.1, 0.4);
        tolerance <- rnd(0.2, 0.6);
        generosity <- rnd(0.3, 0.7);
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        
        if target_location.noise_level < 0.5 {
            do update_happiness(0.02);
            
            if other is Introvert or other is Foodie {
                do update_happiness(0.03);
                ask other {
                    do update_happiness(0.02);
                }
                total_positive_interactions <- total_positive_interactions + 1;
            } else if other is PartyPerson {
                do update_happiness(-0.02);
                total_negative_interactions <- total_negative_interactions + 1;
            }
        } else {
            do update_happiness(-0.04);
            
            if other is PartyPerson {
                do update_happiness(-0.02);
                total_negative_interactions <- total_negative_interactions + 1;
            }
        }
    }
}

// Music Lover: Loves concerts
species MusicLover parent: Guest {
    string favorite_genre <- one_of(["rock", "pop", "jazz", "electronic"]);
    
    init {
        color <- #magenta;
        sociability <- rnd(0.5, 0.9);
        tolerance <- rnd(0.6, 1.0);
        generosity <- rnd(0.4, 0.8);
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        
        if target_location is Concert {
            Concert concert <- Concert(target_location);
            
            if concert.music_genre = favorite_genre {
                do update_happiness(0.05);
                
                if other is MusicLover {
                    MusicLover ml <- MusicLover(other);
                    if ml.favorite_genre = favorite_genre {
                        do update_happiness(0.04);
                        ask other {
                            do update_happiness(0.04);
                        }
                        total_positive_interactions <- total_positive_interactions + 1;
                    } else {
                        do update_happiness(0.01);
                    }
                } else if other is PartyPerson {
                    do update_happiness(0.02);
                    ask other {
                        do update_happiness(0.02);
                    }
                    total_positive_interactions <- total_positive_interactions + 1;
                }
            } else {
                do update_happiness(0.01);
            }
        } else {
            if tolerance > 0.7 {
                do update_happiness(0.01);
            }
        }
    }
}

// Foodie: Loves restaurants
species Foodie parent: Guest {
    string diet_preference <- one_of(["vegetarian", "vegan", "meat", "flexible"]);
    
    init {
        color <- #yellow;
        sociability <- rnd(0.4, 0.7);
        tolerance <- rnd(0.5, 0.9);
        generosity <- rnd(0.6, 1.0);
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        
        if target_location is Restaurant {
            Restaurant rest <- Restaurant(target_location);
            
            bool food_match <- false;
            if diet_preference = "vegan" and rest.cuisine_type = "vegan" {
                food_match <- true;
            } else if diet_preference = "meat" and rest.cuisine_type = "steakhouse" {
                food_match <- true;
            } else if diet_preference = "flexible" {
                food_match <- true;
            }
            
            if food_match {
                do update_happiness(0.04);
                
                if other is Foodie {
                    do update_happiness(0.03);
                    ask other {
                        do update_happiness(0.03);
                    }
                    total_positive_interactions <- total_positive_interactions + 1;
                    
                    if generosity > 0.8 and flip(0.4) {
                        ask other {
                            do update_happiness(0.02);
                        }
                    }
                } else if other is Introvert {
                    do update_happiness(0.02);
                    ask other {
                        do update_happiness(0.02);
                    }
                    total_positive_interactions <- total_positive_interactions + 1;
                }
            } else {
                do update_happiness(-0.01);
            }
        }
    }
}

// Sports Fan: Loves sports venues
species SportsFan parent: Guest {
    string favorite_sport <- one_of(["football", "basketball", "tennis"]);
    
    init {
        color <- #darkgreen;
        sociability <- rnd(0.6, 0.95);
        tolerance <- rnd(0.5, 0.85);
        generosity <- rnd(0.5, 0.9);
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        
        if target_location is SportsVenue {
            SportsVenue venue <- SportsVenue(target_location);
            
            if venue.sport_type = favorite_sport {
                do update_happiness(0.05);
                
                if other is SportsFan {
                    SportsFan sf <- SportsFan(other);
                    if sf.favorite_sport = favorite_sport {
                        do update_happiness(0.05);
                        ask other {
                            do update_happiness(0.05);
                        }
                        total_positive_interactions <- total_positive_interactions + 1;
                    }
                } else if other is PartyPerson {
                    do update_happiness(0.02);
                    ask other {
                        do update_happiness(0.02);
                    }
                    total_positive_interactions <- total_positive_interactions + 1;
                } else if other is Introvert {
                    ask other {
                        do update_happiness(-0.03);
                    }
                    total_negative_interactions <- total_negative_interactions + 1;
                }
            }
        } else {
            if sociability > 0.7 {
                do update_happiness(0.01);
            }
        }
    }
}

experiment SocialSimulation type: gui {
    parameter "Party People" var: nb_party_people min: 5 max: 30;
    parameter "Introverts" var: nb_introverts min: 5 max: 30;
    parameter "Music Lovers" var: nb_music_lovers min: 5 max: 30;
    parameter "Foodies" var: nb_foodies min: 5 max: 30;
    parameter "Sports Fans" var: nb_sports_fans min: 5 max: 30;
    
    // Make simulation run continuously without stopping
    float minimum_cycle_duration <- 0.01;
    
    output {
        display main_display type: 2d {
            graphics "world_boundary" {
                draw square(100) color: #white border: #black wireframe: true;
            }
            graphics "locations_bg" {
                loop loc over: all_locations {
                    draw circle(7) at: loc.location color: rgb(loc.color, 0.15) border: loc.color;
                    draw string(length(loc.current_guests)) at: loc.location color: #black size: 8;
                }
            }
            species Bar aspect: default;
            species Concert aspect: default;
            species Restaurant aspect: default;
            species SportsVenue aspect: default;
            species PartyPerson aspect: default;
            species Introvert aspect: default;
            species MusicLover aspect: default;
            species Foodie aspect: default;
            species SportsFan aspect: default;
        }
        
        display happiness_chart refresh: every(5#cycle) {
            chart "Global Happiness Over Time" type: series size: {1.0, 0.5} position: {0, 0} {
                data "Average Happiness" value: global_happiness color: #blue;
                data "Threshold (0.5)" value: 0.5 color: #gray;
            }
        }
        
        display interaction_chart refresh: every(10#cycle) {
            chart "Interaction Statistics" type: histogram size: {1.0, 0.5} position: {0, 0.5} {
                data "Positive" value: total_positive_interactions color: #green;
                data "Negative" value: total_negative_interactions color: #red;
            }
        }
        
        monitor "Global Happiness" value: global_happiness;
        monitor "Total Interactions" value: total_interactions;
        monitor "Positive Interactions" value: total_positive_interactions;
        monitor "Negative Interactions" value: total_negative_interactions;
        monitor "Active Guests" value: length(PartyPerson) + length(Introvert) + length(MusicLover) + length(Foodie) + length(SportsFan);
        monitor "Total Locations" value: length(all_locations);
        monitor "Positive Rate %" value: total_interactions > 0 ? (total_positive_interactions / total_interactions * 100.0) : 0.0;
    }
}