namespace Microsoft.Bank.DirectDebit;

table 1255 "Direct Debit Collection Buffer"
{
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Direct Debit Collection No."; Integer)
        {
            Caption = 'Direct Debit Collection No.';
            TableRelation = "Direct Debit Collection";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(4; "Applies-to Entry No."; Integer)
        {
            Caption = 'Applies-to Entry No.';
        }
        field(8; "Transaction ID"; Text[35])
        {
            Caption = 'Transaction ID';
            Editable = false;
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'New,File Created,Rejected,Posted';
            OptionMembers = New,"File Created",Rejected,Posted;
        }
    }

    keys
    {
        key(Key1; "Direct Debit Collection No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Applies-to Entry No.", Status)
        {
        }
    }
}