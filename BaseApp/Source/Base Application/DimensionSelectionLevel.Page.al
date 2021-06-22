page 564 "Dimension Selection-Level"
{
    Caption = 'Dimension Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Dimension Selection Buffer";
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
                    ToolTip = 'Specifies the level for the selected dimension.';

                    trigger OnValidate()
                    var
                        DimSelectBuffer: Record "Dimension Selection Buffer";
                        LevelExists: Boolean;
                    begin
                        if Level <> Level::" " then begin
                            DimSelectBuffer.Copy(Rec);
                            Reset;
                            SetFilter(Code, '<>%1', DimSelectBuffer.Code);
                            SetRange(Level, DimSelectBuffer.Level);
                            LevelExists := not IsEmpty;
                            Copy(DimSelectBuffer);

                            if LevelExists then
                                Error(Text000, FieldCaption(Level));
                        end;
                    end;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the selected dimension.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies a description of the selected dimension.';
                }
                field("Dimension Value Filter"; "Dimension Value Filter")
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

    procedure GetDimSelBuf(var TheDimSelectionBuf: Record "Dimension Selection Buffer")
    begin
        TheDimSelectionBuf.DeleteAll();
        if Find('-') then
            repeat
                TheDimSelectionBuf := Rec;
                TheDimSelectionBuf.Insert();
            until Next = 0;
    end;

    procedure InsertDimSelBuf(NewSelected: Boolean; NewCode: Text[30]; NewDescription: Text[30]; NewDimValueFilter: Text[250]; NewLevel: Option)
    var
        Dim: Record Dimension;
        GLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
        CFAcc: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        if NewDescription = '' then
            if Dim.Get(NewCode) then
                NewDescription := Dim.GetMLName(GlobalLanguage);

        Init;
        Selected := NewSelected;
        Code := NewCode;
        Description := NewDescription;
        if NewSelected then begin
            "Dimension Value Filter" := NewDimValueFilter;
            Level := NewLevel;
        end;
        case Code of
            GLAcc.TableCaption:
                "Filter Lookup Table No." := DATABASE::"G/L Account";
            BusinessUnit.TableCaption:
                "Filter Lookup Table No." := DATABASE::"Business Unit";
            CFAcc.TableCaption:
                "Filter Lookup Table No." := DATABASE::"Cash Flow Account";
            CashFlowForecast.TableCaption:
                "Filter Lookup Table No." := DATABASE::"Cash Flow Forecast";
        end;
        Insert;
    end;
}

