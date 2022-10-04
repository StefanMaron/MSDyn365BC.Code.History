table 871 "Social Listening Search Topic"
{
    Caption = 'Social Listening Search Topic';
    ObsoleteState = Removed;
    ObsoleteReason = 'Microsoft Social Engagement has been discontinued.';
    ObsoleteTag = '20.0';
    ReplicateData = false;

    fields
    {
        field(1; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Item,Vendor,Customer';
            OptionMembers = " ",Item,Vendor,Customer;
        }
        field(2; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer
            ELSE
            IF ("Source Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Source Type" = CONST(Item)) Item;
        }
        field(3; "Search Topic"; Text[250])
        {
            Caption = 'Search Topic';
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

