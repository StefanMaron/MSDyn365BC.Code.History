table 871 "Social Listening Search Topic"
{
    Caption = 'Social Listening Search Topic';
    ObsoleteState = Removed;
    ObsoleteReason = 'Microsoft Social Engagement has been discontinued.';
    ObsoleteTag = '20.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

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
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
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

