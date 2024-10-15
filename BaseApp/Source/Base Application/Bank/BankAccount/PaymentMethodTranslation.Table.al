namespace Microsoft.Bank.BankAccount;

using System.Globalization;

table 466 "Payment Method Translation"
{
    Caption = 'Payment Method Translation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Payment Method Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

