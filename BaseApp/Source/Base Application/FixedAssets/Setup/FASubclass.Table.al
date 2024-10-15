namespace Microsoft.FixedAssets.Setup;

using Microsoft.FixedAssets.FixedAsset;

table 5608 "FA Subclass"
{
    Caption = 'FA Subclass';
    LookupPageID = "FA Subclasses";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";
        }
        field(4; "Default FA Posting Group"; Code[20])
        {
            Caption = 'Default FA Posting Group';
            TableRelation = "FA Posting Group";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

