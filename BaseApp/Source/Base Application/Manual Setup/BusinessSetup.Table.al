table 1875 "Business Setup"
{
    Caption = 'Business Setup';
    DataPerCompany = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'This table is being replaced by new table called Manual Setup.';
    ObsoleteTag = '15.0';

    fields
    {
        field(1; Name; Text[50])
        {
            Caption = 'Name';
            ObsoleteState = Pending;
            ObsoleteReason = 'This table is being replaced by new table called Manual Setup.';
            ObsoleteTag = '15.0';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            ObsoleteState = Pending;
            ObsoleteReason = 'This table is being replaced by new table called Manual Setup.';
            ObsoleteTag = '15.0';
        }
        field(3; Keywords; Text[250])
        {
            Caption = 'Keywords';
            ObsoleteState = Pending;
            ObsoleteReason = 'This table is being replaced by new table called Manual Setup.';
            ObsoleteTag = '15.0';
        }
        field(4; "Setup Page ID"; Integer)
        {
            Caption = 'Setup Page ID';
            ObsoleteState = Pending;
            ObsoleteReason = 'This table is being replaced by new table called Manual Setup.';
            ObsoleteTag = '15.0';
        }
        field(5; "Area"; Option)
        {
            Caption = 'Area';
            OptionCaption = ',General,Finance,Sales,Jobs,Fixed Assets,Purchasing,Reference Data,HR,Inventory,Service,System,Relationship Mngt,Intercompany';
            OptionMembers = ,General,Finance,Sales,Jobs,"Fixed Assets",Purchasing,"Reference Data",HR,Inventory,Service,System,"Relationship Mngt",Intercompany;
            ObsoleteState = Pending;
            ObsoleteReason = 'This table is being replaced by new table called Manual Setup.';
            ObsoleteTag = '15.0';
        }
        field(7; Icon; Media)
        {
            Caption = 'Icon';
            ObsoleteState = Pending;
            ObsoleteReason = 'This table is being replaced by new table called Manual Setup.';
            ObsoleteTag = '15.0';
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

