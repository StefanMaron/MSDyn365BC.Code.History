codeunit 6400 "Flow Service Management"
{
    // // Manages access to Microsoft Flow service API

    Permissions = TableData "Flow Service Configuration" = r;

    trigger OnRun()
    begin
    end;

    var
        FlowUrlProdTxt: Label 'https://flow.microsoft.com/', Locked = true;
        FlowUrlTip1Txt: Label 'https://tip1.flow.microsoft.com/', Locked = true;
        FlowUrlTip2Txt: Label 'https://tip2.flow.microsoft.com/', Locked = true;
        FlowARMResourceUrlTxt: Label 'https://management.core.windows.net/', Locked = true;
        FlowServiceResourceUrlTxt: Label 'https://service.flow.microsoft.com/', Locked = true;
        FlowEnvironmentsProdApiTxt: Label 'https://management.azure.com/providers/Microsoft.ProcessSimple/environments?api-version=2016-11-01', Locked = true;
        FlowEnvironmentsTip1ApiTxt: Label 'https://tip1.api.powerapps.com/providers/Microsoft.PowerApps/environments?api-version=2016-11-01', Locked = true;
        FlowEnvironmentsTip2ApiTxt: Label 'https://tip2.api.powerapps.com/providers/Microsoft.PowerApps/environments?api-version=2016-11-01', Locked = true;
        GenericErr: Label 'An error occured while trying to access the Flow service. Please try again or contact your system administrator if the error persists.';
        FlowResourceNameTxt: Label 'Flow Services';
        FlowTemplatePageSizeTxt: Label '20', Locked = true;
        FlowTemplateDestinationNewTxt: Label 'new', Locked = true;
        FlowTemplateDestinationDetailsTxt: Label 'details', Locked = true;
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        DotNetString: DotNet String;
        FlowPPEErr: Label 'Microsoft Flow integration is not supported outside of a PROD environment.';
        FlowAccessDeniedErr: Label 'Windows Azure Service Management API permissions need to be enabled for Flow in the Azure Portal. Contact your system administrator.';
        FlowLinkUrlFormatTxt: Label '%1manage/environments/%2/flows/%3/details', Locked = true;
        FlowManageLinkUrlFormatTxt: Label '%1manage/environments/%2/flows/', Locked = true;
        FlowLinkInvalidFlowIdErr: Label 'An invalid Flow ID was provided.';
        TemplateFilterTxt: Label 'Microsoft Dynamics 365 Business Central', Locked = true;
        SalesFilterTxt: Label 'Sales', Locked = true;
        PurchasingFilterTxt: Label 'Purchase', Locked = true;
        JournalFilterTxt: Label 'General Journal', Locked = true;
        CustomerFilterTxt: Label 'Customer', Locked = true;
        ItemFilterTxt: Label 'Item', Locked = true;
        VendorFilterTxt: Label 'Vendor', Locked = true;
        JObject: DotNet JObject;

    procedure GetFlowUrl(): Text
    var
        FlowUrl: Text;
    begin
        if TryGetFlowUrl(FlowUrl) then
            exit(FlowUrl);

        exit(FlowUrlProdTxt);
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
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        if IsNullGuid(FlowId) then
            Error(FlowLinkInvalidFlowIdErr);

        FlowDetailsUrl := StrSubstNo(FlowLinkUrlFormatTxt, GetFlowUrl, GetFlowEnvironmentID, TypeHelper.GetGuidAsString(FlowId));
    end;

    procedure GetFlowManageUrl() Url: Text
    begin
        Url := StrSubstNo(FlowManageLinkUrlFormatTxt, GetFlowUrl, GetFlowEnvironmentID);
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

    procedure GetFlowEnvironmentID() FlowEnvironmentId: Text
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
    begin
        if FlowUserEnvironmentConfig.Get(UserSecurityId) then
            FlowEnvironmentId := FlowUserEnvironmentConfig."Environment ID"
        else begin
            SetSelectedFlowEnvironmentIDToDefault;
            if FlowUserEnvironmentConfig.Get(UserSecurityId) then
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
        //   https://docs.microsoft.com/en-us/power-automate/developer/embed-flow-dev
        // Currently, this is broken from Flow (see BUG 34364), so we load the Details experience instead

        exit(FlowTemplateDestinationNewTxt);
    end;

    procedure GetFlowTemplateDestinationDetails(): Text
    begin
        // This value asks flow to embed only the template list in the iframe, and on template click open the experience in a new tab, see:
        //   https://docs.microsoft.com/en-us/power-automate/developer/embed-flow-dev

        exit(FlowTemplateDestinationDetailsTxt);
    end;

    [Scope('OnPrem')]
    procedure IsUserReadyForFlow(): Boolean
    begin
        if not AzureAdMgt.IsAzureADAppSetupDone then
            exit(false);

        exit(not DotNetString.IsNullOrWhiteSpace(AzureAdMgt.GetAccessToken(GetFlowARMResourceUrl, GetFlowResourceName, false)));
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

    [Scope('OnPrem')]
    procedure GetSelectedFlowEnvironmentName() FlowEnvironmentName: Text
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
    begin
        if FlowUserEnvironmentConfig.Get(UserSecurityId) then
            FlowEnvironmentName := FlowUserEnvironmentConfig."Environment Display Name"
        else begin
            SetSelectedFlowEnvironmentIDToDefault;
            if FlowUserEnvironmentConfig.Get(UserSecurityId) then
                FlowEnvironmentName := FlowUserEnvironmentConfig."Environment Display Name"
        end;
    end;

    [Scope('OnPrem')]
    procedure GetEnvironments(var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        ResponseText: Text;
    begin
        // Gets a list of Flow user environments from the Flow API.
        if not WebRequestHelper.GetResponseTextUsingCharset(
             'GET', GetFlowEnvironmentsApi, AzureAdMgt.GetAccessToken(FlowARMResourceUrlTxt, FlowResourceNameTxt, false), ResponseText)
        then
            Error(GenericErr);

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
        ObjectEnumerator := JObject.Parse(ResponseText).GetEnumerator;

        while ObjectEnumerator.MoveNext do begin
            Current := ObjectEnumerator.Current;

            if Format(Current.Key) = 'value' then begin
                JArray := Current.Value;
                ArrayEnumerator := JArray.GetEnumerator;

                while ArrayEnumerator.MoveNext do begin
                    JObj := ArrayEnumerator.Current;
                    JObjProp := JObj.SelectToken('properties');

                    if not IsNull(JObjProp) then begin
                        JProperty := JObjProp.Property('provisioningState');

                        // only interested in those that succeeded
                        if LowerCase(Format(JProperty.Value)) = 'succeeded' then begin
                            JToken := JObj.SelectToken('name');
                            JProperty := JObjProp.Property('displayName');

                            TempFlowUserEnvironmentBuffer.Init();
                            TempFlowUserEnvironmentBuffer."Environment ID" := JToken.ToString;
                            TempFlowUserEnvironmentBuffer."Environment Display Name" := Format(JProperty.Value);

                            // mark current environment as enabled/selected if it is currently the user selected environment
                            FlowUserEnvironmentConfig.Reset();
                            FlowUserEnvironmentConfig.SetRange("Environment ID", JToken.ToString);
                            FlowUserEnvironmentConfig.SetRange("User Security ID", UserSecurityId);
                            TempFlowUserEnvironmentBuffer.Enabled := FlowUserEnvironmentConfig.FindFirst;

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
        if FlowUserEnvironmentConfig.Get(UserSecurityId) then begin
            FlowUserEnvironmentConfig."Environment ID" := TempFlowUserEnvironmentBuffer."Environment ID";
            FlowUserEnvironmentConfig."Environment Display Name" := TempFlowUserEnvironmentBuffer."Environment Display Name";
            FlowUserEnvironmentConfig.Modify();

            exit;
        end;

        // User has no previous selection so add new one
        FlowUserEnvironmentConfig.Init();
        FlowUserEnvironmentConfig."User Security ID" := UserSecurityId;
        FlowUserEnvironmentConfig."Environment ID" := TempFlowUserEnvironmentBuffer."Environment ID";
        FlowUserEnvironmentConfig."Environment Display Name" := TempFlowUserEnvironmentBuffer."Environment Display Name";
        FlowUserEnvironmentConfig.Insert();
    end;

    [Scope('OnPrem')]
    procedure SetSelectedFlowEnvironmentIDToDefault()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        WebRequestHelper: Codeunit "Web Request Helper";
        ResponseText: Text;
        PostResult: Boolean;
    begin
        GetEnvironments(TempFlowUserEnvironmentBuffer);
        TempFlowUserEnvironmentBuffer.SetRange(Default, true);
        if TempFlowUserEnvironmentBuffer.FindFirst then
            SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer)
        else begin
            // No environment found so make a post call to create default environment. Post call returns error but actually creates environment
            PostResult := WebRequestHelper.GetResponseText(
                'POST', GetFlowEnvironmentsApi, AzureAdMgt.GetAccessToken(FlowARMResourceUrlTxt, FlowResourceNameTxt, false), ResponseText);

            if not PostResult then
                ; // Do nothing. Need to store the result of the POST call so that error from POST call doesn't bubble up. May need to look at this later.

            // we should have environments now so go ahead and set selected environment
            GetEnvironments(TempFlowUserEnvironmentBuffer);
            TempFlowUserEnvironmentBuffer.SetRange(Default, true);
            if TempFlowUserEnvironmentBuffer.FindFirst then
                SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer)
        end;
    end;

    procedure HasUserSelectedFlowEnvironment(): Boolean
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
    begin
        exit(FlowUserEnvironmentConfig.Get(UserSecurityId));
    end;

    [EventSubscriber(ObjectType::Page, 6302, 'OnOAuthAccessDenied', '', false, false)]
    local procedure CheckOAuthAccessDenied(description: Text; resourceFriendlyName: Text)
    begin
        if StrPos(resourceFriendlyName, FlowResourceNameTxt) > 0 then begin
            if StrPos(description, 'AADSTS65005') > 0 then
                Error(FlowAccessDeniedErr);
        end;
    end;

    [TryFunction]
    local procedure TryGetFlowUrl(var FlowUrl: Text)
    var
        FlowServiceConfiguration: Record "Flow Service Configuration";
    begin
        FlowUrl := FlowUrlProdTxt;
        if FlowServiceConfiguration.FindFirst then
            case FlowServiceConfiguration."Flow Service" of
                FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 1)":
                    FlowUrl := FlowUrlTip1Txt;
                FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 2)":
                    FlowUrl := FlowUrlTip2Txt;
            end;
    end;

    [TryFunction]
    local procedure TryGetFlowEnvironmentsApi(var FlowEnvironmentsApi: Text)
    var
        FlowServiceConfiguration: Record "Flow Service Configuration";
    begin
        FlowEnvironmentsApi := FlowEnvironmentsProdApiTxt;
        if FlowServiceConfiguration.FindFirst then
            case FlowServiceConfiguration."Flow Service" of
                FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 1)":
                    FlowEnvironmentsApi := FlowEnvironmentsTip1ApiTxt;
                FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 2)":
                    FlowEnvironmentsApi := FlowEnvironmentsTip2ApiTxt;
            end;
    end;
}

