codeunit 9522 "Emit Onboarding Signal"
{
    Access = Internal;
    Permissions = tabledata "Onboarding Signal" = rimd,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Purch. Inv. Header" = r,
                  tabledata "G/L Entry" = r;
    Description = 'Used in OnSendDailyTelemetry for analyzing onboarding.';

    trigger OnRun()
    var
        Company: Record Company;
        EnvironmentInfo: Codeunit "Environment Information";
        Telemetry: Codeunit Telemetry;
    begin
        if not Company.Get(CompanyName()) then
            exit;

        if Company."Evaluation Company" then
            exit;

        if EnvironmentInfo.IsSandbox() then
            exit;

        if IsOnboardingSignalEmitted(Company.Name) then
            exit;

        if CheckCompanyOnboarded() then begin
            Telemetry.LogMessage('0000EIV', 'Onboarding Completed', Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher);

            SetOnboardingCompleted(Company.Name);
        end;
    end;

    local procedure IsOnboardingSignalEmitted(CompanyName: Text[30]): Boolean
    var
        OnboardingSignal: Record "Onboarding Signal";
    begin
        OnboardingSignal.SetRange("Company Name", CompanyName);

        if OnboardingSignal.FindFirst() then
            exit(OnboardingSignal."Onboarding Completed");

        exit(false);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Sales Invoice Header", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Purch. Inv. Header", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Entry", 'r')]
    local procedure CheckCompanyOnboarded(): Boolean
    var
        PosedSalesInvoice: Record "Sales Invoice Header";
        PosedPurchaseInvoice: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        SourceType: Enum "Gen. Journal Source Type";
        SourceTypes: List of [Enum "Gen. Journal Source Type"];
        OnboardCriteriaThreshold: Integer;
    begin
        OnboardCriteriaThreshold := 5;

        if (PosedSalesInvoice.Count() >= OnboardCriteriaThreshold) and (PosedPurchaseInvoice.Count() >= OnboardCriteriaThreshold) then begin
            GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);

            SourceTypes.Add(GLEntry."Source Type"::Customer);
            SourceTypes.Add(GLEntry."Source Type"::Vendor);

            foreach SourceType in SourceTypes do begin
                GLEntry.SetRange("Source Type", SourceType);
                if GLEntry.Count() < OnboardCriteriaThreshold then
                    exit(false);
            end;

            exit(true);
        end;

        exit(false);
    end;

    local procedure SetOnboardingCompleted(CompanyName: Text[30])
    var
        OnboardingSignal: Record "Onboarding Signal";
    begin
        OnboardingSignal.SetRange("Company Name", CompanyName);

        if OnboardingSignal.FindFirst() then begin
            OnboardingSignal."Onboarding Completed" := true;
            OnboardingSignal.Modify();
        end else begin
            OnboardingSignal.Init();
            OnboardingSignal."Company Name" := CompanyName;
            OnboardingSignal."Onboarding Completed" := true;
            OnboardingSignal.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteCompany(Rec: Record Company)
    var
        OnboardingSignal: Record "Onboarding Signal";
    begin
        OnboardingSignal.SetRange("Company Name", Rec.Name);

        if OnboardingSignal.FindFirst() then
            OnboardingSignal.Delete();
    end;
}
