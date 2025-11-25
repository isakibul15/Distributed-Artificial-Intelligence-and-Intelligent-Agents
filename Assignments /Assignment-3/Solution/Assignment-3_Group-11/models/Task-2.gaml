/**
* Name: Festival with Multiple Dutch Auctions + Stage Selection (Task 2)
* Author: Sakib, Ahsan, Sing - Extended with Stage Selection via Utility
* Description: Festival with auctions AND stage selection using FIPA protocol
* Challenge 1: Multiple auctions (console output minimized)
* Task 2: Guests select stages based on utility calculation from preferences
*/

model Festival

global {
    geometry shape <- square(100);
    
    // Global variables for tracking
    int totalMemoryStores <- 0;
    int totalNoMemoryStores <- 0;
    float totalDistanceTraveled <- 0.0;
    
    // Auction items with GENRES
    list<string> merch_items <- ["T-Shirt", "CD", "Poster", "Hat", "Hoodie", "Vinyl", "Jacket"];
    list<string> merch_genres <- ["Rock", "Pop", "Jazz", "Electronic", "Metal"];
    
    // Auction statistics
    int total_auctions <- 0;
    list<string> ended_auction_ids <- [];
    int successful_auctions <- 0;
    float total_auction_revenue <- 0.0;
    map<string, int> genre_sales <- ["Rock"::0, "Pop"::0, "Jazz"::0, "Electronic"::0, "Metal"::0];
    
    // Stage statistics (Task 2)
    int total_stage_visits <- 0;
    map<string, int> stage_visit_counts <- map([]);
    
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
        
        // TASK 2: Create stages with different attributes
        create Stage number: 3 {
            location <- (index = 0) ? {15, 85} : ((index = 1) ? {50, 15} : {85, 85});
        }
        
        create Guest number: 25 {
            location <- any_location_in(shape);
        }
        create Security number: 1;
        
        // Challenge 1: Multiple auctioneers
        create Auctioneer number: 4 {
            location <- any_location_in(shape);
        }
        
        write "\n=== FESTIVAL SIMULATION ===";
        write "Task 2: Stage selection via utility calculation";
        write "Stages: " + length(Stage);
        write "Guests: " + length(Guest);
        write "===========================\n";
    }
    
    reflex updateStats {
        totalMemoryStores <- Guest sum_of (each.memoryUsedCount);
        totalNoMemoryStores <- Guest sum_of (each.noMemoryUsedCount);
        totalDistanceTraveled <- Guest sum_of (each.totalDistance);
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

// ============================================================================
// TASK 2: STAGE SPECIES
// ============================================================================
species Stage skills: [fipa] {
    float lightShow <- rnd(0.2, 1.0);
    float speaker <- rnd(0.2, 1.0);
    float musicStyle <- rnd(0.2, 1.0);
    
    rgb stage_color <- rgb(rnd(100, 255), rnd(100, 255), rnd(100, 255));
    int visitor_count <- 0;
    
    init {
        stage_visit_counts[name] <- 0;
        write "[TASK 2] " + name + " - Light:" + lightShow with_precision 2 + 
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
                musicStyle
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
    
   
    list<string> active_auction_ids <- [];
    map<string, float> auction_max_prices <- map([]);
    float auction_budget <- rnd(100.0, 250.0);
    list<string> preferred_genres <- [];
    list<string> owned_merch <- [];
    
    // TASK 2: Stage selection variables
    float pref_lightShow <- rnd(0.1, 1.0);
    float pref_speaker <- rnd(0.1, 1.0);
    float pref_musicStyle <- rnd(0.1, 1.0);
    
    Stage targetStage <- nil;
    bool isSelectingStage <- false;
    bool hasQueriedStages <- false;
    map<string, float> stage_utilities <- map([]);
    int stage_responses_received <- 0;
    float next_stage_selection_time <- rnd(100.0, 200.0);
    float stage_visit_duration <- 0.0;
    float time_at_stage <- 0.0;
    
    init {
        // Challenge 1: Assign random genre preferences for auctions
        int num_preferences <- rnd(2, 4);
        loop times: num_preferences {
            string genre <- one_of(merch_genres);
            if !(genre in preferred_genres) {
                add genre to: preferred_genres;
            }
        }
        
        write "[TASK 2] " + name + " preferences - Light:" + pref_lightShow with_precision 2 + 
              " Speaker:" + pref_speaker with_precision 2 + 
              " Music:" + pref_musicStyle with_precision 2;
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
    
    reflex changeState {
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
    
    reflex checkForBadGuests {
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
        } else if !isHungry and !isThirsty and targetStore = nil and targetStage = nil and !isSelectingStage {
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
    
    // ========================================================================
    // TASK 2: STAGE SELECTION REFLEXES
    // ========================================================================
    
    reflex initiate_stage_selection when: !isSelectingStage and 
                                          targetStage = nil and 
                                          time >= next_stage_selection_time and
                                          !isHungry and !isThirsty and 
                                          targetStore = nil and
                                          !isMovingToInfo {
        
        isSelectingStage <- true;
        hasQueriedStages <- false;
        stage_utilities <- map([]);
        stage_responses_received <- 0;
        
        write "[TASK 2] " + name + " is selecting a stage...";
        
        // Query all stages - SAME PATTERN AS CHALLENGE 1
        do start_conversation to: list(Stage) 
           protocol: 'fipa-query' 
           performative: 'query' 
           contents: [name, "request_attributes"];
        
        hasQueriedStages <- true;
    }
    
    reflex go_to_stage when: targetStage != nil and time_at_stage = 0.0 {
        do goto target: targetStage.location speed: 2.0;
    }
    
    reflex check_arrival_at_stage when: targetStage != nil and time_at_stage = 0.0 {
        if location distance_to targetStage.location < 3.0 {
            write "[TASK 2] " + name + " ARRIVED at " + targetStage.name + "!";
            
            ask targetStage {
                visitor_count <- visitor_count + 1;
            }
            
            total_stage_visits <- total_stage_visits + 1;
            stage_visit_counts[targetStage.name] <- stage_visit_counts[targetStage.name] + 1;
            
            time_at_stage <- time;
        }
    }
    
    reflex stay_at_stage when: targetStage != nil and 
                                time_at_stage > 0.0 and 
                                (time - time_at_stage) >= stage_visit_duration {
        
        write "[TASK 2] " + name + " LEAVING " + targetStage.name;
        
        ask targetStage {
            visitor_count <- visitor_count - 1;
        }
        
        targetStage <- nil;
        time_at_stage <- 0.0;
        next_stage_selection_time <- time + rnd(150.0, 300.0);
    }

    reflex receive_cfp when: !empty(cfps) {
        loop cfp_message over: cfps {
            list contents_list <- list(cfp_message.contents);
            
            if length(contents_list) >= 6 {
                string auction_id <- string(contents_list[0]);
                string item_name <- string(contents_list[1]);
                string item_genre <- string(contents_list[2]);
                float starting_price <- float(contents_list[3]);
                float current_price <- float(contents_list[4]);
                string msg_type <- string(contents_list[5]);
            
                if msg_type = "auction_start" {
                    if item_genre in preferred_genres and auction_budget > starting_price * 0.2 and 
                       !(auction_id in active_auction_ids) and !(auction_id in ended_auction_ids) {
                        
                        add auction_id to: active_auction_ids;
                        float max_willing <- min(auction_budget * rnd(0.6, 0.9), starting_price * rnd(0.7, 1.0));
                        auction_max_prices[auction_id] <- max_willing;
                    } else {
                        do refuse message: cfp_message contents: [name, false];
                    }
                } else if msg_type = "price_update" and (auction_id in active_auction_ids and 
                          !(auction_id in ended_auction_ids)) {
                    float max_willing <- float(auction_max_prices[auction_id]);
                    
                    if current_price <= max_willing and current_price <= auction_budget {
                        do propose message: cfp_message contents: [name, current_price];
                    }
                }
            }
        }
    }
    
    // CRITICAL: SINGLE receive_inform reflex handles BOTH auctions AND stages

    reflex receive_inform when: !empty(informs) {
        loop inform_msg over: informs {
            list data <- list(inform_msg.contents);
            
            if length(data) >= 1 {
                string msg_type <- string(data[0]);
                
                // TASK 2: Handle stage information
                if msg_type = "stage_info" and length(data) >= 5 and isSelectingStage and hasQueriedStages {
                    string stage_name <- string(data[1]);
                    float s_light <- float(data[2]);
                    float s_speaker <- float(data[3]);
                    float s_music <- float(data[4]);
                    
                    // Calculate utility
                    float utility <- (pref_lightShow * s_light) + 
                                    (pref_speaker * s_speaker) + 
                                    (pref_musicStyle * s_music);
                    
                    stage_utilities[stage_name] <- utility;
                    stage_responses_received <- stage_responses_received + 1;
                    
                    write "[TASK 2] " + name + " evaluated " + stage_name + 
                          " - Utility: " + utility with_precision 3;
                    
                    // Once all stages responded, pick best one
                    if stage_responses_received >= length(Stage) and !empty(stage_utilities) {
                        string best_stage_name <- stage_utilities.keys with_max_of (stage_utilities[each]);
                        float best_utility <- stage_utilities[best_stage_name];
                        
                        Stage chosen_stage <- Stage first_with (each.name = best_stage_name);
                        if chosen_stage != nil {
                            targetStage <- chosen_stage;
                            stage_visit_duration <- rnd(50.0, 100.0);
                            time_at_stage <- 0.0;
                            
                            write "[TASK 2] >>> " + name + " CHOSE " + best_stage_name + 
                                  " (utility: " + best_utility with_precision 3 + ") <<<";
                        }
                        
                        isSelectingStage <- false;
                        hasQueriedStages <- false;
                    }
                }
                // Challenge 1: Handle auction winner
                else if msg_type = "winner" and length(data) >= 4 {
                    string auction_id <- string(data[1]);
                    string item_name <- string(data[2]);
                    float final_price <- float(data[3]);
                    
                    add item_name to: owned_merch;
                    auction_budget <- auction_budget - final_price;
                    
                    remove auction_id from: active_auction_ids;
                    remove key: auction_id from: auction_max_prices;
                } 
                // Challenge 1: Handle auction ended
                else if msg_type = "auction_ended" and length(data) >= 2 {
                    string auction_id <- string(data[1]);
                    remove auction_id from: active_auction_ids;
                    remove key: auction_id from: auction_max_prices;
                }
            }
        }
    }
    
    reflex trackDistance {
        totalDistance <- totalDistance + (location distance_to lastLocation);
        lastLocation <- location;
    }
    
    aspect base {
        rgb display_color <- evil ? #red : #yellow;
        
        if targetStage != nil and time_at_stage > 0.0 {
            display_color <- #gold;  // At stage
        } else if targetStage != nil {
            display_color <- #orange;  // Going to stage
        } else if isSelectingStage {
            display_color <- #lime;  // Selecting stage
        } else if length(active_auction_ids) >= 2 {
            display_color <- #purple;
        } else if length(active_auction_ids) = 1 {
            display_color <- #pink;
        }
        
        draw circle(3) color: display_color;
        
        if length(active_auction_ids) > 0 {
            draw string(length(active_auction_ids)) color: #white size: 8 at: location + {0, 4};
        }
    }
}

species Security skills: [moving] {
    Guest AssignedGuest <- nil;
    list<Guest> killed <- [];
    
    aspect base {
        draw circle(3) color: #purple;
    }
    
    reflex GotoGuest when: AssignedGuest != nil and empty(AssignedGuest.active_auction_ids) {
        do goto target: AssignedGuest.location;
    }
    
    action addToKillList(Guest g) {
        add item: g to: killed;
    }
    
    reflex checkForProblem {
        if AssignedGuest != nil {
            if !(killed contains AssignedGuest) {
                if !empty(AssignedGuest.active_auction_ids) {
                    // Wait
                } else if location distance_to AssignedGuest.location < 1.0 {
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


species Auctioneer skills: [fipa] {
    rgb my_color <- #gold;
    
    bool auction_active <- false;
    string current_auction_id;
    string item_name;
    string item_genre;
    float starting_price;
    float current_price;
    float minimum_price;
    float price_reduction;
    float reduction_interval <- 5.0;
    float last_reduction_time;
    
    float auction_interval <- rnd(100.0, 150.0); 
    float next_auction_time <- rnd(40.0, 200.0);
    
    list<agent> participants <- [];
    agent winner <- nil;
    bool waiting_for_bids <- false;
    
    reflex trigger_auction when: time >= next_auction_time {
        if (!auction_active) {
            do start_auction;
            auction_interval <- rnd(80.0, 120.0);
            next_auction_time <- time + auction_interval;
        }
    }
    
    action start_auction {
        if !auction_active {
            auction_active <- true;
            current_auction_id <- name + "_" + string(time);
            
            item_name <- one_of(merch_items);
            item_genre <- one_of(merch_genres);
            starting_price <- rnd(40.0, 100.0);
            current_price <- starting_price;
            minimum_price <- starting_price * 0.25;
            price_reduction <- starting_price * rnd(0.06, 0.12);
            last_reduction_time <- time;
            
            participants <- [];
            winner <- nil;
            waiting_for_bids <- true;
            my_color <- #orange;
            
            total_auctions <- total_auctions + 1;
            
            do start_conversation to: list(Guest) protocol: 'fipa-propose' performative: 'cfp' contents: [
                current_auction_id,
                item_name,
                item_genre,
                starting_price,
                current_price,
                "auction_start"
            ];
        }
    }
    
    reflex receive_refuses when: auction_active and !empty(refuses) {
        // Acknowledge
    }
    
    reflex receive_bids when: auction_active and waiting_for_bids and !empty(proposes) {
        message first_bid <- first(proposes);
        list bid_data_list <- list(first_bid.contents);
        
        if length(bid_data_list) >= 2 {
            float bid_price <- float(bid_data_list[1]);
            winner <- first_bid.sender;
            
            if winner = nil or dead(winner) {
                auction_active <- false;
                waiting_for_bids <- false;
                my_color <- #gold;
                add current_auction_id to: ended_auction_ids;
            } else {
                successful_auctions <- successful_auctions + 1;
                total_auction_revenue <- total_auction_revenue + bid_price;
                genre_sales[item_genre] <- genre_sales[item_genre] + 1;
                add current_auction_id to: ended_auction_ids;
                
                do start_conversation to: [winner] protocol: 'fipa-propose' performative: 'inform' contents: [
                    "winner",
                    current_auction_id,
                    item_name,
                    bid_price
                ];
                
                list<agent> other_buyers <- list(Guest) where (current_auction_id in each.active_auction_ids and 
                                                               each != winner and !dead(each));
                
                if !empty(other_buyers) {
                    do start_conversation to: other_buyers protocol: 'fipa-propose' performative: 'inform' contents: [
                        "auction_ended",
                        current_auction_id
                    ];
                }
                
                auction_active <- false;
                waiting_for_bids <- false;
                my_color <- #gold;
            }
        }
    }
    
    reflex reduce_price when: auction_active and waiting_for_bids and empty(proposes) and 
                             (time - last_reduction_time >= reduction_interval) {
        current_price <- current_price - price_reduction;
        
        if current_price < minimum_price {
            list<agent> interested <- list(Guest) where (current_auction_id in each.active_auction_ids and !dead(each));
            if !empty(interested) {
                do start_conversation to: interested protocol: 'fipa-propose' performative: 'inform' contents: [
                    "auction_ended",
                    current_auction_id
                ];
            }
            
            auction_active <- false;
            waiting_for_bids <- false;
            my_color <- #gold;
        } else {
            list<agent> interested <- list(Guest) where (current_auction_id in each.active_auction_ids and !dead(each));
            if !empty(interested) {
                do start_conversation to: interested protocol: 'fipa-propose' performative: 'cfp' contents: [
                    current_auction_id,
                    item_name,
                    item_genre,
                    starting_price,
                    current_price,
                    "price_update"
                ];
            }
            
            last_reduction_time <- time;
        }
    }
    
    aspect base {
        draw square(8) color: my_color border: #black;
        if auction_active {
            draw circle(12.0) color: #transparent border: #red width: 2;
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
            species Auctioneer aspect: base;
            species Stage aspect: base;
        }
        
        
        display "Stage Visits" {
            chart "Stage Popularity" type: histogram {
                loop stage_name over: stage_visit_counts.keys {
                    data stage_name value: stage_visit_counts[stage_name] color: #lime;
                }
            }
        }
        
        monitor "=== TASK 2: STAGE STATISTICS ===" value: "";
        monitor "Total Stage Visits" value: total_stage_visits;
        monitor "Guests Selecting Stages" value: length(Guest where each.isSelectingStage);
        monitor "Guests at Stages" value: length(Guest where (each.targetStage != nil and each.time_at_stage > 0));
        monitor "Guests Going to Stages" value: length(Guest where (each.targetStage != nil and each.time_at_stage = 0));
        monitor "" value: "";
    }
}