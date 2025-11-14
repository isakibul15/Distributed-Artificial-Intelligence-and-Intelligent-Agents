/**
* Name: BasicModel_challenge1 
* Author: Adele, Kat
* Tags: 
*/

model BasicModel
/* Insert your model definition here */

global {
	int numberOfPeople <- 10;
	int numberOfFoodStores <- 1;
	int numberOfDrinkStores <- 1;
	point infoCenterLocation <- {50,50}; // to make it centralised
	
	init {
		create Person number:numberOfPeople{}
		create FoodStore number:numberOfFoodStores{}
		create DrinkStore number:numberOfDrinkStores{}
		create InfoCenter number: 1
		{
			location <- infoCenterLocation;
		}
		
	}
}

species Person skills: [moving] {
	bool isHungry <- false ;
	bool isThirsty <- false;
	float prob_ht <- 0.005; //probability for dancing (idle) agent to be hungry or thirsty
	string personName <- "Undefined";
	int infoCenterSize <- 5;
	point targetPoint <- nil; 
	bool goingInfo <- false;
	bool goingFoodStore <- false;
	bool goingDrinkStore <- false;
	
	list<point> visitedFoodStores;	
	list<point> visitedDrinkStores;
	list<point> visitedStores;
	
	list<DrinkStore> drinkStoreLocations <- (DrinkStore at_distance 500);

	aspect base {	
		rgb agentColor <- rgb("red");
		if (isThirsty) {
			agentColor <- rgb("darkorange");
		} else if (isHungry) {
			agentColor <- rgb("yellow");
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
		do goto target: targetPoint.location;
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
		rgb storeColor <- rgb("lightskyblue"); 
		if(hasFood){
			storeColor <- rgb("skyblue"); 
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
		rgb storeColor <- rgb("lightgray"); 
		if(hasDrink){
			storeColor <- rgb("green");
		}
		
		draw triangle(5) at: location color: storeColor;
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
		}
	}
}

