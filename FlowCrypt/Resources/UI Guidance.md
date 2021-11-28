## FlowCrypt UI Guidance 

 Instead of using UIKit views and layout them we can use ASTableNode (similar to UITableView). 
 and build or UI in more flexible and reusable way by layouting independent ASTableNodeCells (UITableViewCell)
 They will not dependent on already existed elements. So for example we can add or remove parts without touching any other elements
 ASDK (Texture) can calculate UI not on Main Thread. For this we can use ASCellNodeBlock with ASCellNodes as return element

 For existed nodes please check FlowCryptUI. This contains all elements which are used it the app.
 Please use elements from FlowCryptUI or add new one.
 Consider this as design system for the app.

 Each node built in declarative way and can be build with Input (consider as view model for node)

 For button - ButtonCellNode can be used with appropriate ButtonCellNode.Input
 For titles - SetupTitleNode with input

 Usually all inputs for node can be build with attributed text, insets and action if supported
 There are a lot of usefull extensions for attributed text which uses common styling in app
 (FlowCryptCommon -> String extensions)

 Also app use Decorators for each View Controller focused on ui styling.
