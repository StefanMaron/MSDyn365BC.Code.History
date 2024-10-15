table 14951 "KLADR Category"
{
    Caption = 'KLADR Category';
    LookupPageID = "KLADR Categories";

    fields
    {
        field(1; "Code"; Text[10])
        {
            Caption = 'Code';
        }
        field(2; Level; Integer)
        {
            Caption = 'Level';
        }
        field(3; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(4; Type; Code[3])
        {
            Caption = 'Type';
        }
        field(10; Placement; Option)
        {
            Caption = 'Placement';
            OptionCaption = 'Before,After,Skip';
            OptionMembers = Before,After,Skip;
        }
        field(11; "Place Dot"; Boolean)
        {
            Caption = 'Place Dot';
        }
        field(12; Double; Integer)
        {
            Caption = 'Double';
        }
    }

    keys
    {
        key(Key1; "Code", Level)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure GetTextWithCategory(CatCode: Text[10]; CatLevel: Integer; NameText: Text[40]; Full: Boolean; UseSettings: Boolean): Text[80]
    var
        CatText: Text[50];
    begin
        if Get(CatCode, CatLevel) then begin
            if Full then
                CatText := Name
            else begin
                CatText := Code;
                if UseSettings and "Place Dot" then
                    CatText := CatText + '.';
            end;
            if not UseSettings then
                Placement := Placement::After;
            case Placement of
                Placement::Before:
                    exit(CatText + ' ' + NameText);
                Placement::After:
                    exit(NameText + ' ' + CatText);
            end;
        end;
        exit(NameText);
    end;
}

