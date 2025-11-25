/**
* Name: Festival with Multiple Auction Types - Challenge 2
* Author: Sakib, Ahsan, Sing - Extended with Multiple Auction Types
* Description: Festival simulation with Dutch, English, and Sealed Bid auctions
* Challenge 2: Compare different auction mechanisms
*/

model Festival

global {
    geometry shape <- square(100);
    
    // Global variables for tracking
    int totalMemoryStores <- 0;
    int totalNoMemoryStores <- 0;
    float totalDistanceTraveled <- 0.0;
    
    // Auction timing
    float auction_interval <- 60.0;
    float next_auction_time <- 50.0;
    
    // Auction items with GENRES
    list<string> merch_items <- ["T-Shirt", "CD", "Poster", "Hat", "Hoodie", "Vinyl", "Jacket"];
    list<string> merch_genres <- ["Rock", "Pop", "Jazz", "Electronic", "Metal"];
    
    // CHALLENGE 2: Statistics for comparing auction types
    // Dutch Auction Stats
    int total_dutch <- 0;
    int success_dutch <- 0;
    float revenue_dutch <- 0.0;
    list<float> buyer_savings_dutch <- [];
    
    // English Auction Stats
    int total_english <- 0;
    int success_english <- 0;
    float revenue_english <- 0.0;
    list<float> buyer_savings_english <- [];
    
    // Sealed Bid Auction Stats
    int total_sealed <- 0;
    int success_sealed <- 0;
    float revenue_sealed <- 0.0;
    list<float> buyer_savings_sealed <- [];
    
    map<string, int> genre_sales <- ["Rock"::0, "Pop"::0, "Jazz"::0, "Electronic"::0, "Metal"::0];
    
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
        create Guest number: 30 {
            location <- any_location_in(shape);
        }
        create Security number: 1;
        
        // CHALLENGE 2: Create multiple auctioneers with different auction types
        create Auctioneer number: 6 {
            location <- any_location_in(shape);
            // Assign auction types evenly
            if index < 2 {
                auction_type <- "Dutch";
            } else if index < 4 {
                auction_type <- "English";
            } else {
                auction_type <- "Sealed";
            }
        }
        
        write "\n╔═══════════════════════════════════════════╗";
        write "║  CHALLENGE 2: MULTIPLE AUCTION TYPES     ║";
        write "╠═══════════════════════════════════════════╣";
        write "║  Dutch Auctions:      " + length(Auctioneer where (each.auction_type = "Dutch")) + " auctioneers   ║";
        write "║  English Auctions:    " + length(Auctioneer where (each.auction_type = "English")) + " auctioneers   ║";
        write "║  Sealed Bid Auctions: " + length(Auctioneer where (each.auction_type = "Sealed")) + " auctioneers   ║";
        write "╚═══════════════════════════════════════════╝\n";
    }
    
    reflex updateStats {
        totalMemoryStores <- Guest sum_of (each.memoryUsedCount);
        totalNoMemoryStores <- Guest sum_of (each.noMemoryUsedCount);
        totalDistanceTraveled <- Guest sum_of (each.totalDistance);
    }
    
    reflex trigger_auction when: time >= next_auction_time {
        list<Auctioneer> available <- Auctioneer where (!each.auction_active);
        if !empty(available) {
            ask one_of(available) {
                do start_auction;
            }
        }
        next_auction_time <- time + auction_interval;
    }
    
    reflex show_comparison when: every(250 #cycles) and (total_dutch + total_english + total_sealed) > 6 {
        write "\n╔══════════════ AUCTION TYPE ANALYSIS ══════════════╗";
        write "║ Type    │ Success Rate │ Avg Revenue │ Buyer Savings ║";
        write "╟─────────┼──────────────┼─────────────┼───────────────╢";
        write "║ Dutch   │ " + (total_dutch > 0 ? with_precision(success_dutch/total_dutch*100, 1) : 0.0) + "%       │ $" + 
              (success_dutch > 0 ? with_precision(revenue_dutch/success_dutch, 2) : 0.0) + "    │ $" + 
              (!empty(buyer_savings_dutch) ? with_precision(mean(buyer_savings_dutch), 2) : 0.0) + "         ║";
        write "║ English │ " + (total_english > 0 ? with_precision(success_english/total_english*100, 1) : 0.0) + "%       │ $" + 
              (success_english > 0 ? with_precision(revenue_english/success_english, 2) : 0.0) + "    │ $" + 
              (!empty(buyer_savings_english) ? with_precision(mean(buyer_savings_english), 2) : 0.0) + "         ║";
        write "║ Sealed  │ " + (total_sealed > 0 ? with_precision(success_sealed/total_sealed*100, 1) : 0.0) + "%       │ $" + 
              (success_sealed > 0 ? with_precision(revenue_sealed/success_sealed, 2) : 0.0) + "    │ $" + 
              (!empty(buyer_savings_sealed) ? with_precision(mean(buyer_savings_sealed), 2) : 0.0) + "         ║";
        write "╚════════════════════════════════════════════════════╝\n";
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
    
    // Support for MULTIPLE SIMULTANEOUS AUCTIONS
    list<string> active_auction_ids <- [];
    map<string, float> auction_max_prices <- map([]);
    map<string, string> auction_types <- map([]);
    
    float auction_budget <- rnd(100.0, 300.0);
    list<string> preferred_genres <- [];
    list<string> owned_merch <- [];
    
    init {
        int num_preferences <- rnd(2, 4);
        loop times: num_preferences {
            string genre <- one_of(merch_genres);
            if !(genre in preferred_genres) {
                add genre to: preferred_genres;
            }
        }
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
            isHungry <- flip(0.02);
        }
        if !isThirsty {
            isThirsty <- flip(0.01);
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
        if (isHungry or isThirsty) and targetStore = nil and !isMovingToInfo {
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
        } else if !isHungry and !isThirsty and targetStore = nil {
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
    
    // AUCTION REFLEXES - Support MULTIPLE AUCTION TYPES
    
    reflex receive_cfp when: !empty(cfps) {
        loop cfp_message over: cfps {
            list contents_list <- list(cfp_message.contents);
            
            // Parse: [auction_id, item_name, item_genre, starting_price, current_price, auction_type, message_type]
            if length(contents_list) >= 7 {
                string auction_id <- string(contents_list[0]);
                string item_name <- string(contents_list[1]);
                string item_genre <- string(contents_list[2]);
                float starting_price <- float(contents_list[3]);
                float current_price <- float(contents_list[4]);
                string auc_type <- string(contents_list[5]);
                string msg_type <- string(contents_list[6]);
            
                if msg_type = "auction_start" {
                    if item_genre in preferred_genres and auction_budget > starting_price * 0.2 and !(auction_id in active_auction_ids) {
                        add auction_id to: active_auction_ids;
                        auction_types[auction_id] <- auc_type;
                        float max_willing <- min(auction_budget * rnd(0.6, 0.9), starting_price * rnd(0.8, 1.1));
                        auction_max_prices[auction_id] <- max_willing;
                        
                        write ">>> " + name + " joins " + auc_type + ": " + item_name;
                        
                        // For Sealed bid, submit immediately
                        if auc_type = "Sealed" {
                            float bid <- max_willing * rnd(0.7, 0.95);
                            do propose message: cfp_message contents: [name, bid];
                            write name + " sealed bid: $" + bid;
                        }
                    } else {
                        do refuse message: cfp_message contents: [name, false];
                    }
                } else if msg_type = "price_update" and (auction_id in active_auction_ids) {
                    float max_willing <- float(auction_max_prices[auction_id]);
                    string auc_type_stored <- string(auction_types[auction_id]);
                    
                    if auc_type_stored = "Dutch" {
                        if current_price <= max_willing and current_price <= auction_budget {
                            do propose message: cfp_message contents: [name, current_price];
                            write name + " bids Dutch $" + current_price;
                        }
                    } else if auc_type_stored = "English" {
                        if current_price < max_willing and current_price < auction_budget {
                            float new_bid <- current_price + rnd(5.0, 15.0);
                            if new_bid <= max_willing and new_bid <= auction_budget {
                                do propose message: cfp_message contents: [name, new_bid];
                                write name + " bids English $" + new_bid;
                            }
                        }
                    }
                }
            }
        }
    }
    
    reflex receive_inform when: !empty(informs) {
        loop inform_msg over: informs {
            list data <- list(inform_msg.contents);
            
            if length(data) >= 1 {
                string msg_type <- string(data[0]);
                
                if msg_type = "winner" and length(data) >= 5 {
                    string auction_id <- string(data[1]);
                    string item_name <- string(data[2]);
                    float final_price <- float(data[3]);
                    float saved <- float(data[4]);
                    
                    add item_name to: owned_merch;
                    auction_budget <- auction_budget - final_price;
                    
                    remove auction_id from: active_auction_ids;
                    remove key: auction_id from: auction_max_prices;
                    remove key: auction_id from: auction_types;
                    
                    write name + " WON! " + item_name + " for $" + final_price + " (saved $" + saved + ")";
                } else if msg_type = "auction_ended" and length(data) >= 2 {
                    string auction_id <- string(data[1]);
                    
                    remove auction_id from: active_auction_ids;
                    remove key: auction_id from: auction_max_prices;
                    remove key: auction_id from: auction_types;
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
        if length(active_auction_ids) >= 3 {
            display_color <- #darkblue;
        } else if length(active_auction_ids) = 2 {
            display_color <- #orange;
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

// AUCTIONEER SPECIES - Multiple Auction Types
species Auctioneer skills: [fipa] {
    rgb my_color <- #gold;
    string auction_type <- "Dutch";
    
    bool auction_active <- false;
    string current_auction_id;
    string item_name;
    string item_genre;
    float starting_price;
    float current_price;
    float minimum_price;
    float price_change;
    float action_interval <- 5.0;
    float last_action_time;
    float auction_duration <- 25.0;
    float auction_start_time;
    
    map<agent, float> all_bids <- map([]);
    agent current_highest_bidder <- nil;
    float current_highest_bid <- 0.0;
    agent winner <- nil;
    bool waiting_for_bids <- false;
    
    action start_auction {
        if !auction_active {
            auction_active <- true;
            current_auction_id <- name + "_" + string(time);
            
            item_name <- one_of(merch_items);
            item_genre <- one_of(merch_genres);
            starting_price <- rnd(40.0, 100.0);
            minimum_price <- starting_price * 0.25;
            last_action_time <- time;
            auction_start_time <- time;
            
            all_bids <- map([]);
            current_highest_bidder <- nil;
            current_highest_bid <- 0.0;
            winner <- nil;
            waiting_for_bids <- true;
            
            if auction_type = "Dutch" {
                current_price <- starting_price;
                price_change <- starting_price * rnd(0.06, 0.12);
                my_color <- #orange;
                total_dutch <- total_dutch + 1;
            } else if auction_type = "English" {
                current_price <- starting_price * 0.4;
                price_change <- 5.0;
                my_color <- #cyan;
                total_english <- total_english + 1;
            } else if auction_type = "Sealed" {
                current_price <- starting_price;
                auction_duration <- 15.0;
                my_color <- #darkgreen;
                total_sealed <- total_sealed + 1;
            }
            
            write "\n========== " + auction_type + " AUCTION ==========";
            write name + ": " + item_name + " (" + item_genre + ") - $" + starting_price;
            write "====================================";
            
            do start_conversation to: list(Guest) protocol: 'fipa-propose' performative: 'cfp' contents: [
                current_auction_id, item_name, item_genre, starting_price, current_price, auction_type, "auction_start"
            ];
        }
    }
    
    reflex receive_refuses when: auction_active and !empty(refuses) {
        // Acknowledge
    }
    
    reflex receive_bids when: auction_active and waiting_for_bids and !empty(proposes) {
        loop bid_msg over: proposes {
            list bid_data <- list(bid_msg.contents);
            if length(bid_data) >= 2 {
                agent bidder <- bid_msg.sender;
                float bid_price <- float(bid_data[1]);
                
                if auction_type = "Dutch" {
                    winner <- bidder;
                    current_price <- bid_price;
                    do conclude_auction;
                    return;
                } else if auction_type = "English" {
                    if bid_price > current_highest_bid {
                        current_highest_bidder <- bidder;
                        current_highest_bid <- bid_price;
                        current_price <- bid_price;
                        last_action_time <- time;
                        write name + " - High bid: $" + bid_price;
                    }
                } else if auction_type = "Sealed" {
                    if !(bidder in all_bids.keys) or bid_price > all_bids[bidder] {
                        all_bids[bidder] <- bid_price;
                    }
                }
            }
        }
    }
    
    reflex manage_auction when: auction_active and waiting_for_bids {
        float elapsed <- time - last_action_time;
        float total_elapsed <- time - auction_start_time;
        
        if auction_type = "Dutch" and elapsed >= action_interval {
            current_price <- current_price - price_change;
            
            if current_price < minimum_price {
                write name + " - Dutch CANCELLED";
                do cancel_auction;
            } else {
                write name + " - Price: $" + current_price;
                list<agent> interested <- list(Guest) where (current_auction_id in each.active_auction_ids and !dead(each));
                if !empty(interested) {
                    do start_conversation to: interested protocol: 'fipa-propose' performative: 'cfp' contents: [
                        current_auction_id, item_name, item_genre, starting_price, current_price, auction_type, "price_update"
                    ];
                }
                last_action_time <- time;
            }
        } else if auction_type = "English" {
            if total_elapsed >= auction_duration {
                if current_highest_bidder != nil {
                    winner <- current_highest_bidder;
                    current_price <- current_highest_bid;
                    do conclude_auction;
                } else {
                    write name + " - English CANCELLED";
                    do cancel_auction;
                }
            } else if elapsed >= 3.0 {
                list<agent> interested <- list(Guest) where (current_auction_id in each.active_auction_ids and !dead(each));
                if !empty(interested) {
                    do start_conversation to: interested protocol: 'fipa-propose' performative: 'cfp' contents: [
                        current_auction_id, item_name, item_genre, starting_price, current_price, auction_type, "price_update"
                    ];
                }
                last_action_time <- time;
            }
        } else if auction_type = "Sealed" and total_elapsed >= auction_duration {
            if !empty(all_bids) {
                float highest <- max(all_bids.values);
                loop bidder over: all_bids.keys {
                    if all_bids[bidder] = highest {
                        winner <- bidder;
                        current_price <- highest;
                        break;
                    }
                }
                write name + " - Sealed: " + length(all_bids) + " bids";
                do conclude_auction;
            } else {
                write name + " - Sealed CANCELLED";
                do cancel_auction;
            }
        }
    }
    
    action conclude_auction {
        if winner = nil or dead(winner) {
            do cancel_auction;
            return;
        }
        
        // Cast winner to Guest to access its attributes
        Guest winner_guest <- Guest(winner);
        
        float max_willing <- 0.0;
        if current_auction_id in winner_guest.auction_max_prices.keys {
            max_willing <- float(winner_guest.auction_max_prices[current_auction_id]);
        }
        float saved <- max(0.0, max_willing - current_price);
        
        write "\n*** SOLD (" + auction_type + ") ***";
        write winner.name + " pays $" + current_price + " | Saved: $" + saved;
        write "**********************\n";
        
        if auction_type = "Dutch" {
            success_dutch <- success_dutch + 1;
            revenue_dutch <- revenue_dutch + current_price;
            add saved to: buyer_savings_dutch;
        } else if auction_type = "English" {
            success_english <- success_english + 1;
            revenue_english <- revenue_english + current_price;
            add saved to: buyer_savings_english;
        } else if auction_type = "Sealed" {
            success_sealed <- success_sealed + 1;
            revenue_sealed <- revenue_sealed + current_price;
            add saved to: buyer_savings_sealed;
        }
        
        genre_sales[item_genre] <- genre_sales[item_genre] + 1;
        
        do start_conversation to: [winner] protocol: 'fipa-propose' performative: 'inform' contents: [
            "winner", current_auction_id, item_name, current_price, saved
        ];
        
        list<agent> others <- list(Guest) where (current_auction_id in each.active_auction_ids and each != winner and !dead(each));
        if !empty(others) {
            do start_conversation to: others protocol: 'fipa-propose' performative: 'inform' contents: [
                "auction_ended", current_auction_id
            ];
        }
        
        auction_active <- false;
        waiting_for_bids <- false;
        my_color <- #gold;
    }
    
    action cancel_auction {
        list<agent> participants <- list(Guest) where (current_auction_id in each.active_auction_ids and !dead(each));
        if !empty(participants) {
            do start_conversation to: participants protocol: 'fipa-propose' performative: 'inform' contents: [
                "auction_ended", current_auction_id
            ];
        }
        
        auction_active <- false;
        waiting_for_bids <- false;
        my_color <- #gold;
    }
    
    aspect base {
        draw square(8) color: my_color border: #black;
        if auction_active {
            draw circle(12.0) color: #transparent border: my_color width: 3;
            draw auction_type color: my_color size: 9 at: location + {0, -10};
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
            
            graphics "legend" {
                draw "CHALLENGE 2: Dutch vs English vs Sealed Bid" color: #black size: 12 at: {5, 3};
                draw "Orange=Dutch | Cyan=English | DarkGreen=Sealed" color: #black size: 9 at: {5, 6};
            }
        }
        
        display "Success Rate Comparison" {
            chart "Success Rate by Auction Type" type: histogram {
                data "Dutch" value: (total_dutch > 0) ? (success_dutch / total_dutch * 100.0) : 0.0 color: #orange;
                data "English" value: (total_english > 0) ? (success_english / total_english * 100.0) : 0.0 color: #cyan;
                data "Sealed" value: (total_sealed > 0) ? (success_sealed / total_sealed * 100.0) : 0.0 color: #darkgreen;
            }
        }
        
        display "Revenue Comparison" {
            chart "Average Revenue per Sale" type: histogram {
                data "Dutch" value: (success_dutch > 0) ? (revenue_dutch / success_dutch) : 0.0 color: #orange;
                data "English" value: (success_english > 0) ? (revenue_english / success_english) : 0.0 color: #cyan;
                data "Sealed" value: (success_sealed > 0) ? (revenue_sealed / success_sealed) : 0.0 color: #darkgreen;
            }
        }
        
        display "Buyer Savings" {
            chart "Average Buyer Savings (Lower = Paid More)" type: histogram {
                data "Dutch" value: !empty(buyer_savings_dutch) ? mean(buyer_savings_dutch) : 0.0 color: #orange;
                data "English" value: !empty(buyer_savings_english) ? mean(buyer_savings_english) : 0.0 color: #cyan;
                data "Sealed" value: !empty(buyer_savings_sealed) ? mean(buyer_savings_sealed) : 0.0 color: #darkgreen;
            }
        }
        
        monitor "=== DUTCH AUCTION ===" value: "";
        monitor "Dutch Total" value: total_dutch;
        monitor "Dutch Success" value: success_dutch;
        monitor "Dutch Success %" value: (total_dutch > 0) ? (success_dutch / total_dutch * 100.0) : 0.0;
        monitor "Dutch Avg Revenue" value: (success_dutch > 0) ? (revenue_dutch / success_dutch) : 0.0;
        monitor "Dutch Avg Savings" value: !empty(buyer_savings_dutch) ? mean(buyer_savings_dutch) : 0.0;
        
        monitor "=== ENGLISH AUCTION ===" value: "";
        monitor "English Total" value: total_english;
        monitor "English Success" value: success_english;
        monitor "English Success %" value: (total_english > 0) ? (success_english / total_english * 100.0) : 0.0;
        monitor "English Avg Revenue" value: (success_english > 0) ? (revenue_english / success_english) : 0.0;
        monitor "English Avg Savings" value: !empty(buyer_savings_english) ? mean(buyer_savings_english) : 0.0;
        
        monitor "=== SEALED BID AUCTION ===" value: "";
        monitor "Sealed Total" value: total_sealed;
        monitor "Sealed Success" value: success_sealed;
        monitor "Sealed Success %" value: (total_sealed > 0) ? (success_sealed / total_sealed * 100.0) : 0.0;
        monitor "Sealed Avg Revenue" value: (success_sealed > 0) ? (revenue_sealed / success_sealed) : 0.0;
        monitor "Sealed Avg Savings" value: !empty(buyer_savings_sealed) ? mean(buyer_savings_sealed) : 0.0;
        
        monitor "=== OVERALL ===" value: "";
        monitor "Total Auctions" value: (total_dutch + total_english + total_sealed);
        monitor "Total Successful" value: (success_dutch + success_english + success_sealed);
        monitor "Total Revenue" value: (revenue_dutch + revenue_english + revenue_sealed);
        monitor "Items Sold" value: sum(Guest collect length(each.owned_merch));
    }
}