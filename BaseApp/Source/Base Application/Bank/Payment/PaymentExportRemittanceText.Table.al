namespace Microsoft.Bank.Payment;

table 1229 "Payment Export Remittance Text"
{
    Caption = 'Payment Export Remittance Text';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Pmt. Export Data Entry No."; Integer)
        {
            Caption = 'Pmt. Export Data Entry No.';
            TableRelation = "Payment Export Data";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Text; Text[140])
        {
            Caption = 'Text';
        }
    }

    keys
    {
        key(Key1; "Pmt. Export Data Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

