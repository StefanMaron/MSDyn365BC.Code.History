namespace Microsoft.CRM.Contact;

table 5101 "Contact Value"
{
    Caption = 'Contact Value';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;
        }
        field(2; Value; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Value';
        }
        field(3; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
        }
        field(4; "Questions Answered (%)"; Decimal)
        {
            Caption = 'Questions Answered (%)';
        }
    }

    keys
    {
        key(Key1; "Contact No.")
        {
            Clustered = true;
        }
        key(Key2; Value)
        {
        }
    }

    fieldgroups
    {
    }
}

