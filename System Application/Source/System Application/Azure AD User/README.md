This module provides functionality for retrieving and updating user information from Azure AD.

Use this module to do the following:
- retrieve a user with a specified security ID from Azure AD
- retrieve a user's object ID from Azure AD
- retrieve a user's authentication object ID from Azure AD
- update a User record with information from Azure AD
- ensure an authentication email is not in use

This module is meant for on-premises use only.

# Public Objects
## Azure AD Graph User (Codeunit 9024)

 Exposes functionality to retrieve and update Azure AD users.
 

### GetGraphUser (Method) <a name="GetGraphUser"></a> 
    
 Gets the Azure AD user with the given security ID.
 

#### Syntax
```
[Scope('OnPrem')]
[TryFunction]
procedure GetGraphUser(UserSecurityId: Guid; var User: DotNet UserInfo)
```
#### Parameters
*UserSecurityId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The user's security ID.

*User ([DotNet UserInfo](https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.userinfo?view=azure-dotnet))* 

The Azure AD user.

### GetGraphUser (Method) <a name="GetGraphUser"></a> 
    
 Gets the Azure AD user with the given security ID.
 

#### Syntax
```
[Scope('OnPrem')]
[TryFunction]
procedure GetGraphUser(UserSecurityId: Guid; ForceFetchFromGraph: Boolean; var User: DotNet UserInfo)
```
#### Parameters
*UserSecurityId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The user's security ID.

*ForceFetchFromGraph ([Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type))* 

Forces a graph call to get the latest details for the user.

*User ([DotNet UserInfo](https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.userinfo?view=azure-dotnet))* 

The Azure AD user.

### GetObjectId (Method) <a name="GetObjectId"></a> 

 Retrieves the user’s unique identifier, which is its object ID, from Azure AD.
 

#### Syntax
```
[Scope('OnPrem')]
procedure GetObjectId(UserSecurityId: Guid): Text
```
#### Parameters
*UserSecurityId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The user's security ID.

#### Return Value
*[Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)*


 The object ID of the Azure AD user, or an empty string if the user cannot be found.
 
### GetUserAuthenticationObjectId (Method) <a name="GetUserAuthenticationObjectId"></a> 
User with Security ID UserSecurityId does not exist.

    
 Gets the user's authentication object ID.
 

#### Syntax
```
[Scope('OnPrem')]
procedure GetUserAuthenticationObjectId(UserSecurityId: Guid): Text
```
#### Parameters
*UserSecurityId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The user's security ID.

#### Return Value
*[Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)*

The user's authentication object ID.
### GetUser (Method) <a name="GetUser"></a> 
    
 Gets the user from a given Authentication object ID.
 

#### Syntax
```
[Scope('OnPrem')]
procedure GetUser(AuthenticationObjectID: Text; var User: Record User): Boolean
```
#### Parameters
*AuthenticationObjectID ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The user's Authentication object ID.

*User ([Record User]())* 

The user that has provided Authentication object ID.

#### Return Value
*[Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type)*

True if the user was found, false otherwise.
### UpdateUserFromAzureGraph (Method) <a name="UpdateUserFromAzureGraph"></a> 
    
 Updates the user record with information from Azure AD.
 

#### Syntax
```
[Scope('OnPrem')]
procedure UpdateUserFromAzureGraph(var User: Record User; var AzureADUser: DotNet UserInfo): Boolean
```
#### Parameters
*User ([Record User]())* 

The user record to update.

*AzureADUser ([DotNet UserInfo](https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.userinfo?view=azure-dotnet))* 

The Azure AD user.

#### Return Value
*[Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type)*

True if the user record has been updated. Otherwise, false.
### GetAuthenticationEmail (Method) <a name="GetAuthenticationEmail"></a> 
    
 Gets the authentication email of the provided Graph user.
 

Authentication email corresponds to userPrincipalName property on the Graph user.

#### Syntax
```
[Scope('OnPrem')]
procedure GetAuthenticationEmail(GraphUser: DotNet UserInfo): Text[250]
```
#### Parameters
*GraphUser ([DotNet UserInfo](https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.userinfo?view=azure-dotnet))* 

The Azure AD user.

#### Return Value
*[Text[250]](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)*

The authentication email of the provided Graph user. Can be used to assign to "Authentication Email" field on the User table.
### GetDisplayName (Method) <a name="GetDisplayName"></a> 
    
 Gets the display name of the provided Graph user.
 

Display name corresponds to displayName property on the Graph user.

#### Syntax
```
[Scope('OnPrem')]
procedure GetDisplayName(GraphUser: DotNet UserInfo): Text[50]
```
#### Parameters
*GraphUser ([DotNet UserInfo](https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.userinfo?view=azure-dotnet))* 

The Azure AD user.

#### Return Value
*[Text[50]](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)*

The display name of the provided Graph user. Can be used to assign to "User Name" field on the User table.
### GetContactEmail (Method) <a name="GetContactEmail"></a> 
    
 Gets the contact email of the provided Graph user.
 

Contact email corresponds to Mail property on the Graph user.

#### Syntax
```
[Scope('OnPrem')]
procedure GetContactEmail(GraphUser: DotNet UserInfo): Text[250]
```
#### Parameters
*GraphUser ([DotNet UserInfo](https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.userinfo?view=azure-dotnet))* 

The Azure AD user.

#### Return Value
*[Text[250]](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)*

The contact email of the provided Graph user. Can be used to assign to "Contact Email" field on the User table.
### GetFullName (Method) <a name="GetFullName"></a> 
    
 Gets the full name of the provided Graph user.
 

Full name is composed from the combination of givenName and surname properties on the Graph user.

#### Syntax
```
[Scope('OnPrem')]
procedure GetFullName(GraphUser: DotNet UserInfo): Text[80]
```
#### Parameters
*GraphUser ([DotNet UserInfo](https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.userinfo?view=azure-dotnet))* 

The Azure AD user.

#### Return Value
*[Text[80]](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)*

The full name of the provided Graph user. Can be used to assign to "Full Name" field on the User table.
### GetPreferredLanguageID (Method) <a name="GetPreferredLanguageID"></a> 
    
 Gets the preferred language ID of the provided Graph user.
 

Preferred language ID is derived from preferredLanguage property on the Graph user.

#### Syntax
```
[Scope('OnPrem')]
procedure GetPreferredLanguageID(GraphUser: DotNet UserInfo): Integer
```
#### Parameters
*GraphUser ([DotNet UserInfo](https://docs.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.clients.activedirectory.userinfo?view=azure-dotnet))* 

The Azure AD user.

#### Return Value
*[Integer](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/integer/integer-data-type)*

The preferred language ID of the provided Graph user. Can be used to set the preferred language using the Language module.
### EnsureAuthenticationEmailIsNotInUse (Method) <a name="EnsureAuthenticationEmailIsNotInUse"></a> 
    
 Ensures that an email address specified for authorization is not already in use by another database user.
 If it is, all the database users with this authentication email address are updated and their email 
 addresses are updated the ones that are specified in Azure AD.
 

#### Syntax
```
[Scope('OnPrem')]
procedure EnsureAuthenticationEmailIsNotInUse(AuthenticationEmail: Text)
```
#### Parameters
*AuthenticationEmail ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The authentication email address.

### SetTestInProgress (Method) <a name="SetTestInProgress"></a> 

 Sets a flag that is used to determine whether a test is in progress or not.
 

#### Syntax
```
[Scope('OnPrem')]
procedure SetTestInProgress(TestInProgress: Boolean)
```
#### Parameters
*TestInProgress ([Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type))* 

The value to be set to the flag.

