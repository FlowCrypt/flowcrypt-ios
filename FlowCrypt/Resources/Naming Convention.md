## FlowCrypt naming convention 

### To give a better understanding of the naming convention of most parts of the application.

**ViewController** - represents the screen of the application that the user sees. 
All **ViewControllers** should be located inside the `Controllers` folder. 
Each ViewController should have a dedicated folder or located in folder which represents one flow. 
For example, Settings folder contains all controllers for the settings menu in the application. 
 
**ViewControllerDecorator** - to separate part of UI logic from ViewController itself. 
Decorator used to parse/map raw data to user representable format. 
For example String to NSAttributedString underlined with red line, etc... Or from raw business  model to Node acceptable **Input.** 
Decorator should be located in the same folder as ViewController

**ViewControllerProvider** - Separated part of ViewController which represents it's DataSource object. 
For example LegalViewControllersProvider - is data source for LegalViewController which creates and provides it with proper Segments. 
Also for example, FolderViewController should have possibility to get only folders info from IMAP service, not whole IMAP. 
That's why IMAP service divided with protocols base on it's main responsibility like `FoldersProvider` or `MessageProvider`.  

**Service -** part of app functionality responsible for separate part of application logic. 
For example, `UserService` - responsible for part related with user actions, like getting or renewing tokens, sign in or sign out. 
`GoogleService` - part of functionality related to Google authentication, getting google contacts, google scopes and so on. 
Each service should have protocol that describes it's functionality and should be named as `ServiceType`, for example, `UserServiceType`.  
*DataService* - Part of application mostly responsible for storing information, like tokens, keys and so on. 
Data can be stored in encrypted or local storages. 
Should be located in **Functionality** folder 
 

All other parts related to app functionality should be located **Functionality** folder, with the exception of **Core** folder, which should be a separate folder in root of the project. 

**Node** - UI element. Should be located in separate **FlowCryptUI target**

**Common UI** - will be moved to  **FlowCryptUI target**

