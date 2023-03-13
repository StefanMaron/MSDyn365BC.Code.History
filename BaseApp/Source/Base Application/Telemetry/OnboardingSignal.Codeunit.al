// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 7580 "Onboarding Signal"
{
    Access = Public;
    Permissions = tabledata "Onboarding Signal" = rimd;

    /// <summary> Register a new Onboarding Signal to keep track of. </summary>
    /// <param name="CompanyName"> The name of the company you want to register the onboarding signal for. </param>
    /// <param name="OnboardingSignalType"> A new Onboarding Signal. </param>
    procedure RegisterNewOnboardingSignal(CompanyName: Text[30]; OnboardingSignalType: Enum "Onboarding Signal Type")
    var
        OnboardingSignal: Record "Onboarding Signal";
    begin
        OnboardingSignal.SetRange("Company Name", CompanyName);
        OnboardingSignal.SetRange("Onboarding Signal Type", OnboardingSignalType);

        if not OnboardingSignal.FindFirst() then begin
            OnboardingSignal.Init();
            OnboardingSignal."Company Name" := CompanyName;
            OnboardingSignal."Onboarding Signal Type" := OnboardingSignalType;
            OnboardingSignal."Onboarding Completed" := false;
            OnboardingSignal.Insert();
        end;
    end;

    /// <summary>
    /// Check the status on all registered onboarding signals, and emit corresponding Telemetry when the criteria is met. This is run automatically once a day when login.
    /// </summary>
    procedure CheckAndEmitOnboardingSignals()
    var
        Company: Record Company;
        OnboardingSignal: Record "Onboarding Signal";
        EnvironmentInfo: Codeunit "Environment Information";
        Telemetry: Codeunit Telemetry;
        OnboardingSignalProvider: Interface "Onboarding Signal";
        TelemetryScope: TelemetryScope;
    begin
        if not Company.Get(CompanyName()) then
            exit;

        if Company."Evaluation Company" then
            exit;

        if EnvironmentInfo.IsSandbox() then
            exit;

        OnboardingSignal.SetRange("Company Name", CompanyName);
        OnboardingSignal.SetRange("Onboarding Completed", false);

        if OnboardingSignal.FindSet() then
            repeat
                OnboardingSignalProvider := OnboardingSignal."Onboarding Signal Type";

                if OnboardingSignalProvider.IsOnboarded() then begin
                    OnboardingSignal."Onboarding Completed" := true;
                    OnboardingSignal.Modify();

                    Telemetry.LogMessage('0000EIV', 'Onboarding Completed for criteria: ' + Format(OnboardingSignal."Onboarding Signal Type"), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All);
                end;
            until OnboardingSignal.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteCompany(Rec: Record Company)
    var
        OnboardingSignal: Record "Onboarding Signal";
    begin
        OnboardingSignal.SetRange("Company Name", Rec.Name);

        if OnboardingSignal.FindFirst() then
            OnboardingSignal.DeleteAll();
    end;
}
