table 7153 "Item Analysis View Filter"
{
    Caption = 'Item Analysis View Filter';
    LookupPageID = "Item Analysis View Filter";

    fields
    {
        field(1; "Analysis Area"; Option)
        {
            Caption = 'Analysis Area';
            OptionCaption = 'Sales,Purchase,Inventory';
            OptionMembers = Sales,Purchase,Inventory;
        }
        field(2; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Item Analysis View".Code WHERE("Analysis Area" = FIELD("Analysis Area"),
                                                             Code = FIELD("Analysis View Code"));
        }
        field(3; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;
        }
        field(4; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = FIELD("Dimension Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "Analysis Area", "Analysis View Code", "Dimension Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
    begin
        ItemAnalysisView.Get("Analysis Area", "Analysis View Code");
        ItemAnalysisView.TestField(Blocked, false);
        with ItemAnalysisView do begin
            ValidateDelete(ItemAnalysisViewFilter.FieldCaption("Dimension Code"));
            ItemAnalysisViewReset;
            Modify;
        end;
    end;

    trigger OnInsert()
    begin
        ValidateModifyFilter;
    end;

    trigger OnModify()
    begin
        ValidateModifyFilter;
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You cannot rename an %1.';

    local procedure ValidateModifyFilter()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
    begin
        ItemAnalysisView.Get("Analysis Area", "Analysis View Code");
        ItemAnalysisView.TestField(Blocked, false);
        if (ItemAnalysisView."Last Entry No." <> 0) and (xRec."Dimension Code" <> "Dimension Code") then
            with ItemAnalysisView do begin
                ValidateDelete(ItemAnalysisViewFilter.FieldCaption("Dimension Code"));
                ItemAnalysisViewReset;
                "Dimension Value Filter" := '';
                Modify;
            end;
        if (ItemAnalysisView."Last Entry No." <> 0) and (xRec."Dimension Value Filter" <> "Dimension Value Filter") then
            with ItemAnalysisView do begin
                ValidateDelete(ItemAnalysisViewFilter.FieldCaption("Dimension Value Filter"));
                ItemAnalysisViewReset;
                Modify;
            end;
    end;
}

