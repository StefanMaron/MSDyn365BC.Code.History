namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Enums;
using System.Security.AccessControl;

table 1207 "Direct Debit Collection"
{
    Caption = 'Direct Debit Collection';
    DataCaptionFields = Identifier, "Created Date-Time";
    DrillDownPageID = "Direct Debit Collections";
    LookupPageID = "Direct Debit Collections";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; Identifier; Code[20])
        {
            Caption = 'Identifier';
        }
        field(3; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        field(4; "Created by User"; Code[50])
        {
            Caption = 'Created by User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'New,Canceled,File Created,Posted,Closed';
            OptionMembers = New,Canceled,"File Created",Posted,Closed;
        }
        field(6; "No. of Transfers"; Integer)
        {
            CalcFormula = count("Direct Debit Collection Entry" where("Direct Debit Collection No." = field("No.")));
            Caption = 'No. of Transfers';
            FieldClass = FlowField;
        }
        field(7; "To Bank Account No."; Code[20])
        {
            Caption = 'To Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(8; "To Bank Account Name"; Text[100])
        {
            CalcFormula = lookup("Bank Account".Name where("No." = field("To Bank Account No.")));
            Caption = 'To Bank Account Name';
            FieldClass = FlowField;
        }
        field(9; "Message ID"; Code[35])
        {
            Caption = 'Message ID';
        }
        field(10; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CloseQst: Label 'If you close the collection, you will not be able to register the payments from the collection. Do you want to close the collection anyway?';

    procedure CreateRecord(NewIdentifier: Code[20]; NewBankAccountNo: Code[20]; PartnerType: Enum "Partner Type")
    begin
        Reset();
        LockTable();
        if FindLast() then;
        Init();
        "No." += 1;
        Identifier := NewIdentifier;
        "Message ID" := Identifier;
        "Created Date-Time" := CurrentDateTime();
        "Created by User" := UserId();
        "To Bank Account No." := NewBankAccountNo;
        "Partner Type" := PartnerType;
        Insert();
    end;

    procedure CloseCollection()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        if Status in [Status::Closed, Status::Canceled] then
            exit;
        if not Confirm(CloseQst) then
            exit;

        if Status = Status::New then
            Status := Status::Canceled
        else
            Status := Status::Closed;
        Modify();

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", "No.");
        DirectDebitCollectionEntry.SetRange(Status, DirectDebitCollectionEntry.Status::New);
        DirectDebitCollectionEntry.ModifyAll(Status, DirectDebitCollectionEntry.Status::Rejected);
    end;

    procedure Export()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", "No.");
        if DirectDebitCollectionEntry.FindFirst() then
            DirectDebitCollectionEntry.ExportSEPA();
    end;

    procedure HasPaymentFileErrors() Result: Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasPaymentFileErrors(Rec, GenJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GenJnlLine."Document No." := CopyStr(Format("No."), 1, MaxStrLen(GenJnlLine."Document No."));
        exit(GenJnlLine.HasPaymentFileErrorsInBatch());
    end;

    procedure SetStatus(NewStatus: Option)
    begin
        LockTable();
        Find();
        Status := NewStatus;
        Modify();
    end;

    procedure DeletePaymentFileErrors()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", "No.");
        if DirectDebitCollectionEntry.FindSet() then
            repeat
                DirectDebitCollectionEntry.DeletePaymentFileErrors();
            until DirectDebitCollectionEntry.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasPaymentFileErrors(DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebit: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

