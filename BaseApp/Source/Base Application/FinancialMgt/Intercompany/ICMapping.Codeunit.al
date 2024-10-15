codeunit 428 "IC Mapping"
{
    trigger OnRun()
    begin
    end;

    procedure GetFeatureTelemetryName(): Text
    begin
        exit('Intercompany');
    end;

    procedure MapAccounts(ICAccount: Record "IC G/L Account")
    var
        ICMappingAccounts: Codeunit "IC Mapping Accounts";
    begin
        ICMappingAccounts.MapAccounts(ICAccount);
    end;

    procedure MapIncomingICDimensions(ICDimension: Record "IC Dimension")
    var
        ICMappingDimensions: Codeunit "IC Mapping Dimensions";
    begin
        ICMappingDimensions.MapIncomingICDimensions(ICDimension);
    end;

    procedure MapOutgoingICDimensions(Dimension: Record Dimension)
    var
        ICMappingDimensions: Codeunit "IC Mapping Dimensions";
    begin
        ICMappingDimensions.MapOutgoingICDimensions(Dimension);
    end;

    internal procedure CopyBankAccountsFromPartner(PartnerCode: Code[20])
    var
        PartnersBankAccounts: Record "Bank Account";
        ICBankAccounts: Record "IC Bank Account";
        ICPartner: Record "IC Partner";
    begin
        if not ICPartner.Get(PartnerCode) then
            Error(FailedToFindPartnerErr, PartnerCode);

        if ICPartner."Inbox Type" <> ICPartner."Inbox Type"::Database then
            Error(InboxTypeNotDatabaseErr, PartnerCode, ICPartner."Inbox Type");

        // Delete existing IC Bank Accounts if the syncronization points to a company with no IC Bank Accounts.
        if not PartnersBankAccounts.ChangeCompany(ICPartner."Inbox Details") then
            Error(FailedToChangeCompanyErr, PartnersBankAccounts.TableCaption, ICPartner.Code);
        if not PartnersBankAccounts.ReadPermission() then
            Error(MissingPermissionToReadTableErr, ICPartner.Code);
        PartnersBankAccounts.SetRange(IntercompanyEnable, true);
        if PartnersBankAccounts.IsEmpty() then begin
            Message(NoBankAccountsWithICEnableMsg, ICPartner.Code);
            ICBankAccounts.SetRange("IC Partner Code", PartnerCode);
            if not ICBankAccounts.IsEmpty() then
                ICBankAccounts.DeleteAll();
            exit;
        end;

        ICBankAccounts.Reset();
        PartnersBankAccounts.FindSet();
        repeat
            ICBankAccounts."No." := PartnersBankAccounts."No.";
            ICBankAccounts."IC Partner Code" := PartnerCode;
            ICBankAccounts.Name := PartnersBankAccounts.Name;
            ICBankAccounts."Bank Account No." := PartnersBankAccounts."Bank Account No.";
            ICBankAccounts.Blocked := PartnersBankAccounts.Blocked;
            ICBankAccounts."Currency Code" := PartnersBankAccounts."Currency Code";
            ICBankAccounts.IBAN := PartnersBankAccounts.IBAN;
            ICBankAccounts.Insert();
        until PartnersBankAccounts.Next() = 0;
    end;

    var
        FailedToFindPartnerErr: Label 'There is no partner with code %1 in the list of your intercompany partners.', Comment = '%1 = Partner code';
        InboxTypeNotDatabaseErr: Label 'Copy is only available for partners using database as their intercompany inbox type. Partner %1 inbox type is %2', Comment = '%1 = Partner code, %2 = Partner inbox type';
        FailedToChangeCompanyErr: Label 'It was not possible to find table %1 in partner %2.', Comment = '%1 = Table caption, %2 = Partner Code';
        MissingPermissionToReadTableErr: Label 'You do not have the necessary permissions to access the Bank Accounts of partner %1.', Comment = '%1 = Partner Code';
        NoBankAccountsWithICEnableMsg: Label 'The bank accounts for IC Partner %1 are not set up for intercompany copying. Enable bank accounts to be copied on IC Partner %1 by visiting the bank account card and selecting Enable for Intercompany transactions.', Comment = '%1 = Partner Code';

}