page 888 "SmartList Designer"
{
    Caption = 'SmartList Designer';
    Editable = false;
    PageType = Worksheet;
    ShowFilter = false;
    Extensible = false;
    SourceTable = "SmartList Designer Setup";

    layout
    {
        area(Content)
        {
            group(Unsupported)
            {
                Caption = 'Unsupported';
                Visible = not ShowSmartListDesigner;
                InstructionalText = 'The SmartList Designer has been disabled.';
            }

            usercontrol(SmartListDesigner; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
            {
                ApplicationArea = All;
                Visible = ShowSmartListDesigner;

                trigger ControlAddInReady(callbackUrl: Text)
                begin
                    AddInReady := true;
                    NavigateToUrl();
                end;

                trigger Refresh(callbackUrl: Text)
                begin
                    NavigateToUrl();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        SmartListDesignerSetupPage: Page "SmartList Designer Setup";
    begin
        ShowSmartListDesigner := SmartListDesigner.IsEnabled();

        if not ShowSmartListDesigner then
            exit;

        if not SmartListDesigner.DoesUserHaveAPIAccess(UserSecurityId()) then
            Error(UserDoesNotHaveAccessErr);

        if not FindFirst() or IsNullGuid(PowerAppId) then begin
            SmartListDesignerSetupPage.RunModal();

            if SmartListDesignerSetupPage.WasCancelled() then
                Error(''); // Want to close the page within OnOpenPage. The only option is to throw an 'empty' error

            Get();
        end;

        UpdateDesignerUrl(Rec);
    end;

    local procedure UpdateDesignerUrl(SmartListDesignerSetupRec: Record "SmartList Designer Setup")
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        UrlHelper: Codeunit "Url Helper";
    begin
        ResolvedAppUrl := StrSubstNo(
            SmartListDesignerAppUrlTemplateLbl,
            UrlHelper.GetPowerAppsUrl(), // PowerApps host url
            Format(SmartListDesignerSetupRec.PowerAppId, 36, 4).Trim(), // Id of the PowerApp to run
            Format(SmartListDesignerSetupRec.PowerAppTenantId, 36, 4).Trim(), // AAD Id of the tenant we want to open the PowerApp from
            AzureADTenant.GetAadTenantId(), // AAD Id of the running tenant
            EnvironmentInfo.GetEnvironmentName(), // The name of our environment
            EnvironmentInfo.GetApplicationFamily(), // The application family of our environment
            ResolvedSourceTableParameterTxt, // An optional param to specify the source table to start on
            ResolvedQueryParameterTxt,  // An optional param to specify an existing query to start editing
            ResolveViewIdParameterTxt // An optional param to specify the view of the table to start with when creating from a source table
            );
    end;

    local procedure NavigateToUrl()
    begin
        if AddInReady and ShowSmartListDesigner then
            CurrPage.SmartListDesigner.Navigate(ResolvedAppUrl);
    end;

    internal procedure RunForNewQueryOverTableAndView(TableNo: Integer; ViewId: Text)
    begin
        SetForTableAndView(TableNo, ViewId);
        CurrPage.Run();
    end;

    local procedure SetForTableAndView(TableNo: Integer; ViewId: Text)
    begin
        ResolvedSourceTableParameterTxt := StrSubstNo(SmartListSourceTableParameterLbl, TableNo);
        ResolveViewIdParameterTxt := StrSubstNo(SmartListViewIdParameterLbl, ViewId);
        ResolvedQueryParameterTxt := ''; // QueryId and SourceId parameters should be mutually exclusive
    end;

    internal procedure RunForEditExistingQuery(QueryId: Text)
    begin
        SetForQueryId(QueryId);
        CurrPage.Run();
    end;

    local procedure SetForQueryId(QueryId: Text)
    begin
        ResolvedQueryParameterTxt := StrSubstNo(SmartListQueryIdParameterLbl, QueryId);
        ResolvedSourceTableParameterTxt := ''; // QueryId and SourceId parameters should be mutually exclusive
    end;

    [Obsolete('Use RunForTable on CU 888 (SmartList Designer) instead', '17.0')]
    procedure SetTableNo(TableNo: Integer)
    begin
        SetForTableAndView(TableNo, '');
    end;

    [Obsolete('Use RunForQuery on CU 888 (SmartList Designer) instead', '17.0')]
    procedure SetQueryId(QueryId: Text)
    begin
        SetForQueryId(QueryId);
    end;

    var
        SmartListDesigner: Codeunit "SmartList Designer";
        EnvironmentInfo: Codeunit "Environment Information";
        ShowSmartListDesigner: boolean;
        AddInReady: boolean;
        ResolvedAppUrl: Text;
        ResolvedSourceTableParameterTxt: Text;
        ResolvedQueryParameterTxt: Text;
        ResolveViewIdParameterTxt: Text;
        UserDoesNotHaveAccessErr: Label 'You do not have permission to access the SmartList Designer. Contact your system administrator.';
        SmartListDesignerAppUrlTemplateLbl: Label '%1/play/%2?tenantId=%3&source=bc-embed&tenant=%4&environment=%5&applicationFamily=%6&product=BusinessCentral&screenColor=rgba(255,255,255,1)&isEmbed=1%7%8%9', Locked = true;
        SmartListSourceTableParameterLbl: Label '&sourceId=%1', Locked = true;
        SmartListQueryIdParameterLbl: Label '&queryId=%1', Locked = true;
        SmartListViewIdParameterLbl: Label '&viewId=%1', Locked = true;
}