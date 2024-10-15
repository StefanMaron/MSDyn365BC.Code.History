table 12108 "Contribution Bracket"
{
    Caption = 'Contribution Bracket';
    DrillDownPageID = "Contribution Brackets";
    LookupPageID = "Contribution Brackets";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Contribution Type"; Option)
        {
            Caption = 'Contribution Type';
            OptionCaption = 'INPS,INAIL';
            OptionMembers = INPS,INAIL;
        }
    }

    keys
    {
        key(Key1; "Code", "Contribution Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", "Contribution Type", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        SocialSecurityBracketLine.Reset();
        SocialSecurityBracketLine.SetRange(Code, Code);

        if SocialSecurityBracketLine.FindFirst then
            SocialSecurityBracketLine.DeleteAll();
    end;

    var
        SocialSecurityBracketLine: Record "Contribution Bracket Line";
}

