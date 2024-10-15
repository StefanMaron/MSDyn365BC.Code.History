namespace Microsoft.Bank.PositivePay;

using System.IO;

table 1241 "Positive Pay Detail"
{
    Caption = 'Positive Pay Detail';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Account Number"; Text[30])
        {
            Caption = 'Account Number';
        }
        field(4; "Record Type Code"; Text[1])
        {
            Caption = 'Record Type Code';
        }
        field(5; "Void Check Indicator"; Text[1])
        {
            Caption = 'Void Check Indicator';
        }
        field(6; "Check Number"; Code[20])
        {
            Caption = 'Check Number';
        }
        field(7; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(8; "Issue Date"; Date)
        {
            Caption = 'Issue Date';
        }
        field(9; Payee; Text[100])
        {
            Caption = 'Payee';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
    }

    keys
    {
        key(Key1; "Data Exch. Entry No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Void Check Indicator")
        {
        }
    }

    fieldgroups
    {
    }
}

