model BDISocialAgentsSimulation

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
        
        write "✓ BDI Simulation started with " + (nb_party_people + nb_introverts + nb_music_lovers + nb_foodies + nb_sports_fans) + " agents";
    }
    
    reflex update_global_happiness {
        list<Guest> all_guests <- list(PartyPerson) + list(Introvert) + list(MusicLover) + list(Foodie) + list(SportsFan);
        if length(all_guests) > 0 {
            global_happiness <- mean(all_guests collect each.happiness);
        }
    }
    
    reflex monitor_stats when: every(100#cycle) {
        write "Cycle " + cycle + " | Happiness: " + with_precision(global_happiness, 2) + " | Interactions: " + total_interactions + " | Plans: " + total_plans_executed;
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
    
    init {
        if length(all_locations) > 0 {
            target_location <- one_of(all_locations);
        }
    }
    
    reflex perceive_nearby_agents {
        list<Guest> nearby <- Guest at_distance 10.0;
        
        loop g over: nearby {
            if g is PartyPerson {
                do add_belief(new_predicate("party_person_nearby"));
            } else if g is Introvert {
                do add_belief(new_predicate("introvert_nearby"));
            } else if g is MusicLover {
                do add_belief(new_predicate("music_lover_nearby"));
            } else if g is Foodie {
                do add_belief(new_predicate("foodie_nearby"));
            } else if g is SportsFan {
                do add_belief(new_predicate("sports_fan_nearby"));
            }
        }
    }
    
    reflex perceive_nearby_locations {
        list<Location> nearby_locs <- Location at_distance 20.0;
        
        loop loc over: nearby_locs {
            if loc is Bar {
                do add_belief(new_predicate("bar_nearby"));
            } else if loc is Concert {
                do add_belief(new_predicate("concert_nearby"));
            } else if loc is Restaurant {
                do add_belief(new_predicate("restaurant_nearby"));
            } else if loc is SportsVenue {
                do add_belief(new_predicate("sports_venue_nearby"));
            }
        }
    }
    
    reflex perceive_location when: current_location != nil and has_arrived {
        do add_belief(new_predicate("at_location"));
        if length(current_location.current_guests) > 5 { 
            do add_belief(new_predicate("crowded_location")); 
        } else { 
            do remove_belief(new_predicate("crowded_location")); 
        }
    }
    
    rule belief: new_predicate("at_location") new_desire: new_predicate("socialize") strength: 0.8;
    
    reflex check_energy when: energy < 0.3 {
        do add_desire(new_predicate("rest"));
    }
    
    plan rest_plan intention: new_predicate("rest") when: energy < 0.5 finished_when: energy > 0.7 {
        energy <- min(1.0, energy + 0.05);
        do wander amplitude: 20.0;
        total_plans_executed <- total_plans_executed + 1;
    }
    
    plan socialize_plan intention: new_predicate("socialize") when: has_arrived and length(current_location.current_guests) > 1 {
        list<Guest> others <- current_location.current_guests - self - interacted_this_visit;
        if length(others) > 0 and flip(sociability * 0.5) {
            Guest other <- one_of(others);
            do interact_with(other);
            interacted_this_visit << other;
            total_plans_executed <- total_plans_executed + 1;
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
            target_location <- one_of(all_locations);
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
            write "🧠 " + name + " seeking lively place";
            total_plans_executed <- total_plans_executed + 1;
        }
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        if current_location.noise_level > 0.6 {
            do update_happiness(0.02);
            if other is Introvert {
                ask other { do update_happiness(-0.05); }
                total_negative_interactions <- total_negative_interactions + 1;
            } else {
                do update_happiness(0.03);
                ask other { do update_happiness(0.02); }
                total_positive_interactions <- total_positive_interactions + 1;
            }
        } else {
            total_positive_interactions <- total_positive_interactions + 1;
        }
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
    
    plan seek_quiet intention: new_predicate("find_peaceful_place") when: !has_arrived or (has_arrived and current_location.noise_level > 0.6) {
        list<Location> quiet <- all_locations where (each.noise_level < 0.5);
        if length(quiet) > 0 and (target_location = nil or target_location.noise_level > 0.6) {
            target_location <- one_of(quiet);
            write "🧠 " + name + " seeking quiet place";
            total_plans_executed <- total_plans_executed + 1;
        }
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        if current_location.noise_level < 0.5 {
            do update_happiness(0.02);
            if other is Introvert {
                do update_happiness(0.03);
                ask other { do update_happiness(0.02); }
                total_positive_interactions <- total_positive_interactions + 1;
            } else if other is PartyPerson {
                do update_happiness(-0.03);
                total_negative_interactions <- total_negative_interactions + 1;
            } else {
                total_positive_interactions <- total_positive_interactions + 1;
            }
        } else {
            do update_happiness(-0.04 * (1.0 - tolerance));
            total_negative_interactions <- total_negative_interactions + 1;
        }
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
            write "🧠 " + name + " found " + favorite_genre + " concert";
            total_plans_executed <- total_plans_executed + 1;
        }
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        if current_location is Concert {
            Concert c <- Concert(current_location);
            if c.music_genre = favorite_genre {
                do update_happiness(0.05);
                if other is MusicLover and MusicLover(other).favorite_genre = favorite_genre {
                    do update_happiness(0.04);
                    ask other { do update_happiness(0.04); }
                }
            }
        }
        total_positive_interactions <- total_positive_interactions + 1;
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
    
    plan find_restaurant intention: new_predicate("find_restaurant") when: energy < 0.7 {
        list<Restaurant> restaurants <- all_locations where (each is Restaurant);
        list<Restaurant> match <- [];
        loop r over: restaurants {
            if (diet_preference = "vegan" and Restaurant(r).cuisine_type = "vegan") or
               (diet_preference = "meat" and Restaurant(r).cuisine_type = "steakhouse") or
               (diet_preference = "flexible") {
                match << r;
            }
        }
        if length(match) > 0 {
            target_location <- one_of(match);
            write "🧠 " + name + " found matching restaurant";
            total_plans_executed <- total_plans_executed + 1;
        }
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        if current_location is Restaurant {
            do update_happiness(0.03);
            energy <- min(1.0, energy + 0.1);
            if other is Foodie {
                ask other { do update_happiness(0.02); }
            }
        }
        total_positive_interactions <- total_positive_interactions + 1;
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
            write "🧠 " + name + " found " + favorite_sport + " game";
            total_plans_executed <- total_plans_executed + 1;
        }
    }
    
    action interact_with(Guest other) {
        total_interactions <- total_interactions + 1;
        if current_location is SportsVenue {
            SportsVenue v <- SportsVenue(current_location);
            if v.sport_type = favorite_sport {
                do update_happiness(0.05);
                if other is SportsFan and SportsFan(other).favorite_sport = favorite_sport {
                    do update_happiness(0.05);
                    ask other { do update_happiness(0.05); }
                }
            }
        }
        total_positive_interactions <- total_positive_interactions + 1;
    }
}

experiment BDISocialSimulation type: gui {
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
            chart "Global Happiness" type: series {
                data "Happiness" value: global_happiness color: #blue;
            }
        }
        
        display interaction_chart {
            chart "Interactions" type: series {
                data "Positive" value: total_positive_interactions color: #green;
                data "Negative" value: total_negative_interactions color: #red;
            }
        }
        
        monitor "Happiness" value: global_happiness;
        monitor "Total Interactions" value: total_interactions;
        monitor "BDI Plans Executed" value: total_plans_executed;
    }
}