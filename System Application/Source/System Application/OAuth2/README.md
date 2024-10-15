This module contains tools that support authentication through Azure Active Directory (Azure AD) using OAuth 2.0 authorization protocols.

To learn more about the Microsoft Identity Platform, see [Microsoft Identity Platform documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/).

Use this module to do the following:
- Acquire a token by using the authorization code grant flow. For more information, see [Authorize access to Azure Active Directory web applications using the OAuth 2.0 code grant flow](https://docs.microsoft.com/en-us/azure/active-directory/azuread-dev/v1-protocols-oauth-code/) for v1.0 or [Microsoft identity platform and OAuth 2.0 authorization code flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow/) for v2.0.<br />
- Acquire a token by using the On-Behalf-Of (OBO) flow. For more information, see [Service-to-service calls that use delegated user identity in the On-Behalf-Of flow](https://docs.microsoft.com/en-us/azure/active-directory/azuread-dev/v1-oauth2-on-behalf-of-flow/) for v1.0 or [Microsoft identity platform and OAuth 2.0 On-Behalf-Of flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-on-behalf-of-flow) for v2.0.<br />
- Ask for directory admin consent for all the defined application permissions, see [Admin consent on the Microsoft identity platform](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-admin-consent)
- Acquire a token by using the client credentials grant flow. This requires that the administrator user has already consented the required application permissions. For more information, see [Service to service calls using client credentials](https://docs.microsoft.com/en-us/azure/active-directory/azuread-dev/v1-oauth2-client-creds-grant-flow/) for v1.0 or [Microsoft identity platform and the OAuth 2.0 client credentials flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow) for v2.0. To learn more about admin-restricted permissions, see [Admin-restricted permissions](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent#admin-restricted-permissions/).<br />
- Acquire the authorization code token from cache or a new refreshed token if the existing one has expired. This requires that the token was obtained earlier through the authorization code flow. This returns either the current token from cache or will try to refresh it in the background and return a new access token.<br />
- Acquire the access and refresh tokens by using the OBO flow. For more information, see [Service-to-service calls that use delegated user identity in the On-Behalf-Of flow](https://docs.microsoft.com/en-us/azure/active-directory/azuread-dev/v1-oauth2-on-behalf-of-flow/) for v1.0 or [Microsoft identity platform and OAuth 2.0 On-Behalf-Of flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-on-behalf-of-flow) for v2.0.<br />.<br />
- Acquire the OBO token from cache or a new refreshed token if the existing one has expired. This requires that the token was obtained earlier through the OBO flow. This returns either the current token from cache or will try to refresh it in the background and return a new access token.<br />



# Public Objects
## OAuth2 (Codeunit 501)

 Contains methods supporting authentication via OAuth 2.0 protocol.
 

### AcquireTokenByAuthorizationCode (Method) <a name="AcquireTokenByAuthorizationCode"></a> 

 Gets the authorization token based on the authorization code via the OAuth2.0 code grant flow. 
 

#### Syntax
```
[NonDebuggable]
[TryFunction]
procedure AcquireTokenByAuthorizationCode(ClientId: Text; ClientSecret: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; PromptInteraction: Enum "Prompt Interaction"; var AccessToken: Text; var AuthCodeErr: Text)
```
#### Parameters
*ClientId ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application (client) ID that the "Azure portal – App registrations" experience assigned to your app.

*ClientSecret ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application (client) secret configured in the "Azure Portal - Certificates & Secrets".

*OAuthAuthorityUrl ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The identity authorization provider URL.

*RedirectURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.

*ResourceURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application ID of the resource the application is requesting access to. This parameter can be empty.

*PromptInteraction ([Enum "Prompt Interaction"]())* 

Indicates the type of user interaction that is required.

*AccessToken ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Exit parameter containing the access token. When this parameter is empty, check the AuthCodeErr for a description of the error.

*AuthCodeErr ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Exit parameter containing the encountered error in the authorization code grant flow. This parameter will be empty in case the token is aquired successfuly.

### AcquireOnBehalfOfToken (Method) <a name="AcquireOnBehalfOfToken"></a> 

 Gets the authentication token via the On-Behalf-Of OAuth2.0 protocol flow. 
 

#### Syntax
```
[NonDebuggable]
[TryFunction]
procedure AcquireOnBehalfOfToken(RedirectURL: Text; ResourceURL: Text; var AccessToken: Text)
```
#### Parameters
*RedirectURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.

*ResourceURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application ID of the resource the application is requesting access to. This parameter can be empty.

*AccessToken ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Exit parameter containing the access token.

### AcquireTokenWithClientCredentials (Method) <a name="AcquireTokenWithClientCredentials"></a> 

 Gets the access token via the Client Credentials grant flow. 
 

#### Syntax
```
[NonDebuggable]
[TryFunction]
procedure AcquireTokenWithClientCredentials(ClientId: Text; ClientSecret: Text; OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; var AccessToken: Text)
```
#### Parameters
*ClientId ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application (client) ID that the Azure portal – App registrations experience assigned to your app.

*ClientSecret ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application (client) secret configured in the Azure Portal - Certificates & Secrets.

*OAuthAuthorityUrl ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The identity authorization provider URL.

*RedirectURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.

*ResourceURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application ID of the resource the application is requesting access to. This parameter can be empty.

*AccessToken ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Exit parameter containing the access token.

### AcquireAuthorizationCodeTokenFromCache (Method) <a name="AcquireAuthorizationCodeTokenFromCache"></a> 

 Gets the access token from the cache. 
 

#### Syntax
```
[NonDebuggable]
[TryFunction]
procedure AcquireAuthorizationCodeTokenFromCache(ClientId: Text; ClientSecret: Text; RedirectURL: Text; ResourceURL: Text; var AccessToken: Text)
```
#### Parameters
*ClientId ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application (client) ID that the Azure portal – App registrations experience assigned to your app.

*ClientSecret ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application (client) secret configured in the Azure Portal - Certificates & Secrets.

*RedirectURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.

*ResourceURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application ID of the resource the application is requesting access to. This parameter can be empty.

*AccessToken ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Exit parameter containing the access token.

### AcquireOnBehalfAccessTokenAndRefreshToken (Method) <a name="AcquireOnBehalfAccessTokenAndRefreshToken"></a> 

 Gets the access and refresh token via the On-Behalf-Of OAuth2.0 protocol flow. 
 

#### Syntax
```
[NonDebuggable]
[TryFunction]
procedure AcquireOnBehalfAccessTokenAndRefreshToken(OAuthAuthorityUrl: Text; RedirectURL: Text; ResourceURL: Text; var AccessToken: Text; var RefreshToken: Text)
```
#### Parameters
*OAuthAuthorityUrl ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The identity authorization provider URL.

*RedirectURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.

*ResourceURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application ID of the resource the application is requesting access to. This parameter can be empty.

*AccessToken ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Exit parameter containing the access token.

*RefreshToken ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Exit parameter containing the refresh_token that you acquired when you requested an access token.

### AcquireOnBehalfOfTokenByRefreshToken (Method) <a name="AcquireOnBehalfOfTokenByRefreshToken"></a> 

 Gets the access and refresh token via the On-Behalf-Of OAuth2.0 protocol flow. 
 

#### Syntax
```
[NonDebuggable]
[TryFunction]
procedure AcquireOnBehalfOfTokenByRefreshToken(ClientId: Text; RedirectURL: Text; ResourceURL: Text; RefreshToken: Text; var AccessToken: Text; var NewRefreshToken: Text)
```
#### Parameters
*ClientId ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application (client) ID that the Azure portal – App registrations experience assigned to your app.

*RedirectURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The redirectURL of your app, where authentication responses can be sent and received by your app. It must exactly match one of the redirectURLs you registered in the portal. If this parameter is empty, the default Business Central URL will be used.

*ResourceURL ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Application ID of the resource the application is requesting access to. This parameter can be empty.

*RefreshToken ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The refresh_token that you acquired when you requested an access token.

*AccessToken ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Exit parameter containing the access token.

*NewRefreshToken ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Exit parameter containing the new refresh token.


## OAuth2ControlAddIn (Page 502)
### SetOAuth2CodeFlowGrantProperties (Method) <a name="SetOAuth2CodeFlowGrantProperties"></a> 
#### Syntax
```
[Scope('OnPrem')]
[NonDebuggable]
procedure SetOAuth2CodeFlowGrantProperties(AuthRequestUrl: Text; AuthInitialState: Text)
```
#### Parameters
*AuthRequestUrl ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 



*AuthInitialState ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 



### GetAuthCode (Method) <a name="GetAuthCode"></a> 
#### Syntax
```
[Scope('OnPrem')]
[NonDebuggable]
procedure GetAuthCode(): Text
```
#### Return Value
*[Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)*


### GetAuthCodeError (Method) <a name="GetAuthCodeError"></a> 
#### Syntax
```
[Scope('OnPrem')]
[NonDebuggable]
procedure GetAuthCodeError(): Text
```
#### Return Value
*[Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)*



## Prompt Interaction (Enum 501)

 This enum contains the Prompt Interaction values possible for OAuth 2.0.
 

### None (value: 0)


 No prompt parameter in the request
 

### Login (value: 1)


 The user should be prompted to reauthenticate.
 

### Select Account (value: 2)


 The user is prompted to select an account, interrupting single sign on. The user may select an existing signed-in account, enter their credentials for a remembered account, or choose to use a different account altogether.
 

### Consent (value: 3)


 User consent has been granted, but needs to be updated. The user should be prompted to consent.
 

### Admin Consent (value: 4)


 An administrator should be prompted to consent on behalf of all users in their organization.
 

