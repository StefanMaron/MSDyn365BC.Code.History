table 1875 "Business Setup"
{
    Caption = 'Business Setup';
    DataPerCompany = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'This table is being replaced by new table called Manual Setup.';
    ObsoleteTag = '18.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; Keywords; Text[250])
        {
            Caption = 'Keywords';
        }
        field(4; "Setup Page ID"; Integer)
        {
            Caption = 'Setup Page ID';
        }
        field(5; "Area"; Option)
        {
            Caption = 'Area';
            OptionCaption = ',General,Finance,Sales,Jobs,Fixed Assets,Purchasing,Reference Data,HR,Inventory,Service,System,Relationship Mngt,Intercompany';
            OptionMembers = ,General,Finance,Sales,Jobs,"Fixed Assets",Purchasing,"Reference Data",HR,Inventory,Service,System,"Relationship Mngt",Intercompany;
        }
        field(7; Icon; Media)
        {
            Caption = 'Icon';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; Description, Name, Icon)
        {
        }
    }
}

