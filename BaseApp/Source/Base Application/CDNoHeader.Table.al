table 12407 "CD No. Header"
{
    Caption = 'CD No. Header';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to CD Tracking extension table CD Number Header.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "No."; Code[30])
        {
            Caption = 'No.';
        }
        field(3; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            TableRelation = "Country/Region";
        }
        field(4; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(5; "Declaration Date"; Date)
        {
            Caption = 'Declaration Date';
        }
        field(7; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer,Vendor,Item';
            OptionMembers = " ",Customer,Vendor,Item;
        }
        field(8; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST(Item)) Item;
        }
        field(17; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
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
        fieldgroup(DropDown; "No.", "Declaration Date", "Source Type", "Source No.", "Country/Region of Origin Code")
        {
        }
    }
}

