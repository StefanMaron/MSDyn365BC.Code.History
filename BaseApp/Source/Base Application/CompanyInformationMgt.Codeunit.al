codeunit 1306 "Company Information Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        CompanyBankAccountTxt: Label 'CompanyBankAccount';
        XPAYMENTTxt: Label 'PAYMENT', Comment = 'Payment';
        XPmtRegTxt: Label 'PMT REG', Comment = 'Payment Registration';
        CompanyBankAccountPostGroupTxt: Label 'OPERATING', Comment = 'Same as Bank Account Posting Group';

    local procedure UpdateGeneralJournalBatch(BankAccount: Record "Bank Account"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        with GenJournalBatch do
            if Get(JournalTemplateName, JournalBatchName) then
                if ("Bal. Account Type" = "Bal. Account Type"::"Bank Account") and ("Bal. Account No." = '') then begin
                    Validate("Bal. Account No.", BankAccount."No.");
                    Modify;
                end;
    end;

    procedure UpdateCompanyBankAccount(var CompanyInformation: Record "Company Information"; BankAccountPostingGroup: Code[20]; var BankAccount: Record "Bank Account")
    begin
        // create or update existing company bank account with the information entered by the user
        // update general journal payment batches to point to the company bank account (unless a bank account is already specified in them)
        with CompanyInformation do begin
            if (("Bank Branch No." = '') and ("Bank Account No." = '')) and (("SWIFT Code" = '') and (IBAN = '')) then
                exit;
            UpdateBankAccount(BankAccount, CompanyInformation, BankAccountPostingGroup);
            UpdateGeneralJournalBatch(BankAccount, XPAYMENTTxt, XPmtRegTxt);
            UpdatePaymentRegistrationSetup(BankAccount, XPAYMENTTxt, XPmtRegTxt);
        end;
    end;

    local procedure UpdatePaymentRegistrationSetup(BankAccount: Record "Bank Account"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        if not PaymentRegistrationSetup.Get(UserId) then begin
            PaymentRegistrationSetup."User ID" := UserId;
            PaymentRegistrationSetup.Insert();
        end;
        PaymentRegistrationSetup."Journal Template Name" := JournalTemplateName;
        PaymentRegistrationSetup."Journal Batch Name" := JournalBatchName;
        PaymentRegistrationSetup."Bal. Account Type" := PaymentRegistrationSetup."Bal. Account Type"::"Bank Account";
        PaymentRegistrationSetup."Bal. Account No." := BankAccount."No.";
        PaymentRegistrationSetup."Use this Account as Def." := true;
        PaymentRegistrationSetup."Auto Fill Date Received" := true;
        PaymentRegistrationSetup.Modify();
    end;

    local procedure UpdateBankAccount(var BankAccount: Record "Bank Account"; CompanyInformation: Record "Company Information"; BankAccountPostingGroup: Code[20])
    var
        BankAccPostingGroup: Record "Bank Account Posting Group";
        IsCompanyBankAcc: Boolean;
    begin
        if BankAccount."No." = '' then
            BankAccount."No." := CompanyBankAccountTxt;

        with CompanyInformation do begin
            if not BankAccount.Get(BankAccount."No.") then begin
                BankAccount.Init();
                BankAccount."No." := CompanyBankAccountTxt;
                BankAccount.Insert();

                IsCompanyBankAcc := true;
            end;
            BankAccount.Validate(Name, "Bank Name");
            BankAccount.Validate("Bank Branch No.", "Bank Branch No.");
            BankAccount.Validate("Country/Region Code", "Country/Region Code");
            BankAccount.Validate("Bank Account No.", "Bank Account No.");
            BankAccount.Validate("SWIFT Code", "SWIFT Code");
            BankAccount.Validate(IBAN, IBAN);
            if (BankAccountPostingGroup = '') and IsCompanyBankAcc then
                BankAccountPostingGroup := CompanyBankAccountPostGroupTxt;
            if BankAccPostingGroup.Get(BankAccountPostingGroup) then
                BankAccount.Validate("Bank Acc. Posting Group", BankAccPostingGroup.Code);
            BankAccount.Modify();
        end;
    end;

    procedure GetCompanyBankAccount(): Code[20]
    begin
        exit(CompanyBankAccountTxt);
    end;

    procedure GetCompanyBankAccountPostingGroup(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.Get(CompanyBankAccountTxt) then
            exit(BankAccount."Bank Acc. Posting Group");
        exit('');
    end;

    procedure IsDemoCompany(): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get then;
        exit(CompanyInformation."Demo Company");
    end;

    [EventSubscriber(ObjectType::Table, 79, 'OnAfterModifyEvent', '', false, false)]
    procedure SetCompanyDisplayNameOnCompanyInformationModify(var Rec: Record "Company Information"; var xRec: Record "Company Information"; RunTrigger: Boolean)
    var
        Company: Record Company;
    begin
        if Rec.IsTemporary then
            exit;

        Company.LockTable();
        if Company.Get(Rec.CurrentCompany) then
            if (Company."Display Name" <> Rec.Name) and (Rec.Name <> '') and (xRec.Name <> Rec.Name) then begin
                Company.Validate("Display Name", Rec.Name);
                Company.Modify(true);
            end;
    end;

    [Scope('OnPrem')]
    procedure IsEUCompany(CompanyInformation: Record "Company Information"): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CompanyInformation."Country/Region Code") then
            exit(false);

        exit(CountryRegion."EU Country/Region Code" <> '');
    end;

    procedure GetCompanyDisplayNameDefaulted(Company: Record Company): Text[250]
    begin
        if Company."Display Name" <> '' then
            exit(Company."Display Name");
        exit(Company.Name)
    end;
}
