This module provides the tools needed to manage an extension.

Use this module to do the following:
- Install and uninstall extensions, with the option to use UI events
- Upload and deploy an extension
- Publish or unpublish extensions (publishing is available only in the client)
- Download a per-tenant extension source
- Check whether an extension is installed, which version, and whether its the latest
- Refresh and retrieve the extension deployment status and information
- Enable or disable http client requests
- Retrieve an extension's logo

# Public Objects
## Extension Management (Codeunit 2504)

 Provides features for installing and uninstalling, downloading and uploading, configuring and publishing extensions and their dependencies.
 

### InstallExtension (Method) <a name="InstallExtension"></a> 

 Installs an extension, based on its PackageId and Locale Identifier.
 

#### Syntax
```
procedure InstallExtension(PackageId: Guid; lcid: Integer; IsUIEnabled: Boolean): Boolean
```
#### Parameters
*PackageId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The ID of the extension package.

*lcid ([Integer](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/integer/integer-data-type))* 

The Locale Identifier.

*IsUIEnabled ([Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type))* 

Indicates whether the install operation is invoked through the UI.

#### Return Value
*[Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type)*

True if the extention is installed successfully; false otherwise.
### UninstallExtension (Method) <a name="UninstallExtension"></a> 

 Uninstalls an extension, based on its PackageId.
 

#### Syntax
```
procedure UninstallExtension(PackageId: Guid; IsUIEnabled: Boolean): Boolean
```
#### Parameters
*PackageId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The ID of the extension package.

*IsUIEnabled ([Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type))* 

Indicates if the uninstall operation is invoked through the UI.

#### Return Value
*[Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type)*

True if the extention is uninstalled successfully; false otherwise.
### UploadExtension (Method) <a name="UploadExtension"></a> 

 Uploads an extension, using a File Stream and based on the Locale Identifier.
 This method is only applicable in SaaS environment.
 

#### Syntax
```
procedure UploadExtension(FileStream: InStream; lcid: Integer)
```
#### Parameters
*FileStream ([InStream](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type))* 

The File Stream containing the extension to be uploaded.

*lcid ([Integer](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/integer/integer-data-type))* 

The Locale Identifier.

### DeployExtension (Method) <a name="DeployExtension"></a> 

 Deploys an extension, based on its ID and Locale Identifier.
 This method is only applicable in SaaS environment.
 

#### Syntax
```
procedure DeployExtension(AppId: Guid; lcid: Integer; IsUIEnabled: Boolean)
```
#### Parameters
*AppId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The AppId of the extension.

*lcid ([Integer](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/integer/integer-data-type))* 

The Locale Identifier.

*IsUIEnabled ([Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type))* 

Indicates whether the install operation is invoked through the UI.

### UnpublishExtension (Method) <a name="UnpublishExtension"></a> 

 Unpublishes an extension, based on its PackageId. 
 An extension can only be unpublished, if it is a per-tenant one and it has been uninstalled first.
 

#### Syntax
```
procedure UnpublishExtension(PackageId: Guid): Boolean
```
#### Parameters
*PackageId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The PackageId of the extension.

#### Return Value
*[Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type)*

True if the extention is unpublished successfully; false otherwise.
### DownloadExtensionSource (Method) <a name="DownloadExtensionSource"></a> 

 Downloads the source of an extension, based on its PackageId.
 

#### Syntax
```
procedure DownloadExtensionSource(PackageId: Guid): Boolean
```
#### Parameters
*PackageId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The PackageId of the extension.

#### Return Value
*[Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type)*

True if the operation was successful; false otherwise.
### IsInstalledByPackageId (Method) <a name="IsInstalledByPackageId"></a> 

 Checks whether an extension is installed, based on its PackageId.
 

#### Syntax
```
procedure IsInstalledByPackageId(PackageId: Guid): Boolean
```
#### Parameters
*PackageId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The ID of the extension package.

#### Return Value
*[Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type)*

The result of checking whether an extension is installed.
### IsInstalledByAppId (Method) <a name="IsInstalledByAppId"></a> 

 Checks whether an extension is installed, based on its AppId.
 

#### Syntax
```
procedure IsInstalledByAppId(AppId: Guid): Boolean
```
#### Parameters
*AppId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The AppId of the extension.

#### Return Value
*[Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type)*

The result of checking whether an extension is installed.
### GetAllExtensionDeploymentStatusEntries (Method) <a name="GetAllExtensionDeploymentStatusEntries"></a> 

 Retrieves a list of all the Deployment Status Entries
 

#### Syntax
```
procedure GetAllExtensionDeploymentStatusEntries(var NavAppTenantOperation: Record "NAV App Tenant Operation")
```
#### Parameters
*NavAppTenantOperation ([Record "NAV App Tenant Operation"]())* 

Gets the list of all the Deployment Status Entries.

### GetDeployOperationInfo (Method) <a name="GetDeployOperationInfo"></a> 

 Retrieves the AppName,Version,Schedule,Publisher by the NAVApp Tenant OperationId.
 

#### Syntax
```
procedure GetDeployOperationInfo(OperationId: Guid; var Version: Text; var Schedule: Text; var Publisher: Text; var AppName: Text; Description: Text)
```
#### Parameters
*OperationId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The OperationId of the NAVApp Tenant.

*Version ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Gets the Version of the NavApp.

*Schedule ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Gets the Schedule of the NavApp.

*Publisher ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Gets the Publisher of the NavApp.

*AppName ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

Gets the AppName of the NavApp.

*Description ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Description of the NavApp; in case no name is provided, the description will replace the AppName.

### RefreshStatus (Method) <a name="RefreshStatus"></a> 

 Refreshes the status of the Operation.
 

#### Syntax
```
procedure RefreshStatus(OperationId: Guid)
```
#### Parameters
*OperationId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The Id of the operation to be refreshed.

### ConfigureExtensionHttpClientRequestsAllowance (Method) <a name="ConfigureExtensionHttpClientRequestsAllowance"></a> 

 Allows or disallows Http Client requests against the specified extension.
 

#### Syntax
```
procedure ConfigureExtensionHttpClientRequestsAllowance(PackageId: Text; AreHttpClientRqstsAllowed: Boolean): Boolean
```
#### Parameters
*PackageId ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The Id of the extension to configure.

*AreHttpClientRqstsAllowed ([Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type))* 

The value to set for "Allow HttpClient Requests".

#### Return Value
*[Boolean](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/boolean/boolean-data-type)*

True configuration was successful; false otherwise.
### GetLatestVersionPackageIdByAppId (Method) <a name="GetLatestVersionPackageIdByAppId"></a> 

 Gets the PackageId of the latest Extension Version by the Extension AppId.
 

#### Syntax
```
procedure GetLatestVersionPackageIdByAppId(AppId: Guid): Guid
```
#### Parameters
*AppId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The AppId of the extension.

#### Return Value
*[Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type)*

The package ID by app ID. Empty GUID, if package with the provided app ID does not exist.
### GetCurrentlyInstalledVersionPackageIdByAppId (Method) <a name="GetCurrentlyInstalledVersionPackageIdByAppId"></a> 

 Gets the PackageId of the latest version of the extension by the extension's AppId.
 

#### Syntax
```
procedure GetCurrentlyInstalledVersionPackageIdByAppId(AppId: Guid): Guid
```
#### Parameters
*AppId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The AppId of the installed extension.

#### Return Value
*[Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type)*

The package ID of the installed version of an extenstion. Empty GUID, if package with the provided app ID does not exist.
### GetSpecificVersionPackageIdByAppId (Method) <a name="GetSpecificVersionPackageIdByAppId"></a> 

 Gets the package ID of the version of the extension by the extension's AppId, Name, Version Major, Version Minor, Version Build, Version Revision.
 

#### Syntax
```
procedure GetSpecificVersionPackageIdByAppId(AppId: Guid; Name: Text; VersionMajor: Integer; VersionMinor: Integer; VersionBuild: Integer; VersionRevision: Integer): Guid
```
#### Parameters
*AppId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The AppId of the extension.

*Name ([Text](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type))* 

The input/output Name parameter of the extension. If there is no need to filter by this parameter, the default value is ''.

*VersionMajor ([Integer](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/integer/integer-data-type))* 

The input/output Version Major parameter of the extension. If there is no need to filter by this parameter, the default value is "0".

*VersionMinor ([Integer](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/integer/integer-data-type))* 

The input/output Version Minor parameter  of the extension. If there is no need to filter by this parameter, the default value is "0"..

*VersionBuild ([Integer](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/integer/integer-data-type))* 

The input/output Version Build parameter  of the extension. If there is no need to filter by this parameter, the default value is "0".

*VersionRevision ([Integer](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/integer/integer-data-type))* 

The input/output Version Revision parameter  of the extension. If there is no need to filter by this parameter, the default value is "0".

#### Return Value
*[Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type)*

The package ID of the extension with the specified paramters.
### GetExtensionLogo (Method) <a name="GetExtensionLogo"></a> 

 Gets the logo of an extension.
 

#### Syntax
```
procedure GetExtensionLogo(AppId: Guid; var Logo: Codeunit "Temp Blob")
```
#### Parameters
*AppId ([Guid](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/guid/guid-data-type))* 

The App ID of the extension.

*Logo ([Codeunit "Temp Blob"]())* 

Out parameter holding the logo of the extension.


## Extension Deployment Status (Page 2508)

 Displays the deployment status for extensions that are deployed or are scheduled for deployment.
 


## Extension Details (Page 2501)

 Displays details about the selected extension, and offers features for installing and uninstalling it.
 


## Extension Details Part (Page 2504)

 Displays information about the extension.
 


## Extension Installation (Page 2503)

 Installs the selected extension.
 


## Extension Logo Part (Page 2506)

 Displays the extension logo.
 


## Extension Management (Page 2500)

 Lists the available extensions, and provides features for managing them.
 


## Extension Settings (Page 2511)

 Displays settings for the selected extension, and allows users to edit them.
 


## Extn Deployment Status Detail (Page 2509)

 Displays details about the deployment status of the selected extension.
 


## Marketplace Extn Deployment (Page 2510)

 Provides an interface for installing extensions from AppSource.
 


## Upload And Deploy Extension (Page 2507)

 Allows users to upload an extension and schedule its deployment.
 

