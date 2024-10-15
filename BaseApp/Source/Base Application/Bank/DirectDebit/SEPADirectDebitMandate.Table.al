namespace Microsoft.Bank.DirectDebit;

using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;

table 1230 "SEPA Direct Debit Mandate"
{
    Caption = 'SEPA Direct Debit Mandate';
    DataCaptionFields = ID, "Customer Bank Account Code";
    DrillDownPageID = "SEPA Direct Debit Mandates";
    LookupPageID = "SEPA Direct Debit Mandates";
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Code[35])
        {
            Caption = 'ID';

            trigger OnValidate()
            var
                SalesSetup: Record "Sales & Receivables Setup";
                NoSeries: Codeunit "No. Series";
            begin
                if ID <> xRec.ID then begin
                    SalesSetup.Get();
                    NoSeries.TestManual(SalesSetup."Direct Debit Mandate Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            begin
                if (xRec."Customer No." <> '') and ("Customer No." <> xRec."Customer No.") then begin
                    TestField("Date of Signature", 0D);
                    TestField("Debit Counter", 0);
                    "Customer Bank Account Code" := '';
                end;
            end;
        }
        field(3; "Customer Bank Account Code"; Code[20])
        {
            Caption = 'Customer Bank Account Code';
            NotBlank = true;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Customer No."));
        }
        field(4; "Valid From"; Date)
        {
            Caption = 'Valid From';

            trigger OnValidate()
            begin
                ValidateDates();
            end;
        }
        field(5; "Valid To"; Date)
        {
            Caption = 'Valid To';

            trigger OnValidate()
            begin
                ValidateDates();
            end;
        }
        field(6; "Date of Signature"; Date)
        {
            Caption = 'Date of Signature';
            NotBlank = true;
        }
        field(7; "Type of Payment"; Option)
        {
            Caption = 'Type of Payment';
            OptionCaption = 'OneOff,Recurrent';
            OptionMembers = OneOff,Recurrent;

            trigger OnValidate()
            begin
                if ("Type of Payment" = "Type of Payment"::OneOff) then begin
                    if "Debit Counter" > 1 then
                        Error(MandateChangeErr);
                    "Expected Number of Debits" := 1;
                    "Ignore Exp. Number of Debits" := false;
                end;
            end;
        }
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(9; "Expected Number of Debits"; Integer)
        {
            Caption = 'Expected Number of Debits';
            InitValue = 1;
            MinValue = 1;

            trigger OnValidate()
            begin
                if DoesDebitCounterExceedExpectedNumber() then
                    Error(InvalidNumberOfDebitsTxt);
                if ("Type of Payment" = "Type of Payment"::OneOff) and ("Expected Number of Debits" > 1) then
                    Error(InvalidOneOffNumOfDebitsErr);
                SetClosed();
            end;
        }
        field(10; "Debit Counter"; Integer)
        {
            Caption = 'Debit Counter';
            Editable = false;

            trigger OnValidate()
            begin
                if DoesDebitCounterExceedExpectedNumber() then begin
                    Message(InvalidNumberOfDebitsTxt);
                    FieldError("Debit Counter");
                end;
            end;
        }
        field(11; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(12; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        field(13; "Ignore Exp. Number of Debits"; Boolean)
        {
            Caption = 'Ignore Expected Number of Debits';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Type of Payment" = "Type of Payment"::OneOff then
                    "Ignore Exp. Number of Debits" := false;
            end;

        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Customer No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; ID, "Customer Bank Account Code", "Valid From", "Valid To", "Type of Payment")
        {
        }
    }

    trigger OnInsert()
    begin
        if not IsOnInsertHandled() then
            InsertNoSeries();
    end;

    trigger OnModify()
    begin
        if not IsOnModifyHandled() then
            if xRec.Blocked then
                TestField(Blocked, false);
    end;

    var
        DateErr: Label 'The Valid To date must be after the Valid From date.';
        InvalidNumberOfDebitsTxt: Label 'The Debit Counter cannot be greater than the Number of Debits.';
        InvalidOneOffNumOfDebitsErr: Label 'The Number of Debits for OneOff Sequence Type cannot be greater than one.';
        MandateChangeErr: Label 'SequenceType cannot be set to OneOff, since the Mandate has already been used.';

    local procedure InsertNoSeries()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
#if not CLEAN24
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NewNo: Code[20];
        IsHandled: Boolean;
#endif
    begin
        if ID = '' then begin
            SalesSetup.Get();
            SalesSetup.TestField("Direct Debit Mandate Nos.");
#if not CLEAN24
            NoSeriesManagement.RaiseObsoleteOnBeforeInitSeries(SalesSetup."Direct Debit Mandate Nos.", xRec."No. Series", 0D, NewNo, "No. Series", IsHandled);
            if not IsHandled then begin
                if NoSeries.AreRelated(SalesSetup."Direct Debit Mandate Nos.", xRec."No. Series") then
                    "No. Series" := xRec."No. Series"
                else
                    "No. Series" := SalesSetup."Direct Debit Mandate Nos.";
                NewNo := NoSeries.GetNextNo("No. Series");
                NoSeriesManagement.RaiseObsoleteOnAfterInitSeries("No. Series", SalesSetup."Direct Debit Mandate Nos.", 0D, NewNo);
            end;
            ID := NewNo;
#else
			if NoSeries.AreRelated(SalesSetup."Direct Debit Mandate Nos.", xRec."No. Series") then
				"No. Series" := xRec."No. Series"
			else
				"No. Series" := SalesSetup."Direct Debit Mandate Nos.";
            ID := NoSeries.GetNextNo("No. Series");
#endif
        end;
    end;

    procedure IsMandateActive(TransactionDate: Date): Boolean
    begin
        if ("Valid To" <> 0D) and ("Valid To" < TransactionDate) or ("Valid From" > TransactionDate) or Blocked or Closed then
            exit(false);
        exit(true)
    end;

    local procedure DoesDebitCounterExceedExpectedNumber(): Boolean;
    begin
        exit(not "Ignore Exp. Number of Debits" and ("Debit Counter" > "Expected Number of Debits"));
    end;

    procedure GetDefaultMandate(CustomerNo: Code[20]; DueDate: Date): Code[35]
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        Customer: Record Customer;
    begin
        SEPADirectDebitMandate.SetRange("Customer No.", CustomerNo);
        SEPADirectDebitMandate.SetFilter("Valid From", '%1|<=%2', 0D, DueDate);
        SEPADirectDebitMandate.SetFilter("Valid To", '%1|>=%2', 0D, DueDate);
        SEPADirectDebitMandate.SetRange(Blocked, false);
        SEPADirectDebitMandate.SetRange(Closed, false);
        if SEPADirectDebitMandate.FindFirst() then;
        if Customer.Get(CustomerNo) and (Customer."Preferred Bank Account Code" <> '') then
            SEPADirectDebitMandate.SetRange("Customer Bank Account Code", Customer."Preferred Bank Account Code");
        if SEPADirectDebitMandate.FindFirst() then;
        exit(SEPADirectDebitMandate.ID);
    end;

    procedure UpdateCounter()
    begin
        TestField(Blocked, false);
        Validate("Debit Counter", "Debit Counter" + 1);
        SetClosed();
        Modify();
    end;

    procedure GetSequenceType(): Integer
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.Init();
        if "Type of Payment" = "Type of Payment"::OneOff then
            exit(DirectDebitCollectionEntry."Sequence Type"::"One Off");
        if "Debit Counter" = 0 then
            exit(DirectDebitCollectionEntry."Sequence Type"::First);
        if not "Ignore Exp. Number of Debits" then
            if "Debit Counter" >= "Expected Number of Debits" - 1 then
                exit(DirectDebitCollectionEntry."Sequence Type"::Last);
        exit(DirectDebitCollectionEntry."Sequence Type"::Recurring);
    end;

    procedure RollBackSequenceType()
    begin
        if "Debit Counter" <= 0 then
            exit;

        "Debit Counter" -= 1;
        SetClosed();
        Modify();
    end;

    local procedure SetClosed()
    begin
        if not "Ignore Exp. Number of Debits" then
            Closed := "Debit Counter" >= "Expected Number of Debits";
    end;

    local procedure ValidateDates()
    begin
        if ("Valid To" <> 0D) and ("Valid From" > "Valid To") then
            Error(DateErr);
    end;

    local procedure IsOnInsertHandled() IsHandled: boolean;
    begin
        OnBeforeInsert(IsHandled, Rec);
    end;

    local procedure IsOnModifyHandled() IsHandled: boolean;
    begin
        OnBeforeModify(IsHandled, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsert(var IsHandled: boolean; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify(var IsHandled: boolean; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    begin
    end;
}

