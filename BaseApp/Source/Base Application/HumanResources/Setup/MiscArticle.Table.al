namespace Microsoft.HumanResources.Setup;

table 5213 "Misc. Article"
{
    Caption = 'Misc. Article';
    LookupPageID = "Misc. Articles";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(17400; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Award,Reward,Title of Honour,Social Benefits';
            OptionMembers = " ",Award,Reward,"Title of Honour","Social Benefits";
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

