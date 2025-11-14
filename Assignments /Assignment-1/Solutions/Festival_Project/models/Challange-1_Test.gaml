/**
* Name: BasicModel_challenge2
* Author: Adele, Kat
* Tags: 
*/

model BasicModel
/* Insert your model definition here */

global {
	int numberOfPerson <- 10;
	int numberOfFoodStores <- 2;
	int numberOfDrinkStores <- 2;
	point infoCenterLocation <- {50,50}; // to make it centralised
	float personSpeed <- 0.5;
	float securitySpeed <- personSpeed * 2.0;
	
	init {
		create Person number:numberOfPerson{}
		create FoodStore number:numberOfFoodStores{}
		create DrinkStore number:numberOfDrinkStores{}
		create InfoCenter number: 1
		{
			location <- infoCenterLocation;
		}
		
		create SecurityGuard number:1{}
		
	}
}

species Person skills: [moving] {
	bool isHungry <- false ;
	bool isThirsty <- false;
	float prob_ht <- 0.005;
	int infoCenterSize <- 5;
	point targetPoint <- nil; 
	bool goingInfo <- false;
	bool goingFoodStore <- false;
	bool goingDrinkStore <- false;
	
	list<point> visitedFoodStores;	
	list<point> visitedDrinkStores;
	
	bool isBadGuest <- flip(0.2); //modified to identify bad behaviour for this challenge

	
	aspect base {	
		rgb agentColor <- rgb("red");
		if (isThirsty) {
			agentColor <- rgb("darkorange");
		} else if (isHungry) {
			agentColor <- rgb("yellow");
		}	
		
		if (isBadGuest){
			agentColor <- rgb("black");
		}	
		draw circle(2) color: agentColor;
	}
	
	
	reflex beIdle when:targetPoint = nil
	{
		do wander; //randomly dancing
	}
	
	reflex stateUpdate
	{
		if(!isHungry){
			if(flip(prob_ht)){
			 	isHungry <- true;
			 }
		}
		if(!isThirsty){
			if(flip(prob_ht)) {
			 	isThirsty <- true;
			 }
		}
	}
	
    reflex decideWhereToGo when: isHungry or isThirsty {
        if (targetPoint = nil) {
        	// Person has 50% chance of using small brain(memory)
			bool useSmallBrain <- flip(0.5);
			if(useSmallBrain){
				if(isHungry and length(visitedFoodStores)>0){
					 targetPoint <- one_of(visitedFoodStores);
					 goingFoodStore <- true;
					 write "small brain used";
				}
				// If user is thirsty, ask brain for drink stores
				else if(isThirsty and length(visitedDrinkStores)>0)
				{
					targetPoint <- one_of(visitedDrinkStores);
					goingDrinkStore <- true;
					write "small brain used";
				}
			}
		}
		
		if(!goingFoodStore and !goingDrinkStore){
			targetPoint <- infoCenterLocation;
        	goingInfo <- true;
		}
		
    }
    
    reflex moveToTarget when: targetPoint != nil
	{	/* default move towards is info center*/
		do goto target: targetPoint.location speed: personSpeed;
	}

    reflex enterInfo when: goingInfo and (location distance_to(infoCenterLocation) <= infoCenterSize) {
		if(isHungry){
			ask one_of (FoodStore where each.hasFood) {
				myself.targetPoint <- location;
			}
			goingFoodStore <- true;
		} else if(isThirsty){
			ask one_of (DrinkStore where each.hasDrink) {
				myself.targetPoint <- location;
			}
			goingDrinkStore <- true;
		}
		goingInfo <- false;
	}

    reflex enterFoodStore when: goingFoodStore and (location distance_to(targetPoint) <= 1) {
		isHungry <- false;
		goingFoodStore <- false;
		if(length(visitedFoodStores) < 2)
		{
			visitedFoodStores <+ targetPoint;
		}
		targetPoint <- nil;
		do wander;
	}
	
	reflex enterDrinkStore when: goingDrinkStore and (location distance_to(targetPoint) <= 1) {
		isThirsty <- false;
		goingDrinkStore <- false;
		if(length(visitedDrinkStores) < 2)
		{
			visitedDrinkStores <+ targetPoint;
		}
		targetPoint <- nil;
		do wander;
	}	
}

species InfoCenter {	
	// Get some food and drink store locations
	list<FoodStore> foodStoreLocations <- (FoodStore at_distance 500);
	list<DrinkStore> drinkStoreLocations <- (DrinkStore at_distance 500);
	
	bool hasLocations <- false;
	reflex listStoreLocations when: hasLocations = false{
		ask foodStoreLocations {
			write "Food store at:" + location; 
		}	
		ask drinkStoreLocations {
			write "Drink store at:" + location; 
		}
		hasLocations <- true;
	}
	
	reflex reportBadBehavior {
		list<Person> badGuestsList;	
		// Iterating over all Person agents to add the ones that are bad guests and not dead
        ask Person {
        	if(isBadGuest){
        		badGuestsList <+ self;
        	}	
        }
        
	    if (length(badGuestsList) > 0) {
	        // Now, you can safely ask a bad guest
	        let badGuest <- one_of(badGuestsList);
	    	ask one_of (SecurityGuard) {
				if(!dead(badGuest) and !(self.targets contains badGuest))
				{
					self.targets <+ badGuest;
					write "Information center reported a bad guest to Security Guard.";
				}
			}
		}
	}
		
	aspect default {
		rgb infoColor <- rgb("darkblue");
		draw cube(5) at: location color: infoColor;
	}
}


species FoodStore {
	bool hasFood <- true; 
	bool hasDrink <- false;
	string storeName <- "Undefined";
	
	action setName(int num) {
		storeName <- "Store " + num;
	}
	
	aspect default
	{
		rgb storeColor <- rgb("lightskyblue"); //0
		if(hasFood){
			storeColor <- rgb("skyblue"); //2
		}
		
		draw triangle(5) at: location color: storeColor;
	}
}

species DrinkStore {
	bool hasFood <- false;
	bool hasDrink <- true;
	string storeName <- "Undefined";
	
	action setName(int num) {
		storeName <- "Store " + num;
	}
	
	aspect default
	{
		rgb storeColor <- rgb("lightgray"); //0
		if(hasDrink){
			storeColor <- rgb("green"); //2
		}
		
		draw triangle(5) at: location color: storeColor;
	}
}

species SecurityGuard skills: [moving] {
	list<Person> targets;
	bool isOnDuty <- false;
	
	aspect default
	{
		draw cube(5) at: location color: #black;
	}
	
	reflex catchBadGuest when: length(targets) > 0
	{
		if(dead(targets[0]))
		{
			targets >- first(targets);
			//if a badGuest left the party on their own, skip and move to next one
		}
		else
		{
			do goto target:(targets[0].location) speed: securitySpeed;
		}
	}
	
	reflex killBadGuest when: length(targets) > 0 and !dead(targets[0]) and (location distance_to(targets[0].location) < 1) 
	{
		Person badGuest <- targets[0];
        if (badGuest != nil and !dead(badGuest) and (location distance_to(badGuest.location) < 1)) {
            ask badGuest {
                write 'Bad guest caught and killed by Security Guard!';
                do die;
            }
            targets >- badGuest; // Remove the bad guest from the targets list
            
        } else {
            targets >- badGuest; // Remove the nil or dead guest from the targets list
        }
	} 
	
}


experiment main type: gui
{	
	output {
		display map {
			species Person aspect:base;
			species FoodStore;
			species DrinkStore;
			species InfoCenter;
			
			species SecurityGuard;
		}
	}
	
}

