namespace System.Automation;

using System;
using System.Azure.Identity;
using System.Environment;
using System.Integration;

codeunit 6400 "Flow Service Management"
{
    // // Manages access to Microsoft Power Automate (previously called Microsoft Flow) service API
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = TableData "Flow Service Configuration" = r;

    trigger OnRun()
    begin
    end;

    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        DotNetString: DotNet String;
        JObject: DotNet JObject;

        FlowUrlProdTxt: Label 'https://make.powerautomate.com/', Locked = true;
        FlowUrlTip1Txt: Label 'https://make.test.powerautomate.com/', Locked = true;
        FlowSearchTemplatesUrlTxt: Label 'https://make.powerautomate.com/templates/?q=%1', Locked = true, Comment = '%1: a query string to use for template search';
        FlowARMResourceUrlTxt: Label 'https://management.core.windows.net/', Locked = true;
        FlowServiceResourceUrlTxt: Label 'https://service.flow.microsoft.com/', Locked = true, Comment = 'Note: while the url of Power Automate changed, the AAD resource still contains the old product name"Flow".';
        FlowEnvironmentsProdApiTxt: Label 'https://api.flow.microsoft.com/providers/Microsoft.ProcessSimple/environments?api-version=2016-11-01', Locked = true;
        FlowEnvironmentsTip1ApiTxt: Label 'https://tip1.api.powerapps.com/providers/Microsoft.PowerApps/environments?api-version=2016-11-01', Locked = true;
        GenericErr: Label 'An error occurred while trying to access the Power Automate service. Please try again or contact your system administrator if the error persists.';
        FlowResourceNameTxt: Label 'Flow Services';
        FlowTemplatePageSizeTxt: Label '20', Locked = true;
        FlowTemplateDestinationNewTxt: Label 'new', Locked = true;
        FlowTemplateDestinationDetailsTxt: Label 'details', Locked = true;
        FlowPPEErr: Label 'Power Automate integration is only supported on a production environment.';
        FlowAccessDeniedErr: Label 'Windows Azure Service Management API permissions need to be enabled for Power Automate in the Azure portal. Contact your system administrator.';
        FlowLinkUrlFormatTxt: Label '%1environments/%2/flows/%3/details', Locked = true;
        FlowManageLinkUrlFormatTxt: Label '%1environments/%2/flows/', Locked = true;
        FlowLinkInvalidFlowIdErr: Label 'An invalid flow ID was provided.';
        TemplateFilterTxt: Label 'Microsoft Dynamics 365 Business Central', Locked = true;
        SalesFilterTxt: Label 'Sales', Locked = true;
        PurchasingFilterTxt: Label 'Purchase', Locked = true;
        JournalFilterTxt: Label 'General Journal', Locked = true;
        CustomerFilterTxt: Label 'Customer', Locked = true;
        ItemFilterTxt: Label 'Item', Locked = true;
        VendorFilterTxt: Label 'Vendor', Locked = true;
        EmptyAccessTokenTelemetryMsg: Label 'Encountered an empty access token for Power Automate services.', Locked = true;
        PowerAutomatePickerTelemetryCategoryLbl: Label 'AL Power Automate Environment Picker', Locked = true;

    procedure GetFlowUrl(): Text
    var
        FlowServiceConfiguration: Record "Flow Service Configuration";
        FlowUrl: Text;
    begin
        FlowUrl := FlowUrlProdTxt;
        if FlowServiceConfiguration.FindFirst() then
            case FlowServiceConfiguration."Flow Service" of
                FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 1)":
                    FlowUrl := FlowUrlTip1Txt;
            end;

        exit(FlowUrl);
    end;

    procedure GetFlowEnvironmentsApi(): Text
    var
        FlowEnvironmentsApi: Text;
    begin
        if TryGetFlowEnvironmentsApi(FlowEnvironmentsApi) then
            exit(FlowEnvironmentsApi);

        exit(FlowEnvironmentsProdApiTxt);
    end;

    procedure GetLocale(): Text
    var
        CultureInfo: DotNet CultureInfo;
        TextInfo: DotNet TextInfo;
    begin
        CultureInfo := CultureInfo.CultureInfo(GlobalLanguage);
        TextInfo := CultureInfo.TextInfo;
        exit(LowerCase(TextInfo.CultureName));
    end;

    procedure GetFlowDetailsUrl(FlowId: Guid) FlowDetailsUrl: Text
    begin
        if IsNullGuid(FlowId) then
            Error(FlowLinkInvalidFlowIdErr);

        FlowDetailsUrl := StrSubstNo(FlowLinkUrlFormatTxt, GetFlowUrl(), GetFlowEnvironmentID(), LowerCase(Format(FlowId, 0, 4)));
    end;

    procedure GetFlowManageUrl() Url: Text
    begin
        Url := StrSubstNo(FlowManageLinkUrlFormatTxt, GetFlowUrl(), GetFlowEnvironmentID());
    end;

    procedure GetFlowARMResourceUrl(): Text
    begin
        exit(FlowARMResourceUrlTxt);
    end;

    procedure GetFlowServiceResourceUrl(): Text
    begin
        exit(FlowServiceResourceUrlTxt);
    end;

    procedure GetFlowResourceName(): Text
    begin
        exit(FlowResourceNameTxt);
    end;

    procedure GetGenericError(): Text
    begin
        exit(GenericErr);
    end;

    procedure CanApproveForAll(): Boolean
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
    begin
        exit(FlowUserEnvironmentConfig.WritePermission());
    end;

    procedure GetFlowEnvironmentID() FlowEnvironmentId: Text
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
        EmptyGuid: Guid;
    begin
        // Check if a user has a specific environment configured
        if FlowUserEnvironmentConfig.Get(UserSecurityId()) then
            FlowEnvironmentId := FlowUserEnvironmentConfig."Environment ID"
        else
            // If not, check if the default environment is configured
            if FlowUserEnvironmentConfig.Get(EmptyGuid) then
                FlowEnvironmentId := FlowUserEnvironmentConfig."Environment ID"
            else begin
                // If still not, set the user environment to the first environment in the list
                SetSelectedFlowEnvironmentIDToDefault();
                if FlowUserEnvironmentConfig.Get(UserSecurityId()) then
                    FlowEnvironmentId := FlowUserEnvironmentConfig."Environment ID"
            end;
    end;

    procedure GetFlowTemplatePageSize(): Text
    begin
        // Notice: the behaviour of the pagesize parameter for templates depends on the destination parameter:
        //  - If destination=new and pagesize=x, then the list loads x templates in the initial view, but a button is present to "load more templates"
        //  - If destination=details and pagesize=x, then the list loads x templates in the view, but since no button is present to "load more templates",
        //    the user is stuck in a view with only x templates

        exit(FlowTemplatePageSizeTxt);
    end;

    procedure GetFlowTemplateDestinationNew(): Text
    begin
        // This value asks flow to embed the full flow creation experience from template into the iframe, see:
        //   https://go.microsoft.com/fwlink/?linkid=2206517
        // Currently, this is broken from Flow (see BUG 34364), so we load the Details experience instead

        exit(FlowTemplateDestinationNewTxt);
    end;

    procedure GetFlowTemplateDestinationDetails(): Text
    begin
        // This value asks flow to embed only the template list in the iframe, and on template click open the experience in a new tab, see:
        //   https://go.microsoft.com/fwlink/?linkid=2206173

        exit(FlowTemplateDestinationDetailsTxt);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure IsUserReadyForFlow(): Boolean
    begin
        if not AzureAdMgt.IsAzureADAppSetupDone() then
            exit(false);

        exit(not DotNetString.IsNullOrWhiteSpace(AzureAdMgt.GetAccessToken(GetFlowARMResourceUrl(), GetFlowResourceName(), false)));
    end;

    procedure GetFlowPPEError(): Text
    begin
        exit(FlowPPEErr);
    end;

    procedure GetTemplateFilter(): Text
    begin
        // Gets the default text value that filters Flow templates when opening page 6400.
        exit(TemplateFilterTxt);
    end;

    procedure GetSalesTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for Sales pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + SalesFilterTxt);
    end;

    procedure GetPurchasingTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for Purchasing pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + PurchasingFilterTxt);
    end;

    procedure GetJournalTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for General Journal pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + JournalFilterTxt);
    end;

    procedure GetCustomerTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for Customer pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + CustomerFilterTxt);
    end;

    procedure GetItemTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for Item pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + ItemFilterTxt);
    end;

    procedure GetVendorTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for Vendor pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + VendorFilterTxt);
    end;

    procedure GetSelectedFlowEnvironmentName() FlowEnvironmentName: Text
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
        EmptyGuid: Guid;
    begin
        FlowEnvironmentName := '';
        if not HasUserSelectedFlowEnvironment() then
            exit;
        // Check if a user has a specific environment configured
        if FlowUserEnvironmentConfig.Get(UserSecurityId()) then
            FlowEnvironmentName := FlowUserEnvironmentConfig."Environment Display Name"
        else
            // If not, check if the default environment is configured
            if FlowUserEnvironmentConfig.Get(EmptyGuid) then
                FlowEnvironmentName := FlowUserEnvironmentConfig."Environment Display Name"
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure GetEnvironments(var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        ResponseText: Text;
        Handled: Boolean;
        AccessToken: Text;
    begin
        Handled := false;
        OnBeforeSendGetEnvironmentRequest(ResponseText, Handled);
        if not Handled then begin
            AccessToken := AzureAdMgt.GetAccessToken(FlowARMResourceUrlTxt, FlowResourceNameTxt, false);

            if AccessToken = '' then
                Session.LogMessage('0000MJX', EmptyAccessTokenTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerAutomatePickerTelemetryCategoryLbl);

            // Gets a list of Flow user environments from the Flow API.
            if not WebRequestHelper.GetResponseTextUsingCharset('GET', GetFlowEnvironmentsApi(), AccessToken, ResponseText)
            then
                Error(GenericErr);
        end;

        ParseResponseTextForEnvironments(ResponseText, TempFlowUserEnvironmentBuffer);
    end;

    procedure ParseResponseTextForEnvironments(ResponseText: Text; var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
        Current: DotNet GenericKeyValuePair2;
        JObj: DotNet JObject;
        JObjProp: DotNet JObject;
        ObjectEnumerator: DotNet IEnumerator;
        JArray: DotNet JArray;
        ArrayEnumerator: DotNet IEnumerator;
        JToken: DotNet JToken;
        JProperty: DotNet JProperty;
    begin
        // Parse the ResponseText from Flow environments api for a list of environments
        ObjectEnumerator := JObject.Parse(ResponseText).GetEnumerator();

        while ObjectEnumerator.MoveNext() do begin
            Current := ObjectEnumerator.Current;

            if Format(Current.Key) = 'value' then begin
                JArray := Current.Value();
                ArrayEnumerator := JArray.GetEnumerator();

                while ArrayEnumerator.MoveNext() do begin
                    JObj := ArrayEnumerator.Current;
                    JObjProp := JObj.SelectToken('properties');

                    if not IsNull(JObjProp) then begin
                        JProperty := JObjProp.Property('provisioningState');

                        // only interested in those that succeeded
                        if LowerCase(Format(JProperty.Value)) = 'succeeded' then begin
                            JToken := JObj.SelectToken('name');
                            JProperty := JObjProp.Property('displayName');

                            TempFlowUserEnvironmentBuffer.Init();
                            TempFlowUserEnvironmentBuffer."Environment ID" := JToken.ToString();
                            TempFlowUserEnvironmentBuffer."Environment Display Name" := Format(JProperty.Value);

                            // mark current environment as enabled/selected if it is currently the user selected environment
                            FlowUserEnvironmentConfig.Reset();
                            FlowUserEnvironmentConfig.SetRange("Environment ID", JToken.ToString());
                            FlowUserEnvironmentConfig.SetRange("User Security ID", UserSecurityId());
                            TempFlowUserEnvironmentBuffer.Enabled := FlowUserEnvironmentConfig.FindFirst();

                            // check if environment is the default
                            JProperty := JObjProp.Property('isDefault');
                            if LowerCase(Format(JProperty.Value)) = 'true' then
                                TempFlowUserEnvironmentBuffer.Default := true;

                            TempFlowUserEnvironmentBuffer.Insert();
                        end;
                    end;
                end;
            end;
        end;
    end;

    procedure SaveFlowUserEnvironmentSelection(var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
    begin
        // User previously selected environment so update
        if FlowUserEnvironmentConfig.Get(UserSecurityId()) then begin
            FlowUserEnvironmentConfig."Environment ID" := TempFlowUserEnvironmentBuffer."Environment ID";
            FlowUserEnvironmentConfig."Environment Display Name" := TempFlowUserEnvironmentBuffer."Environment Display Name";
            FlowUserEnvironmentConfig.Modify();

            exit;
        end;

        // User has no previous selection so add new one
        FlowUserEnvironmentConfig.Init();
        FlowUserEnvironmentConfig."User Security ID" := UserSecurityId();
        FlowUserEnvironmentConfig."Environment ID" := TempFlowUserEnvironmentBuffer."Environment ID";
        FlowUserEnvironmentConfig."Environment Display Name" := TempFlowUserEnvironmentBuffer."Environment Display Name";
        FlowUserEnvironmentConfig.Insert();
    end;

    procedure SaveFlowEnvironmentSelectionForAll(var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
        EmptyGuid: Guid;
    begin
        // Remove all previous selections
        FlowUserEnvironmentConfig.Reset();
        FlowUserEnvironmentConfig.DeleteAll();

        // Add new selection for all users
        FlowUserEnvironmentConfig.Init();
        FlowUserEnvironmentConfig."User Security ID" := EmptyGuid;
        FlowUserEnvironmentConfig."Environment ID" := TempFlowUserEnvironmentBuffer."Environment ID";
        FlowUserEnvironmentConfig."Environment Display Name" := TempFlowUserEnvironmentBuffer."Environment Display Name";
        FlowUserEnvironmentConfig.Insert();
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure SetSelectedFlowEnvironmentIDToDefault()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        WebRequestHelper: Codeunit "Web Request Helper";
        ResponseText: Text;
        PostResult: Boolean;
        Handled: Boolean;
        AccessToken: Text;
    begin
        Handled := false;
        OnBeforeSetDefaultEnvironmentRequest(ResponseText, Handled);
        if not Handled then begin
            GetEnvironments(TempFlowUserEnvironmentBuffer);
            TempFlowUserEnvironmentBuffer.SetRange(Default, true);
            if TempFlowUserEnvironmentBuffer.FindFirst() then
                SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer)
            else begin
                AccessToken := AzureAdMgt.GetAccessToken(FlowARMResourceUrlTxt, FlowResourceNameTxt, false);

                if AccessToken = '' then
                    Session.LogMessage('0000MJY', EmptyAccessTokenTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerAutomatePickerTelemetryCategoryLbl);

                // No environment found so make a post call to create default environment. Post call returns error but actually creates environment
                PostResult := WebRequestHelper.GetResponseTextUsingCharset('POST', GetFlowEnvironmentsApi(), AccessToken, ResponseText);

                if not PostResult then
                    ; // Do nothing. Need to store the result of the POST call so that error from POST call doesn't bubble up. May need to look at this later.

                // we should have environments now so go ahead and set selected environment
                GetEnvironments(TempFlowUserEnvironmentBuffer);
                TempFlowUserEnvironmentBuffer.SetRange(Default, true);
                if TempFlowUserEnvironmentBuffer.FindFirst() then
                    SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer)
            end;
        end;
    end;

    procedure HasUserSelectedFlowEnvironment(): Boolean
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
        EmptyGuid: Guid;
    begin
        exit(FlowUserEnvironmentConfig.Get(UserSecurityId()) or FlowUserEnvironmentConfig.Get(EmptyGuid));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetPowerPlatformEnvironmentId', '', true, true)]
    local procedure GetEnvironmentId(Scenario: Text; var EnvironmentId: Text)
    begin
        EnvironmentId := '';
        if not HasUserSelectedFlowEnvironment() then
            exit;
        EnvironmentId := GetFlowEnvironmentID();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Azure AD Access Dialog", 'OnOAuthAccessDenied', '', false, false)]
    local procedure CheckOAuthAccessDenied(description: Text; resourceFriendlyName: Text)
    begin
        if StrPos(resourceFriendlyName, FlowResourceNameTxt) > 0 then
            if StrPos(description, 'AADSTS65005') > 0 then
                Error(FlowAccessDeniedErr);
    end;

    procedure GetFlowTemplateSearchUrl(): Text
    begin
        exit(FlowSearchTemplatesUrlTxt);
    end;

    [TryFunction]
    local procedure TryGetFlowEnvironmentsApi(var FlowEnvironmentsApi: Text)
    var
        FlowServiceConfiguration: Record "Flow Service Configuration";
    begin
        FlowEnvironmentsApi := FlowEnvironmentsProdApiTxt;
        if FlowServiceConfiguration.FindFirst() then
            case FlowServiceConfiguration."Flow Service" of
                FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 1)":
                    FlowEnvironmentsApi := FlowEnvironmentsTip1ApiTxt;
            end;
    end;

    [InternalEvent(false)]
    internal procedure OnBeforeSendGetEnvironmentRequest(var ResponseText: Text; var Handled: Boolean)
    begin
    end;

    [InternalEvent(false)]
    internal procedure OnBeforeSetDefaultEnvironmentRequest(var ResponseText: Text; var Handled: Boolean)
    begin
    end;
}
