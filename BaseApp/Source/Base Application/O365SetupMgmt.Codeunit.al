#if not CLEAN21
codeunit 2315 "O365 Setup Mgmt"
{
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    trigger OnRun()
    begin
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        O365GettingStartedMgt: Codeunit "O365 Getting Started Mgt.";
        EvaluationCompanyDoesNotExistsMsg: Label 'Sorry, but the evaluation company isn''t available right now so we can''t start Dynamics 365 Business Central. Please try again later.';
        InvToBusinessCentralCategoryLbl: Label 'AL Invoicing To Business Central', Locked = true;
        UserPersonalizationUpdatedTelemetryTxt: Label 'User Personalization company has been updated to evaluation company.', Locked = true;
        SessionSettingUpdatedTelemetryTxt: Label 'Session settings has been updated to evaluation company.', Locked = true;
        EvaluationCompanyNotSetTelemetryTxt: Label 'Evaluation company is not set up.', Locked = true;
        InvToBusinessCentralTrialTelemetryTxt: Label 'User clicked the Try Business Central button from Invoicing.', Locked = true;
        TypeHelper: Codeunit "Type Helper";
        SupportContactEmailTxt: Label 'support@Office365.com', Locked = true;

    procedure InvoicesExist(): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if SalesInvoiceHeader.FindFirst() then
            exit(true);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        if SalesHeader.FindFirst() then
            exit(true);
    end;

    procedure EstimatesExist(): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        if SalesHeader.FindFirst() then
            exit(true);
    end;

    procedure DocumentsExist(): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if SalesInvoiceHeader.FindFirst() then
            exit(true);

        SalesHeader.SetFilter("Document Type", '%1|%2', SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::Quote);
        if SalesHeader.FindFirst() then
            exit(true);
    end;

    procedure ShowCreateTestInvoice(): Boolean
    begin
        exit(not DocumentsExist());
    end;

    procedure WizardShouldBeOpenedForInvoicing(): Boolean
    var
        O365GettingStarted: Record "O365 Getting Started";
    begin
        if not GettingStartedSupportedForInvoicing() then
            exit(false);

        if O365GettingStarted.Get(UserId, ClientTypeManagement.GetCurrentClientType()) then
            exit(false);

        exit(true);
    end;

    procedure GettingStartedSupportedForInvoicing(): Boolean
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        if not EnvInfoProxy.IsInvoicing() then
            exit(false);

        if not (ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Web) then
            exit(false);

        exit(O365GettingStartedMgt.UserHasPermissionsToRunGettingStarted());
    end;

    [Scope('OnPrem')]
    procedure ChangeToEvaluationCompany()
    var
        UserPersonalization: Record "User Personalization";
        Company: Record Company;
        SessionSetting: SessionSettings;
    begin
        Company.SetRange("Evaluation Company", true);
        if Company.FindFirst() then begin
            UserPersonalization.Get(UserSecurityId());
            UserPersonalization.Validate(Company, Company.Name);
            UserPersonalization.Modify(true);
            Session.LogMessage('00007L4', UserPersonalizationUpdatedTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InvToBusinessCentralCategoryLbl);
            // Update session settings
            SessionSetting.Init();
            SessionSetting.Company := Company.Name;
            SessionSetting.RequestSessionUpdate(true);
            Session.LogMessage('00007L5', SessionSettingUpdatedTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InvToBusinessCentralCategoryLbl);
        end else begin
            Message(EvaluationCompanyDoesNotExistsMsg);
            Session.LogMessage('00007L6', EvaluationCompanyNotSetTelemetryTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InvToBusinessCentralCategoryLbl);
        end;
    end;

    [Scope('OnPrem')]
    procedure GotoBusinessCentralWithEvaluationCompany()
    var
        Company: Record Company;
        UrlHelper: Codeunit "Url Helper";
        ClientUrl: Text;
        CompanyPart: Text;
    begin
        ClientUrl := UrlHelper.GetFixedClientEndpointBaseUrl();

        Company.SetRange("Evaluation Company", true);
        if Company.FindFirst() then begin
            Session.LogMessage('00007L3', InvToBusinessCentralTrialTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InvToBusinessCentralCategoryLbl);
            CompanyPart := StrSubstNo('?company=%1', TypeHelper.UriEscapeDataString(Company.Name));
            HyperLink(ClientUrl + CompanyPart);
        end else begin
            Session.LogMessage('00007NJ', EvaluationCompanyNotSetTelemetryTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', InvToBusinessCentralCategoryLbl);
            HyperLink(ClientUrl);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetBusinessCentralTrialVisibility(): Boolean
    begin
        exit(UserHasPermissionsForEvaluationCompany());
    end;

    [Scope('OnPrem')]
    procedure UserHasPermissionsForEvaluationCompany(): Boolean
    var
        DummySalesHeader: Record "Sales Header";
        Company: Record Company;
    begin
        Company.SetRange("Evaluation Company", true);
        if Company.FindFirst() then
            if DummySalesHeader.ChangeCompany(Company.Name) then
                exit(DummySalesHeader.WritePermission);

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Help & Support Management", 'OnBeforeGetSupportInformation', '', false, false)]
    local procedure PopulateSupportInformation(var SupportName: Text; var SupportEmail: Text; var SupportUrl: Text)
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        if not EnvInfoProxy.IsInvoicing() then
            exit;

        SupportEmail := SupportContactEmailTxt;
    end;
}
#endif

