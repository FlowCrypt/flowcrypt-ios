# FlowCryptUI test application

## Test application for easy testing UI common nodes 

All common UI elements are located in `FlowCryptUI` target.
This target also include `Texture` pod. 
Every build of this app will also build a FlowCryptUI target.

UI elements (Nodes and Views) are added in ViewController as a separate cells in table view. 
Which is a root controller of this test app

## Usage
* Choose FlowCryptUIApplication in schemes of the application and run it on simulator 
* You can add elements into `ViewController`
* Just add case into Elements enum and return proper node for this UIElement
 
