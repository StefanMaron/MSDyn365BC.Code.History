namespace Microsoft.Sales.Customer;

using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Receivables;
using System.Email;
using System.Globalization;
using Microsoft.Bank.Payment;
using Microsoft.Utilities;

table 287 "Customer Bank Account"
{
    Caption = 'Customer Bank Account';
    DataCaptionFields = "Customer No.", "Code", Name;
    DrillDownPageID = "Customer Bank Account List";
    LookupPageID = "Customer Bank Account List";

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(5; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(6; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(7; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(10; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(11; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(12; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(13; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';

            trigger OnValidate()
            begin
                OnValidateBankAccount(Rec, 'Bank Branch No.');
            end;
        }
        field(14; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';

            trigger OnValidate()
            var
                LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
            begin
                if not LocalFunctionalityMgt.CheckBankAccNo("Bank Account No.", "Country/Region Code", "Bank Account No.") then
                    Message(Text1000001, "Bank Account No.");

                UpdateBankAccountNo();
                OnValidateBankAccount(Rec, 'Bank Account No.');
            end;
        }
        field(15; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
        }
        field(16; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(17; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(18; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(19; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(20; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(21; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(22; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(23; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(24; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateIBAN(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                CompanyInfo.CheckIBAN(IBAN);
                UpdateIBAN();
            end;
        }
        field(25; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                UpdateSWIFT();
            end;
        }
        field(1211; "Bank Clearing Code"; Text[50])
        {
            Caption = 'Bank Clearing Code';
        }
        field(1212; "Bank Clearing Standard"; Text[50])
        {
            Caption = 'Bank Clearing Standard';
            TableRelation = "Bank Clearing Standard";
        }
        field(11000000; "Account Holder Name"; Text[100])
        {
            Caption = 'Account Holder Name';
        }
        field(11000001; "Account Holder Address"; Text[100])
        {
            Caption = 'Account Holder Address';
        }
        field(11000002; "Account Holder Post Code"; Code[20])
        {
            Caption = 'Account Holder Post Code';
            TableRelation = if ("Acc. Hold. Country/Region Code" = CONST('')) "Post Code"
            else
            if ("Acc. Hold. Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Acc. Hold. Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode("Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(11000003; "Account Holder City"; Text[30])
        {
            Caption = 'Account Holder City';
            TableRelation = if ("Acc. Hold. Country/Region Code" = CONST('')) "Post Code".City
            else
            if ("Acc. Hold. Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Acc. Hold. Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidateCity("Account Holder City", "Account Holder Post Code", County, "Acc. Hold. Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(11000004; "Acc. Hold. Country/Region Code"; Code[10])
        {
            Caption = 'Acc. Hold. Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11000005; "National Bank Code"; Code[10])
        {
            Caption = 'National Bank Code';
        }
        field(11000007; "Abbrev. National Bank Code"; Code[3])
        {
            Caption = 'Abbrev. National Bank Code';
        }
        field(11000008; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Customer No."),
                                                               "Customer Bank Account Code" = field(Code));

            trigger OnValidate()
            begin
                UpdateMandateID();
            end;
        }
    }

    keys
    {
        key(Key1; "Customer No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name)
        {
        }
        fieldgroup(Brick; "Code", Name, "Phone No.", Contact)
        {
        }
    }

    trigger OnDelete()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", "Customer No.");
        CustLedgerEntry.SetRange("Recipient Bank Account", Code);
        CustLedgerEntry.SetRange(Open, true);
        if not CustLedgerEntry.IsEmpty() then
            Error(BankAccDeleteErr);
        UpdateCustPreferredBankAccountCode();
    end;

    trigger OnInsert()
    begin
        Cust.Get("Customer No.");
        "Account Holder Name" := Cust.Name;
        "Account Holder Address" := Cust.Address;
        "Account Holder Post Code" := Cust."Post Code";
        "Account Holder City" := Cust.City;
        "Acc. Hold. Country/Region Code" := Cust."Country/Region Code";
    end;

    trigger OnRename()
    begin
    end;

    var
        PostCode: Record "Post Code";
        Cust: Record Customer;
        Text1000001: Label 'Bank Account No. %1 may be incorrect.';
        BankAccIdentifierIsEmptyErr: Label 'You must specify either a Bank Account No. or an IBAN.';
        BankAccDeleteErr: Label 'You cannot delete this bank account because it is associated with one or more open ledger entries.';

    local procedure UpdateMandateID()
    var
        ProposalLine: Record "Proposal Line";
    begin
        if FindProposalLines(ProposalLine) then
            ProposalLine.ModifyAll("Direct Debit Mandate ID", "Direct Debit Mandate ID")
    end;

    local procedure UpdateIBAN()
    var
        ProposalLine: Record "Proposal Line";
    begin
        if FindProposalLines(ProposalLine) then
            ProposalLine.ModifyAll(IBAN, IBAN)
    end;

    local procedure UpdateSWIFT()
    var
        ProposalLine: Record "Proposal Line";
    begin
        if FindProposalLines(ProposalLine) then
            ProposalLine.ModifyAll("SWIFT Code", "SWIFT Code")
    end;

    local procedure UpdateBankAccountNo()
    var
        ProposalLine: Record "Proposal Line";
    begin
        if FindProposalLines(ProposalLine) then
            ProposalLine.ModifyAll("Bank Account No.", "Bank Account No.")
    end;

    local procedure FindProposalLines(var ProposalLine: Record "Proposal Line"): Boolean
    begin
        ProposalLine.SetRange("Account Type", ProposalLine."Account Type"::Customer);
        ProposalLine.SetRange("Account No.", "Customer No.");
        ProposalLine.SetRange(Bank, "Code");
        exit(not ProposalLine.IsEmpty());
    end;

    procedure GetBankAccountNoWithCheck() AccountNo: Text
    begin
        AccountNo := GetBankAccountNo();
        if AccountNo = '' then
            Error(BankAccIdentifierIsEmptyErr);
    end;

    procedure GetBankAccountNo(): Text
    var
        Handled: Boolean;
        ResultBankAccountNo: Text;
    begin
        OnGetBankAccount(Handled, Rec, ResultBankAccountNo);

        if Handled then exit(ResultBankAccountNo);

        if IBAN <> '' then
            exit(DelChr(IBAN, '=<>'));

        if "Bank Account No." <> '' then
            exit("Bank Account No.");
    end;

    local procedure UpdateCustPreferredBankAccountCode()
    var
        CustomerLocal: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCustPreferredBankAccountCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if CustomerLocal.Get("Customer No.") and (CustomerLocal."Preferred Bank Account Code" = Code) then begin
            CustomerLocal."Preferred Bank Account Code" := '';
            CustomerLocal.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; FieldToValidate: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIBAN(var CustomerBankAccount: Record "Customer Bank Account"; var xCustomerBankAccount: Record "Customer Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBankAccount(var Handled: Boolean; CustomerBankAccount: Record "Customer Bank Account"; var ResultBankAccountNo: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var CustomerBankAccount: Record "Customer Bank Account"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustPreferredBankAccountCode(var CustomerBankAccount: Record "Customer Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var CustomerBankAccount: Record "Customer Bank Account"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}

