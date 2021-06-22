page 9219 "Purch. Budget Overview Matrix"
{
    Caption = 'Purch. Budget Overview Matrix';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Dimension Code Buffer";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = PurchaseBudget;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Name; Name)
                {
                    ApplicationArea = PurchaseBudget;
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the name of the record.';
                }
                field(Quantity; +Quantity)
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Budgeted Quantity';
                    Editable = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the total quantity of the purchase budget entries.';
                    Visible = QuantityVisible;

                    trigger OnDrillDown()
                    begin
                        DrillDown(true, ValueType::Quantity);
                    end;
                }
                field(Amount; +Amount)
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    Caption = 'Budgeted Cost Amount';
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the total cost of the purchase budget entries.';
                    Visible = AmountVisible;

                    trigger OnDrillDown()
                    begin
                        DrillDown(true, ValueType::"Cost Amount");
                    end;
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateAmount(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = PurchaseBudget;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    StyleExpr = 'Strong';

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
    }

    trigger OnAfterGetCurrRecord()
    begin
        if AmountVisible then
            Amount := CalcAmt(1, false);
        if QuantityVisible then
            Quantity := CalcAmt(2, false);
    end;

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        NameIndent := 0;
        if AmountVisible then
            Amount := MatrixMgt.RoundValue(CalcAmt(ValueType::"Cost Amount", false), RoundingFactor);
        if QuantityVisible then
            Quantity := MatrixMgt.RoundValue(CalcAmt(ValueType::Quantity, false), RoundingFactor);

        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_CurrentNoOfMatrixColumn do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;

        FormatLine;
        AmountOnFormat(Format(Amount));
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(
          ItemBudgetManagement.FindRec(
            ItemBudgetName, LineDimOption, Rec, Which,
            ItemFilter, SourceNoFilter, PeriodType, DateFilter, PeriodInitialized, InternalDateFilter,
            GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter));
    end;

    trigger OnInit()
    begin
        QuantityVisible := true;
        AmountVisible := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(
          ItemBudgetManagement.NextRec(
            ItemBudgetName, LineDimOption, Rec, Steps,
            ItemFilter, SourceNoFilter, PeriodType, DateFilter,
            GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter));
    end;

    trigger OnOpenPage()
    begin
        CurrentAnalysisArea := CurrentAnalysisArea::Purchase;
        ItemBudgetManagement.BudgetNameSelection(
          CurrentAnalysisArea, CurrentBudgetName, ItemBudgetName, ItemStatisticsBuffer,
          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);

        GLSetup.Get();
        SourceTypeFilter := SourceTypeFilter::Vendor;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ItemBudgetName: Record "Item Budget Name";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        MatrixRecords: array[32] of Record "Dimension Code Buffer";
        MATRIX_ColumnTempRec: Record "Dimension Code Buffer";
        ItemBudgetManagement: Codeunit "Item Budget Management";
        MatrixMgt: Codeunit "Matrix Management";
        CurrentAnalysisArea: Option Sales,Purchase,Inventory;
        CurrentBudgetName: Code[10];
        SourceTypeFilter: Option " ",Customer,Vendor,Item;
        SourceNoFilter: Text;
        ItemFilter: Text;
        ValueType: Option ,"Cost Amount",Quantity;
        RoundingFactor: Option "None","1","1000","1000000";
        LineDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3";
        ColumnDimOption: Option Item,Customer,Vendor,Period,Location,"Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        GlobalDim1Filter: Text;
        GlobalDim2Filter: Text;
        BudgetDim1Filter: Text;
        BudgetDim2Filter: Text;
        BudgetDim3Filter: Text;
        DateFilter: Text;
        InternalDateFilter: Text;
        PeriodInitialized: Boolean;
        Text002: Label 'You may only edit column 1 to %1.';
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_CaptionSet: array[32] of Text[80];
        RoundingFactorFormatString: Text;
        [InDataSet]
        AmountVisible: Boolean;
        [InDataSet]
        QuantityVisible: Boolean;
        [InDataSet]
        NameIndent: Integer;

    local procedure CalcAmt(ValueType: Integer; SetColFilter: Boolean): Decimal
    begin
        exit(
          ItemBudgetManagement.CalcAmount(
            ValueType, SetColFilter,
            ItemStatisticsBuffer, ItemBudgetName,
            ItemFilter, SourceTypeFilter, SourceNoFilter, DateFilter,
            GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter,
            LineDimOption, Rec, ColumnDimOption, MATRIX_ColumnTempRec));
    end;

    local procedure SetAmt(ValueType: Integer; SetColFilter: Boolean; NewAmount: Decimal)
    begin
        ItemBudgetManagement.UpdateAmount(
          ValueType, SetColFilter,
          ItemStatisticsBuffer, ItemBudgetName,
          ItemFilter, SourceTypeFilter, SourceNoFilter, DateFilter,
          GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter,
          LineDimOption, Rec, ColumnDimOption, MATRIX_ColumnTempRec, NewAmount);
    end;

    local procedure DrillDown(OnlyLines: Boolean; ValueType: Option "Sales Amount","Cost Amount",Quantity)
    begin
        ItemBudgetManagement.BudgetDrillDown(
          ItemBudgetName,
          ItemFilter, SourceTypeFilter, SourceNoFilter, DateFilter,
          GlobalDim1Filter, GlobalDim2Filter, BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter,
          LineDimOption, Rec,
          ColumnDimOption, MATRIX_ColumnTempRec,
          ValueType,
          OnlyLines);
    end;

    procedure Load(MatrixColumns1: array[32] of Text[80]; var MatrixRecords1: array[32] of Record "Dimension Code Buffer"; CurrentNoOfMatrixColumns: Integer; _CurrentBudgetName: Code[10]; _LineDimOption: Integer; _ColumnDimOption: Integer; _RoundingFactor: Integer; _ValueType: Integer; _PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period")
    var
        i: Integer;
    begin
        Clear(MATRIX_CellData);

        for i := 1 to 12 do begin
            MATRIX_CaptionSet[i] := MatrixColumns1[i];
            MatrixRecords[i] := MatrixRecords1[i];
        end;
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        CurrentAnalysisArea := CurrentAnalysisArea::Purchase;
        CurrentBudgetName := _CurrentBudgetName;
        LineDimOption := _LineDimOption;
        ColumnDimOption := _ColumnDimOption;
        RoundingFactor := _RoundingFactor;
        ValueType := _ValueType;
        PeriodType := _PeriodType;
        ItemBudgetManagement.BudgetNameSelection(
          CurrentAnalysisArea, CurrentBudgetName, ItemBudgetName, ItemStatisticsBuffer,
          BudgetDim1Filter, BudgetDim2Filter, BudgetDim3Filter);
        RoundingFactorFormatString := MatrixMgt.GetFormatString(RoundingFactor, false);
    end;

    procedure SetFilters(_DateFilter: Text; _ItemFilter: Text; _SourceNoFilter: Text; _GlobalDim1Filter: Text; _GlobalDim2Filter: Text; _BudgetDim1Filter: Text; _BudgetDim2Filter: Text; _BudgetDim3Filter: Text)
    begin
        DateFilter := _DateFilter;
        ItemFilter := _ItemFilter;
        SourceNoFilter := _SourceNoFilter;
        GlobalDim1Filter := _GlobalDim1Filter;
        GlobalDim2Filter := _GlobalDim2Filter;
        BudgetDim1Filter := _BudgetDim1Filter;
        BudgetDim2Filter := _BudgetDim2Filter;
        BudgetDim3Filter := _BudgetDim3Filter;
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    begin
        MATRIX_ColumnTempRec := MatrixRecords[MATRIX_ColumnOrdinal];
        DrillDown(false, ValueType);
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        MATRIX_ColumnTempRec := MatrixRecords[MATRIX_ColumnOrdinal];
        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue(CalcAmt(ValueType, true), RoundingFactor);
    end;

    local procedure UpdateAmount(MATRIX_ColumnOrdinal: Integer)
    var
        NewAmount: Decimal;
    begin
        ItemBudgetName.TestField(Blocked, false);
        if MATRIX_ColumnOrdinal > MATRIX_CurrentNoOfMatrixColumn then
            Error(Text002, MATRIX_CurrentNoOfMatrixColumn);
        MATRIX_ColumnTempRec := MatrixRecords[MATRIX_ColumnOrdinal];

        NewAmount := FromRoundedValue(MATRIX_CellData[MATRIX_ColumnOrdinal]);
        SetAmt(ValueType, true, NewAmount);
        Amount := MatrixMgt.RoundValue(CalcAmt(ValueType::"Cost Amount", false), RoundingFactor);
        Quantity := MatrixMgt.RoundValue(CalcAmt(ValueType::Quantity, false), RoundingFactor);
    end;

    local procedure FromRoundedValue(OrgAmount: Decimal): Decimal
    var
        NewAmount: Decimal;
    begin
        NewAmount := OrgAmount;
        case RoundingFactor of
            RoundingFactor::"1000":
                NewAmount := OrgAmount * 1000;
            RoundingFactor::"1000000":
                NewAmount := OrgAmount * 1000000;
        end;
        exit(NewAmount);
    end;

    local procedure FormatLine()
    begin
        NameIndent := Indentation;
    end;

    local procedure AmountOnFormat(Text: Text[1024])
    begin
        ItemBudgetManagement.FormatAmount(Text, RoundingFactor);
    end;

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;
}

