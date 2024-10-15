table 31122 "EET Cash Register"
{
    Caption = 'EET Cash Register';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '21.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Business Premises Code"; Code[10])
        {
            Caption = 'Business Premises Code';
            NotBlank = true;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(10; "Register Type"; Option)
        {
            Caption = 'Register Type';
            OptionCaption = ' ,Cash Desk';
            OptionMembers = " ","Cash Desk";

            trigger OnValidate()
            begin
                Validate("Register No.", '');
            end;
        }
        field(12; "Register No."; Code[20])
        {
            Caption = 'Register No.';
        }
        field(15; "Register Name"; Text[50])
        {
            Caption = 'Register Name';
        }
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
        }
        field(20; "Receipt Serial Nos."; Code[20])
        {
            Caption = 'Receipt Serial Nos.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Business Premises Code", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Register Type", "Register No.")
        {
        }
    }

    fieldgroups
    {
    }
}