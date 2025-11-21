/**
* Name: Festival with Dutch Auction
* Author: Sakib, Ahsan, Sing - Extended with Auction System
* Description: Festival simulation with merchandise auctions using FIPA protocol
*/

model Festival

global {
    geometry shape <- square(100);
    
    // Global variables for tracking
    int totalMemoryStores <- 0;
    int totalNoMemoryStores <- 0;
    float totalDistanceTraveled <- 0.0;
    
    // Auction timing
    float auction_interval <- 150.0;
    float next_auction_time <- 100.0;
    
    // Auction items
    list<string> merch_items <- ["T-Shirt", "CD", "Poster", "Hat", "Hoodie"];
    list<string> merch_genres <- ["Rock", "Pop", "Jazz", "Electronic", "Metal"];
    
    // Auction statistics
    int total_auctions <- 0;
    int successful_auctions <- 0;
    float total_auction_revenue <- 0.0;
    
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
        create Guest number: 20 {
            location <- any_location_in(shape);
        }
        create Security number: 1;
        
        // Create auctioneers for merchandise
        create Auctioneer number: 1 {
            location <- any_location_in(shape);
        }
    }
    
    reflex updateStats {
        totalMemoryStores <- Guest sum_of (each.memoryUsedCount);
        totalNoMemoryStores <- Guest sum_of (each.noMemoryUsedCount);
        totalDistanceTraveled <- Guest sum_of (each.totalDistance);
    }
    
    reflex trigger_auction when: time >= next_auction_time {
        ask one_of(Auctioneer where (!each.auction_active)) {
            do start_auction;
        }
        next_auction_time <- time + auction_interval;
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
    
    // Auction participation
    bool participating_in_auction <- false;
    string current_auction_id;
    float auction_budget <- rnd(80.0, 200.0);
    float max_willing_to_pay <- 0.0;
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
        if (isHungry or isThirsty) and targetStore = nil and !isMovingToInfo and !participating_in_auction {
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
        } else if !isHungry and !isThirsty and targetStore = nil and !participating_in_auction {
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
    
    reflex goToStore when: targetStore != nil and !participating_in_auction {
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
    
    // AUCTION REFLEXES - FIPA Protocol Communication
    
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
                    // Decide if interested based on genre and budget
                    if item_genre in preferred_genres and auction_budget > starting_price * 0.2 and !participating_in_auction {
                        participating_in_auction <- true;
                        current_auction_id <- auction_id;
                        max_willing_to_pay <- min(auction_budget * rnd(0.7, 0.95), starting_price * rnd(0.8, 1.1));
                        
                        write ">>> " + name + " INTERESTED in " + item_name + " (" + item_genre + "). Max: $" + max_willing_to_pay;
                    } else {
                        // Send REFUSE - not interested
                        do refuse message: cfp_message contents: [name, false];
                    }
                } else if msg_type = "price_update" and participating_in_auction {
                    if auction_id = current_auction_id {
                        // Dutch auction: Bid if price is acceptable
                        if current_price <= max_willing_to_pay and current_price <= auction_budget {
                            do propose message: cfp_message contents: [name, current_price];
                            write name + " BIDS at $" + current_price;
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
                
                if msg_type = "winner" and length(data) >= 3 {
                    string item_name <- string(data[1]);
                    float final_price <- float(data[2]);
                    
                    add item_name to: owned_merch;
                    auction_budget <- auction_budget - final_price;
                    participating_in_auction <- false;
                    max_willing_to_pay <- 0.0;
                    
                    write name + " WON! Bought " + item_name + " for $" + final_price + ". Budget left: $" + auction_budget;
                } else if msg_type = "auction_ended" {
                    participating_in_auction <- false;
                    max_willing_to_pay <- 0.0;
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
        if participating_in_auction {
            display_color <- #pink;
        }
        draw circle(3) color: display_color;
    }
}

species Security skills: [moving] {
    Guest AssignedGuest <- nil;
    list<Guest> killed <- [];
    
    aspect base {
        draw circle(3) color: #purple;
    }
    
    reflex GotoGuest when: AssignedGuest != nil and !AssignedGuest.participating_in_auction {
        do goto target: AssignedGuest.location;
    }
    
    action addToKillList(Guest g) {
        add item: g to: killed;
    }
    
    reflex checkForProblem {
        if AssignedGuest != nil {
            if !(killed contains AssignedGuest) {
                // Don't kill guests who are in auctions - wait until they finish
                if AssignedGuest.participating_in_auction {
                    write "Security waiting - " + AssignedGuest.name + " is in an auction";
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
            
            // Generate random merchandise item
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
            write name + " STARTING DUTCH AUCTION!";
            write "Item: " + item_name + " (" + item_genre + ")";
            write "Starting price: $" + starting_price;
            write "Minimum: $" + minimum_price;
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
                write "Winner died before completing purchase!";
                auction_active <- false;
                waiting_for_bids <- false;
                my_color <- #gold;
                return;
            }
            
            write "\n*** SOLD! ***";
            write name + " - " + winner.name + " bought " + item_name + " for $" + bid_price;
            write "**************\n";
            
            successful_auctions <- successful_auctions + 1;
            total_auction_revenue <- total_auction_revenue + bid_price;
            
            // Get all other participants (filter out dead agents)
            list<agent> other_buyers <- list(Guest) where (each.participating_in_auction and each != winner and !dead(each));
            
            // Inform winner using FIPA INFORM
            do start_conversation to: [winner] protocol: 'fipa-propose' performative: 'inform' contents: [
                "winner",
                item_name,
                bid_price
            ];
            
            // Inform all other interested buyers that auction ended
            if !empty(other_buyers) {
                do start_conversation to: other_buyers protocol: 'fipa-propose' performative: 'inform' contents: [
                    "auction_ended"
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
            // Cancel auction - price fell below minimum threshold
            write "\n*** AUCTION CANCELLED ***";
            write name + " - Price below minimum ($" + minimum_price + ")";
            write "*************************\n";
            
            // Inform all interested participants (filter out dead agents)
            list<agent> interested <- list(Guest) where (each.participating_in_auction and !dead(each));
            if !empty(interested) {
                do start_conversation to: interested protocol: 'fipa-propose' performative: 'inform' contents: [
                    "auction_ended"
                ];
            }
            
            auction_active <- false;
            waiting_for_bids <- false;
            my_color <- #gold;
        } else {
            // Send price update to all interested buyers (filter out dead agents)
            write name + " - Price reduced to: $" + current_price;
            
            list<agent> interested <- list(Guest) where (each.participating_in_auction and !dead(each));
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
            draw "AUCTION" color: #red size: 10 at: location + {0, -10};
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
                data "Total Auctions" value: total_auctions color: #orange;
                data "Successful" value: successful_auctions color: #green;
                data "Revenue ÷10" value: total_auction_revenue / 10 color: #purple;
            }
        }
        
        monitor "Total Auctions" value: total_auctions;
        monitor "Successful" value: successful_auctions;
        monitor "Success Rate" value: (total_auctions > 0) ? (successful_auctions / total_auctions * 100.0) : 0.0;
        monitor "Revenue" value: total_auction_revenue;
        monitor "Avg Price" value: (successful_auctions > 0) ? (total_auction_revenue / successful_auctions) : 0.0;
        monitor "Items Sold" value: sum(Guest collect length(each.owned_merch));
    }
}