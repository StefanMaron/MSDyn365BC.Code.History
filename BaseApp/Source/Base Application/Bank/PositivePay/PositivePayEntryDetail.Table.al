namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using System.Security.AccessControl;

table 1232 "Positive Pay Entry Detail"
{
    Caption = 'Positive Pay Entry Detail';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account"."No.";
        }
        field(2; "Upload Date-Time"; DateTime)
        {
            Caption = 'Upload Date-Time';
            TableRelation = "Positive Pay Entry"."Upload Date-Time" where("Bank Account No." = field("Bank Account No."));
        }
        field(3; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(5; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(7; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'CHECK,VOID';
            OptionMembers = CHECK,VOID;
        }
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(9; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(10; Payee; Text[100])
        {
            Caption = 'Payee';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(12; "Update Date"; Date)
        {
            Caption = 'Update Date';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Upload Date-Time", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CopyFromPosPayEntryDetail(PosPayDetail: Record "Positive Pay Detail"; BankAcct: Code[20])
    begin
        "Bank Account No." := BankAcct;
        "No." := PosPayDetail."Entry No.";
        "Check No." := PosPayDetail."Check Number";
        "Currency Code" := PosPayDetail."Currency Code";
        if PosPayDetail."Record Type Code" = 'V' then
            "Document Type" := "Document Type"::VOID
        else
            "Document Type" := "Document Type"::CHECK;

        "Document Date" := PosPayDetail."Issue Date";
        Amount := PosPayDetail.Amount;
        Payee := PosPayDetail.Payee;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Update Date" := Today;
    end;
}

