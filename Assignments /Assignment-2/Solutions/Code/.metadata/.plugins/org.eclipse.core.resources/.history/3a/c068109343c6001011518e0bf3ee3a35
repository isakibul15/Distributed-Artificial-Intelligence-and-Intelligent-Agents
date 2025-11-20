/**
* Name: Festival Dutch Auction
* Description: Implementation of Dutch auction at a music festival using FIPA protocol
* Based on FIPA Auction-Dutch Protocol specification
* Author: Assignment 2 - DAIIA
*/

model FestivalDutchAuction

global {
    // Festival parameters
    int nb_guests <- 20;
    int nb_stores <- 5;
    int nb_auctioneers <- 2;
    
    // Auction timing
    float auction_interval <- 100.0;
    float next_auction_time <- 50.0;
    
    // Item types and genres for auction
    list<string> item_types <- ["T-Shirt", "CD", "Poster", "Hat", "Mug"];
    list<string> genres <- ["Rock", "Pop", "Jazz", "Electronic", "Metal"];
    
    init {
        // Create festival guests (potential buyers)
        create guest number: nb_guests {
            location <- {rnd(100.0), rnd(100.0)};
            my_color <- rnd_color(255);
            budget <- rnd(50.0, 300.0);
            
            // Assign random genre preferences
            int num_preferences <- rnd(1, 3);
            loop times: num_preferences {
                add one_of(genres) to: preferred_genres;
            }
        }
        
        // Create stores
        create store number: nb_stores {
            location <- {rnd(100.0), rnd(100.0)};
        }
        
        // Create auctioneers
        create auctioneer number: nb_auctioneers {
            location <- {rnd(100.0), rnd(100.0)};
            my_color <- #gold;
        }
    }
    
    reflex trigger_auction when: time >= next_auction_time {
        ask one_of(auctioneer where (!each.auction_active)) {
            do start_auction;
        }
        next_auction_time <- time + auction_interval;
    }
}

// Guest species - potential buyers
species guest skills: [moving, fipa] {
    rgb my_color;
    float budget;
    list<string> preferred_genres <- [];
    list<string> owned_items <- [];
    point target;
    
    // Auction participation
    bool participating_in_auction <- false;
    string current_auction_id;
    float max_willing_to_pay;
    
    reflex move when: target != nil {
        do goto target: target speed: 2.0;
        if location distance_to target < 2.0 {
            target <- nil;
        }
    }
    
    reflex wander when: target = nil and !participating_in_auction {
        do wander amplitude: 90.0 speed: 1.0;
    }
    
    // Handle CFP (Call for Proposal) - auction announcement
    reflex receive_cfp when: !empty(cfps) {
        loop cfp_message over: cfps {
            map auction_data <- cfp_message.contents;
            string msg_type <- string(auction_data["message_type"]);
            
            if msg_type = "auction_start" {
                string item_name <- string(auction_data["item_name"]);
                string item_genre <- string(auction_data["item_genre"]);
                float starting_price <- float(auction_data["starting_price"]);
                
                // Decide if interested based on genre and budget
                if item_genre in preferred_genres and budget > starting_price * 0.3 {
                    participating_in_auction <- true;
                    current_auction_id <- string(auction_data["auction_id"]);
                    max_willing_to_pay <- min(budget * rnd(0.6, 0.9), starting_price);
                    
                    write name + " is interested in " + item_name + " (genre: " + item_genre + "). Max willing to pay: $" + max_willing_to_pay;
                } else {
                    // Send REFUSE - not interested
                    do refuse message: cfp_message contents: ["participant_id", name, "interested", false];
                }
            } else if msg_type = "price_update" and participating_in_auction {
                string auction_id <- string(auction_data["auction_id"]);
                
                if auction_id = current_auction_id {
                    float current_price <- float(auction_data["current_price"]);
                    
                    // Dutch auction: Accept immediately if price is acceptable
                    if current_price <= max_willing_to_pay and current_price <= budget {
                        // Send PROPOSE to buy at current price (Dutch auction bid)
                        do propose message: cfp_message contents: [
                            "participant_id", name, 
                            "bid_price", current_price
                        ];
                        write name + " BIDS at price: $" + current_price;
                    }
                }
            }
        }
    }
    
    // Handle auction result - INFORM messages
    reflex receive_inform when: !empty(informs) {
        loop inform_msg over: informs {
            map data <- inform_msg.contents;
            string msg_type <- string(data["message_type"]);
            
            if msg_type = "winner" {
                string item_name <- string(data["item_name"]);
                float final_price <- float(data["final_price"]);
                
                add item_name to: owned_items;
                budget <- budget - final_price;
                participating_in_auction <- false;
                my_color <- #green;
                
                write name + " WON! Bought " + item_name + " for $" + final_price + ". Remaining budget: $" + budget;
            } else if msg_type = "auction_ended" {
                participating_in_auction <- false;
                string reason <- string(data["reason"]);
                write name + " - Auction ended: " + reason;
            }
        }
    }
    
    aspect default {
        draw circle(2.0) color: my_color border: #black;
        if participating_in_auction {
            draw circle(3.5) color: #transparent border: #red width: 2;
        }
    }
}

// Store species
species store {
    rgb my_color <- #blue;
    
    aspect default {
        draw square(5.0) color: my_color border: #black;
    }
}

// Auctioneer species - conducts Dutch auctions using FIPA protocol
species auctioneer skills: [fipa] {
    rgb my_color;
    
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
    
    list<agent> interested_buyers <- [];
    agent winner <- nil;
    bool waiting_for_bids <- false;
    
    action start_auction {
        if !auction_active {
            auction_active <- true;
            current_auction_id <- name + "_" + string(time);
            
            // Generate random item
            item_name <- one_of(item_types);
            item_genre <- one_of(genres);
            starting_price <- rnd(50.0, 150.0);
            current_price <- starting_price;
            minimum_price <- starting_price * 0.3;
            price_reduction <- starting_price * rnd(0.05, 0.15);
            last_reduction_time <- time;
            
            interested_buyers <- [];
            winner <- nil;
            waiting_for_bids <- true;
            my_color <- #orange;
            
            write "\n========================================";
            write name + " STARTING DUTCH AUCTION!";
            write "Item: " + item_name + " (" + item_genre + ")";
            write "Starting price: $" + starting_price;
            write "Minimum price: $" + minimum_price;
            write "Price reduction: $" + price_reduction + " per round";
            write "========================================";
            
            // Send CFP to all guests using FIPA protocol
            do start_conversation to: list(guest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [
                "auction_id", current_auction_id,
                "item_name", item_name,
                "item_genre", item_genre,
                "starting_price", starting_price,
                "current_price", current_price,
                "message_type", "auction_start"
            ];
        }
    }
    
    // Collect REFUSE messages from uninterested buyers
    reflex receive_refuses when: auction_active and !empty(refuses) {
        loop refuse_msg over: refuses {
            // Just acknowledge - these buyers are not interested
        }
    }
    
    // Handle PROPOSE messages (bids) - In Dutch auction, first bidder wins
    reflex receive_bids when: auction_active and waiting_for_bids and !empty(proposes) {
        // First bidder wins in Dutch auction!
        message first_bid <- first(proposes);
        map bid_data <- first_bid.contents;
        float bid_price <- float(bid_data["bid_price"]);
        winner <- first_bid.sender;
        
        write "\n*** SOLD! ***";
        write name + " - " + winner.name + " bought " + item_name + " for $" + bid_price;
        write "**************\n";
        
        // Inform winner using FIPA INFORM
        do inform message: first_bid contents: [
            "message_type", "winner",
            "item_name", item_name,
            "final_price", bid_price
        ];
        
        // Inform all other interested buyers that auction has ended
        list<agent> other_buyers <- list(guest) where (each.participating_in_auction and each != winner);
        if !empty(other_buyers) {
            do start_conversation to: other_buyers protocol: 'fipa-contract-net' performative: 'inform' contents: [
                "message_type", "auction_ended",
                "reason", "Item sold to another buyer"
            ];
        }
        
        auction_active <- false;
        waiting_for_bids <- false;
        my_color <- #gold;
    }
    
    // Handle price reduction - reduce price at intervals
    reflex reduce_price when: auction_active and waiting_for_bids and empty(proposes) and (time - last_reduction_time >= reduction_interval) {
        // No bids received yet, reduce price
        current_price <- current_price - price_reduction;
        
        if current_price < minimum_price {
            // Cancel auction - price fell below minimum threshold
            write "\n*** AUCTION CANCELLED ***";
            write name + " - Price fell below minimum threshold ($" + minimum_price + ")";
            write "*************************\n";
            
            // Inform all interested participants using FIPA INFORM
            list<agent> participants <- list(guest) where each.participating_in_auction;
            if !empty(participants) {
                do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'inform' contents: [
                    "message_type", "auction_ended",
                    "reason", "No buyer at minimum price - auction cancelled"
                ];
            }
            
            auction_active <- false;
            waiting_for_bids <- false;
            my_color <- #gold;
        } else {
            // Send price update to all interested buyers using FIPA CFP
            write name + " - Price reduced to: $" + current_price;
            
            list<agent> participants <- list(guest) where each.participating_in_auction;
            if !empty(participants) {
                do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'cfp' contents: [
                    "auction_id", current_auction_id,
                    "current_price", current_price,
                    "message_type", "price_update"
                ];
            }
            
            last_reduction_time <- time;
        }
    }
    
    aspect default {
        draw square(6.0) color: my_color border: #black;
        if auction_active {
            draw circle(10.0) color: #transparent border: #red width: 3;
            draw "AUCTION" color: #red size: 12 at: location + {0, -10};
        }
    }
}

experiment FestivalAuction type: gui {
    parameter "Number of guests" var: nb_guests min: 5 max: 50;
    parameter "Number of stores" var: nb_stores min: 2 max: 10;
    parameter "Number of auctioneers" var: nb_auctioneers min: 1 max: 5;
    parameter "Auction interval" var: auction_interval min: 50.0 max: 300.0;
    
    output {
        display main_display type: 2d {
            graphics "background" {
                draw rectangle(100, 100) color: #lightgreen;
            }
            
            species store aspect: default;
            species auctioneer aspect: default;
            species guest aspect: default;
        }
        
        monitor "Current time" value: time;
        monitor "Active auctions" value: length(auctioneer where each.auction_active);
        monitor "Guests in auctions" value: length(guest where each.participating_in_auction);
        monitor "Total items sold" value: sum(guest collect length(each.owned_items));
    }
}