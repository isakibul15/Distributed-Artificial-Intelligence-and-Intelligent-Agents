/**
* Name: old
* Based on the internal empty template. 
* Author: Group-11
* Tags: 
*/

model Festival

global {
    geometry shape <- square(100);  // Define world bounds
    
    init {


        create FoodStore number: 1 {
            location <- {20, 20};
        }
        create DrinkStore number: 1 {
            location <- {50, 80};
        }
        create BothStore number: 1 {
            location <- {70, 20};
        }
        create InformationCenter number: 1 {
            location <- {50, 50};  
        }
                create Guest number: 20 {
            location <- any_location_in(shape);  // Random locations
        }
                create Security number:1 ;
        
    }
}

species Store {
    int capacity <- 20;
    int currentCapacity <- 0;
}

species FoodStore parent: Store {
    aspect base {
        draw square(8) color: #black;
    }
}

species DrinkStore parent: Store {
    aspect base {
        draw square(5) color: #black;
    }
}

species BothStore parent: Store {
    aspect base {
        draw square(9) color: #black;
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

species StoreInfo{
	Store store;
	string type;
}

species Guest skills: [moving] {
    bool isHungry <- false;
    bool isThirsty <- false;
    InformationCenter center <- first(InformationCenter);
    Store targetStore;
    bool isMovingToInfo <- false;
    bool evil <- false;
    list<StoreInfo> visited <- [];
    bool shouldReport <- false;
    Guest guestToBeReported <- nil;
    
    
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
    
	action addToStore(Store s,string t){
		
			create StoreInfo{
                store <- s;
                type <- t;
            }
           add item:last(StoreInfo) to: visited;
            
	}   
	
	action getStore(string t) {
    StoreInfo match <- visited first_with (each.type = t);
    if (match != nil) {
        return match.store;
    }
    return nil;
	} 

  reflex changeState {
        if (!isHungry) {
            isHungry <- flip(0.02);  
        }
        if (!isThirsty) {
            isThirsty <- flip(0.01);  
        }
        if(!isHungry and !isThirsty and !evil ){
        	evil <- flip(0.0005);
        	if(evil){
        		write "turned evil";
        	}
        }
    }
    
    reflex checkForBadGuests{
    	list<Guest> evil_guests <- (Guest - self) where (each.evil);

        // 2. if the list is empty → return nil
        if (!empty(evil_guests)) {
           guestToBeReported <- evil_guests closest_to(self);
           shouldReport <- true;
        }

    }
    
    
    
    reflex MovingToInfo when : (isMovingToInfo){
    	 do goto target: center.location;
    }

    reflex CheckForHungerOrThirst {
        if ((isHungry or isThirsty) and targetStore = nil and !isMovingToInfo) {
        	float randomValue <- rnd(1.0);
			if (randomValue < 0.1 or length(visited) <= 0 or shouldReport) { // discover new place
				write "Want to visit new store or going to report";
				 isMovingToInfo <- true;
				}
			else{
				Store s <- getStore(getNeedType());
				if(s != nil){
					write "Got store in memory";
					targetStore <- s;
				}
				else{
					write "Needed store not in memory";
					isMovingToInfo <- true;
				}
			}
			write "stores visited is" + visited;
        }
        else if (!isHungry and !isThirsty and targetStore = nil) {
            do wander;
        }
        // If targetStore != nil, do nothing here - let goToStore handle it
    }


    reflex askInfo {
      if (location distance_to center.location < 1.0 and targetStore = nil and (isHungry or isThirsty))  { //only if they reached , they can ask
   		
   		isMovingToInfo <- false;
   		
   		if(shouldReport){
   			ask Security{
   				if(killed contains myself.guestToBeReported){
   					//nothing
   				}
   				else{
   					write " reporting guest " + myself.guestToBeReported;
   					AssignedGuest <- myself.guestToBeReported;
   				}

   			}
   			guestToBeReported <- nil;
   			shouldReport <- false;
   		}
   		
        if (isHungry and isThirsty) {
            ask center {
            	
             myself.targetStore <- one_of(bothStores);
             	
             }
             
         
              }
 
        else if (isHungry) {
            ask center {
             myself.targetStore <- one_of(foodStores);          
              }
        }
        else if (isThirsty) {
            ask center {
             myself.targetStore <- one_of(drinkStores);          
              }
        }
        
        if (targetStore != nil) {
            write "location is " + targetStore.location;
            
            
        } else {
            write "No store found!";
        }
    }
    
    }
        
     reflex goToStore when: (targetStore != nil) {
        do goto target: targetStore.location;
    }
    
    
    reflex checkArrivalAtStore{
    	if(targetStore != nil ){
    		  if (location distance_to targetStore.location < 1.0) {
				do addToStore(targetStore,getNeedType());
			  	write "Guest arrived at store!";
                isHungry <- false;
                isThirsty <- false;
                targetStore <- nil;
    		  }
    		
    	}
    }
    
    

    aspect base {
        draw circle(3) color: evil ? #red : #yellow;
       
    }
}

species Security skills:[moving]{
	
	Guest AssignedGuest <- nil;
	list<Guest>  killed <- [];
	
	
	aspect base {
        draw circle(3) color: #purple;
    }
    
    reflex GotoGuest when : (AssignedGuest !=nil){
    	  do goto target: AssignedGuest.location;
    
    }
    
    action addToKillList(Guest g){
    	add item:g to: killed;
    }
    
    
    reflex checkForProblem{
    	if(AssignedGuest != nil){
    		if(!(killed contains AssignedGuest)){
    			write "kill list " + killed;
    		if (location distance_to AssignedGuest.location < 1.0 ) {
    			write "killing guest ";
    			do addToKillList(AssignedGuest);
    			ask AssignedGuest{
    				do die;
    			}
    			AssignedGuest <- nil;
    		}
    	}
    	
    	}
    	else{
    		do wander;
    	}
    }
}

experiment festival type: gui {
    output {
        display main_display {
            species Guest aspect: base;
            species InformationCenter aspect: base;
            species FoodStore aspect: base;
            species DrinkStore aspect: base;
            species BothStore aspect: base;
                        species Security aspect: base ;
            
        }
    }
}