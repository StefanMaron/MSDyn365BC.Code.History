table 10871 "Unreal. CV Ledg. Entry Buffer"
{
    Caption = 'Unreal. CV Ledg. Entry Buffer';

    fields
    {
        field(1; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Customer,Vendor';
            OptionMembers = Customer,Vendor;
        }
        field(2; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor."No.";
        }
        field(3; "Payment Slip No."; Code[20])
        {
            Caption = 'Payment Slip No.';
        }
        field(4; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(5; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(6; "Applied Amount"; Decimal)
        {
            Caption = 'Applied Amount';
        }
        field(7; Realized; Boolean)
        {
            Caption = 'Realized';
        }
    }

    keys
    {
        key(Key1; "Account Type", "Account No.", "Payment Slip No.", "Applies-to ID", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

