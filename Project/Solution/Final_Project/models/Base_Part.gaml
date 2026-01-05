/**
* Name: Social Agents Simulation - Final Project
* Author: Sakib, Ahsan, Sing 
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
    float global_happiness <- 0.5;
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
        list<Guest> all_guests <- (list(PartyPerson) + list(Introvert) + list(MusicLover) + list(Foodie) + list(SportsFan));
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
        
        // Draw conclusions periodically
        if cycle > 0 and cycle mod 500 = 0 {
            write "";
            write "╔════════════════════════════════════════════════╗";
            write "║          SIMULATION ANALYSIS (Cycle " + cycle + ")      ║";
            write "╚════════════════════════════════════════════════╝";
            
            float positive_rate <- total_interactions > 0 ? (total_positive_interactions / float(total_interactions)) : 0.0;
            
            write "📊 Key Metrics:";
            write "  • Average Happiness: " + with_precision(global_happiness, 3);
            write "  • Positive Interaction Rate: " + with_precision(positive_rate * 100, 1) + "%";
            
            write "";
            write "🔍 Conclusion:";
            
            if global_happiness > 0.55 {
                write "  ✓ POSITIVE ENVIRONMENT: When compatible personality types";
                write "    meet in appropriate locations (e.g., Introverts in quiet";
                write "    Restaurants, Party People at Bars), overall happiness rises.";
            } else if global_happiness < 0.45 {
                write "  ✗ NEGATIVE ENVIRONMENT: Personality mismatches in unsuitable";
                write "    locations (e.g., Introverts forced into noisy Concerts/Bars)";
                write "    significantly decrease overall happiness.";
            } else {
                write "  ≈ BALANCED ENVIRONMENT: Mixed interactions create neutral";
                write "    happiness. Some agents thrive while others struggle.";
            }
            
            write "";
            write "💡 Insight:";
            if positive_rate > 0.55 {
                write "  → Compatibility matters! Matching agent types with suitable";
                write "    venues leads to more positive social interactions.";
            } else {
                write "  → Context is everything! The same agents can have vastly";
                write "    different experiences based on location characteristics.";
            }
            write "═══════════════════════════════════════════════════";
            write "";
        }
    }
}

// Base species for all locations
species Location {
    rgb color;
    float noise_level <- rnd(0.3, 1.0);
    list<Guest> current_guests <- [];
    
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

// Base Guest species
species Guest skills: [fipa, moving] {
    // Personal traits (at least 3)
    float generosity <- rnd(0.0, 1.0);
    float sociability <- rnd(0.0, 1.0);
    float tolerance <- rnd(0.0, 1.0);
    
    // State variables
    float happiness <- 0.5;
    Location target_location <- nil;
    Location current_location <- nil;
    bool has_arrived <- false;
    rgb color;
    
    // Movement and timing
    int time_at_location <- 0;
    int min_stay_time <- 30;
    int max_stay_time <- 100;
    int stay_duration <- rnd(30, 100);
    
    // Interaction tracking
    list<Guest> interacted_this_visit <- [];
    list<Guest> friends <- [];
    
    // FIPA cooldown to prevent message spam
    int last_invitation_sent <- -100;
    int last_invitation_received <- -100;
    
    init {
        if length(all_locations) > 0 {
            do choose_new_location;
        }
    }
    
    // FIPA Messaging - Send invitations with cooldown
    reflex send_invitation when: has_arrived and 
                                  time_at_location > 10 and 
                                  (cycle - last_invitation_sent) > 50 and
                                  flip(0.05) and 
                                  length(friends) > 0 {
        Guest friend <- one_of(friends);
        
        // Only send if friend is at a different location
        if friend.current_location != nil and friend.current_location != current_location {
            do start_conversation to: [friend] protocol: 'fipa-request' 
               performative: 'inform' 
               contents: ['invitation', current_location];
            
            last_invitation_sent <- cycle;
            write "📧 " + name + " → " + friend.name + ": Come to " + current_location;
        }
    }
    
    // FIPA Messaging - Receive and process messages with cooldown
    reflex receive_messages when: !empty(informs) and (cycle - last_invitation_received) > 30 {
        // If multiple invitations received, choose based on sociability and friendship
        if length(informs) > 1 {
            write "📬📬 " + name + " received " + length(informs) + " invitations simultaneously!";
        }
        
        // Collect all valid invitations
        list<message> valid_invitations <- [];
        loop msg over: informs {
            Guest sender <- Guest(msg.sender);
            if sender != nil and sender.current_location != nil {
                valid_invitations << msg;
            }
        }
        
        // Process invitations
        if length(valid_invitations) > 0 {
            message chosen_invitation <- nil;
            
            if length(valid_invitations) = 1 {
                // Only one invitation
                chosen_invitation <- valid_invitations[0];
            } else {
                // Multiple invitations - choose based on friendship and sociability
                write "  🤔 " + name + " must choose between " + length(valid_invitations) + " invitations...";
                
                // High sociability = more likely to accept any invitation
                if sociability > 0.7 {
                    // Very social - prioritize friends
                    list<message> friend_invitations <- [];
                    loop msg over: valid_invitations {
                        Guest sender <- Guest(msg.sender);
                        if sender in friends {
                            friend_invitations << msg;
                        }
                    }
                    
                    if length(friend_invitations) > 0 {
                        chosen_invitation <- one_of(friend_invitations);
                        write "  👥 Chose friend's invitation (high sociability)";
                    } else {
                        chosen_invitation <- one_of(valid_invitations);
                        write "  🎲 Chose random invitation";
                    }
                } else if sociability > 0.4 {
                    // Moderately social - only accept if from friend
                    list<message> friend_invitations <- [];
                    loop msg over: valid_invitations {
                        Guest sender <- Guest(msg.sender);
                        if sender in friends {
                            friend_invitations << msg;
                        }
                    }
                    
                    if length(friend_invitations) > 0 {
                        chosen_invitation <- one_of(friend_invitations);
                        write "  👥 Chose friend's invitation";
                    } else {
                        write "  ✗ Declined all - no friends";
                    }
                } else {
                    // Low sociability
                    write "  ✗ Declined all - too introverted";
                }
            }
            
            // Accept chosen invitation with probability
            if chosen_invitation != nil and flip(0.3) {
                Guest sender <- Guest(chosen_invitation.sender);
                write "  ✓ " + name + " accepted invitation from " + sender.name;
                
                // Go to friend's location
                do leave_and_choose_new_location;
                target_location <- sender.current_location;
                has_arrived <- false;
                stay_duration <- rnd(min_stay_time, max_stay_time);
                last_invitation_received <- cycle;
                
                // Reply back
                do start_conversation to: [sender] protocol: 'fipa-request' 
                   performative: 'agree' 
                   contents: ['accepted'];
                   
                // Reject others if multiple
                if length(valid_invitations) > 1 {
                    loop msg over: valid_invitations {
                        if msg != chosen_invitation {
                            Guest rejected_sender <- Guest(msg.sender);
                            do start_conversation to: [rejected_sender] protocol: 'fipa-request' 
                               performative: 'refuse' 
                               contents: ['sorry, busy'];
                            write "  ✗ Rejected " + rejected_sender.name + "'s invitation";
                        }
                    }
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
    
    // Receive rejection messages
    reflex receive_rejections when: !empty(refuses) {
        loop msg over: refuses {
            write "  😔 " + name + "'s invitation was rejected by " + Guest(msg.sender).name;
            do update_happiness(-0.01);
        }
    }
    
    reflex move_to_location when: target_location != nil and !has_arrived {
        float dist <- location distance_to target_location.location;
        
        if dist > 1.0 {
            do goto target: target_location.location speed: 2.0;
        } else {
            // Arrived!
            location <- target_location.location;
            current_location <- target_location;
            has_arrived <- true;
            time_at_location <- 0;
            interacted_this_visit <- [];
            
            if !(self in current_location.current_guests) {
                current_location.current_guests << self;
            }
            
            write "✓ " + name + " ARRIVED at " + current_location + " (guests: " + length(current_location.current_guests) + ")";
        }
    }
    
    reflex stay_and_interact when: has_arrived and current_location != nil {
        time_at_location <- time_at_location + 1;
        
        // Try to interact with others at this location
        list<Guest> others <- current_location.current_guests - self - interacted_this_visit;
        
        // SOCIABILITY affects interaction frequency
        float interaction_chance <- 0.2 + (sociability * 0.3);
        
        if length(others) > 0 and flip(interaction_chance) {
            Guest other <- one_of(others);
            do interact_with(other);
            interacted_this_visit << other;
            
            // TOLERANCE affects friendship building
            float friendship_chance <- 0.2 + (tolerance * 0.3);
            
            if flip(friendship_chance) and !(other in friends) {
                friends << other;
                ask other {
                    if !(myself in friends) {
                        friends << myself;
                    }
                }
                write "  💛 " + name + " and " + other.name + " became friends! (tolerance: " + with_precision(tolerance,2) + ")";
            }
        }
        
        // Leave after stay duration
        if time_at_location >= stay_duration {
            write "→ " + name + " LEAVING " + current_location + " after " + time_at_location + " cycles";
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
        if current_location != nil {
            current_location.current_guests >> self;
            write "  ← " + name + " unregistered from " + current_location;
        }
        
        // Reset state
        current_location <- nil;
        target_location <- nil;
        has_arrived <- false;
        time_at_location <- 0;
        interacted_this_visit <- [];
        
        // Choose new destination
        do choose_new_location;
        write "  → " + name + " heading to NEW location: " + target_location;
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
        
        if current_location.noise_level > 0.6 {
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
                
                // GENEROSITY
                if generosity > 0.7 and flip(generosity * 0.5) {
                    ask other {
                        do update_happiness(0.03);
                    }
                    write "  🍺 " + name + " bought " + other.name + " a drink! (generosity: " + with_precision(generosity,2) + ")";
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
        
        if current_location.noise_level < 0.5 {
            do update_happiness(0.02);
            
            if other is Introvert or other is Foodie {
                do update_happiness(0.03);
                ask other {
                    do update_happiness(0.02);
                }
                total_positive_interactions <- total_positive_interactions + 1;
            } else if other is PartyPerson {
                if tolerance > 0.5 {
                    do update_happiness(-0.01);
                    write "  😌 " + name + " tolerated " + other.name + "'s energy (tolerance: " + with_precision(tolerance,2) + ")";
                } else {
                    do update_happiness(-0.03);
                }
                total_negative_interactions <- total_negative_interactions + 1;
            } else {
                total_positive_interactions <- total_positive_interactions + 1;
            }
        } else {
            // In noisy place
            float noise_penalty <- -0.04 * (1.0 - tolerance);
            do update_happiness(noise_penalty);
            
            if other is PartyPerson {
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
        
        if current_location is Concert {
            Concert concert <- Concert(current_location);
            
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
                        total_positive_interactions <- total_positive_interactions + 1;
                    }
                } else if other is PartyPerson {
                    do update_happiness(0.02);
                    ask other {
                        do update_happiness(0.02);
                    }
                    total_positive_interactions <- total_positive_interactions + 1;
                } else {
                    total_positive_interactions <- total_positive_interactions + 1;
                }
            } else {
                do update_happiness(0.01);
                total_positive_interactions <- total_positive_interactions + 1;
            }
        } else {
            if tolerance > 0.7 {
                do update_happiness(0.01);
            }
            total_positive_interactions <- total_positive_interactions + 1;
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
        
        if current_location is Restaurant {
            Restaurant rest <- Restaurant(current_location);
            
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
                    
                    if generosity > 0.75 and flip(generosity * 0.6) {
                        ask other {
                            do update_happiness(0.03);
                        }
                        write "  🍽️ " + name + " shared food with " + other.name + "! (generosity: " + with_precision(generosity,2) + ")";
                    }
                } else if other is Introvert {
                    do update_happiness(0.02);
                    ask other {
                        do update_happiness(0.02);
                    }
                    total_positive_interactions <- total_positive_interactions + 1;
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
        
        if current_location is SportsVenue {
            SportsVenue venue <- SportsVenue(current_location);
            
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
                    } else {
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
                } else {
                    total_positive_interactions <- total_positive_interactions + 1;
                }
            } else {
                total_positive_interactions <- total_positive_interactions + 1;
            }
        } else {
            if sociability > 0.7 {
                do update_happiness(0.01);
            }
            total_positive_interactions <- total_positive_interactions + 1;
        }
    }
}

experiment SocialSimulation type: gui {
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
            species PartyPerson aspect: default;
            species Introvert aspect: default;
            species MusicLover aspect: default;
            species Foodie aspect: default;
            species SportsFan aspect: default;
        }
        
        display happiness_chart background: #white refresh: every(5#cycle) {
            chart "Global Happiness Over Time" type: series y_range: [0.0, 1.0] {
                data "Average Happiness" value: global_happiness color: #blue;
                data "Baseline (0.5)" value: 0.5 color: #gray;
            }
        }
        
        display interaction_chart background: #white refresh: every(10#cycle) {
            chart "Positive vs Negative Interactions" type: series {
                data "Positive" value: total_positive_interactions color: #green;
                data "Negative" value: total_negative_interactions color: #red;
            }
        }
        
        monitor "Cycle" value: cycle;
        monitor "Global Happiness" value: global_happiness;
        monitor "Total Interactions" value: total_interactions;
        monitor "Positive Interactions" value: total_positive_interactions;
        monitor "Negative Interactions" value: total_negative_interactions;
        monitor "Active Guests" value: length(PartyPerson) + length(Introvert) + length(MusicLover) + length(Foodie) + length(SportsFan);
        monitor "Total Locations" value: length(all_locations);
        monitor "Positive Rate %" value: total_interactions > 0 ? (total_positive_interactions / total_interactions * 100.0) : 0.0;
    }
}