codeunit 138041 "O365 Company Information"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Company Information] [Bank Account] [SMB]
    end;

    var
        CompanyBankAccountTxt: Label 'CompanyBankAccount';
        XPAYMENTTxt: Label 'PAYMENT', Comment = 'Payment';
        XPmtRegTxt: Label 'PMT REG', Comment = 'Payment Registration';
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountCreatedAfterClosingPage()
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        CompanyInformation: Record "Company Information";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        CompanyInformationPage: TestPage "Company Information";
    begin
        LibraryApplicationArea.EnableFoundationSetup();

        // delete company bank account
        if BankAccount.Get(CompanyBankAccountTxt) then
            BankAccount.Delete();

        if GenJournalBatch.Get(XPAYMENTTxt, XPmtRegTxt) then begin
            GenJournalBatch."Bal. Account No." := '';
            GenJournalBatch.Modify();
        end;

        // fill out bank account information in Company Information page
        BankAccPostingGroup.FindLast();

        with CompanyInformationPage do begin
            OpenEdit();
            "Bank Name".SetValue('Stans Bank');
            "Bank Branch No.".SetValue('0235');
            "Bank Account No.".SetValue('3276392693');
            "SWIFT Code".SetValue('DABASTAN');
            IBAN.SetValue('GB 80 RBOS 161732 41116737');
            BankAccountPostingGroup.SetValue(BankAccPostingGroup.Code);
            OK().Invoke();
        end;

        // verify that a bank account has been created
        CompanyInformation.Get();
        Assert.IsTrue(BankAccount.Get(CompanyBankAccountTxt), 'Bank account ' + CompanyBankAccountTxt + ' not generated.');

        with BankAccount do begin
            TestField(Name, CompanyInformation."Bank Name");
            TestField("Bank Account No.", CompanyInformation."Bank Account No.");
            TestField("Bank Branch No.", CompanyInformation."Bank Branch No.");
            TestField("SWIFT Code", CompanyInformation."SWIFT Code");
            TestField(IBAN, CompanyInformation.IBAN);
            TestField("Bank Acc. Posting Group", BankAccPostingGroup.Code);
        end;

        // verify that payment registration General Journal Batch points to the company bank account
        if GenJournalBatch.Get(XPAYMENTTxt, XPmtRegTxt) then
            GenJournalBatch.TestField("Bal. Account No.", BankAccount."No.");

        // verify that payment registration setup points to to the company bank account
        with PaymentRegistrationSetup do
            if Get(UserId) then begin
                TestField("Journal Template Name", XPAYMENTTxt);
                TestField("Journal Batch Name", XPmtRegTxt);
                TestField("Bal. Account Type", "Bal. Account Type"::"Bank Account");
                TestField("Bal. Account No.", BankAccount."No.");
            end;

        // Modify bank name
        with CompanyInformationPage do begin
            OpenEdit();
            "Bank Name".SetValue("Bank Name".Value + "Bank Name".Value);
            OK().Invoke();
        end;

        // Verify that company bank account has been updated
        BankAccount.TestField(Name, CompanyInformation."Bank Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NameChangeInCompInfChangesCompanyDisplayName()
    var
        Company: Record Company;
        CompanyInformation: TestPage "Company Information";
        NewCompanyName: Code[10];
    begin
        // Validate that changing company name in the company information table changes the company display name

        CompanyInformation.OpenEdit();

        NewCompanyName := LibraryUtility.GenerateGUID();
        CompanyInformation.Name.SetValue(NewCompanyName);
        CompanyInformation.Close();

        Company.Get(CompanyName);
        Company.TestField("Display Name", NewCompanyName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountPostingGroupSaveOnPageAfterReopenCompanyInvormationPage()
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CompanyInformation: TestPage "Company Information";
    begin
        // [SCENARIO 373047] "Bank Account Posting Group" do not reset to blank after reopen "Company Information" page
        // [GIVEN] Create Bank Account Posting Group
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);

        // [GIVEN] Opened "Company Information" page and change "Bank Account Posting Group"
        CompanyInformation.OpenEdit();
        CompanyInformation.BankAccountPostingGroup.SetValue(BankAccountPostingGroup.Code);

        // [WHEN] Reopen "Company Information" page
        CompanyInformation.Close();
        CompanyInformation.OpenEdit();

        // [THEN] BankAccountPostingGroup is populated
        CompanyInformation.BankAccountPostingGroup.AssertEquals(BankAccountPostingGroup.Code);
        CompanyInformation.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyRegistrationNoIsEditable()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
        RegistrationNo: Text[50];
    begin
        // [SCENARIO 359959] Registration No. field is editable on the Company Information page
        CompanyInformationPage.OpenEdit();

        RegistrationNo := LibraryUtility.GenerateGUID();
        CompanyInformationPage."Registration No.".SetValue(RegistrationNo);
        CompanyInformationPage.Close();

        CompanyInformation.Get();
        CompanyInformation.TestField("Registration No.", RegistrationNo);
    end;
}

