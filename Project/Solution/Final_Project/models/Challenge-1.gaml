/**
 * BDI Social Agents - Challenge 1 Implementation
 * Demonstrates BDI architecture with Beliefs, Desires, and Intentions
 * for different types of social agents
 */

model BDISocialAgents

global {
    // Environment setup
    int nb_party_people <- 10;
    int nb_introverts <- 10;
    int nb_rock_fans <- 10;
    int nb_disco_dancers <- 10;
    int nb_vegans <- 10;
    
    // Places
    list<point> bars;
    list<point> concerts;
    point park;
    
    // Global metrics
    float global_happiness <- 0.5;
    int positive_interactions <- 0;
    int negative_interactions <- 0;
    
    init {
        // Create locations
        create bar number: 2;
        create concert number: 2;
        create park_location number: 1;
        
        bars <- bar collect each.location;
        concerts <- concert collect each.location;
        park <- first(park_location).location;
        
        // Create different agent types
        create party_person number: nb_party_people;
        create introvert number: nb_introverts;
        create rock_fan number: nb_rock_fans;
        create disco_dancer number: nb_disco_dancers;
        create vegan number: nb_vegans;
    }
    
    reflex update_global_happiness {
        list<guest> all_guests <- (party_person + introvert + rock_fan + disco_dancer + vegan);
        global_happiness <- mean(all_guests collect each.happiness);
    }
}

// ============================================
// BDI ARCHITECTURE BASE
// ============================================

species guest skills: [moving] control: simple_bdi {
    
    // Personal traits (affect BDI reasoning)
    float generosity <- rnd(0.0, 1.0);
    float sociability <- rnd(0.0, 1.0);
    float tolerance <- rnd(0.0, 1.0);
    
    // State variables
    float happiness <- 0.5;
    float energy <- 1.0;
    point target_location;
    guest interaction_partner;
    
    // BDI Components will be defined in subspecies
    
    // Perception - what the agent senses
    perceive target: guest in: 5.0 {
        myself.add_belief(new_predicate("nearby_agent", ["agent"::self, "type"::self.species]));
    }
    
    // Common actions
    action go_to_location(point loc) {
        target_location <- loc;
        do goto target: target_location;
    }
    
    action rest {
        energy <- min(1.0, energy + 0.1);
        do wander;
    }
    
    action socialize(guest other) {
        // This will be overridden in subspecies
    }
    
    reflex update_energy when: energy > 0 {
        energy <- max(0.0, energy - 0.01);
    }
    
    reflex check_low_energy when: energy < 0.3 {
        do add_desire(new_predicate("rest"));
    }
    
    aspect default {
        draw circle(1) color: #gray;
    }
}

// ============================================
// PARTY PERSON - BDI Implementation
// ============================================

species party_person parent: guest {
    
    // BDI specific traits
    float noise_level <- rnd(0.5, 1.0);
    
    init {
        sociability <- rnd(0.7, 1.0);
        
        // Initial beliefs
        do add_belief(new_predicate("i_am_social"));
        do add_belief(new_predicate("i_like_crowds"));
        
        // Initial desires
        do add_desire(new_predicate("find_party_spot"));
        do add_desire(new_predicate("make_friends"));
    }
    
    // Perception specific to party person
    perceive target: guest in: 10.0 {
        if (self.species = introvert) {
            myself.add_belief(new_predicate("introvert_nearby", ["agent"::self]));
        } else if (self.species = party_person) {
            myself.add_belief(new_predicate("fellow_party_person", ["agent"::self]));
        }
    }
    
    // PLANS (Intentions)
    
    plan find_party when: has_desire(new_predicate("find_party_spot")) 
                    finished_when: target_location != nil {
        if (flip(0.6)) {
            target_location <- one_of(bars);
        } else {
            target_location <- one_of(concerts);
        }
        do goto target: target_location;
    }
    
    plan socialize_with_others when: has_desire(new_predicate("make_friends")) and 
                                     has_belief(new_predicate("fellow_party_person")) {
        list<guest> nearby_party <- guest at_distance 5.0 where (each.species = party_person);
        if (!empty(nearby_party)) {
            guest partner <- one_of(nearby_party);
            do socialize(partner);
            happiness <- min(1.0, happiness + 0.15);
            positive_interactions <- positive_interactions + 1;
        }
    }
    
    plan be_generous when: has_desire(new_predicate("make_friends")) and 
                          generosity > 0.7 {
        list<guest> nearby <- guest at_distance 5.0;
        if (!empty(nearby)) {
            guest receiver <- one_of(nearby);
            do add_belief(new_predicate("offered_drink", ["to"::receiver]));
            happiness <- min(1.0, happiness + 0.05);
        }
    }
    
    plan avoid_conflict when: has_belief(new_predicate("introvert_nearby")) and
                             target_location in bars {
        // At bar with introvert - might cause conflict
        if (tolerance < 0.5) {
            happiness <- max(0.0, happiness - 0.05);
            negative_interactions <- negative_interactions + 1;
        }
    }
    
    aspect default {
        draw circle(1) color: #red;
        if (happiness > 0.7) {
            draw circle(1.5) color: #red border: #yellow;
        }
    }
}

// ============================================
// INTROVERT - BDI Implementation
// ============================================

species introvert parent: guest {
    
    float comfort_distance <- rnd(8.0, 15.0);
    
    init {
        sociability <- rnd(0.1, 0.4);
        tolerance <- rnd(0.3, 0.8);
        
        // Initial beliefs
        do add_belief(new_predicate("i_need_space"));
        do add_belief(new_predicate("i_prefer_quiet"));
        
        // Initial desires
        do add_desire(new_predicate("find_quiet_spot"));
        do add_desire(new_predicate("maintain_personal_space"));
    }
    
    perceive target: guest in: 8.0 {
        if (self.species = party_person) {
            myself.add_belief(new_predicate("loud_person_nearby", ["agent"::self]));
            if (myself.target_location in bars) {
                myself.add_belief(new_predicate("uncomfortable_situation"));
            }
        } else if (self.species = introvert) {
            myself.add_belief(new_predicate("kindred_spirit", ["agent"::self]));
        }
    }
    
    // PLANS
    
    plan seek_solitude when: has_desire(new_predicate("find_quiet_spot")) 
                        finished_when: target_location != nil {
        target_location <- park;
        do goto target: target_location;
    }
    
    plan quiet_interaction when: has_belief(new_predicate("kindred_spirit")) and
                                sociability > 0.25 {
        list<guest> fellow_introverts <- guest at_distance 5.0 where (each.species = introvert);
        if (!empty(fellow_introverts)) {
            guest partner <- one_of(fellow_introverts);
            if (flip(0.4)) {
                do socialize(partner);
                happiness <- min(1.0, happiness + 0.1);
                positive_interactions <- positive_interactions + 1;
            }
        }
    }
    
    plan escape_noise when: has_belief(new_predicate("uncomfortable_situation")) {
        do remove_intention(new_predicate("find_quiet_spot"), true);
        target_location <- park;
        do goto target: target_location speed: 2.0;
        happiness <- max(0.0, happiness - 0.1);
        negative_interactions <- negative_interactions + 1;
    }
    
    plan accept_drink when: has_belief(new_predicate("offered_drink")) {
        if (tolerance > 0.6 and flip(0.5)) {
            happiness <- min(1.0, happiness + 0.08);
            do add_belief(new_predicate("positive_social_experience"));
        } else {
            happiness <- max(0.0, happiness - 0.03);
        }
    }
    
    plan recharge when: has_desire(new_predicate("rest")) and energy < 0.5 {
        do rest;
        happiness <- min(1.0, happiness + 0.05);
    }
    
    aspect default {
        draw circle(1) color: #blue;
        if (has_belief(new_predicate("uncomfortable_situation"))) {
            draw circle(1.5) color: #blue border: #red;
        }
    }
}

// ============================================
// ROCK FAN - BDI Implementation
// ============================================

species rock_fan parent: guest {
    
    string favorite_venue <- "concert";
    
    init {
        sociability <- rnd(0.4, 0.8);
        
        do add_belief(new_predicate("i_love_rock"));
        do add_desire(new_predicate("find_rock_concert"));
        do add_desire(new_predicate("meet_fellow_fans"));
    }
    
    perceive target: guest in: 7.0 {
        if (self.species = rock_fan and myself.target_location in concerts) {
            myself.add_belief(new_predicate("fellow_rock_fan", ["agent"::self]));
            myself.add_belief(new_predicate("shared_interest"));
        }
    }
    
    plan attend_concert when: has_desire(new_predicate("find_rock_concert")) {
        target_location <- one_of(concerts);
        do goto target: target_location;
        
        if (distance_to(self, target_location) < 3.0) {
            happiness <- min(1.0, happiness + 0.12);
        }
    }
    
    plan bond_over_music when: has_belief(new_predicate("shared_interest")) {
        list<guest> fellow_fans <- guest at_distance 7.0 where 
            (each.species = rock_fan or each.species = introvert);
        
        if (!empty(fellow_fans)) {
            guest partner <- one_of(fellow_fans);
            do socialize(partner);
            happiness <- min(1.0, happiness + 0.2);
            positive_interactions <- positive_interactions + 1;
            
            // Even introverts can bond over shared music interest!
            if (partner.species = introvert) {
                ask partner {
                    happiness <- min(1.0, happiness + 0.15);
                    do add_belief(new_predicate("positive_social_experience"));
                }
            }
        }
    }
    
    aspect default {
        draw circle(1) color: #purple;
        if (target_location in concerts and distance_to(self, target_location) < 3.0) {
            draw circle(1.5) color: #purple border: #white;
        }
    }
}

// ============================================
// DISCO DANCER - BDI Implementation
// ============================================

species disco_dancer parent: guest {
    
    init {
        sociability <- rnd(0.8, 1.0);
        energy <- 1.0;
        
        do add_belief(new_predicate("i_love_dancing"));
        do add_desire(new_predicate("find_dance_floor"));
    }
    
    perceive target: guest in: 6.0 {
        if (self.species = disco_dancer and myself.target_location in bars) {
            myself.add_belief(new_predicate("dance_partner_available", ["agent"::self]));
        }
    }
    
    plan go_dancing when: has_desire(new_predicate("find_dance_floor")) and energy > 0.4 {
        target_location <- one_of(bars);
        do goto target: target_location;
        
        if (distance_to(self, target_location) < 3.0) {
            energy <- max(0.0, energy - 0.05);
            happiness <- min(1.0, happiness + 0.18);
        }
    }
    
    plan dance_together when: has_belief(new_predicate("dance_partner_available")) and energy > 0.3 {
        list<guest> dancers <- guest at_distance 6.0 where 
            (each.species = disco_dancer or each.species = party_person);
        
        if (!empty(dancers)) {
            happiness <- min(1.0, happiness + 0.15);
            positive_interactions <- positive_interactions + 1;
        }
    }
    
    aspect default {
        draw circle(1) color: #yellow;
        if (energy > 0.7) {
            draw circle(1.8) color: #yellow border: #orange;
        }
    }
}

// ============================================
// VEGAN - BDI Implementation
// ============================================

species vegan parent: guest {
    
    float ethical_concern <- rnd(0.7, 1.0);
    
    init {
        tolerance <- rnd(0.5, 0.9);
        
        do add_belief(new_predicate("i_am_vegan"));
        do add_desire(new_predicate("find_vegan_food"));
    }
    
    perceive target: guest in: 5.0 {
        if (self.species = vegan) {
            myself.add_belief(new_predicate("fellow_vegan", ["agent"::self]));
        }
    }
    
    plan seek_food when: has_desire(new_predicate("find_vegan_food")) and energy < 0.7 {
        if (flip(0.7)) {
            target_location <- park; // Picnic area
        } else {
            target_location <- one_of(bars);
        }
        do goto target: target_location;
        
        if (distance_to(self, target_location) < 2.0) {
            energy <- min(1.0, energy + 0.15);
            happiness <- min(1.0, happiness + 0.1);
        }
    }
    
    plan discuss_ethics when: has_belief(new_predicate("fellow_vegan")) and sociability > 0.5 {
        list<guest> vegans <- guest at_distance 5.0 where (each.species = vegan);
        if (!empty(vegans)) {
            happiness <- min(1.0, happiness + 0.12);
            positive_interactions <- positive_interactions + 1;
        }
    }
    
    aspect default {
        draw circle(1) color: #green;
    }
}

// ============================================
// LOCATION SPECIES
// ============================================

species bar {
    aspect default {
        draw square(4) color: #brown;
    }
}

species concert {
    aspect default {
        draw square(5) color: #black;
    }
}

species park_location {
    aspect default {
        draw square(6) color: #lightgreen;
    }
}

// ============================================
// EXPERIMENT & VISUALIZATION
// ============================================

experiment BDI_Social_Simulation type: gui {
    
    parameter "Party People" var: nb_party_people min: 5 max: 30;
    parameter "Introverts" var: nb_introverts min: 5 max: 30;
    parameter "Rock Fans" var: nb_rock_fans min: 5 max: 30;
    parameter "Disco Dancers" var: nb_disco_dancers min: 5 max: 30;
    parameter "Vegans" var: nb_vegans min: 5 max: 30;
    
    output {
        display main_display {
            species bar;
            species concert;
            species park_location;
            species party_person;
            species introvert;
            species rock_fan;
            species disco_dancer;
            species vegan;
        }
        
        display happiness_chart {
            chart "Global Happiness Over Time" type: series {
                data "Average Happiness" value: global_happiness color: #blue;
            }
        }
        
        display interactions_chart {
            chart "Social Interactions" type: series {
                data "Positive" value: positive_interactions color: #green;
                data "Negative" value: negative_interactions color: #red;
            }
        }
        
        monitor "Global Happiness" value: global_happiness;
        monitor "Positive Interactions" value: positive_interactions;
        monitor "Negative Interactions" value: negative_interactions;
    }
}