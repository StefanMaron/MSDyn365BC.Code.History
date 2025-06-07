#pragma warning disable AA0247
codeunit 31428 "Bank. Doc. Contoso Module CZB" implements "Contoso Demo Data Module"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure RunConfigurationPage()
    begin
    end;

    procedure GetDependencies() Dependencies: List of [enum "Contoso Demo Data Module"]
    begin
        Dependencies.Add(Enum::"Contoso Demo Data Module"::Foundation);
        Dependencies.Add(Enum::"Contoso Demo Data Module"::Bank);
        Dependencies.Add(Enum::"Contoso Demo Data Module"::Purchase);
    end;

    procedure CreateSetupData()
    begin
        Codeunit.Run(Codeunit::"Create Search Rule CZB");
    end;

    procedure CreateMasterData()
    begin
        Codeunit.Run(Codeunit::"Create Bank Account CZB");
    end;

    procedure CreateTransactionalData()
    begin
        Codeunit.Run(Codeunit::"Create Bank Statement CZB");
        Codeunit.Run(Codeunit::"Create Payment Order CZB");
    end;

    procedure CreateHistoricalData()
    var
        CreateBankStatementCZB: Codeunit "Create Bank Statement CZB";
        CreatePaymentOrderCZB: Codeunit "Create Payment Order CZB";
    begin
        CreateBankStatementCZB.IssueBankStatements();
        CreatePaymentOrderCZB.IssueBankStatements();
    end;
}
