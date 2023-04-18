page 7161 "Analysis Dim. Selection-Level"
{
    Caption = 'Analysis Dim. Selection-Level';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Analysis Dim. Selection Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Level; Level)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the level for the selected dimension for analysis.';

                    trigger OnValidate()
                    var
                        xAnalysisDimSelBuf: Record "Analysis Dim. Selection Buffer";
                        HasError: Boolean;
                    begin
                        if Level <> Level::" " then begin
                            xAnalysisDimSelBuf.Copy(Rec);
                            Reset();
                            SetFilter(Code, '<>%1', xAnalysisDimSelBuf.Code);
                            SetRange(Level, xAnalysisDimSelBuf.Level);
                            HasError := not IsEmpty();
                            Copy(xAnalysisDimSelBuf);
                            if HasError then
                                Error(Text000, FieldCaption(Level));
                        end;
                    end;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a code for the selection.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a description of the selection.';
                }
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value that the analysis view is based on.';
                }
            }
        }
    }

    actions
    {
    }

    var
        Text000: Label 'This %1 already exists.';

    procedure GetDimSelBuf(var AnalysisDimSelBuf: Record "Analysis Dim. Selection Buffer")
    begin
        AnalysisDimSelBuf.DeleteAll();
        if FindSet() then
            repeat
                AnalysisDimSelBuf := Rec;
                AnalysisDimSelBuf.Insert();
            until Next() = 0;
    end;

    procedure InsertDimSelBuf(NewSelected: Boolean; NewCode: Text[30]; NewDescription: Text[30]; NewDimValueFilter: Text[250]; NewLevel: Option)
    var
        Dim: Record Dimension;
    begin
        if NewDescription = '' then
            if Dim.Get(NewCode) then
                NewDescription := Dim.GetMLName(GlobalLanguage);

        Init();
        Selected := NewSelected;
        Code := NewCode;
        Description := NewDescription;
        if NewSelected then begin
            "Dimension Value Filter" := NewDimValueFilter;
            Level := NewLevel;
        end;
        Insert();
    end;
}

