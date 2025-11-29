/**
* Name: Festival - Global Utility Function (Challenge 1)
* Author: Sakib, Ahsan, Sing
* Description: Complete working version with all corner cases handled
*/

model Festival

global {
    geometry shape <- square(100);
    
    // Global variables for tracking
    int totalMemoryStores <- 0;
    int totalNoMemoryStores <- 0;
    float totalDistanceTraveled <- 0.0;
    
    // Stage statistics
    int total_stage_visits <- 0;
    map<string, int> stage_visit_counts <- map([]);
    
    // CHALLENGE 1: Global Utility variables
    Guest leader <- nil;
    bool optimization_phase <- false;
    float initial_global_utility <- 0.0;
    float current_global_utility <- 0.0;
    float max_global_utility <- 0.0;
    bool max_utility_reached <- false;
    int optimization_iterations <- 0;
    int max_optimization_iterations <- 10;
    list<float> utility_history <- [];
    int no_improvement_count <- 0;
    float last_utility <- 0.0;
    
    init {
        create FoodStore number: 2 {
            location <- (index = 0) ? {20, 20} : {80, 70};
        }
        create DrinkStore number: 2 {
            location <- (index = 0) ? {50, 80} : {30, 70};
        }
        create BothStore number: 1 {
            location <- {70, 20};
        }
        create InformationCenter number: 1 {
            location <- {50, 50};
        }
        
        // Create stages with different attributes
        create Stage number: 3 {
            location <- (index = 0) ? {15, 85} : ((index = 1) ? {50, 15} : {85, 85});
        }
        
        create Guest number: 25 {
            location <- any_location_in(shape);
        }
        
        // Random leader selection
        leader <- one_of(Guest);
        ask leader {
            is_leader <- true;
        }
        
        create Security number: 1;
        
        write "\n=== FESTIVAL SIMULATION - CHALLENGE 1 ===";
        write "Global Utility Optimization with Crowd Mass Preferences";
        write "Stages: " + length(Stage);
        write "Guests: " + length(Guest);
        write "Leader: " + leader.name + " (randomly selected)";
        write "==========================================\n";
    }
    
    reflex updateStats {
        totalMemoryStores <- Guest sum_of (each.memoryUsedCount);
        totalNoMemoryStores <- Guest sum_of (each.noMemoryUsedCount);
        totalDistanceTraveled <- Guest sum_of (each.totalDistance);
    }
    
    // Check if leader is alive and elect new one if needed
    reflex check_leader_alive {
        if leader = nil or dead(leader) {
            list<Guest> alive_guests <- list(Guest);
            if !empty(alive_guests) {
                string old_leader_name <- "Unknown";
                if leader != nil and !dead(leader) {
                    old_leader_name <- leader.name;
                }
                
                leader <- one_of(alive_guests);
                ask leader {
                    is_leader <- true;
                }
                
                write "\n[LEADER CHANGE] " + old_leader_name + " died. New leader: " + leader.name + "\n";
                
                // Reset optimization if in progress
                if optimization_phase and !max_utility_reached {
                    optimization_phase <- false;
                    optimization_iterations <- 0;
                }
            }
        }
    }
    
    // CHALLENGE 1: Calculate global utility
    action calculate_global_utility {
        float total_utility <- 0.0;
        
        ask Guest {
            if targetStage != nil and time_at_stage > 0.0 {
                float personal_utility <- myself.calculate_guest_utility(self);
                total_utility <- total_utility + personal_utility;
            }
        }
        
        return total_utility;
    }
    
    action calculate_guest_utility(Guest g) {
        if g.targetStage = nil or g.time_at_stage = 0.0 {
            return 0.0;
        }
        
        // Base utility from stage attributes
        float base_utility <- (g.pref_lightShow * g.targetStage.lightShow) + 
                             (g.pref_speaker * g.targetStage.speaker) + 
                             (g.pref_musicStyle * g.targetStage.musicStyle);
        
        // Crowd mass adjustment
        int crowd_size <- g.targetStage.visitor_count;
        float crowd_factor <- 1.0;
        
        if g.pref_crowd_mass > 0.7 {
            // Prefers large crowds
            crowd_factor <- 1.0 + (crowd_size / 15.0);
        } else if g.pref_crowd_mass < 0.3 {
            // Prefers small crowds
            crowd_factor <- max(0.3, 1.5 - (crowd_size / 10.0));
        } else {
            // Moderate preference
            crowd_factor <- 1.0 + (0.2 - abs(crowd_size - 8.0) / 20.0);
        }
        
        return base_utility * crowd_factor;
    }
}

species Store {
    int capacity <- 20;
    int currentCapacity <- 0;
}

species FoodStore parent: Store {
    aspect base {
        draw square(8) color: #orange;
    }
}

species DrinkStore parent: Store {
    aspect base {
        draw square(5) color: #cyan;
    }
}

species BothStore parent: Store {
    aspect base {
        draw square(9) color: #green;
    }
}

species InformationCenter {
    list<FoodStore> foodStores <- list(FoodStore);
    list<DrinkStore> drinkStores <- list(DrinkStore);
    list<BothStore> bothStores <- list(BothStore);

    aspect base {
        draw square(10) color: #blue;
    }
}

species Stage skills: [fipa] {
    float lightShow <- rnd(0.2, 1.0);
    float speaker <- rnd(0.2, 1.0);
    float musicStyle <- rnd(0.2, 1.0);
    
    rgb stage_color <- rgb(rnd(100, 255), rnd(100, 255), rnd(100, 255));
    int visitor_count <- 0;
    
    init {
        stage_visit_counts[name] <- 0;
        write "[STAGE] " + name + " - Light:" + lightShow with_precision 2 + 
              " Speaker:" + speaker with_precision 2 + 
              " Music:" + musicStyle with_precision 2;
    }
    
    reflex respond_to_queries when: !empty(queries) {
        loop query_msg over: queries {
            do start_conversation to: [query_msg.sender] 
               protocol: 'fipa-query' 
               performative: 'inform' 
               contents: [
                "stage_info",
                name,
                lightShow,
                speaker,
                musicStyle,
                visitor_count
            ];
        }
    }
    
    aspect base {
        draw square(12) color: stage_color border: #black width: 2;
        draw name color: #white size: 8 at: location + {0, -15};
        draw "Visitors: " + visitor_count color: #white size: 7 at: location + {0, 15};
    }
}

species StoreInfo {
    Store store;
    string type;
}

species Guest skills: [moving, fipa] {
    bool isHungry <- false;
    bool isThirsty <- false;
    InformationCenter center <- first(InformationCenter);
    Store targetStore;
    bool isMovingToInfo <- false;
    bool evil <- false;
    list<StoreInfo> visited <- [];
    bool shouldReport <- false;
    Guest guestToBeReported <- nil;
    
    // Tracking variables
    int memoryUsedCount <- 0;
    int noMemoryUsedCount <- 0;
    float totalDistance <- 0.0;
    point lastLocation <- location;
    
    // Stage selection variables
    float pref_lightShow <- rnd(0.1, 1.0);
    float pref_speaker <- rnd(0.1, 1.0);
    float pref_musicStyle <- rnd(0.1, 1.0);
    float pref_crowd_mass <- rnd(0.0, 1.0);
    
    Stage targetStage <- nil;
    Stage initial_choice <- nil;
    bool isSelectingStage <- false;
    bool hasQueriedStages <- false;
    bool has_made_initial_choice <- false;
    map<string, float> stage_utilities <- map([]);
    int stage_responses_received <- 0;
    float next_stage_selection_time <- rnd(50.0, 100.0);
    float time_at_stage <- 0.0;
    
    // Leader and optimization
    bool is_leader <- false;
    bool ready_for_optimization <- false;
    float my_current_utility <- 0.0;
    bool received_switch_command <- false;
    Stage pending_switch_stage <- nil;
    
    init {
        write "[GUEST] " + name + " preferences - Light:" + pref_lightShow with_precision 2 + 
              " Speaker:" + pref_speaker with_precision 2 + 
              " Music:" + pref_musicStyle with_precision 2 +
              " CrowdMass:" + pref_crowd_mass with_precision 2 + 
              (is_leader ? " [LEADER]" : "");
    }
    
    string getNeedType {
        if (isHungry and isThirsty) {
            return "both";
        } else if (isHungry) {
            return "food";
        } else if (isThirsty) {
            return "drink";
        }
        return "none";
    }
    
    action addToStore(Store s, string t) {
        create StoreInfo {
            store <- s;
            type <- t;
        }
        add item: last(StoreInfo) to: visited;
    }
    
    action getStore(string t) {
        StoreInfo match <- visited first_with (each.type = t);
        if match != nil {
            return match.store;
        }
        return nil;
    }
    
    reflex changeState when: !max_utility_reached {
        if !isHungry {
            isHungry <- flip(0.015);
        }
        if !isThirsty {
            isThirsty <- flip(0.008);
        }
        if !isHungry and !isThirsty and !evil {
            evil <- flip(0.0005);
        }
    }
    
    reflex checkForBadGuests when: !optimization_phase and !max_utility_reached {
        list<Guest> evil_guests <- (Guest - self) where (each.evil);
        if !empty(evil_guests) {
            guestToBeReported <- evil_guests closest_to (self);
            shouldReport <- true;
        }
    }
    
    reflex MovingToInfo when: isMovingToInfo {
        do goto target: center.location;
    }
    
    reflex CheckForHungerOrThirst {
        if (isHungry or isThirsty) and targetStore = nil and !isMovingToInfo and targetStage = nil {
            float randomValue <- rnd(1.0);
            if randomValue < 0.1 or length(visited) <= 0 or shouldReport {
                isMovingToInfo <- true;
                noMemoryUsedCount <- noMemoryUsedCount + 1;
            } else {
                Store s <- getStore(getNeedType());
                if s != nil {
                    targetStore <- s;
                    memoryUsedCount <- memoryUsedCount + 1;
                } else {
                    isMovingToInfo <- true;
                    noMemoryUsedCount <- noMemoryUsedCount + 1;
                }
            }
        } else if !isHungry and !isThirsty and targetStore = nil and targetStage = nil and !isSelectingStage and !max_utility_reached {
            do wander;
        }
    }
    
    reflex askInfo {
        if location distance_to center.location < 1.0 and targetStore = nil and (isHungry or isThirsty) {
            isMovingToInfo <- false;
            
            if shouldReport {
                ask Security {
                    if killed contains myself.guestToBeReported {
                        // nothing
                    } else {
                        AssignedGuest <- myself.guestToBeReported;
                    }
                }
                guestToBeReported <- nil;
                shouldReport <- false;
            }
            
            if isHungry and isThirsty {
                ask center {
                    myself.targetStore <- one_of(bothStores);
                }
            } else if isHungry {
                ask center {
                    myself.targetStore <- one_of(foodStores);
                }
            } else if isThirsty {
                ask center {
                    myself.targetStore <- one_of(drinkStores);
                }
            }
        }
    }
    
    reflex goToStore when: targetStore != nil {
        do goto target: targetStore.location;
    }
    
    reflex checkArrivalAtStore {
        if targetStore != nil {
            if location distance_to targetStore.location < 1.0 {
                do addToStore(targetStore, getNeedType());
                isHungry <- false;
                isThirsty <- false;
                targetStore <- nil;
            }
        }
    }
    
    // Initial stage selection
    reflex initiate_stage_selection when: !isSelectingStage and 
                                          targetStage = nil and 
                                          time >= next_stage_selection_time and
                                          !isHungry and !isThirsty and 
                                          targetStore = nil and
                                          !isMovingToInfo and
                                          !has_made_initial_choice {
        
        isSelectingStage <- true;
        hasQueriedStages <- false;
        stage_utilities <- map([]);
        stage_responses_received <- 0;
        
        write "[SELECTION] " + name + " is selecting a stage...";
        
        do start_conversation to: list(Stage) 
           protocol: 'fipa-query' 
           performative: 'query' 
           contents: [name, "request_attributes"];
        
        hasQueriedStages <- true;
    }
    
    // Process stage information responses
    reflex receive_stage_info when: !empty(informs) and isSelectingStage and hasQueriedStages {
        loop inform_msg over: informs {
            list data <- list(inform_msg.contents);
            
            if length(data) >= 6 and string(data[0]) = "stage_info" {
                string stage_name <- string(data[1]);
                float s_light <- float(data[2]);
                float s_speaker <- float(data[3]);
                float s_music <- float(data[4]);
                int s_crowd <- int(data[5]);
                
                // Calculate utility
                float base_utility <- (pref_lightShow * s_light) + 
                                    (pref_speaker * s_speaker) + 
                                    (pref_musicStyle * s_music);
                
                float crowd_factor <- 1.0;
                if pref_crowd_mass > 0.7 {
                    crowd_factor <- 1.0 + (s_crowd / 15.0);
                } else if pref_crowd_mass < 0.3 {
                    crowd_factor <- max(0.3, 1.5 - (s_crowd / 10.0));
                }
                
                float utility <- base_utility * crowd_factor;
                
                stage_utilities[stage_name] <- utility;
                stage_responses_received <- stage_responses_received + 1;
                
                write "[EVALUATION] " + name + " evaluated " + stage_name + 
                      " - Utility: " + utility with_precision 3 + 
                      " (Crowd: " + s_crowd + ")";
                
                // Once all stages responded, pick best one
                if stage_responses_received >= length(Stage) {
                    string best_stage_name <- stage_utilities.keys with_max_of (stage_utilities[each]);
                    float best_utility <- stage_utilities[best_stage_name];
                    
                    Stage chosen_stage <- Stage first_with (each.name = best_stage_name);
                    if chosen_stage != nil {
                        targetStage <- chosen_stage;
                        time_at_stage <- 0.0;
                        
                        write "[CHOICE] >>> " + name + " CHOSE " + best_stage_name + 
                              " (utility: " + best_utility with_precision 3 + ") <<<";
                    }
                    
                    isSelectingStage <- false;
                    hasQueriedStages <- false;
                }
            }
        }
        informs <- [];
    }
    
    reflex go_to_stage when: targetStage != nil and time_at_stage = 0.0 and !isSelectingStage {
        do goto target: targetStage.location speed: 2.0;
    }
    
    reflex check_arrival_at_stage when: targetStage != nil and time_at_stage = 0.0 and !isSelectingStage {
        if location distance_to targetStage.location < 3.0 {
            write "[ARRIVAL] " + name + " ARRIVED at " + targetStage.name + "!";
            
            ask targetStage {
                visitor_count <- visitor_count + 1;
            }
            
            total_stage_visits <- total_stage_visits + 1;
            stage_visit_counts[targetStage.name] <- stage_visit_counts[targetStage.name] + 1;
            
            time_at_stage <- time;
            
            if !has_made_initial_choice {
                has_made_initial_choice <- true;
                initial_choice <- targetStage;
                ready_for_optimization <- true;
                
                write "[READY] " + name + " is ready for optimization";
            }
        }
    }
    
    // Leader initiates optimization
    reflex leader_check_all_ready when: is_leader and 
                                        !optimization_phase and 
                                        length(Guest where each.ready_for_optimization) = length(Guest) {
        
        optimization_phase <- true;
        
        initial_global_utility <- world.calculate_global_utility();
        current_global_utility <- initial_global_utility;
        max_global_utility <- initial_global_utility;
        last_utility <- initial_global_utility;
        add initial_global_utility to: utility_history;
        
        write "\n========================================";
        write "[OPTIMIZATION] ALL GUESTS HAVE MADE INITIAL CHOICES";
        write "[OPTIMIZATION] Initial Global Utility: " + initial_global_utility with_precision 3;
        write "========================================\n";
    }
    
    // Leader optimization algorithm
    reflex leader_optimize when: is_leader and 
                                optimization_phase and 
                                !max_utility_reached and
                                optimization_iterations < max_optimization_iterations and
                                mod(cycle, 50) = 0 {
        
        optimization_iterations <- optimization_iterations + 1;
        write "\n[OPTIMIZATION] === Iteration " + optimization_iterations + " ===";
        
        current_global_utility <- world.calculate_global_utility();
        add current_global_utility to: utility_history;
        
        write "[OPTIMIZATION] Current Global Utility: " + current_global_utility with_precision 3;
        
        // Check if utility is decreasing (oscillating)
        float improvement <- current_global_utility - last_utility;
        
        if current_global_utility > max_global_utility {
            max_global_utility <- current_global_utility;
            no_improvement_count <- 0;
        } else if improvement < -0.1 {
            // Utility is decreasing - we're oscillating
            no_improvement_count <- no_improvement_count + 2;
        } else if abs(improvement) < 0.1 {
            no_improvement_count <- no_improvement_count + 1;
        } else {
            no_improvement_count <- 0;
        }
        
        // Stop if no improvement for 3 iterations OR reached max iterations
        if no_improvement_count >= 3 or optimization_iterations >= max_optimization_iterations {
            max_utility_reached <- true;
            
            // Use the best utility we've achieved
            float final_utility <- max([max_global_utility, initial_global_utility]);
            
            write "\n========================================";
            write "[SUCCESS] MAXIMUM GLOBAL UTILITY REACHED!";
            write "[SUCCESS] Initial Utility: " + initial_global_utility with_precision 3;
            write "[SUCCESS] Final Utility: " + final_utility with_precision 3;
            write "[SUCCESS] Improvement: " + (final_utility - initial_global_utility) with_precision 3;
            write "[SUCCESS] Iterations: " + optimization_iterations;
            
            if no_improvement_count >= 3 {
                write "[SUCCESS] Converged - No more beneficial switches found";
            } else {
                write "[SUCCESS] Maximum iterations reached";
            }
            
            write "[SUCCESS] All guests can now enjoy their shows!";
            write "========================================\n";
            
            ask Guest {
                if targetStage != nil and time_at_stage > 0.0 {
                    write "[ENJOY] " + name + " is enjoying the show at " + targetStage.name + "!";
                }
            }
            
            return;
        }
        
        last_utility <- current_global_utility;
        
        // Find beneficial switches that IMPROVE from CURRENT state
        map<Guest, Stage> proposed_switches <- map([]);
        float baseline_global_utility <- current_global_utility;
        float best_found_utility <- baseline_global_utility;
        
        list<Guest> guests_to_check <- Guest where (each.targetStage != nil and each.time_at_stage > 0.0 and each != self);
        
        loop guest_to_optimize over: guests_to_check {
            Stage current_stage <- guest_to_optimize.targetStage;
            Stage best_stage <- current_stage;
            float best_global_utility <- baseline_global_utility;
            
            list<Stage> alternative_stages <- list(Stage) where (each != current_stage);
            
            loop test_stage over: alternative_stages {
                // Simulate switch
                int original_test_count <- test_stage.visitor_count;
                int original_current_count <- current_stage.visitor_count;
                
                test_stage.visitor_count <- test_stage.visitor_count + 1;
                current_stage.visitor_count <- current_stage.visitor_count - 1;
                
                Stage temp_original <- guest_to_optimize.targetStage;
                guest_to_optimize.targetStage <- test_stage;
                
                float test_global_utility <- world.calculate_global_utility();
                
                // Restore
                test_stage.visitor_count <- original_test_count;
                current_stage.visitor_count <- original_current_count;
                guest_to_optimize.targetStage <- temp_original;
                
                // Only accept if it improves SIGNIFICANTLY from baseline
                if test_global_utility > best_global_utility + 0.5 {
                    best_global_utility <- test_global_utility;
                    best_stage <- test_stage;
                }
            }
            
            if best_stage != current_stage and best_global_utility > best_found_utility {
                proposed_switches[guest_to_optimize] <- best_stage;
                best_found_utility <- best_global_utility;
                write "[SWITCH] " + guest_to_optimize.name + " should switch to " + best_stage.name + 
                      " (utility gain: " + (best_global_utility - baseline_global_utility) with_precision 3 + ")";
            }
        }
        
        if !empty(proposed_switches) {
            write "[OPTIMIZATION] Executing " + length(proposed_switches) + " switches";
            
            loop g over: proposed_switches.keys {
                Stage new_stage <- proposed_switches[g];
                
                ask g {
                    pending_switch_stage <- new_stage;
                    received_switch_command <- true;
                }
            }
        } else {
            write "[OPTIMIZATION] No beneficial switches found";
            no_improvement_count <- no_improvement_count + 1;
        }
    }
    
    // Execute pending switch
    reflex execute_switch when: pending_switch_stage != nil and targetStage != nil and time_at_stage > 0.0 {
        write "[MOVING] " + name + " switching from " + targetStage.name + " to " + pending_switch_stage.name;
        
        ask targetStage {
            visitor_count <- visitor_count - 1;
        }
        
        targetStage <- pending_switch_stage;
        time_at_stage <- 0.0;
        pending_switch_stage <- nil;
        received_switch_command <- false;
    }
    
    reflex update_utility when: targetStage != nil and time_at_stage > 0.0 {
        my_current_utility <- world.calculate_guest_utility(self);
    }
    
    reflex trackDistance {
        totalDistance <- totalDistance + (location distance_to lastLocation);
        lastLocation <- location;
    }
    
    aspect base {
        rgb display_color <- evil ? #red : #yellow;
        
        if max_utility_reached and targetStage != nil and time_at_stage > 0.0 {
            display_color <- #magenta;
        } else if optimization_phase and targetStage != nil and time_at_stage > 0.0 {
            display_color <- #cyan;
        } else if targetStage != nil and time_at_stage > 0.0 {
            display_color <- #gold;
        } else if targetStage != nil {
            display_color <- #orange;
        } else if isSelectingStage {
            display_color <- #lime;
        }
        
        if is_leader {
            draw circle(5) color: display_color border: #black width: 3;
            draw "L" color: #white size: 10 at: location;
        } else {
            draw circle(3) color: display_color;
        }
    }
}

species Security skills: [moving] {
    Guest AssignedGuest <- nil;
    list<Guest> killed <- [];
    
    aspect base {
        draw circle(3) color: #purple;
    }
    
    reflex GotoGuest when: AssignedGuest != nil {
        do goto target: AssignedGuest.location;
    }
    
    action addToKillList(Guest g) {
        add item: g to: killed;
    }
    
    reflex checkForProblem when: !optimization_phase and !max_utility_reached {
        if AssignedGuest != nil {
            if !(killed contains AssignedGuest) {
                if location distance_to AssignedGuest.location < 1.0 {
                    do addToKillList(AssignedGuest);
                    ask AssignedGuest {
                        do die;
                    }
                    AssignedGuest <- nil;
                } else {
                    do goto target: AssignedGuest.location;
                }
            } else {
                AssignedGuest <- nil;
            }
        } else {
            do wander;
        }
    }
}

experiment Festival_Simulation type: gui {
    output {
        display main_display {
            species Guest aspect: base;
            species InformationCenter aspect: base;
            species FoodStore aspect: base;
            species DrinkStore aspect: base;
            species BothStore aspect: base;
            species Security aspect: base;
            species Stage aspect: base;
        }
        
        display "Stage Visits" {
            chart "Stage Popularity" type: histogram {
                loop stage_name over: stage_visit_counts.keys {
                    data stage_name value: stage_visit_counts[stage_name] color: #lime;
                }
            }
        }
        
        display "Global Utility Over Time" {
            chart "Utility Optimization" type: series {
                data "Current Utility" value: current_global_utility color: #blue;
                data "Initial Utility" value: initial_global_utility color: #red;
                data "Max Utility" value: max_global_utility color: #green;
            }
        }
        
        monitor "=== CHALLENGE 1: GLOBAL UTILITY ===" value: "";
        monitor "Leader" value: leader != nil ? leader.name : "None";
        monitor "Optimization Phase" value: optimization_phase;
        monitor "Initial Global Utility" value: initial_global_utility with_precision 3;
        monitor "Current Global Utility" value: current_global_utility with_precision 3;
        monitor "Max Utility" value: max_global_utility with_precision 3;
        monitor "Improvement" value: (current_global_utility - initial_global_utility) with_precision 3;
        monitor "Max Reached" value: max_utility_reached;
        monitor "Iterations" value: optimization_iterations;
        monitor "" value: "";
        monitor "=== GUEST STATUS ===" value: "";
        monitor "Guests Ready" value: length(Guest where each.ready_for_optimization);
        monitor "Guests at Stages" value: length(Guest where (each.targetStage != nil and each.time_at_stage > 0));
        monitor "Guests Selecting" value: length(Guest where each.isSelectingStage);
        monitor "Total Guests" value: length(Guest);
    }
}