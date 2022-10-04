table 364 "Analysis View Filter"
{
    Caption = 'Analysis View Filter';

    fields
    {
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Analysis View";
        }
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;
        }
        field(3; "Dimension Value Filter"; Code[250])
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
        key(Key1; "Analysis View Code", "Dimension Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewFilter: Record "Analysis View Filter";
    begin
        AnalysisView.Get("Analysis View Code");
        AnalysisView.TestField(Blocked, false);
        with AnalysisView do begin
            ValidateDelete(AnalysisViewFilter.FieldCaption("Dimension Code"));
            AnalysisViewReset();
            Modify();
        end;
    end;

    trigger OnInsert()
    begin
        ValidateModifyFilter();
    end;

    trigger OnModify()
    begin
        ValidateModifyFilter();
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You can''t rename an %1.';

    local procedure ValidateModifyFilter()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewFilter: Record "Analysis View Filter";
    begin
        AnalysisView.Get("Analysis View Code");
        AnalysisView.TestField(Blocked, false);
        if (AnalysisView."Last Entry No." <> 0) and (xRec."Dimension Code" <> "Dimension Code")
        then
            with AnalysisView do begin
                ValidateDelete(AnalysisViewFilter.FieldCaption("Dimension Code"));
                AnalysisViewReset();
                "Dimension Value Filter" := '';
                Modify();
            end;
        if (AnalysisView."Last Entry No." <> 0) and (xRec."Dimension Value Filter" <> "Dimension Value Filter")
        then
            with AnalysisView do begin
                ValidateDelete(AnalysisViewFilter.FieldCaption("Dimension Value Filter"));
                AnalysisViewReset();
                Modify();
            end;
    end;
}

