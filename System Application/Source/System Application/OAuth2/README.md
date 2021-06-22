This module contains supporting tools for authenticating via Azure Active Directory (Azure AD) using different OAuth 2.0 authorization protocols.
To learn more about Microsoft Identity Platform, you can go here. (https://docs.microsoft.com/en-us/azure/active-directory/develop/authentication-vs-authorization#authentication-and-authorization-using-the-microsoft-identity-platform)

Use this module to do the following:
- Acquire a token using the authorization code grant flow. To learn more about this flow you can go here. (https://docs.microsoft.com/en-us/azure/active-directory/azuread-dev/v1-protocols-oauth-code)
- Acquire a token using the On-Behalf-Of flow. To learn more about this flow you can go here. (https://docs.microsoft.com/en-us/azure/active-directory/azuread-dev/v1-oauth2-on-behalf-of-flow)
- Acquire a token using the client credentials grant flow. To learn more about this flow you can go here. (https://docs.microsoft.com/en-us/azure/active-directory/azuread-dev/v1-oauth2-client-creds-grant-flow)
- Acquire a token from cache. The prerequisite for the success of this method is that a token was obtained through one of the existing protocols. When invoked, this method will either return the current token from cache or will attempt to refresh it in the background for the flows that allow refreshing of the token.



