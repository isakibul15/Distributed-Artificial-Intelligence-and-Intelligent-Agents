/**
* Name: NewModel
* Based on the internal empty template. 
* Author: ahsankarim
* Tags: 
*/
model NewModel

global {
    int N <- 8;
    list<map> solutions <- [];
    bool searching <- true;
    int max_solutions <- 1;
    bool algorithm_started <- false;
    
    init {
        create queen number: N;
    }
    
    reflex start_algorithm when: !algorithm_started and length(queen) = N {
        algorithm_started <- true;
        write "========================================";
        write "Starting N-Queens algorithm";
        write "========================================";
        
        // Trigger first queen to start
        queen first_queen <- queen(0);
        first_queen.should_start <- true;
    }
}

species queen skills: [fipa] {
    int id <- (index + 1);
    int row <- id;
    list<int> possible_columns <- [];
    int col_index <- 0;
    int my_col <- 0;
    map<int, int> current_config <- [];
    
    bool placed <- false;
    bool waiting <- false;
    bool initialized <- false;
    bool should_start <- false;
    
    rgb color <- #blue;
    point location <- {0, 0};
    
    // Initialize columns on first step
    reflex init_columns when: !initialized {
        loop i from: 1 to: N {
            add i to: possible_columns;
        }
        initialized <- true;
        write "Queen " + id + " initialized with columns: " + possible_columns;
    }
    
    // Start algorithm when triggered
    reflex start when: should_start and initialized {
        should_start <- false;
        write "Queen " + id + " starting placement";
        do try_place;
    }

    bool conflicts_with_predecessors(int test_col) {
        loop q_id over: current_config.keys {
            int col_q <- current_config[q_id];
            
            if (col_q = test_col) {
                return true;
            }
            
            if (abs(row - q_id) = abs(test_col - col_q)) {
                return true;
            }
        }
        return false;
    }
    
   reflex handle_fipa_messages when: (!empty(requests) or !empty(informs)) {
    
    loop m over: requests {
        list data <- list(m.contents);
        string msg_type <- string(data[0]);
        
        if (msg_type = "TRY") {
            current_config <- map(data[1]);
            col_index <- 0;
            placed <- false;
            waiting <- false;
            color <- #blue;
            write "Queen " + id + " received TRY with config: " + current_config;
            do try_place;
        }
        else if (msg_type = "BACKTRACK") {
            write "Queen " + id + " received BACKTRACK";
            col_index <- col_index + 1;
            placed <- false;
            color <- #orange;
            do try_place;
        }
    }
    
    loop m over: informs {
        list data <- list(m.contents);
        string msg_type <- string(data[0]);
        
        if (msg_type = "SUCCESS") {
            map<int, int> solution <- map(data[1]);
            write "Queen " + id + " received SUCCESS: " + solution;
            
            bool already_exists <- false;
            loop existing_sol over: solutions {
                if (existing_sol = solution) {
                    already_exists <- true;
                    break;
                }
            }
            
            if (!already_exists) {
                add solution to: solutions;
                write "========================================";
                write "=== Solution #" + length(solutions) + " found ===";
                write solution;
                write "========================================";
            }
            
            if (id > 1) {
                do start_conversation (
                    to :: [queen(id - 2)],
                    protocol :: 'fipa-request',  // ✅ FIXED
                    performative :: 'inform',
                    contents :: ['SUCCESS', solution]
                );
            }
        }
    }
}

action try_place {
    write "Queen " + id + " trying to place (col_index=" + col_index + ")";
    
    if (length(possible_columns) = 0) {
        write "ERROR: Queen " + id + " has empty possible_columns list!";
        return;
    }
    
    loop while: col_index < length(possible_columns) {
        int test_col <- possible_columns[col_index];
        write "  Testing column " + test_col;
        
        if (not conflicts_with_predecessors(test_col)) {
            my_col <- test_col;
            placed <- true;
            color <- #green;
            
            location <- {my_col * 10.0, row * 10.0};
            current_config[id] <- my_col;
            write "  ✓ Queen " + id + " placed in column " + my_col;
            
            if (id < N) {
                write "  → Sending TRY to Queen " + (id + 1);
                do start_conversation (
                    to :: [queen(id)],
                    protocol :: 'fipa-request',
                    performative :: 'request',
                    contents :: ['TRY', current_config]
                );
            } else {
                write "*** SOLUTION FOUND BY LAST QUEEN ***";
                color <- #gold;
                do start_conversation (
                    to :: [queen(id - 2)],
                    protocol :: 'fipa-request',  // ✅ FIXED
                    performative :: 'inform',
                    contents :: ['SUCCESS', current_config]
                );
            }
            
            return;
        }
        
        col_index <- col_index + 1;
    }
    
    write "  ✗ Queen " + id + " failed to place, backtracking";
    color <- #red;
    
    if (id > 1) {
        write "  ← Sending BACKTRACK to Queen " + (id - 1);
        do start_conversation (
            to :: [queen(id - 2)],
            protocol :: 'fipa-request',
            performative :: 'request',
            contents :: ['BACKTRACK']
        );
    } else {
        write "========================================";
        write "=== Search complete. Total solutions: " + length(solutions) + " ===";
        write "========================================";
        searching <- false;
    }
}    
    aspect default {
        if (placed) {
            draw circle(5) color: color border: #black;
            draw string(id) color: #white size: 8 at: location;
        }
    }
}

experiment NQueens type: gui {
    parameter "Board Size (N)" var: N min: 4 max: 20 category: "Board";
    parameter "Max Solutions to Find" var: max_solutions min: 1 max: 100 category: "Search";
    
    output {
        display "N-Queens Board" type: 2d {
            graphics "Chessboard" {
                loop i from: 1 to: N {
                    loop j from: 1 to: N {
                        rgb cell_color <- ((i + j) mod 2 = 0) ? #white : #lightgray;
                        draw square(10) at: {j * 10.0, i * 10.0} color: cell_color border: #black;
                    }
                }
                
                loop i from: 1 to: N {
                    draw string(i) at: {i * 10.0, 5.0} color: #black size: 10;
                }
                
                loop i from: 1 to: N {
                    draw string(i) at: {5.0, i * 10.0} color: #black size: 10;
                }
            }
            
            species queen aspect: default;
        }
        
        display "Statistics" type: 2d {
            graphics "Info" {
                draw "N-Queens Problem Solver" at: {10, 20} color: #black font: font("Arial", 16, #bold);
                draw "Board Size: " + N at: {10, 50} color: #black font: font("Arial", 14, #plain);
                draw "Solutions Found: " + length(solutions) at: {10, 80} color: #black font: font("Arial", 14, #plain);
                draw "Status: " + (searching ? "Searching..." : "Complete") at: {10, 110} color: #black font: font("Arial", 14, #plain);
                
                draw "Legend:" at: {10, 150} color: #black font: font("Arial", 14, #bold);
                draw circle(5) at: {30, 180} color: #blue;
                draw "Trying" at: {50, 180} color: #black font: font("Arial", 12, #plain);
                
                draw circle(5) at: {30, 210} color: #green;
                draw "Placed" at: {50, 210} color: #black font: font("Arial", 12, #plain);
                
                draw circle(5) at: {30, 240} color: #orange;
                draw "Backtracking" at: {50, 240} color: #black font: font("Arial", 12, #plain);
                
                draw circle(5) at: {30, 270} color: #red;
                draw "Failed" at: {50, 270} color: #black font: font("Arial", 12, #plain);
                
                draw circle(5) at: {30, 300} color: #gold;
                draw "Solution!" at: {50, 300} color: #black font: font("Arial", 12, #plain);
            }
        }
        
        display "Solutions" type: 2d {
            graphics "Solution List" {
                draw "All Solutions Found:" at: {10, 20} color: #black font: font("Arial", 14, #bold);
                
                int y_pos <- 50;
                loop i from: 0 to: length(solutions) - 1 {
                    map sol <- solutions[i];
                    string sol_text <- "Solution " + (i + 1) + ": " + sol;
                    draw sol_text at: {10, y_pos} color: #black font: font("Arial", 12, #plain);
                    y_pos <- y_pos + 30;
                }
            }
        }
        
        monitor "Board Size (N)" value: N;
        monitor "Solutions Found" value: length(solutions);
        monitor "Currently Searching" value: searching;
        monitor "Queens Created" value: length(queen);
    }
}