/**
* Name: Festival Dutch Auction
* Description: Implementation of Dutch auction at a music festival using FIPA protocol
* Author: Assignment 2 - DAIIA
*/

model FestivalDutchAuction

global {
    // Festival parameters
    int nb_guests <- 20;
    int nb_stores <- 5;
    int nb_auctioneers <- 2;
    
    // Auction timing
    float auction_interval <- 100.0; // Time between auctions
    float next_auction_time <- 50.0;
    
    // Item types for auction
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
    
    reflex trigger_auction when: (time >= next_auction_time) {
        // Randomly select an auctioneer to start auction
        ask one_of(auctioneer) {
            do start_auction;
        }
        next_auction_time <- time + auction_interval;
    }
}

// Guest species - potential buyers
species guest skills: [moving, fipa] {
    rgb my_color;
    float budget;
    list<string> preferred_genres;
    list<string> owned_items;
    point target;
    
    // Auction participation
    bool participating_in_auction <- false;
    string current_auction_id;
    float current_price;
    float max_willing_to_pay;
    
    reflex move when: target != nil {
        do goto target: target speed: 2.0;
        if (location distance_to target < 2.0) {
            target <- nil;
        }
    }
    
    reflex wander when: target = nil and !participating_in_auction {
        do wander amplitude: 90.0 speed: 1.0;
    }
    
    // Handle CFP (Call for Proposal) - auction announcement
    reflex receive_cfp when: !empty(cfps) {
        message cfp_message <- cfps[0];
        
        // Parse auction details
        map<string, unknown> auction_data <- cfp_message.contents;
        string item_name <- string(auction_data["item_name"]);
        string item_genre <- string(auction_data["item_genre"]);
        float starting_price <- float(auction_data["starting_price"]);
        
        // Decide if interested based on genre and budget
        bool interested <- false;
        if (item_genre in preferred_genres and budget > starting_price * 0.3) {
            interested <- true;
            participating_in_auction <- true;
            current_auction_id <- string(auction_data["auction_id"]);
            
            // Calculate maximum willing to pay (60-90% of budget)
            max_willing_to_pay <- min(budget * rnd(0.6, 0.9), starting_price);
            
            // Send PROPOSE to join auction
            do propose message: cfp_message contents: [
                "participant_id"::name,
                "interested"::true
            ];
            
            write name + " is interested in " + item_name + " (genre: " + item_genre + ")";
        } else {
            // Send REFUSE
            do refuse message: cfp_message contents: [
                "participant_id"::name,
                "interested"::false
            ];
        }
    }
    
    // Handle price updates during auction
    reflex receive_cfp_update when: !empty(cfps) and participating_in_auction {
        loop cfp_msg over: cfps {
            map<string, unknown> data <- cfp_msg.contents;
            
            if (data["auction_id"] = current_auction_id and data["message_type"] = "price_update") {
                current_price <- float(data["current_price"]);
                
                // Decide whether to accept current price
                if (current_price <= max_willing_to_pay and current_price <= budget) {
                    // Accept the offer!
                    do accept_proposal message: cfp_msg contents: [
                        "participant_id"::name,
                        "accepted_price"::current_price
                    ];
                    write name + " accepts price: $" + current_price;
                } else {
                    // Wait for lower price
                    do propose message: cfp_msg contents: [
                        "participant_id"::name,
                        "waiting"::true
                    ];
                }
            }
        }
    }
    
    // Handle winning confirmation
    reflex receive_inform when: !empty(informs) {
        message inform_msg <- informs[0];
        map<string, unknown> data <- inform_msg.contents;
        
        if (data["message_type"] = "winner") {
            string item_name <- string(data["item_name"]);
            float final_price <- float(data["final_price"]);
            
            add item_name to: owned_items;
            budget <- budget - final_price;
            participating_in_auction <- false;
            my_color <- #green;
            
            write name + " WON! Bought " + item_name + " for $" + final_price + ". Remaining budget: $" + budget;
        } else if (data["message_type"] = "auction_cancelled") {
            participating_in_auction <- false;
            write name + " - Auction cancelled (price too low)";
        } else if (data["message_type"] = "lost") {
            participating_in_auction <- false;
            write name + " - Lost the auction (someone else won)";
        }
    }
    
    aspect default {
        draw circle(2.0) color: my_color border: #black;
        if (participating_in_auction) {
            draw circle(3.5) color: my_color border: #red empty: true;
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

// Auctioneer species - conducts Dutch auctions
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
    float reduction_interval <- 5.0; // Time between price reductions
    float last_reduction_time;
    
    list<agent> participants;
    agent winner;
    
    action start_auction {
        if (!auction_active) {
            auction_active <- true;
            current_auction_id <- name + "_" + string(time);
            
            // Generate random item
            item_name <- one_of(item_types);
            item_genre <- one_of(genres);
            starting_price <- rnd(50.0, 150.0);
            current_price <- starting_price;
            minimum_price <- starting_price * 0.3; // Won't sell below 30% of starting price
            price_reduction <- starting_price * rnd(0.05, 0.15); // Reduce by 5-15% each round
            last_reduction_time <- time;
            
            participants <- [];
            winner <- nil;
            my_color <- #orange;
            
            write "\n" + name + " STARTING DUTCH AUCTION!";
            write "Item: " + item_name + " (" + item_genre + ")";
            write "Starting price: $" + starting_price;
            write "Minimum price: $" + minimum_price;
            write "Price reduction per round: $" + price_reduction;
            
            // Send CFP to all guests
            do start_conversation to: list(guest) protocol: 'fipa-contract-net' performative: 'cfp' contents: [
                "auction_id"::current_auction_id,
                "item_name"::item_name,
                "item_genre"::item_genre,
                "starting_price"::starting_price,
                "message_type"::"auction_start"
            ];
        }
    }
    
    // Collect participants who showed interest
    reflex receive_proposals when: auction_active and !empty(proposes) {
        loop propose_msg over: proposes {
            map<string, unknown> data <- propose_msg.contents;
            if (data["interested"] = true and !(propose_msg.sender in participants)) {
                add propose_msg.sender to: participants;
                write name + " - " + propose_msg.sender.name + " joined the auction";
            }
        }
    }
    
    // Handle price reduction and check for acceptance
    reflex manage_auction when: auction_active and (time - last_reduction_time >= reduction_interval) {
        // Check if anyone accepted at current price
        if (!empty(accept_proposals)) {
            // First acceptance wins!
            message accept_msg <- accept_proposals[0];
            winner <- accept_msg.sender;
            
            write "\n" + name + " - SOLD to " + winner.name + " for $" + current_price + "!";
            
            // Inform winner
            do inform message: accept_msg contents: [
                "message_type"::"winner",
                "item_name"::item_name,
                "final_price"::current_price
            ];
            
            // Inform losers
            loop participant over: participants {
                if (participant != winner) {
                    do start_conversation to: [participant] protocol: 'fipa-contract-net' performative: 'inform' contents: [
                        "message_type"::"lost"
                    ];
                }
            }
            
            auction_active <- false;
            my_color <- #gold;
        } else {
            // No acceptance, reduce price
            current_price <- current_price - price_reduction;
            
            if (current_price < minimum_price) {
                // Cancel auction - price too low
                write "\n" + name + " - AUCTION CANCELLED (price below minimum)";
                
                loop participant over: participants {
                    do start_conversation to: [participant] protocol: 'fipa-contract-net' performative: 'inform' contents: [
                        "message_type"::"auction_cancelled"
                    ];
                }
                
                auction_active <- false;
                my_color <- #gold;
            } else {
                // Send price update to participants
                write name + " - Price reduced to $" + current_price;
                
                do start_conversation to: participants protocol: 'fipa-contract-net' performative: 'cfp' contents: [
                    "auction_id"::current_auction_id,
                    "current_price"::current_price,
                    "message_type"::"price_update"
                ];
                
                last_reduction_time <- time;
            }
        }
    }
    
    aspect default {
        draw square(6.0) color: my_color border: #black;
        if (auction_active) {
            draw circle(10.0) color: #red empty: true;
            draw "AUCTION" color: #red size: 15 at: location + {0, -8};
        }
    }
}

experiment FestivalAuction type: gui {
    parameter "Number of guests" var: nb_guests min: 5 max: 50;
    parameter "Number of stores" var: nb_stores min: 2 max: 10;
    parameter "Number of auctioneers" var: nb_auctioneers min: 1 max: 5;
    parameter "Auction interval" var: auction_interval min: 50.0 max: 300.0;
    
    output {
        display main_display {
            graphics "background" {
                draw rectangle(100, 100) color: #lightgreen border: #black;
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