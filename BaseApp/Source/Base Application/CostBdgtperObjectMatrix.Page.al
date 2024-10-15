page 1133 "Cost Bdgt. per Object Matrix"
{
    Caption = 'Cost Bdgt. per Object Matrix';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Cost Type";

    layout
    {
        area(content)
        {
            repeater(Control6)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = CostAccounting;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the cost type.';
                }
                field(Column1; MATRIX_CellData[1])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[1];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(1);
                    end;
                }
                field(Column2; MATRIX_CellData[2])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[2];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(2);
                    end;
                }
                field(Column3; MATRIX_CellData[3])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[3];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(3);
                    end;
                }
                field(Column4; MATRIX_CellData[4])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[4];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(4);
                    end;
                }
                field(Column5; MATRIX_CellData[5])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[5];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(5);
                    end;
                }
                field(Column6; MATRIX_CellData[6])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[6];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(6);
                    end;
                }
                field(Column7; MATRIX_CellData[7])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[7];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(7);
                    end;
                }
                field(Column8; MATRIX_CellData[8])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[8];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(8);
                    end;
                }
                field(Column9; MATRIX_CellData[9])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[9];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(9);
                    end;
                }
                field(Column10; MATRIX_CellData[10])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[10];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(10);
                    end;
                }
                field(Column11; MATRIX_CellData[11])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[11];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(11);
                    end;
                }
                field(Column12; MATRIX_CellData[12])
                {
                    ApplicationArea = CostAccounting;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_ColumnCaption[12];
                    Style = Strong;
                    StyleExpr = Emphasize;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(12);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Cost Type")
            {
                Caption = '&Cost Type';
                Image = Costs;
                action("&Card")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Card';
                    Image = EditLines;
                    RunObject = Page "Cost Type Card";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Cost Center Filter" = FIELD("Cost Center Filter"),
                                  "Cost Object Filter" = FIELD("Cost Object Filter"),
                                  "Budget Filter" = FIELD("Budget Filter");
                    RunPageOnRec = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information for the cost type.';
                }
                action("E&ntries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'E&ntries';
                    Image = Entries;
                    RunObject = Page "Cost Entries";
                    RunPageLink = "Cost Type No." = FIELD("No.");
                    RunPageView = SORTING("Cost Type No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the entries for the cost object per center.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        for MATRIX_CurrentColumnOrdinal := 1 to MATRIX_CurrentNoOfMatrixColumn do
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        NameIndent := Indentation;
        Emphasize := Type <> Type::"Cost Type";
    end;

    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostObjectMatrixRecords: array[12] of Record "Cost Object";
        MatrixMgt: Codeunit "Matrix Management";
        BudgetFilter: Text;
        MATRIX_ColumnCaption: array[12] of Text[80];
        DateFilter: Text;
        RoundingFactorFormatString: Text;
        RoundingFactor: Enum "Analysis Rounding Factor";
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[12] of Decimal;
        [InDataSet]
        Emphasize: Boolean;
        [InDataSet]
        NameIndent: Integer;
        Text000: Label 'Set View As to Net Change before you edit entries.';

#if not CLEAN19
    [Obsolete('Replaced by LoadMatrix()', '19.0')]
    procedure Load(MatrixColumns1: array[12] of Text[80]; var CostObjectMatrixRecords1: array[12] of Record "Cost Object"; CurrentNoOfMatrixColumns: Integer; DateFilter1: Text; BudgetFilter1: Text; RoundingFactor1: Option)
    begin
        LoadMatrix(
            MatrixColumns1, CostObjectMatrixRecords1, CurrentNoOfMatrixColumns, DateFilter1, BudgetFilter1,
            "Analysis Rounding Factor".FromInteger(RoundingFactor1));
    end;
#endif

    procedure LoadMatrix(NewMatrixColumns: array[12] of Text[80]; var NewCostObjectMatrixRecords: array[12] of Record "Cost Object"; CurrentNoOfMatrixColumns: Integer; NewDateFilter: Text; NewBudgetFilter: Text; NewRoundingFactor: Enum "Analysis Rounding Factor")
    var
        i: Integer;
    begin
        for i := 1 to 12 do begin
            if NewMatrixColumns[i] = '' then
                MATRIX_ColumnCaption[i] := ' '
            else
                MATRIX_ColumnCaption[i] := NewMatrixColumns[i];
            CostObjectMatrixRecords[i] := NewCostObjectMatrixRecords[i];
        end;
        if MATRIX_ColumnCaption[1] = '' then; // To make this form pass preCAL test

        if CurrentNoOfMatrixColumns > ArrayLen(MATRIX_CellData) then
            MATRIX_CurrentNoOfMatrixColumn := ArrayLen(MATRIX_CellData)
        else
            MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        DateFilter := NewDateFilter;
        BudgetFilter := NewBudgetFilter;
        RoundingFactor := NewRoundingFactor;
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(RoundingFactor, false);

        CurrPage.Update(false);
    end;

    local procedure MATRIX_OnDrillDown(ColumnID: Integer)
    begin
        OnBeforeMATRIX_OnDrillDown(CostBudgetEntry);

        CostBudgetEntry.SetCurrentKey("Budget Name", "Cost Type No.", "Cost Center Code", "Cost Object Code", Date);
        if Rec.Type in [Rec.Type::Total, Rec.Type::"End-Total"] then
            CostBudgetEntry.SetFilter("Cost Type No.", Rec.Totaling)
        else
            CostBudgetEntry.SetRange("Cost Type No.", Rec."No.");
        CostBudgetEntry.SetFilter("Cost Object Code", CostObjectMatrixRecords[ColumnID].Code);
        CostBudgetEntry.SetFilter("Budget Name", BudgetFilter);
        CostBudgetEntry.SetFilter(Date, Rec.GetFilter("Date Filter"));
        PAGE.Run(0, CostBudgetEntry);
    end;

    local procedure MATRIX_OnAfterGetRecord(ColumnID: Integer)
    begin
        SetRecordFilters(ColumnID);
        Rec.CalcFields("Budget Amount");
        MATRIX_CellData[ColumnID] := MatrixMgt.RoundAmount(Rec."Budget Amount", RoundingFactor);

        OnAfterMATRIX_OnAfterGetRecord(Rec, MATRIX_CellData, ColumnID, RoundingFactor);
    end;

    local procedure UpdateAmount(ColumnID: Integer)
    begin
        SetRecordFilters(ColumnID);
        if Rec.GetRangeMin("Date Filter") = 0D then
            Error(Text000);

        Rec.CalcFields("Budget Amount");
        Rec.Validate("Budget Amount", MATRIX_CellData[ColumnID]);

        OnAfterUpdateAmount(Rec, MATRIX_CellData, ColumnID);
    end;

    local procedure SetRecordFilters(ColumnID: Integer)
    begin
        Rec.SetFilter("Date Filter", DateFilter);
        Rec.SetFilter("Cost Object Filter", CostObjectMatrixRecords[ColumnID].Code);
        Rec.SetFilter("Budget Filter", BudgetFilter);

        OnAfterSetRecordFilters(Rec);
    end;

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRecordFilters(var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMATRIX_OnDrillDown(var CostBudgetEntry: Record "Cost Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMATRIX_OnAfterGetRecord(var CostType: Record "Cost Type"; var MATRIX_CellData: array[12] of Decimal; ColumnID: Integer; RoundingFactor: Enum "Analysis Rounding Factor")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmount(var CostType: Record "Cost Type"; var MATRIX_CellData: array[12] of Decimal; ColumnID: Integer)
    begin
    end;
}

