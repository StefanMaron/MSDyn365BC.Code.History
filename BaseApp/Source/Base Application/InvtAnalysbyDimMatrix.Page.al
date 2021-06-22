page 9209 "Invt. Analys by Dim. Matrix"
{
    Caption = 'Invt. Analys by Dim. Matrix';
    DataCaptionExpression = CurrentItemAnalysisViewCode;
    Editable = false;
    LinksAllowed = false;
    PageType = List;
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
                    ApplicationArea = Suite;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the code of the record.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ItemAnalysisMgt.LookUpCode(LineDimOption, LineDimCode, Code);
                    end;
                }
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the name of the record.';
                }
                field(TotalQuantity; +Quantity)
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Caption = 'Total Quantity';
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the total quantity of the item that is currently in inventory. The Total Quantity field is used to calculate the Available Inventory field as follows: Available Inventory = Total Quantity - Reserved Quantity.';

                    trigger OnDrillDown()
                    begin
                        ItemAnalysisMgt.DrillDown(
                          CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                          ItemFilter, LocationFilter, DateFilter,
                          Dim1Filter, Dim2Filter, Dim3Filter, BudgetFilter,
                          LineDimOption, Rec,
                          ColumnDimOption, MatrixRecord,
                          false, 2, ShowActualBudget);
                        // Line with .. ColumnDimOption,MatrixRecord, might be wrong...
                    end;
                }
                field(TotalInvtValue; +Amount)
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Caption = 'Total Inventory Value';
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the value of the total quantity in inventory.';

                    trigger OnDrillDown()
                    begin
                        ItemAnalysisMgt.DrillDown(
                          CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                          ItemFilter, LocationFilter, DateFilter,
                          Dim1Filter, Dim2Filter, Dim3Filter, BudgetFilter,
                          LineDimOption, Rec,
                          ColumnDimOption, Rec,
                          false, 1, ShowActualBudget);

                        // Line with might be wrong... ColumnDimOption,Rec,
                    end;
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    StyleExpr = 'Strong';

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(32);
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
        // IF CurrForm.TotalQuantity.VISIBLE THEN
        Quantity := CalcAmt(2, false);
        // IF CurrForm.TotalInvtValue.VISIBLE THEN
        Amount := CalcAmt(1, false);
    end;

    trigger OnAfterGetRecord()
    var
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        NameIndent := 0;
        // IF CurrForm.TotalQuantity.VISIBLE THEN
        Quantity := CalcAmt(2, false);
        // IF CurrForm.TotalQuantity.VISIBLE THEN
        Amount := CalcAmt(1, false);
        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_CurrentNoOfMatrixColumn do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;

        FormatLine;
        QuantityOnFormat(Format(+Quantity));
        AmountOnFormat(Format(+Amount));
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(
          ItemAnalysisMgt.FindRec(
            ItemAnalysisView, LineDimOption, Rec, Which,
            ItemFilter, LocationFilter, PeriodType, DateFilter, PeriodInitialized, InternalDateFilter,
            Dim1Filter, Dim2Filter, Dim3Filter));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(
          ItemAnalysisMgt.NextRec(
            ItemAnalysisView, LineDimOption, Rec, Steps,
            ItemFilter, LocationFilter, PeriodType, DateFilter,
            Dim1Filter, Dim2Filter, Dim3Filter));
    end;

    trigger OnOpenPage()
    begin
        CurrentAnalysisArea := CurrentAnalysisArea::Inventory;

        GLSetup.Get();
        ItemAnalysisMgt.AnalysisViewSelection(
          CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
          Dim1Filter, Dim2Filter, Dim3Filter);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ItemAnalysisView: Record "Item Analysis View";
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        MatrixRecords: array[32] of Record "Dimension Code Buffer";
        MatrixRecord: Record "Dimension Code Buffer";
        ItemAnalysisMgt: Codeunit "Item Analysis Management";
        CurrentAnalysisArea: Option Sales,Purchase,Inventory;
        CurrentItemAnalysisViewCode: Code[10];
        ItemFilter: Code[250];
        LocationFilter: Code[250];
        BudgetFilter: Code[250];
        ValueType: Option "Sales Amount","Inventory Value","Sales Quantity";
        ShowActualBudget: Option "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%";
        RoundingFactor: Option "None","1","1000","1000000";
        LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        ColumnDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        Dim1Filter: Code[250];
        Dim2Filter: Code[250];
        Dim3Filter: Code[250];
        LineDimCode: Text[30];
        DateFilter: Text[30];
        InternalDateFilter: Text[30];
        PeriodInitialized: Boolean;
        AnalysisValue: Decimal;
        ShowOppositeSign: Boolean;
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_CaptionSet: array[32] of Text[80];
        [InDataSet]
        NameIndent: Integer;

    local procedure CalcAmt(ValueType: Integer; SetColFilter: Boolean): Decimal
    var
        Amt: Decimal;
    begin
        Amt := ItemAnalysisMgt.CalcAmount(
            ValueType, SetColFilter,
            CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
            ItemFilter, LocationFilter, DateFilter, BudgetFilter,
            Dim1Filter, Dim2Filter, Dim3Filter,
            LineDimOption, Rec,
            ColumnDimOption, MatrixRecord,
            ShowActualBudget);
        if ShowOppositeSign then
            Amt := -Amt;
        exit(Amt);
    end;

    procedure Load(MatrixColumns1: array[32] of Text[1024]; var MatrixRecords1: array[32] of Record "Dimension Code Buffer"; CurrentNoOfMatrixColumns: Integer; _LineDimOption: Integer; _ColumnDimOption: Integer; _RoundingFactor: Integer; _DateFilter: Text[30]; _ValueType: Integer; _ItemAnalysisView: Record "Item Analysis View"; _CurrentItemAnalysisViewCode: Code[10]; _ItemFilter: Code[250]; _LocationFilter: Code[250]; _BudgetFilter: Code[250]; _Dim1Filter: Code[250]; _Dim2Filter: Code[250]; _Dim3Filter: Code[250]; ShowOppSign: Boolean)
    var
        FilterTokens: Codeunit "Filter Tokens";
        i: Integer;
    begin
        CopyArray(MATRIX_CaptionSet, MatrixColumns1, 1);
        for i := 1 to ArrayLen(MatrixRecords) do
            MatrixRecords[i].Copy(MatrixRecords1[i]);
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        LineDimOption := _LineDimOption;
        ColumnDimOption := _ColumnDimOption;
        RoundingFactor := _RoundingFactor;
        ValueType := _ValueType;
        ItemAnalysisView := _ItemAnalysisView;
        CurrentItemAnalysisViewCode := _CurrentItemAnalysisViewCode;
        FilterTokens.MakeDateFilter(_DateFilter);
        ItemStatisticsBuffer.SetFilter("Date Filter", _DateFilter);
        DateFilter := ItemStatisticsBuffer.GetFilter("Date Filter");
        ItemFilter := _ItemFilter;
        LocationFilter := _LocationFilter;
        BudgetFilter := _BudgetFilter;
        Dim1Filter := _Dim1Filter;
        Dim2Filter := _Dim2Filter;
        Dim3Filter := _Dim3Filter;
        InternalDateFilter := DateFilter;
        ShowOppositeSign := ShowOppSign;
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    begin
        ItemAnalysisMgt.DrillDown(
          CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
          ItemFilter, LocationFilter, DateFilter,
          Dim1Filter, Dim2Filter, Dim3Filter, BudgetFilter,
          LineDimOption, Rec,
          ColumnDimOption, MatrixRecords[MATRIX_ColumnOrdinal],
          true, ValueType, ShowActualBudget);
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        MatrixRecord := MatrixRecords[MATRIX_ColumnOrdinal];
        AnalysisValue := CalcAmt(ValueType, true);
        MATRIX_CellData[MATRIX_ColumnOrdinal] := AnalysisValue;
    end;

    local procedure FormatLine()
    begin
        NameIndent := Indentation;
    end;

    local procedure QuantityOnFormat(Text: Text[1024])
    begin
        ItemAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure AmountOnFormat(Text: Text[1024])
    begin
        ItemAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;
}

