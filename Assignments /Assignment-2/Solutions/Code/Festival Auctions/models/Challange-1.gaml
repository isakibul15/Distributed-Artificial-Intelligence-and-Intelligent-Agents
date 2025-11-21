/**
* Name: Festival with Multiple Dutch Auctions - Challenge 1
* Author: Sakib, Ahsan, Sing - Extended with Multiple Auction System
* Description: Festival simulation with MULTIPLE SIMULTANEOUS merchandise auctions using FIPA protocol
* Challenge 1: Multiple auctions at the same time with genre-based participation
*/

model Festival

global {
    geometry shape <- square(100);
    
    // Global variables for tracking
    int totalMemoryStores <- 0;
    int totalNoMemoryStores <- 0;
    float totalDistanceTraveled <- 0.0;
    
    // Auction timing
    float auction_interval <- 80.0;  // More frequent auctions
    float next_auction_time <- 50.0;
    
    // Auction items with GENRES
    list<string> merch_items <- ["T-Shirt", "CD", "Poster", "Hat", "Hoodie", "Vinyl", "Jacket"];
    list<string> merch_genres <- ["Rock", "Pop", "Jazz", "Electronic", "Metal"];
    
    // Auction statistics
    int total_auctions <- 0;
    int successful_auctions <- 0;
    float total_auction_revenue <- 0.0;
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
        create Guest number: 25 {
            location <- any_location_in(shape);
        }
        create Security number: 1;
        
        // CHALLENGE 1: Create MULTIPLE auctioneers for simultaneous auctions
        create Auctioneer number: 4 {
            location <- any_location_in(shape);
        }
        
        write "\n=== CHALLENGE 1: MULTIPLE SIMULTANEOUS AUCTIONS ===";
        write "Created " + length(Auctioneer) + " auctioneers";
        write "Guests can participate in multiple auctions simultaneously";
        write "Genre-based filtering is active";
        write "===================================================\n";
    }
    
    reflex updateStats {
        totalMemoryStores <- Guest sum_of (each.memoryUsedCount);
        totalNoMemoryStores <- Guest sum_of (each.noMemoryUsedCount);
        totalDistanceTraveled <- Guest sum_of (each.totalDistance);
    }
    
    reflex trigger_auction when: time >= next_auction_time {
        // Trigger auction on a random available auctioneer
        list<Auctioneer> available <- Auctioneer where (!each.auction_active);
        if !empty(available) {
            ask one_of(available) {
                do start_auction;
            }
        }
        next_auction_time <- time + auction_interval;
    }
    
    reflex show_active_auctions when: every(50 #cycles) {
        int active <- length(Auctioneer where each.auction_active);
        if active > 0 {
            write "\n>>> SIMULTANEOUS AUCTIONS: " + active + " active auctions running!";
            loop auc over: (Auctioneer where each.auction_active) {
                write "  - " + auc.name + ": " + auc.item_name + " (" + auc.item_genre + ") at $" + auc.current_price;
            }
        }
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
    
    // CHALLENGE 1: Support for MULTIPLE SIMULTANEOUS AUCTIONS
    list<string> active_auction_ids <- [];  // Can join multiple auctions!
    map<string, float> auction_max_prices <- map([]);  // Max willing to pay per auction
    
    float auction_budget <- rnd(100.0, 250.0);
    list<string> preferred_genres <- [];
    list<string> owned_merch <- [];
    
    init {
        // Assign random genre preferences (more genres = more interest)
        int num_preferences <- rnd(2, 4);
        loop times: num_preferences {
            string genre <- one_of(merch_genres);
            if !(genre in preferred_genres) {
                add genre to: preferred_genres;
            }
        }
        write name + " likes: " + preferred_genres + " (budget: $" + auction_budget + ")";
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
            // Can wander even while in auctions (auctions are via FIPA messages, not location-based)
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
    
    // CHALLENGE 1: AUCTION REFLEXES - Support MULTIPLE SIMULTANEOUS AUCTIONS
    
    reflex receive_cfp when: !empty(cfps) {
        loop cfp_message over: cfps {
            list contents_list <- list(cfp_message.contents);
            
            // Parse: [auction_id, item_name, item_genre, starting_price, current_price, message_type]
            if length(contents_list) >= 6 {
                string auction_id <- string(contents_list[0]);
                string item_name <- string(contents_list[1]);
                string item_genre <- string(contents_list[2]);
                float starting_price <- float(contents_list[3]);
                float current_price <- float(contents_list[4]);
                string msg_type <- string(contents_list[5]);
            
                if msg_type = "auction_start" {
                    // CHALLENGE 1: Check if interested in THIS GENRE
                    if item_genre in preferred_genres and auction_budget > starting_price * 0.2 and !(auction_id in active_auction_ids) {
                        // Join this auction!
                        add auction_id to: active_auction_ids;
                        float max_willing <- min(auction_budget * rnd(0.6, 0.9), starting_price * rnd(0.7, 1.0));
                        auction_max_prices[auction_id] <- max_willing;
                        
                        write ">>> " + name + " JOINS " + item_genre + " auction: " + item_name + " (max: $" + max_willing + ")";
                    } else {
                        // Not interested in this genre or already in this auction
                        do refuse message: cfp_message contents: [name, false];
                        if !(item_genre in preferred_genres) {
                            write name + " REFUSES " + item_genre + " auction (likes: " + preferred_genres + ")";
                        }
                    }
                } else if msg_type = "price_update" and (auction_id in active_auction_ids) {
                    // Get max willing to pay for THIS specific auction
                    float max_willing <- float(auction_max_prices[auction_id]);
                    
                    // Dutch auction: Bid if price is acceptable
                    if current_price <= max_willing and current_price <= auction_budget {
                        do propose message: cfp_message contents: [name, current_price];
                        write name + " BIDS on " + item_genre + " " + item_name + " at $" + current_price;
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
                
                if msg_type = "winner" and length(data) >= 4 {
                    string auction_id <- string(data[1]);
                    string item_name <- string(data[2]);
                    float final_price <- float(data[3]);
                    
                    add item_name to: owned_merch;
                    auction_budget <- auction_budget - final_price;
                    
                    // Remove this auction from active list
                    remove auction_id from: active_auction_ids;
                    remove key: auction_id from: auction_max_prices;
                    
                    write name + " WON! " + item_name + " for $" + final_price + " (budget left: $" + auction_budget + ")";
                } else if msg_type = "auction_ended" and length(data) >= 2 {
                    string auction_id <- string(data[1]);
                    
                    // Remove this auction from active list
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
        // CHALLENGE 1: Different colors based on number of active auctions
        if length(active_auction_ids) >= 3 {
            display_color <- #purple;  // In 3+ auctions
        } else if length(active_auction_ids) = 2 {
            display_color <- #magenta;  // In 2 auctions
        } else if length(active_auction_ids) = 1 {
            display_color <- #pink;  // In 1 auction
        }
        
        draw circle(3) color: display_color;
        
        // Show number of active auctions as text
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
                // Don't kill guests who are in auctions - wait until they finish
                if !empty(AssignedGuest.active_auction_ids) {
                    write "Security waiting - " + AssignedGuest.name + " is in " + length(AssignedGuest.active_auction_ids) + " auction(s)";
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

// AUCTIONEER SPECIES - Dutch Auction Implementation using FIPA Protocol
species Auctioneer skills: [fipa] {
    rgb my_color <- #gold;
    
    // Auction state
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
    
    list<agent> participants <- [];
    agent winner <- nil;
    bool waiting_for_bids <- false;
    
    action start_auction {
        if !auction_active {
            auction_active <- true;
            current_auction_id <- name + "_" + string(time);
            
            // Generate random merchandise item with GENRE
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
            
            write "\n========================================";
            write name + " AUCTION #" + total_auctions;
            write "Item: " + item_name + " | Genre: " + item_genre;
            write "Starting: $" + starting_price + " | Min: $" + minimum_price;
            write "========================================";
            
            // Send CFP to all guests using FIPA protocol
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
        // Acknowledge uninterested buyers
    }
    
    reflex receive_bids when: auction_active and waiting_for_bids and !empty(proposes) {
        // First bidder wins in Dutch auction!
        message first_bid <- first(proposes);
        list bid_data_list <- list(first_bid.contents);
        
        if length(bid_data_list) >= 2 {
            float bid_price <- float(bid_data_list[1]);
            winner <- first_bid.sender;
            
            // Check if winner is still alive
            if winner = nil or dead(winner) {
                write "Winner died!";
                auction_active <- false;
                waiting_for_bids <- false;
                my_color <- #gold;
                return;
            }
            
            write "\n*** SOLD! ***";
            write name + " - " + winner.name + " bought " + item_genre + " " + item_name + " for $" + bid_price;
            write "**************\n";
            
            successful_auctions <- successful_auctions + 1;
            total_auction_revenue <- total_auction_revenue + bid_price;
            genre_sales[item_genre] <- genre_sales[item_genre] + 1;
            
            // Get all other participants (filter out dead agents)
            list<agent> other_buyers <- list(Guest) where (current_auction_id in each.active_auction_ids and each != winner and !dead(each));
            
            // Inform winner - include auction_id so they can remove it
            do start_conversation to: [winner] protocol: 'fipa-propose' performative: 'inform' contents: [
                "winner",
                current_auction_id,
                item_name,
                bid_price
            ];
            
            // Inform all other interested buyers that this auction ended
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
    
    reflex reduce_price when: auction_active and waiting_for_bids and empty(proposes) and (time - last_reduction_time >= reduction_interval) {
        // No bids received yet, reduce price
        current_price <- current_price - price_reduction;
        
        if current_price < minimum_price {
            // Cancel auction
            write "\n*** CANCELLED ***";
            write name + " - " + item_genre + " " + item_name + " - no buyers";
            write "*****************\n";
            
            // Inform all interested participants (filter out dead agents)
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
            // Send price update
            write name + " - " + item_genre + " price: $" + current_price;
            
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
            draw circle(12.0) color: #transparent border: #red width: 3;
            draw item_genre color: #red size: 9 at: location + {0, -10};
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
            
        }
        
        display "Auction Statistics" {
            chart "Auction Performance" type: series {
                data "Total" value: total_auctions color: #orange;
                data "Successful" value: successful_auctions color: #green;
                data "Revenue ÷10" value: total_auction_revenue / 10 color: #purple;
            }
        }
        
        display "Genre Sales" {
            chart "Sales by Genre" type: pie {
                data "Rock" value: genre_sales["Rock"] color: #red;
                data "Pop" value: genre_sales["Pop"] color: #pink;
                data "Jazz" value: genre_sales["Jazz"] color: #blue;
                data "Electronic" value: genre_sales["Electronic"] color: #cyan;
                data "Metal" value: genre_sales["Metal"] color: #gray;
            }
        }
        
        monitor "Active Auctions NOW" value: length(Auctioneer where each.auction_active);
        monitor "Total Auctions" value: total_auctions;
        monitor "Successful" value: successful_auctions;
        monitor "Success Rate" value: (total_auctions > 0) ? (successful_auctions / total_auctions * 100.0) : 0.0;
        monitor "Revenue" value: total_auction_revenue;
        monitor "Avg Price" value: (successful_auctions > 0) ? (total_auction_revenue / successful_auctions) : 0.0;
        monitor "Total Items Sold" value: sum(Guest collect length(each.owned_merch));
        monitor "Guests in Auctions" value: length(Guest where (!empty(each.active_auction_ids)));
    }
}