#pragma warning disable AA0247
codeunit 31464 "Comp. Contoso Module CZC" implements "Contoso Demo Data Module"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure RunConfigurationPage()
    begin
    end;

    procedure GetDependencies() Dependencies: List of [enum "Contoso Demo Data Module"]
    begin
        Dependencies.Add(Enum::"Contoso Demo Data Module"::Foundation);
        Dependencies.Add(Enum::"Contoso Demo Data Module"::Finance);
        Dependencies.Add(Enum::"Contoso Demo Data Module"::Purchase);
        Dependencies.Add(Enum::"Contoso Demo Data Module"::Sales);
    end;

    procedure CreateSetupData()
    begin
        Codeunit.Run(Codeunit::"Create Compensations Setup CZC");
    end;

    procedure CreateMasterData()
    begin
    end;

    procedure CreateTransactionalData()
    begin
        Codeunit.Run(Codeunit::"Create Compensation Doc. CZC");
    end;

    procedure CreateHistoricalData()
    var
        CreateCompensationDocCZC: Codeunit "Create Compensation Doc. CZC";
    begin
        CreateCompensationDocCZC.UpdateCompensationLines();
        CreateCompensationDocCZC.ApplyBalanceCompensations();
        CreateCompensationDocCZC.ReleaseCompensations();
        CreateCompensationDocCZC.PostCompensations();
    end;
}
