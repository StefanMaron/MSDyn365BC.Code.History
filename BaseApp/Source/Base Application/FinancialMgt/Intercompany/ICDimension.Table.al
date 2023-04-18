table 411 "IC Dimension"
{
    Caption = 'IC Dimension';
    DataCaptionFields = "Code", Name;
    LookupPageID = "IC Dimension List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(3; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(4; "Map-to Dimension Code"; Code[20])
        {
            Caption = 'Map-to Dimension Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Map-to Dimension Code" <> xRec."Map-to Dimension Code" then begin
                    ICDimensionValue.SetRange("Dimension Code", Code);
                    ICDimensionValue.ModifyAll("Map-to Dimension Code", "Map-to Dimension Code");
                    ICDimensionValue.ModifyAll("Map-to Dimension Value Code", '');
                end;
            end;
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
        fieldgroup(DropDown; "Code", Name, Blocked, "Map-to Dimension Code")
        {
        }
    }

    trigger OnDelete()
    var
        ICDimValue: Record "IC Dimension Value";
    begin
        ICDimValue.SetRange("Dimension Code", Code);
        ICDimValue.DeleteAll();
    end;

    var
        ICDimensionValue: Record "IC Dimension Value";
}

