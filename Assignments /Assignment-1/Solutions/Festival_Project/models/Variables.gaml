/**
* Name: Variables
* Based on the internal skeleton template. 
* Author: md.sakibulislam
* Tags: 
*/

model Variables

/* Insert your model definition here */

global {
	int integerVariable <- 3;
	float floatVariable <- 2.5;
	string stringVariable <- "test";
	bool booleanVariable <- true; // or flase

	reflex writeDebug {
		write integerVariable;
		write floatVariable;
		write stringVariable;
		write booleanVariable;
		floatVariable <- 3.0;
		write floatVariable;
	}
}

// GUI experiment
experiment myExperiment {}