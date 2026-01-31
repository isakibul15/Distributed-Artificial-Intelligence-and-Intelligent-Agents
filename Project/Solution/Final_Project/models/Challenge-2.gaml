/**
* Challenge-02
* Author: Sakib, Ahsan, Sing 
*/
model BDIRLSocialAgentsSimulation

global {
    int nb_party_people <- 12;
    int nb_introverts <- 10;
    int nb_music_lovers <- 10;
    int nb_foodies <- 10;
    int nb_sports_fans <- 8;
    
    list<Location> all_locations <- [];
    float global_happiness <- 0.5;
    int total_positive_interactions <- 0;
    int total_negative_interactions <- 0;
    int total_interactions <- 0;
    int total_plans_executed <- 0;
    
    // Q-Learning metrics
    float total_learning_improvements <- 0.0;
    int agents_learning_count <- 0;
    
    geometry shape <- square(100);
    
    init {
        create Bar number: 2 { all_locations << self; }
        create Concert number: 2 { all_locations << self; }
        create Restaurant number: 2 { all_locations << self; }
        create SportsVenue number: 2 { all_locations << self; }
        
        create PartyPerson number: nb_party_people;
        create Introvert number: nb_introverts;
        create MusicLover number: nb_music_lovers;
        create Foodie number: nb_foodies;
        create SportsFan number: nb_sports_fans;
        
        write "";
        write "╔═══════════════════════════════════════════════════════════════╗";
        write "║     BDI + Q-LEARNING SIMULATION - CHALLENGES 1 & 2          ║";
        write "╚═══════════════════════════════════════════════════════════════╝";
        write "✓ Total Agents: " + (nb_party_people + nb_introverts + nb_music_lovers + nb_foodies + nb_sports_fans);
        write "✓ BDI Architecture: Active";
        write "✓ Q-Learning: Active (α=0.1, γ=0.9, ε=0.2)";
        write "✓ FIPA Communication: Active";
        write "";
        write "═══════════════════════════════════════════════════════════════";
        write "                  Q-LEARNING FEATURES                          ";
        write "═══════════════════════════════════════════════════════════════";
        write "• Agents learn location preferences based on happiness";
        write "• Agents remember interactions with other agent types";
        write "• Agents avoid negative experiences and seek positive ones";
        write "• Learning improves over time (exploration → exploitation)";
        write "═══════════════════════════════════════════════════════════════";
        write "";      
    }
    
    reflex update_global_happiness {
        list<Guest> all_guests <- list(PartyPerson) + list(Introvert) + list(MusicLover) + list(Foodie) + list(SportsFan);
        if length(all_guests) > 0 {
            global_happiness <- mean(all_guests collect each.happiness);
        }
    }
    
    reflex monitor_stats when: every(100#cycle) {
        write "[Cycle " + cycle + "] Happiness: " + with_precision(global_happiness, 2) + 
              " | Interactions: " + total_interactions + 
              " | BDI Plans: " + total_plans_executed + 
              " | Learning Events: " + agents_learning_count;
    }
    
    reflex show_learning_progress when: cycle = 500 or cycle = 1000 or cycle = 1500 {
        write "";
        write "╔═══════════════════════════════════════════════════════════════╗";
        write "║           Q-LEARNING PROGRESS (Cycle " + cycle + ")                  ║";
        write "╚═══════════════════════════════════════════════════════════════╝";
        
        list<Guest> all_guests <- list(PartyPerson) + list(Introvert) + list(MusicLover) + list(Foodie) + list(SportsFan);
        float avg_q_max <- mean(all_guests collect max(each.q_location_values));
        
        write "📊 Average Max Q-Value: " + with_precision(avg_q_max, 3);
        write "📈 Learning Improvements: " + agents_learning_count;
        write "🎯 Agents are " + (avg_q_max > 0.3 ? "EXPLOITING learned knowledge" : "still EXPLORING");
        write "═══════════════════════════════════════════════════════════════";
        write "";
    }
}

species Location {
    rgb color;
    float noise_level <- rnd(0.3, 1.0);
    list<Guest> current_guests <- [];
    aspect default { draw circle(5) color: color; }
}

species Bar parent: Location {
    init { location <- {rnd(20.0, 80.0), rnd(20.0, 80.0)}; color <- #blue; noise_level <- rnd(0.6, 1.0); }
}

species Concert parent: Location {
    string music_genre <- one_of(["rock", "pop", "jazz"]);
    init { location <- {rnd(20.0, 80.0), rnd(20.0, 80.0)}; color <- #purple; noise_level <- rnd(0.7, 1.0); }
}

species Restaurant parent: Location {
    string cuisine_type <- one_of(["italian", "vegan", "steakhouse"]);
    init { location <- {rnd(20.0, 80.0), rnd(20.0, 80.0)}; color <- #orange; noise_level <- rnd(0.2, 0.5); }
}

species SportsVenue parent: Location {
    string sport_type <- one_of(["football", "basketball"]);
    init { location <- {rnd(20.0, 80.0), rnd(20.0, 80.0)}; color <- #green; noise_level <- rnd(0.5, 0.9); }
}

species Guest skills: [fipa, moving] control: simple_bdi {
    // Personal traits
    float generosity <- rnd(0.0, 1.0);
    float sociability <- rnd(0.0, 1.0);
    float tolerance <- rnd(0.0, 1.0);
    float happiness <- 0.5;
    float energy <- 1.0;
    Location target_location;
    Location current_location;
    bool has_arrived <- false;
    rgb color;
    int time_at_location <- 0;
    int stay_duration <- rnd(30, 100);
    list<Guest> interacted_this_visit <- [];
    list<Guest> friends <- [];
    int last_invitation_cycle <- -100;
    
    // ============================================
    // Q-LEARNING VARIABLES (Challenge 2)
    // ============================================
    
    // Q-Table for location preferences: Location → Q-value
    map<Location, float> q_location_values <- [];
    
    // Q-Table for agent type interactions: agent_type → Q-value
    map<string, float> q_agent_interaction_values <- [];
    
    // Experience memory
    Location previous_location;
    float previous_happiness;
    
    // Q-Learning hyperparameters
    float learning_rate <- 0.1;      // α - how much to update
    float discount_factor <- 0.9;     // γ - importance of future rewards
    float exploration_rate <- 0.2;    // ε - exploration vs exploitation
    
    // Learning statistics
    int times_learned <- 0;
    bool has_logged_learning <- false;
    
    init {
        if length(all_locations) > 0 {
            target_location <- one_of(all_locations);
        }
        
        // Initialize Q-tables with neutral values
        loop loc over: all_locations {
            q_location_values[loc] <- 0.0;
        }
        
        // Initialize agent type Q-values
        q_agent_interaction_values["PartyPerson"] <- 0.0;
        q_agent_interaction_values["Introvert"] <- 0.0;
        q_agent_interaction_values["MusicLover"] <- 0.0;
        q_agent_interaction_values["Foodie"] <- 0.0;
        q_agent_interaction_values["SportsFan"] <- 0.0;
        
        previous_happiness <- happiness;
    }
    
    // ============================================
    // Q-LEARNING: Location Selection with Learned Preferences
    // ============================================
    
    Location choose_location_with_learning {
        // ε-greedy strategy: explore vs exploit
        if flip(exploration_rate) {
            // EXPLORE: Random location
            return one_of(all_locations);
        } else {
            // EXPLOIT: Choose best learned location
            Location best_loc <- nil;
            float max_q <- -999.9;
            
            loop loc over: all_locations {
                if q_location_values[loc] > max_q {
                    max_q <- q_location_values[loc];
                    best_loc <- loc;
                }
            }
            
            return best_loc != nil ? best_loc : one_of(all_locations);
        }
    }
    
    // ============================================
    // Q-LEARNING: Update Q-values based on experience
    // ============================================
    
    action learn_from_experience {
        if previous_location != nil {
            // Calculate reward (change in happiness)
            float reward <- happiness - previous_happiness;
            
            // Get current Q-value
            float old_q <- q_location_values[previous_location];
            
            // Get max Q-value of current location (future reward)
            float max_future_q <- current_location != nil ? q_location_values[current_location] : 0.0;
            
            // Q-Learning update rule: Q(s,a) = Q(s,a) + α[r + γ*max(Q(s',a')) - Q(s,a)]
            float new_q <- old_q + learning_rate * (reward + discount_factor * max_future_q - old_q);
            q_location_values[previous_location] <- new_q;
            
            // Log significant learning events
            if abs(reward) > 0.05 and !has_logged_learning {
                string result_type <- reward > 0 ? "POSITIVE" : "NEGATIVE";
                write "🎓 Q-LEARNING: " + name;
                write "   Location: " + previous_location + " | Reward: " + with_precision(reward, 3);
                write "   Q-value: " + with_precision(old_q, 3) + " → " + with_precision(new_q, 3);
                write "   Result: " + result_type + " experience learned!";
                has_logged_learning <- true;
                times_learned <- times_learned + 1;
                agents_learning_count <- agents_learning_count + 1;
            }
        }
        
        // Update previous state
        previous_location <- current_location;
        previous_happiness <- happiness;
    }
    
    // ============================================
    // Q-LEARNING: Learn from agent interactions
    // ============================================
    
    action learn_from_interaction(Guest other, float interaction_reward) {
        string other_type <- "";
        
        if other is PartyPerson { other_type <- "PartyPerson"; }
        else if other is Introvert { other_type <- "Introvert"; }
        else if other is MusicLover { other_type <- "MusicLover"; }
        else if other is Foodie { other_type <- "Foodie"; }
        else if other is SportsFan { other_type <- "SportsFan"; }
        
        if other_type != "" {
            float old_q <- q_agent_interaction_values[other_type];
            float new_q <- old_q + learning_rate * (interaction_reward - old_q);
            q_agent_interaction_values[other_type] <- new_q;
            
            // Log learning
            if abs(interaction_reward) > 0.03 and flip(0.1) {
                write "🎓 INTERACTION LEARNING: " + name + " learned about " + other_type;
                write "   Q-value: " + with_precision(old_q, 3) + " → " + with_precision(new_q, 3);
            }
        }
    }
    
    // ============================================
    // Q-LEARNING: Decide whether to interact based on learned experience
    // ============================================
    
    bool should_interact_with(Guest other) {
        string other_type <- "";
        
        if other is PartyPerson { other_type <- "PartyPerson"; }
        else if other is Introvert { other_type <- "Introvert"; }
        else if other is MusicLover { other_type <- "MusicLover"; }
        else if other is Foodie { other_type <- "Foodie"; }
        else if other is SportsFan { other_type <- "SportsFan"; }
        
        if other_type = "" { return true; }
        
        float learned_value <- q_agent_interaction_values[other_type];
        
        // If strongly negative learned experience, avoid with high probability
        if learned_value < -0.2 {
            if flip(0.7) {
                write "🚫 " + name + " AVOIDED " + other.name + " (" + other_type + ") due to past negative experience (Q=" + with_precision(learned_value, 2) + ")";
                return false;
            }
        }
        
        // If strongly positive, seek interaction
        if learned_value > 0.2 {
            return true;
        }
        
        return flip(sociability);
    }
    
    // ============================================
    // BDI PERCEPTION
    // ============================================
    
    reflex perceive_nearby_agents {
        list<Guest> nearby <- Guest at_distance 10.0;
        loop g over: nearby {
            if g is PartyPerson { do add_belief(new_predicate("party_person_nearby")); }
            else if g is Introvert { do add_belief(new_predicate("introvert_nearby")); }
            else if g is MusicLover { do add_belief(new_predicate("music_lover_nearby")); }
            else if g is Foodie { do add_belief(new_predicate("foodie_nearby")); }
            else if g is SportsFan { do add_belief(new_predicate("sports_fan_nearby")); }
            if g in friends { do add_belief(new_predicate("friend_nearby")); }
        }
    }
    
    reflex perceive_nearby_locations {
        list<Location> nearby_locs <- Location at_distance 20.0;
        loop loc over: nearby_locs {
            if loc is Bar { do add_belief(new_predicate("bar_nearby")); }
            else if loc is Concert { do add_belief(new_predicate("concert_nearby")); }
            else if loc is Restaurant { do add_belief(new_predicate("restaurant_nearby")); }
            else if loc is SportsVenue { do add_belief(new_predicate("sports_venue_nearby")); }
        }
    }
    
    reflex perceive_location when: current_location != nil and has_arrived {
        do add_belief(new_predicate("at_location"));
        if length(current_location.current_guests) > 5 { 
            do add_belief(new_predicate("crowded_location")); 
        } else { 
            do remove_belief(new_predicate("crowded_location")); 
        }
        
        // Q-LEARNING: Learn from location experience
        do learn_from_experience;
        has_logged_learning <- false;
    }
    
    rule belief: new_predicate("at_location") new_desire: new_predicate("socialize") strength: 0.8;
    
    reflex check_energy when: energy < 0.3 {
        do add_belief(new_predicate("low_energy"));
        do add_desire(new_predicate("rest"));
    }
    
    // ============================================
    // BDI PLANS
    // ============================================
    
    plan rest_plan intention: new_predicate("rest") when: energy < 0.5 finished_when: energy > 0.7 {
        energy <- min(1.0, energy + 0.05);
        do wander amplitude: 20.0;
        total_plans_executed <- total_plans_executed + 1;
    }
    
    plan socialize_plan intention: new_predicate("socialize") when: has_arrived and length(current_location.current_guests) > 1 {
        list<Guest> others <- current_location.current_guests - self - interacted_this_visit;
        if length(others) > 0 {
            Guest other <- one_of(others);
            
            // Q-LEARNING: Decide based on learned experience
            bool should_interact <- should_interact_with(other);
            
            if should_interact {
                do interact_with(other);
                interacted_this_visit << other;
                total_plans_executed <- total_plans_executed + 1;
                
                if flip(tolerance * 0.3) and !(other in friends) {
                    friends << other;
                    ask other { if !(myself in friends) { friends << myself; } }
                }
            }
        }
    }
    

    
    reflex send_invitation when: has_arrived and 
                                  (cycle - last_invitation_cycle) > 80 and
                                  length(friends) > 0 and flip(0.08) {
        Guest friend <- one_of(friends);
        if friend.current_location != current_location {
            do start_conversation to: [friend] protocol: 'fipa-request' 
               performative: 'inform' contents: ['invitation', current_location];
            last_invitation_cycle <- cycle;
        }
    }
    
    reflex receive_invitations when: !empty(informs) and (cycle - last_invitation_cycle) > 50 {
        loop msg over: informs {
            Guest sender <- Guest(msg.sender);
            if sender in friends and flip(0.4) {
                if current_location != nil { current_location.current_guests >> self; }
                current_location <- nil;
                target_location <- sender.current_location;
                has_arrived <- false;
                last_invitation_cycle <- cycle;
                do start_conversation to: [sender] protocol: 'fipa-request' 
                   performative: 'agree' contents: ['accepted'];
            }
        }
    }
    
    reflex move_to_location when: target_location != nil and !has_arrived {
        if location distance_to target_location.location > 1.0 {
            do goto target: target_location.location speed: 2.0;
        } else {
            location <- target_location.location;
            current_location <- target_location;
            has_arrived <- true;
            time_at_location <- 0;
            interacted_this_visit <- [];
            if !(self in current_location.current_guests) { current_location.current_guests << self; }
            do add_belief(new_predicate("arrived_at_location"));
            do add_desire(new_predicate("socialize"));
        }
    }
    
    reflex stay_and_interact when: has_arrived and current_location != nil {
        time_at_location <- time_at_location + 1;
        energy <- max(0.0, energy - 0.01);
        
        if time_at_location >= stay_duration {
            if current_location != nil { current_location.current_guests >> self; }
            current_location <- nil;
            
            // Q-LEARNING: Choose next location based on learned preferences
            target_location <- choose_location_with_learning();
            
            has_arrived <- false;
            time_at_location <- 0;
            interacted_this_visit <- [];
        }
    }
    
    action interact_with(Guest other) {}
    
    action update_happiness(float delta) {
        happiness <- max(0.0, min(1.0, happiness + delta));
    }
    
    aspect default {
        draw circle(1.5) color: color;
        // Show learning progress with glow
        if times_learned > 5 {
            draw circle(2.0) color: color at: location border: #yellow;
        }
    }
}

species PartyPerson parent: Guest {
    init {
        color <- #red;
        sociability <- rnd(0.7, 1.0);
        generosity <- rnd(0.5, 1.0);
        do add_belief(new_predicate("i_am_social"));
        do add_desire(new_predicate("find_lively_place"));
    }
    
    plan seek_party intention: new_predicate("find_lively_place") when: !has_arrived {
        list<Location> lively <- all_locations where (each.noise_level > 0.6);
        if length(lively) > 0 and target_location != nil and !(target_location in lively) {
            target_location <- one_of(lively);
            total_plans_executed <- total_plans_executed + 1;
        }
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        float reward <- 0.0;
        
        if current_location.noise_level > 0.6 {
            do update_happiness(0.02);
            if other is Introvert {
                reward <- -0.05;
                ask other { do update_happiness(-0.05); }
                total_negative_interactions <- total_negative_interactions + 1;
            } else {
                reward <- 0.03;
                do update_happiness(0.03);
                ask other { do update_happiness(0.02); }
                total_positive_interactions <- total_positive_interactions + 1;
            }
        } else {
            reward <- 0.01;
            total_positive_interactions <- total_positive_interactions + 1;
        }
        
        // Q-LEARNING: Learn from interaction
        do learn_from_interaction(other, reward);
    }
}

species Introvert parent: Guest {
    init {
        color <- #lightblue;
        sociability <- rnd(0.1, 0.4);
        tolerance <- rnd(0.2, 0.6);
        do add_belief(new_predicate("i_need_quiet"));
        do add_desire(new_predicate("find_peaceful_place"));
    }
    
    reflex detect_uncomfortable when: has_arrived and current_location != nil {
        if current_location.noise_level > 0.6 and tolerance < 0.5 {
            do add_belief(new_predicate("uncomfortable_environment"));
            do add_desire(new_predicate("escape_now"));
        }
    }
    
    plan escape_plan intention: new_predicate("escape_now") priority: 10 {
        list<Location> quiet <- all_locations where (each.noise_level < 0.5);
        if length(quiet) > 0 {
            if current_location != nil { current_location.current_guests >> self; }
            current_location <- nil;
            target_location <- one_of(quiet);
            has_arrived <- false;
            do update_happiness(-0.05);
            total_plans_executed <- total_plans_executed + 1;
        }
        do remove_intention(new_predicate("escape_now"), true);
    }
    
    plan seek_quiet intention: new_predicate("find_peaceful_place") when: !has_arrived {
        list<Location> quiet <- all_locations where (each.noise_level < 0.5);
        if length(quiet) > 0 and (target_location = nil or target_location.noise_level > 0.6) {
            target_location <- one_of(quiet);
            total_plans_executed <- total_plans_executed + 1;
        }
    }
    

    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        float reward <- 0.0;
        
        if current_location.noise_level < 0.5 {
            do update_happiness(0.02);
            if other is Introvert {
                reward <- 0.03;
                do update_happiness(0.03);
                ask other { do update_happiness(0.02); }
                total_positive_interactions <- total_positive_interactions + 1;
            } else if other is PartyPerson {
                reward <- -0.03;
                do update_happiness(-0.03);
                total_negative_interactions <- total_negative_interactions + 1;
            } else {
                reward <- 0.01;
                total_positive_interactions <- total_positive_interactions + 1;
            }
        } else {
            reward <- -0.04 * (1.0 - tolerance);
            do update_happiness(reward);
            total_negative_interactions <- total_negative_interactions + 1;
        }
        
        // Q-LEARNING: Learn from interaction
        do learn_from_interaction(other, reward);
    }
}

species MusicLover parent: Guest {
    string favorite_genre <- one_of(["rock", "pop", "jazz"]);
    
    init {
        color <- #magenta;
        sociability <- rnd(0.5, 0.9);
        do add_belief(new_predicate("i_love_music"));
        do add_desire(new_predicate("find_concert"));
    }
    
    plan find_concert intention: new_predicate("find_concert") when: !has_arrived {
        list<Concert> concerts <- all_locations where (each is Concert);
        list<Concert> fav <- concerts where (Concert(each).music_genre = favorite_genre);
        if length(fav) > 0 {
            target_location <- one_of(fav);
            total_plans_executed <- total_plans_executed + 1;
        }
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        float reward <- 0.01;
        
        if current_location is Concert {
            Concert c <- Concert(current_location);
            if c.music_genre = favorite_genre {
                reward <- 0.05;
                do update_happiness(0.05);
                if other is MusicLover and MusicLover(other).favorite_genre = favorite_genre {
                    reward <- 0.08;
                    do update_happiness(0.04);
                    ask other { do update_happiness(0.04); }
                }
            }
        }
        total_positive_interactions <- total_positive_interactions + 1;
        
        // Q-LEARNING: Learn from interaction
        do learn_from_interaction(other, reward);
    }
}

species Foodie parent: Guest {
    string diet_preference <- one_of(["vegan", "meat", "flexible"]);
    
    init {
        color <- #yellow;
        generosity <- rnd(0.6, 1.0);
        do add_belief(new_predicate("i_love_food"));
        do add_desire(new_predicate("find_restaurant"));
    }
    
    plan find_restaurant intention: new_predicate("find_restaurant") when: energy < 0.7 and !has_arrived {
        list<Restaurant> restaurants <- all_locations where (each is Restaurant);
        if length(restaurants) > 0 {
            target_location <- one_of(restaurants);
            total_plans_executed <- total_plans_executed + 1;
        }
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        float reward <- 0.01;
        
        if current_location is Restaurant {
            reward <- 0.03;
            do update_happiness(0.03);
            energy <- min(1.0, energy + 0.1);
            if other is Foodie {
                reward <- 0.05;
                ask other { do update_happiness(0.02); }
            }
        }
        total_positive_interactions <- total_positive_interactions + 1;
        
        // Q-LEARNING: Learn from interaction
        do learn_from_interaction(other, reward);
    }
}

species SportsFan parent: Guest {
    string favorite_sport <- one_of(["football", "basketball"]);
    
    init {
        color <- #darkgreen;
        sociability <- rnd(0.6, 0.95);
        do add_belief(new_predicate("i_love_sports"));
        do add_desire(new_predicate("watch_game"));
    }
    
    plan find_game intention: new_predicate("watch_game") when: !has_arrived {
        list<SportsVenue> venues <- all_locations where (each is SportsVenue);
        list<SportsVenue> fav <- venues where (SportsVenue(each).sport_type = favorite_sport);
        if length(fav) > 0 {
            target_location <- one_of(fav);
            total_plans_executed <- total_plans_executed + 1;
        }
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        float reward <- 0.01;
        
        if current_location is SportsVenue {
            SportsVenue v <- SportsVenue(current_location);
            if v.sport_type = favorite_sport {
                reward <- 0.05;
                do update_happiness(0.05);
                if other is SportsFan and SportsFan(other).favorite_sport = favorite_sport {
                    reward <- 0.08;
                    do update_happiness(0.05);
                    ask other { do update_happiness(0.05); }
                }
            }
        }
        total_positive_interactions <- total_positive_interactions + 1;
        
        // Q-LEARNING: Learn from interaction
        do learn_from_interaction(other, reward);
    }
}

experiment BDIRLSimulation type: gui {
    float minimum_cycle_duration <- 0.01;
    
    output {
        display main_display {
            species Bar;
            species Concert;
            species Restaurant;
            species SportsVenue;
            species PartyPerson;
            species Introvert;
            species MusicLover;
            species Foodie;
            species SportsFan;
        }
        
        display happiness_chart {
            chart "Global Happiness Over Time" type: series {
                data "Happiness" value: global_happiness color: #blue;
                data "Baseline" value: 0.5 color: #gray;
            }
        }
        
        display interaction_chart {
            chart "Positive vs Negative Interactions" type: series {
                data "Positive" value: total_positive_interactions color: #green;
                data "Negative" value: total_negative_interactions color: #red;
            }
        }
        
        display learning_chart {
            chart "Q-Learning Progress" type: series {
                data "Learning Events" value: agents_learning_count color: #purple;
            }
        }
        
        monitor "Cycle" value: cycle;
        monitor "Global Happiness" value: global_happiness;
        monitor "BDI Plans" value: total_plans_executed;
        monitor "Learning Events" value: agents_learning_count;
        
        
        }
}