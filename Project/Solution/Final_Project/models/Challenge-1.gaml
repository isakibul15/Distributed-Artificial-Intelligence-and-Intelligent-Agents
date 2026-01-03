/**
 * Social Agents Simulation - BDI Architecture Implementation
 * Challenge 1: Demonstrating BDI Behavior
 */

model SocialAgentsBDI

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
    float global_happiness <- 0.5;
    list<float> happiness_history <- [];
    int total_positive_interactions <- 0;
    int total_negative_interactions <- 0;
    int total_interactions <- 0;
    
    // Environment bounds
    geometry shape <- square(100);
    
    // BDI PREDICATES - Represent facts about the world
    string suitable_venue_found <- "suitable_venue_found";
    string venue_too_noisy <- "venue_too_noisy";
    string venue_too_quiet <- "venue_too_quiet";
    string friend_nearby <- "friend_nearby";
    string lonely <- "lonely";
    
    predicate find_suitable_venue <- new_predicate("find suitable venue");
    predicate go_to_venue <- new_predicate("go to venue");
    predicate socialize <- new_predicate("socialize");
    predicate improve_happiness <- new_predicate("improve happiness");
    predicate make_friends <- new_predicate("make friends");
    predicate join_friend <- new_predicate("join friend");
    
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
        
        // Create BDI guests
        create PartyPersonBDI number: nb_party_people;
        create IntrovertBDI number: nb_introverts;
        create MusicLoverBDI number: nb_music_lovers;
        create FoodieBDI number: nb_foodies;
        create SportsFanBDI number: nb_sports_fans;
        
        int total_guests <- length(PartyPersonBDI) + length(IntrovertBDI) + length(MusicLoverBDI) + length(FoodieBDI) + length(SportsFanBDI);
        write "✓ BDI Simulation started: " + total_guests + " guests, " + length(all_locations) + " locations";
    }
    
    reflex update_global_happiness {
        list<GuestBDI> all_guests <- (list(PartyPersonBDI) + list(IntrovertBDI) + list(MusicLoverBDI) + list(FoodieBDI) + list(SportsFanBDI));
        if length(all_guests) > 0 {
            global_happiness <- mean(all_guests collect each.happiness);
            happiness_history << global_happiness;
        }
    }
    
    reflex monitor_stats when: every(50#cycle) {
        write "=== Cycle " + cycle + " Stats ===";
        write "Global Happiness: " + with_precision(global_happiness, 3);
        write "Total Interactions: " + total_interactions;
        write "Positive: " + total_positive_interactions + " | Negative: " + total_negative_interactions;
        
        if cycle > 0 and cycle mod 500 = 0 {
            write "";
            write "╔════════════════════════════════════════════════╗";
            write "║     BDI ANALYSIS (Cycle " + cycle + ")         ║";
            write "╚════════════════════════════════════════════════╝";
            
            float positive_rate <- total_interactions > 0 ? (total_positive_interactions / float(total_interactions)) : 0.0;
            
            write "📊 BDI Behavior Metrics:";
            write "  • Average Happiness: " + with_precision(global_happiness, 3);
            write "  • Positive Interaction Rate: " + with_precision(positive_rate * 100, 1) + "%";
            write "  • Active Beliefs: " + sum((list(PartyPersonBDI) + list(IntrovertBDI) + list(MusicLoverBDI) + list(FoodieBDI) + list(SportsFanBDI)) collect length(each.get_beliefs()));
            write "  • Active Desires: " + sum((list(PartyPersonBDI) + list(IntrovertBDI) + list(MusicLoverBDI) + list(FoodieBDI) + list(SportsFanBDI)) collect length(each.get_desires()));
            write "  • Active Intentions: " + sum((list(PartyPersonBDI) + list(IntrovertBDI) + list(MusicLoverBDI) + list(FoodieBDI) + list(SportsFanBDI)) collect length(each.get_intentions()));
            
            write "";
            write "🔍 BDI Conclusion:";
            if global_happiness > 0.55 {
                write "  ✓ Agents successfully use BDI reasoning to find";
                write "    suitable venues matching their beliefs about";
                write "    environmental preferences.";
            } else if global_happiness < 0.45 {
                write "  ✗ Agents' desires conflict with environmental";
                write "    realities, leading to intention failures.";
            } else {
                write "  ≈ Mixed BDI performance: Some agents achieve";
                write "    desires while others struggle.";
            }
            write "═══════════════════════════════════════════════════";
        }
    }
}

// Location species remain the same
species Location {
    rgb color;
    float noise_level <- rnd(0.3, 1.0);
    list<GuestBDI> current_guests <- [];
    
    aspect default {
        draw circle(5) at: location color: color border: #black width: 1;
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

// BASE BDI GUEST SPECIES
species GuestBDI skills: [moving] control: simple_bdi {
    // Personal traits
    float generosity <- rnd(0.0, 1.0);
    float sociability <- rnd(0.0, 1.0);
    float tolerance <- rnd(0.0, 1.0);
    
    // State variables
    float happiness <- 0.5;
    Location target_location <- nil;
    Location current_location <- nil;
    rgb color;
    float speed <- 2.0;
    
    // Interaction tracking
    list<GuestBDI> friends <- [];
    list<GuestBDI> interacted_this_visit <- [];
    int time_at_location <- 0;
    int stay_duration <- rnd(30, 100);
    
    // BDI-specific variables
    float preferred_noise_min;
    float preferred_noise_max;
    
    init {
        // DESIRE: Initially all agents desire to find a suitable venue
        do add_desire(find_suitable_venue);
        // DESIRE: Agents also desire to improve their happiness
        do add_desire(improve_happiness);
    }
    
    // PERCEPTION: Detect suitable venues based on noise preference
perceive target: Location in: 1000.0 {
    // Check if venue matches noise preferences
    bool is_suitable <- (noise_level >= myself.preferred_noise_min and noise_level <= myself.preferred_noise_max);
    
    if (is_suitable) {
        focus id: suitable_venue_found var: location;
        ask myself {
            if (target_location = nil) {
                target_location <- Location first_with (each.location = myself.location);
                do add_desire(go_to_venue);
            }
        }
    } else if (noise_level > myself.preferred_noise_max) {
        focus id: venue_too_noisy var: location;
    } else {
        focus id: venue_too_quiet var: location;
    }
}

// PERCEPTION: Detect friends at locations
perceive target: GuestBDI in: 1000.0 {
    // Check if this is a friend at a different location
    bool is_friend <- (self in myself.friends);
    bool at_different_location <- (current_location != nil and current_location != myself.current_location);
    
    if (is_friend and at_different_location) {
        focus id: friend_nearby var: location;
    }
}
    
    // BDI RULE: If agent knows suitable venue and is unhappy, desire to go there
    rule belief: new_predicate(suitable_venue_found) new_desire: go_to_venue strength: 3.0;
    
    // BDI RULE: If agent has few friends, desire to make more
    rule belief: new_predicate(lonely) new_desire: make_friends strength: 2.5;
    
    // BDI RULE: If friend is at different venue, consider joining
    rule belief: new_predicate(friend_nearby) new_desire: join_friend strength: 2.0;
    
    // PLAN: Wander to find suitable venues
    plan wander_to_find intention: find_suitable_venue {
        if target_location = nil or current_location = nil {
            do wander speed: speed;
            write "[BDI] " + name + " wandering to find suitable venue (Intention: find_suitable_venue)";
        } else {
            do remove_intention(find_suitable_venue, false);
        }
    }
    
    // PLAN: Go to known suitable venue
    plan go_to_suitable_venue intention: go_to_venue {
        if target_location != nil {
            do goto target: target_location.location speed: speed;
            write "[BDI] " + name + " executing plan to go to venue (Intention: go_to_venue)";
            
            if location distance_to target_location.location < 1.0 {
                location <- target_location.location;
                current_location <- target_location;
                
                if !(self in current_location.current_guests) {
                    current_location.current_guests << self;
                }
                
                time_at_location <- 0;
                interacted_this_visit <- [];
                
                write "✓ [BDI] " + name + " ARRIVED at " + current_location + " (achieved intention: go_to_venue)";
                do remove_intention(go_to_venue, true);
                do add_desire(socialize);
            }
        }
    }
    
    // PLAN: Socialize with others
    plan interact_with_others intention: socialize {
        time_at_location <- time_at_location + 1;
        
        if current_location != nil {
            list<GuestBDI> others <- current_location.current_guests - self - interacted_this_visit;
            float interaction_chance <- 0.2 + (sociability * 0.3);
            
            if length(others) > 0 and flip(interaction_chance) {
                GuestBDI other <- one_of(others);
                do interact_with(other);
                interacted_this_visit << other;
                
                write "[BDI] " + name + " socializing with " + other.name + " (Intention: socialize)";
                
                // Build friendships
                float friendship_chance <- 0.2 + (tolerance * 0.3);
                if flip(friendship_chance) and !(other in friends) {
                    friends << other;
                    ask other {
                        if !(myself in friends) {
                            friends << myself;
                        }
                    }
                    
                    // Update belief about loneliness
                    if length(friends) > 3 {
                        do remove_belief(new_predicate(lonely));
                    }
                    
                    write "  💛 [BDI] " + name + " and " + other.name + " became friends! (updated beliefs)";
                }
            }
            
            // Leave after stay duration
            if time_at_location >= stay_duration {
                write "→ [BDI] " + name + " completed stay, removing socialize intention";
                do leave_venue();
            }
        }
    }
    
    // PLAN: Join friend at their venue
    plan join_friend_venue intention: join_friend instantaneous: true {
        list<mental_state> friend_beliefs <- get_beliefs_with_name(friend_nearby);
        
        if length(friend_beliefs) > 0 {
            mental_state belief <- friend_beliefs[0];
            Location friend_location <- Location(get_predicate(belief).values["location_value"]);
            
            if friend_location != nil and friend_location != current_location {
                write "[BDI] " + name + " deciding to join friend at " + friend_location;
                do leave_venue();
                target_location <- friend_location;
                do add_desire(go_to_venue);
            }
        }
        
        do remove_intention(join_friend, true);
    }
    
    // Helper actions
//    action evaluate_venue(Location venue) {
//        if venue.noise_level >= preferred_noise_min and venue.noise_level <= preferred_noise_max {
//            do add_belief(new_predicate(suitable_venue_found, ["location_value"::venue.location]));
//            
//            if target_location = nil {
//                target_location <- venue;
//                write "[BDI] " + name + " formed BELIEF: suitable venue found at " + venue;
//                do add_desire(go_to_venue);
//            }
//        } else if venue.noise_level > preferred_noise_max {
//            do add_belief(new_predicate(venue_too_noisy, ["location_value"::venue.location]));
//        } else {
//            do add_belief(new_predicate(venue_too_quiet, ["location_value"::venue.location]));
//        }
//    }
    
    action detect_friend_at_venue(GuestBDI friend, Location venue) {
        do add_belief(new_predicate(friend_nearby, ["friend_name"::friend.name, "location_value"::venue]));
        write "[BDI] " + name + " formed BELIEF: friend " + friend.name + " is at " + venue;
    }
    
    action leave_venue {
        if current_location != nil {
            current_location.current_guests >> self;
            write "  ← [BDI] " + name + " left " + current_location;
        }
        
        current_location <- nil;
        target_location <- nil;
        time_at_location <- 0;
        interacted_this_visit <- [];
        
        // Reset beliefs about current venue
        do remove_intention(socialize, true);
        do add_desire(find_suitable_venue);
        
        // Check if lonely
        if length(friends) < 2 {
            do add_belief(new_predicate(lonely));
        }
    }
    
    action interact_with(GuestBDI other) {
        // To be overridden by subclasses
    }
    
    action update_happiness(float delta) {
        happiness <- happiness + delta;
        happiness <- max(0.0, min(1.0, happiness));
        
        // Update desire to improve happiness based on current state
        if happiness < 0.4 {
            if !has_desire(improve_happiness) {
                do add_desire(improve_happiness);
            }
        }
    }
    
    aspect default {
        draw circle(1.5) color: color border: #black;
        rgb happiness_color <- rgb(255 * (1 - happiness), 255 * happiness, 0);
        draw circle(0.7) color: happiness_color at: location + {0, 2.5};
        
        // Show BDI state
        if length(get_current_intention()) > 0 {
            draw square(0.5) at: location + {0, -2} color: #blue; // Has intention
        }
    }
}

// PARTY PERSON BDI
species PartyPersonBDI parent: GuestBDI {
    init {
        color <- #red;
        sociability <- rnd(0.7, 1.0);
        generosity <- rnd(0.5, 1.0);
        tolerance <- rnd(0.4, 0.8);
        preferred_noise_min <- 0.6;
        preferred_noise_max <- 1.0;
        
        write "[BDI INIT] " + name + " (PartyPerson) - Prefers noisy venues (0.6-1.0)";
    }
    
    action interact_with(GuestBDI other) {
        total_interactions <- total_interactions + 1;
        
        if current_location != nil and current_location.noise_level > 0.6 {
            do update_happiness(0.02);
            
            if other is IntrovertBDI {
                ask other {
                    do update_happiness(-0.05);
                }
                total_negative_interactions <- total_negative_interactions + 1;
            } else if other is PartyPersonBDI or other is MusicLoverBDI {
                do update_happiness(0.03);
                ask other {
                    do update_happiness(0.03);
                }
                total_positive_interactions <- total_positive_interactions + 1;
                
                if generosity > 0.7 and flip(generosity * 0.5) {
                    ask other {
                        do update_happiness(0.03);
                    }
                    write "  🍺 [BDI] " + name + " bought drink (generosity-based action)";
                }
            } else {
                total_positive_interactions <- total_positive_interactions + 1;
            }
        } else {
            do update_happiness(0.01);
            total_positive_interactions <- total_positive_interactions + 1;
        }
    }
}

// INTROVERT BDI
species IntrovertBDI parent: GuestBDI {
    init {
        color <- #lightblue;
        sociability <- rnd(0.1, 0.4);
        tolerance <- rnd(0.2, 0.6);
        generosity <- rnd(0.3, 0.7);
        preferred_noise_min <- 0.0;
        preferred_noise_max <- 0.5;
        
        write "[BDI INIT] " + name + " (Introvert) - Prefers quiet venues (0.0-0.5)";
    }
    
    action interact_with(GuestBDI other) {
        total_interactions <- total_interactions + 1;
        
        if current_location != nil and current_location.noise_level < 0.5 {
            do update_happiness(0.02);
            
            if other is IntrovertBDI or other is FoodieBDI {
                do update_happiness(0.03);
                ask other {
                    do update_happiness(0.02);
                }
                total_positive_interactions <- total_positive_interactions + 1;
            } else if other is PartyPersonBDI {
                if tolerance > 0.5 {
                    do update_happiness(-0.01);
                    write "  😌 [BDI] " + name + " tolerated party person (tolerance trait)";
                } else {
                    do update_happiness(-0.03);
                }
                total_negative_interactions <- total_negative_interactions + 1;
            } else {
                total_positive_interactions <- total_positive_interactions + 1;
            }
        } else {
            float noise_penalty <- -0.04 * (1.0 - tolerance);
            do update_happiness(noise_penalty);
            
            if other is PartyPersonBDI {
                if tolerance > 0.6 {
                    do update_happiness(-0.01);
                } else {
                    do update_happiness(-0.03);
                }
                total_negative_interactions <- total_negative_interactions + 1;
            } else {
                total_negative_interactions <- total_negative_interactions + 1;
            }
        }
    }
}

// MUSIC LOVER BDI
species MusicLoverBDI parent: GuestBDI {
    string favorite_genre <- one_of(["rock", "pop", "jazz", "electronic"]);
    
    init {
        color <- #magenta;
        sociability <- rnd(0.5, 0.9);
        tolerance <- rnd(0.6, 1.0);
        generosity <- rnd(0.4, 0.8);
        preferred_noise_min <- 0.5;
        preferred_noise_max <- 1.0;
        
        write "[BDI INIT] " + name + " (MusicLover) - Prefers concerts/noisy venues, favorite genre: " + favorite_genre;
    }
    
    action interact_with(GuestBDI other) {
        total_interactions <- total_interactions + 1;
        
        if current_location != nil {
            if current_location is Concert {
                Concert concert <- Concert(current_location);
                
                if concert.music_genre = favorite_genre {
                    do update_happiness(0.05);
                    
                    if other is MusicLoverBDI {
                        MusicLoverBDI ml <- MusicLoverBDI(other);
                        if ml.favorite_genre = favorite_genre {
                            do update_happiness(0.04);
                            ask other {
                                do update_happiness(0.04);
                            }
                            total_positive_interactions <- total_positive_interactions + 1;
                        } else {
                            do update_happiness(0.01);
                            total_positive_interactions <- total_positive_interactions + 1;
                        }
                    } else {
                        total_positive_interactions <- total_positive_interactions + 1;
                    }
                } else {
                    do update_happiness(0.01);
                    total_positive_interactions <- total_positive_interactions + 1;
                }
            } else {
                total_positive_interactions <- total_positive_interactions + 1;
            }
        }
    }
}

// FOODIE BDI
species FoodieBDI parent: GuestBDI {
    string diet_preference <- one_of(["vegetarian", "vegan", "meat", "flexible"]);
    
    init {
        color <- #yellow;
        sociability <- rnd(0.4, 0.7);
        tolerance <- rnd(0.5, 0.9);
        generosity <- rnd(0.6, 1.0);
        preferred_noise_min <- 0.0;
        preferred_noise_max <- 0.5;
        
        write "[BDI INIT] " + name + " (Foodie) - Prefers quiet restaurants, diet: " + diet_preference;
    }
    
    action interact_with(GuestBDI other) {
        total_interactions <- total_interactions + 1;
        
        if current_location != nil {
            if current_location is Restaurant {
                Restaurant rest <- Restaurant(current_location);
                
                bool food_match <- (diet_preference = "flexible") or 
                                  (diet_preference = "vegan" and rest.cuisine_type = "vegan") or
                                  (diet_preference = "meat" and rest.cuisine_type = "steakhouse");
                
                if food_match {
                    do update_happiness(0.04);
                    
                    if other is FoodieBDI {
                        do update_happiness(0.03);
                        ask other {
                            do update_happiness(0.03);
                        }
                        total_positive_interactions <- total_positive_interactions + 1;
                        
                        if generosity > 0.75 and flip(generosity * 0.6) {
                            ask other {
                                do update_happiness(0.03);
                            }
                            write "  🍽️ [BDI] " + name + " shared food (generosity-based action)";
                        }
                    } else {
                        total_positive_interactions <- total_positive_interactions + 1;
                    }
                } else {
                    do update_happiness(-0.01);
                    total_negative_interactions <- total_negative_interactions + 1;
                }
            } else {
                total_positive_interactions <- total_positive_interactions + 1;
            }
        }
    }
}

// SPORTS FAN BDI
species SportsFanBDI parent: GuestBDI {
    string favorite_sport <- one_of(["football", "basketball", "tennis"]);
    
    init {
        color <- #darkgreen;
        sociability <- rnd(0.6, 0.95);
        tolerance <- rnd(0.5, 0.85);
        generosity <- rnd(0.5, 0.9);
        preferred_noise_min <- 0.4;
        preferred_noise_max <- 1.0;
        
        write "[BDI INIT] " + name + " (SportsFan) - Prefers sports venues, favorite sport: " + favorite_sport;
    }
    
    action interact_with(GuestBDI other) {
        total_interactions <- total_interactions + 1;
        
        if current_location != nil {
            if current_location is SportsVenue {
                SportsVenue venue <- SportsVenue(current_location);
                
                if venue.sport_type = favorite_sport {
                    do update_happiness(0.05);
                    
                    if other is SportsFanBDI {
                        SportsFanBDI sf <- SportsFanBDI(other);
                        if sf.favorite_sport = favorite_sport {
                            do update_happiness(0.05);
                            ask other {
                                do update_happiness(0.05);
                            }
                            total_positive_interactions <- total_positive_interactions + 1;
                        } else {
                            total_positive_interactions <- total_positive_interactions + 1;
                        }
                    } else {
                        total_positive_interactions <- total_positive_interactions + 1;
                    }
                } else {
                    total_positive_interactions <- total_positive_interactions + 1;
                }
            } else {
                total_positive_interactions <- total_positive_interactions + 1;
            }
        }
    }
}

experiment BDISimulation type: gui {
    parameter "Party People" var: nb_party_people min: 5 max: 30;
    parameter "Introverts" var: nb_introverts min: 5 max: 30;
    parameter "Music Lovers" var: nb_music_lovers min: 5 max: 30;
    parameter "Foodies" var: nb_foodies min: 5 max: 30;
    parameter "Sports Fans" var: nb_sports_fans min: 5 max: 30;
    
    float minimum_cycle_duration <- 0.01;
    
    output {
        display main_display type: java2D background: #white {
            graphics "world_boundary" {
                draw square(100) at: {50, 50} color: #lightgray border: #black width: 2;
            }
            graphics "locations" {
                loop loc over: all_locations {
                    draw circle(7) at: loc.location color: rgb(loc.color, 0.2) border: loc.color width: 2;
                    draw string(length(loc.current_guests)) at: loc.location + {0, -1} color: #black size: 10;
                }
            }
            species Bar aspect: default;
            species Concert aspect: default;
            species Restaurant aspect: default;
            species SportsVenue aspect: default;
            species PartyPersonBDI aspect: default;
            species IntrovertBDI aspect: default;
            species MusicLoverBDI aspect: default;
            species FoodieBDI aspect: default;
            species SportsFanBDI aspect: default;
        }
        
        display happiness_chart background: #white refresh: every(5#cycle) {
            chart "Global Happiness Over Time (BDI)" type: series y_range: [0.0, 1.0] {
                data "Average Happiness" value: global_happiness color: #blue;
                data "Baseline (0.5)" value: 0.5 color: #gray;
            }
        }
        
        display interaction_chart background: #white refresh: every(10#cycle) {
            chart "Positive vs Negative Interactions (BDI)" type: series {
                data "Positive" value: total_positive_interactions color: #green;
                data "Negative" value: total_negative_interactions color: #red;
            }
        }
        
        display bdi_chart background: #white refresh: every(10#cycle) {
            chart "BDI Architecture Activity" type: series {
                data "Total Beliefs" value: sum((list(PartyPersonBDI) + list(IntrovertBDI) + list(MusicLoverBDI) + list(FoodieBDI) + list(SportsFanBDI)) collect length(each.get_beliefs())) color: #orange;
                data "Total Desires" value: sum((list(PartyPersonBDI) + list(IntrovertBDI) + list(MusicLoverBDI) + list(FoodieBDI) + list(SportsFanBDI)) collect length(each.get_desires())) color: #purple;
                data "Total Intentions" value: sum((list(PartyPersonBDI) + list(IntrovertBDI) + list(MusicLoverBDI) + list(FoodieBDI) + list(SportsFanBDI)) collect length(each.get_intentions())) color: #red;
            }
        }
        
        monitor "Cycle" value: cycle;
        monitor "Global Happiness" value: global_happiness;
        monitor "Total Beliefs" value: sum((list(PartyPersonBDI) + list(IntrovertBDI) + list(MusicLoverBDI) + list(FoodieBDI) + list(SportsFanBDI)) collect length(each.get_beliefs()));
        monitor "Total Desires" value: sum((list(PartyPersonBDI) + list(IntrovertBDI) + list(MusicLoverBDI) + list(FoodieBDI) + list(SportsFanBDI)) collect length(each.get_desires()));
        monitor "Total Intentions" value: sum((list(PartyPersonBDI) + list(IntrovertBDI) + list(MusicLoverBDI) + list(FoodieBDI) + list(SportsFanBDI)) collect length(each.get_intentions()));
        monitor "Total Interactions" value: total_interactions;
        monitor "Positive/Negative Ratio" value: total_interactions > 0 ? total_positive_interactions / float(total_interactions) : 0.0;
    }
}