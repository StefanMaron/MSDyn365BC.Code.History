page 9223 "Item Statistics Matrix"
{
    Caption = 'Item Statistics Matrix';
    DataCaptionExpression = ItemName;
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
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the name of the record.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    Caption = 'Total Amount';
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the total value for the amount type that you select in the Show field.';

                    trigger OnDrillDown()
                    begin
                        with ItemBuffer do
                            if not (("Line Option" = "Line Option"::"Profit Calculation") and
                                    ((Name = FieldCaption("Profit (LCY)")) or (Name = FieldCaption("Profit %"))) or
                                    (("Line Option" = "Line Option"::"Cost Specification") and (Name = FieldCaption("Inventoriable Costs"))))
                            then begin
                                SetCommonFilters(ItemBuffer);
                                SetFilters(ItemBuffer, 0);
                                DrillDown();
                            end;
                    end;
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    Visible = Field8Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    Visible = Field32Visible;

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

    trigger OnAfterGetRecord()
    var
        MATRIX_Steps: Integer;
    begin
        NameIndent := 0;
        Amount := Calculate(false);
        MATRIX_ColumnOrdinal := 0;
        if MATRIX_OnFindRecord('=><') then begin
            MATRIX_ColumnOrdinal := 1;
            repeat
                MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal);
                MATRIX_Steps := MATRIX_OnNextRecord(1);
                MATRIX_ColumnOrdinal := MATRIX_ColumnOrdinal + MATRIX_Steps;
            until (MATRIX_ColumnOrdinal - MATRIX_Steps = ArrayLen(MatrixRecords)) or (MATRIX_Steps = 0);
            if MATRIX_ColumnOrdinal <> 1 then
                MATRIX_OnNextRecord(1 - MATRIX_ColumnOrdinal);
        end;
        NameOnFormat();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        IntegerLineSetFilter();
        exit(FindRec(ItemBuffer."Line Option", Rec, Which));
    end;

    trigger OnInit()
    begin
        Field32Visible := true;
        Field31Visible := true;
        Field30Visible := true;
        Field29Visible := true;
        Field28Visible := true;
        Field27Visible := true;
        Field26Visible := true;
        Field25Visible := true;
        Field24Visible := true;
        Field23Visible := true;
        Field22Visible := true;
        Field21Visible := true;
        Field20Visible := true;
        Field19Visible := true;
        Field18Visible := true;
        Field17Visible := true;
        Field16Visible := true;
        Field15Visible := true;
        Field14Visible := true;
        Field13Visible := true;
        Field12Visible := true;
        Field11Visible := true;
        Field10Visible := true;
        Field9Visible := true;
        Field8Visible := true;
        Field7Visible := true;
        Field6Visible := true;
        Field5Visible := true;
        Field4Visible := true;
        Field3Visible := true;
        Field2Visible := true;
        Field1Visible := true;
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(ItemBuffer."Line Option", Rec, Steps));
    end;

    trigger OnOpenPage()
    begin
        Field1Visible := 1 <= MATRIX_CurrentNoOfMatrixColumn;
        Field2Visible := 2 <= MATRIX_CurrentNoOfMatrixColumn;
        Field3Visible := 3 <= MATRIX_CurrentNoOfMatrixColumn;
        Field4Visible := 4 <= MATRIX_CurrentNoOfMatrixColumn;
        Field5Visible := 5 <= MATRIX_CurrentNoOfMatrixColumn;
        Field6Visible := 6 <= MATRIX_CurrentNoOfMatrixColumn;
        Field7Visible := 7 <= MATRIX_CurrentNoOfMatrixColumn;
        Field8Visible := 8 <= MATRIX_CurrentNoOfMatrixColumn;
        Field9Visible := 9 <= MATRIX_CurrentNoOfMatrixColumn;
        Field10Visible := 10 <= MATRIX_CurrentNoOfMatrixColumn;
        Field11Visible := 11 <= MATRIX_CurrentNoOfMatrixColumn;
        Field12Visible := 12 <= MATRIX_CurrentNoOfMatrixColumn;
        Field13Visible := 13 <= MATRIX_CurrentNoOfMatrixColumn;
        Field14Visible := 14 <= MATRIX_CurrentNoOfMatrixColumn;
        Field15Visible := 15 <= MATRIX_CurrentNoOfMatrixColumn;
        Field16Visible := 16 <= MATRIX_CurrentNoOfMatrixColumn;
        Field17Visible := 17 <= MATRIX_CurrentNoOfMatrixColumn;
        Field18Visible := 18 <= MATRIX_CurrentNoOfMatrixColumn;
        Field19Visible := 19 <= MATRIX_CurrentNoOfMatrixColumn;
        Field20Visible := 20 <= MATRIX_CurrentNoOfMatrixColumn;
        Field21Visible := 21 <= MATRIX_CurrentNoOfMatrixColumn;
        Field22Visible := 22 <= MATRIX_CurrentNoOfMatrixColumn;
        Field23Visible := 23 <= MATRIX_CurrentNoOfMatrixColumn;
        Field24Visible := 24 <= MATRIX_CurrentNoOfMatrixColumn;
        Field25Visible := 25 <= MATRIX_CurrentNoOfMatrixColumn;
        Field26Visible := 26 <= MATRIX_CurrentNoOfMatrixColumn;
        Field27Visible := 27 <= MATRIX_CurrentNoOfMatrixColumn;
        Field28Visible := 28 <= MATRIX_CurrentNoOfMatrixColumn;
        Field29Visible := 29 <= MATRIX_CurrentNoOfMatrixColumn;
        Field30Visible := 30 <= MATRIX_CurrentNoOfMatrixColumn;
        Field31Visible := 31 <= MATRIX_CurrentNoOfMatrixColumn;
        Field32Visible := 32 <= MATRIX_CurrentNoOfMatrixColumn;

        with Item do begin
            if "No." <> '' then
                ItemFilter := "No.";
            if GetFilter("Date Filter") <> '' then
                DateFilter := GetFilter("Date Filter");
            if GetFilter("Variant Filter") <> '' then
                VariantFilter := GetFilter("Variant Filter");
            if GetFilter("Location Filter") <> '' then
                LocationFilter := GetFilter("Location Filter");
        end;

        if ColumnDimCode = '' then
            ColumnDimCode := Text002;
        ItemBuffer."Column Option" := DimCodeToOption(ColumnDimCode);
        PeriodInitialized := DateFilter <> '';
        FindPeriod('');
        ItemName := StrSubstNo('%1  %2', Item."No.", Item.Description);
    end;

    var
        Item: Record Item;
        ItemBuffer: Record "Item Statistics Buffer";
        IntegerLine: Record "Integer";
        MatrixRecord: Record "Dimension Code Buffer";
        MatrixRecords: array[32] of Record "Dimension Code Buffer";
        MatrixMgt: Codeunit "Matrix Management";
        ColumnDimCode: Text[30];
        ItemName: Text[250];
        PeriodType: Enum "Analysis Period Type";
        RoundingFactor: Enum "Analysis Rounding Factor";
        AmountType: Enum "Analysis Amount Type";
        DateFilter: Text;
        InternalDateFilter: Text;
        ItemFilter: Text;
        VariantFilter: Text;
        LocationFilter: Text;
        ItemChargesFilter: Text;
        PeriodInitialized: Boolean;
        PerUnit: Boolean;
        IncludeExpected: Boolean;
        Qty: Decimal;
        CellAmount: Decimal;
        Text002: Label 'Period';
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_ColumnOrdinal: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_CaptionSet: array[32] of Text[80];
        RoundingFactorFormatString: Text;
        [InDataSet]
        Field1Visible: Boolean;
        [InDataSet]
        Field2Visible: Boolean;
        [InDataSet]
        Field3Visible: Boolean;
        [InDataSet]
        Field4Visible: Boolean;
        [InDataSet]
        Field5Visible: Boolean;
        [InDataSet]
        Field6Visible: Boolean;
        [InDataSet]
        Field7Visible: Boolean;
        [InDataSet]
        Field8Visible: Boolean;
        [InDataSet]
        Field9Visible: Boolean;
        [InDataSet]
        Field10Visible: Boolean;
        [InDataSet]
        Field11Visible: Boolean;
        [InDataSet]
        Field12Visible: Boolean;
        [InDataSet]
        Field13Visible: Boolean;
        [InDataSet]
        Field14Visible: Boolean;
        [InDataSet]
        Field15Visible: Boolean;
        [InDataSet]
        Field16Visible: Boolean;
        [InDataSet]
        Field17Visible: Boolean;
        [InDataSet]
        Field18Visible: Boolean;
        [InDataSet]
        Field19Visible: Boolean;
        [InDataSet]
        Field20Visible: Boolean;
        [InDataSet]
        Field21Visible: Boolean;
        [InDataSet]
        Field22Visible: Boolean;
        [InDataSet]
        Field23Visible: Boolean;
        [InDataSet]
        Field24Visible: Boolean;
        [InDataSet]
        Field25Visible: Boolean;
        [InDataSet]
        Field26Visible: Boolean;
        [InDataSet]
        Field27Visible: Boolean;
        [InDataSet]
        Field28Visible: Boolean;
        [InDataSet]
        Field29Visible: Boolean;
        [InDataSet]
        Field30Visible: Boolean;
        [InDataSet]
        Field31Visible: Boolean;
        [InDataSet]
        Field32Visible: Boolean;
        [InDataSet]
        NameIndent: Integer;

    local procedure IntegerLineSetFilter()
    begin
        if ItemBuffer."Line Option" = ItemBuffer."Line Option"::"Profit Calculation" then
            IntegerLine.SetRange(Number, 1, 5)
        else
            if ItemBuffer."Line Option" = ItemBuffer."Line Option"::"Cost Specification" then
                IntegerLine.SetRange(Number, 1, 9);

        OnAfterIntegerLineSetFilter(ItemBuffer, IntegerLine);
    end;

    local procedure DimCodeToOption(DimCode: Text[30]): Enum "Item Statistics Column Option"
    var
        Location: Record Location;
    begin
        case DimCode of
            '':
                exit("Item Statistics Column Option"::Undefined);
            Text002:
                exit("Item Statistics Column Option"::Period);
            Location.TableCaption():
                exit("Item Statistics Column Option"::Location);
            else
                exit("Item Statistics Column Option"::Undefined);
        end;
    end;

    local procedure FindRec(DimOption: Enum "Item Statistics Column Option"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]): Boolean
    var
        ItemCharge: Record "Item Charge";
        Location: Record Location;
        Period: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        Found: Boolean;
    begin
        case DimOption of
            DimOption::"Profit Calculation",
            DimOption::"Cost Specification":
                begin
                    if Evaluate(IntegerLine.Number, DimCodeBuf.Code) then;
                    Found := IntegerLine.Find(Which);
                    if Found then
                        CopyDimValueToBuf(IntegerLine, DimCodeBuf);
                end;
            DimOption::"Purch. Item Charge Spec.",
            DimOption::"Sales Item Charge Spec.":
                begin
                    ItemCharge."No." := DimCodeBuf.Code;
                    Found := ItemCharge.Find(Which);
                    if Found then
                        CopyAddChargesToBuf(ItemCharge, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if not PeriodInitialized then
                        DateFilter := '';
                    PeriodInitialized := true;
                    Period.Reset();
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter)
                    else
                        if not PeriodInitialized and (InternalDateFilter <> '') then
                            Period.SetFilter("Period Start", InternalDateFilter);
                    if DimCodeBuf."Period Start" = 0D then
                        Period.FindFirst()
                    else
                        Period."Period Start" := DimCodeBuf."Period Start";
                    Found := PeriodPageMgt.FindDate(Which, Period, PeriodType);
                    if Found then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimOption::Location:
                begin
                    Location.Code := DimCodeBuf.Code;
                    if LocationFilter <> '' then
                        Location.SetFilter(Code, LocationFilter);
                    Found := Location.Find(Which);
                    if Found then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
        end;
        exit(Found);
    end;

    local procedure NextRec(DimOption: Enum "Item Statistics Column Option"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer): Integer
    var
        ItemCharge: Record "Item Charge";
        Location: Record Location;
        Period: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
        ResultSteps: Integer;
    begin
        case DimOption of
            DimOption::"Profit Calculation",
            DimOption::"Cost Specification":
                begin
                    if Evaluate(IntegerLine.Number, DimCodeBuf.Code) then;
                    ResultSteps := IntegerLine.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(IntegerLine, DimCodeBuf);
                end;
            DimOption::"Purch. Item Charge Spec.",
            DimOption::"Sales Item Charge Spec.":
                begin
                    ItemCharge."No." := DimCodeBuf.Code;
                    if ItemChargesFilter <> '' then
                        ItemCharge.SetFilter("No.", ItemChargesFilter);
                    ResultSteps := ItemCharge.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyAddChargesToBuf(ItemCharge, DimCodeBuf);
                end;
            DimOption::Period:
                begin
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter);
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodPageMgt.NextDate(Steps, Period, PeriodType);
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf);
                end;
            DimOption::Location:
                begin
                    Location.Code := DimCodeBuf.Code;
                    if LocationFilter <> '' then
                        Location.SetFilter(Code, LocationFilter);
                    ResultSteps := Location.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
        end;
        exit(ResultSteps);
    end;

    local procedure CopyDimValueToBuf(var TheDimValue: Record "Integer"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with ItemBuffer do
            case "Line Option" of
                "Line Option"::"Profit Calculation":
                    case TheDimValue.Number of
                        1:
                            InsertRow('1', FieldCaption("Sales (LCY)"), 0, false, TheDimCodeBuf);
                        2:
                            InsertRow('2', FieldCaption("COGS (LCY)"), 0, false, TheDimCodeBuf);
                        3:
                            InsertRow('3', FieldCaption("Non-Invtbl. Costs (LCY)"), 0, false, TheDimCodeBuf);
                        4:
                            InsertRow('4', FieldCaption("Profit (LCY)"), 0, false, TheDimCodeBuf);
                        5:
                            InsertRow('5', FieldCaption("Profit %"), 0, false, TheDimCodeBuf);
                    end;
                "Line Option"::"Cost Specification":
                    case TheDimValue.Number of
                        1:
                            InsertRow('1', FieldCaption("Inventoriable Costs"), 0, true, TheDimCodeBuf);
                        2:
                            InsertRow('2', FieldCaption("Direct Cost (LCY)"), 1, false, TheDimCodeBuf);
                        3:
                            InsertRow('3', FieldCaption("Revaluation (LCY)"), 1, false, TheDimCodeBuf);
                        4:
                            InsertRow('4', FieldCaption("Rounding (LCY)"), 1, false, TheDimCodeBuf);
                        5:
                            InsertRow('5', FieldCaption("Indirect Cost (LCY)"), 1, false, TheDimCodeBuf);
                        6:
                            InsertRow('6', FieldCaption("Variance (LCY)"), 1, false, TheDimCodeBuf);
                        7:
                            InsertRow('7', FieldCaption("Inventoriable Costs, Total"), 0, true, TheDimCodeBuf);
                        8:
                            InsertRow('8', FieldCaption("COGS (LCY)"), 0, true, TheDimCodeBuf);
                        9:
                            InsertRow('9', FieldCaption("Inventory (LCY)"), 0, true, TheDimCodeBuf);
                    end;
            end;
        OnAfterCopyDimValueToBuf(ItemBuffer, TheDimValue, TheDimCodeBuf);
    end;

    local procedure CopyAddChargesToBuf(var TheItemCharge: Record "Item Charge"; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init();
            Code := TheItemCharge."No.";
            Name := CopyStr(
                StrSubstNo('%1 %2', TheItemCharge."No.", TheItemCharge.Description), 1, 50);
        end;
    end;

    local procedure CopyLocationToBuf(var TheLocation: Record Location; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init();
            Code := TheLocation.Code;
            Name := TheLocation.Name;
        end;
    end;

    local procedure CopyPeriodToBuf(var ThePeriod: Record Date; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init();
            Code := Format(ThePeriod."Period Start");
            "Period Start" := ThePeriod."Period Start";
            "Period End" := ThePeriod."Period End";
            Name := ThePeriod."Period Name";
        end;
    end;

    protected procedure InsertRow(Code1: Code[10]; Name1: Text[80]; Indentation1: Integer; Bold1: Boolean; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init();
            Code := Code1;
            Name := CopyStr(Name1, 1, MaxStrLen(Name));
            Indentation := Indentation1;
            "Show in Bold" := Bold1;
        end;
    end;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if DateFilter <> '' then begin
            Calendar.SetFilter("Period Start", DateFilter);
            if not PeriodPageMgt.FindDate('+', Calendar, PeriodType) then
                PeriodPageMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageMgt.FindDate(SearchText, Calendar, PeriodType);
        with ItemBuffer do
            if AmountType = AmountType::"Net Change" then begin
                SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
                if GetRangeMin("Date Filter") = GetRangeMax("Date Filter") then
                    SetRange("Date Filter", GetRangeMin("Date Filter"));
            end else
                SetRange("Date Filter", 0D, Calendar."Period End");
        InternalDateFilter := ItemBuffer.GetFilter("Date Filter");
    end;

    local procedure DrillDown()
    var
        ValueEntry: Record "Value Entry";
    begin
        with ItemBuffer do begin
            ValueEntry.SetCurrentKey(
              "Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type", "Variance Type",
              "Item Charge No.", "Location Code", "Variant Code");
            if GetFilter("Item Filter") <> '' then
                CopyFilter("Item Filter", ValueEntry."Item No.");
            if GetFilter("Date Filter") <> '' then
                CopyFilter("Date Filter", ValueEntry."Posting Date")
            else
                ValueEntry.SetRange("Posting Date", 0D, DMY2Date(31, 12, 9999));
            if GetFilter("Entry Type Filter") <> '' then
                CopyFilter("Entry Type Filter", ValueEntry."Entry Type");
            if GetFilter("Item Ledger Entry Type Filter") <> '' then
                CopyFilter("Item Ledger Entry Type Filter", ValueEntry."Item Ledger Entry Type");
            if GetFilter("Variance Type Filter") <> '' then
                CopyFilter("Variance Type Filter", ValueEntry."Variance Type");
            if GetFilter("Item Charge No. Filter") <> '' then
                CopyFilter("Item Charge No. Filter", ValueEntry."Item Charge No.");
            if GetFilter("Location Filter") <> '' then
                CopyFilter("Location Filter", ValueEntry."Location Code");
            if GetFilter("Variant Filter") <> '' then
                CopyFilter("Variant Filter", ValueEntry."Variant Code");
            case true of
                (("Line Option" = "Line Option"::"Profit Calculation") and (Name = FieldCaption("Sales (LCY)"))) or
              ("Line Option" = "Line Option"::"Sales Item Charge Spec."):
                    PAGE.Run(0, ValueEntry, ValueEntry."Sales Amount (Actual)");
                Name = FieldCaption("Non-Invtbl. Costs (LCY)"):
                    PAGE.Run(0, ValueEntry, ValueEntry."Cost Amount (Non-Invtbl.)");
                else
                    PAGE.Run(0, ValueEntry, ValueEntry."Cost Amount (Actual)");
            end;
        end;
    end;

    protected procedure SetCommonFilters(var TheItemBuffer: Record "Item Statistics Buffer")
    begin
        with TheItemBuffer do begin
            Reset();
            if ItemFilter <> '' then
                SetFilter("Item Filter", ItemFilter);
            if DateFilter <> '' then
                SetFilter("Date Filter", DateFilter);
            if LocationFilter <> '' then
                SetFilter("Location Filter", LocationFilter);
            if VariantFilter <> '' then
                SetFilter("Variant Filter", VariantFilter);
        end;
    end;

    protected procedure SetFilters(var ItemBuffer: Record "Item Statistics Buffer"; LineOrColumn: Option Line,Column)
    var
        DimCodeBuf: Record "Dimension Code Buffer";
        DimOption: Enum "Item Statistics Column Option";
    begin
        if LineOrColumn = LineOrColumn::Line then begin
            DimCodeBuf := Rec;
            DimOption := ItemBuffer."Line Option";
        end else begin
            DimCodeBuf := MatrixRecords[MATRIX_ColumnOrdinal];
            DimOption := ItemBuffer."Column Option";
        end;
        with ItemBuffer do begin
            case DimOption of
                DimOption::Location:
                    SetRange("Location Filter", DimCodeBuf.Code);
                DimOption::Period:
                    if AmountType = AmountType::"Net Change" then
                        SetRange("Date Filter", DimCodeBuf."Period Start", DimCodeBuf."Period End")
                    else
                        SetRange("Date Filter", 0D, DimCodeBuf."Period End");
                DimOption::"Profit Calculation",
              DimOption::"Cost Specification":
                    case Name of
                        FieldCaption("Sales (LCY)"),
                        FieldCaption("COGS (LCY)"),
                        FieldCaption("Profit (LCY)"),
                        FieldCaption("Profit %"):
                            begin
                                SetRange("Item Ledger Entry Type Filter", "Item Ledger Entry Type Filter"::Sale);
                                if DimOption = DimOption::"Profit Calculation" then
                                    SetFilter("Entry Type Filter", '<>%1', "Entry Type Filter"::Revaluation);
                                SetRange("Variance Type Filter", "Variance Type Filter"::" ");
                            end;
                        FieldCaption("Direct Cost (LCY)"),
                        FieldCaption("Revaluation (LCY)"),
                        FieldCaption("Rounding (LCY)"),
                        FieldCaption("Indirect Cost (LCY)"),
                        FieldCaption("Variance (LCY)"),
                        FieldCaption("Inventoriable Costs, Total"):
                            begin
                                SetFilter(
                                  "Item Ledger Entry Type Filter", '<>%1&<>%2',
                                  "Item Ledger Entry Type Filter"::Sale,
                                  "Item Ledger Entry Type Filter"::" ");
                                SetRange("Variance Type Filter", "Variance Type Filter"::" ");
                                case Name of
                                    FieldCaption("Direct Cost (LCY)"):
                                        SetRange("Entry Type Filter", "Entry Type Filter"::"Direct Cost");
                                    FieldCaption("Revaluation (LCY)"):
                                        SetRange("Entry Type Filter", "Entry Type Filter"::Revaluation);
                                    FieldCaption("Rounding (LCY)"):
                                        SetRange("Entry Type Filter", "Entry Type Filter"::Rounding);
                                    FieldCaption("Indirect Cost (LCY)"):
                                        SetRange("Entry Type Filter", "Entry Type Filter"::"Indirect Cost");
                                    FieldCaption("Variance (LCY)"):
                                        begin
                                            SetRange("Entry Type Filter", "Entry Type Filter"::Variance);
                                            SetFilter("Variance Type Filter", '<>%1', "Variance Type Filter"::" ");
                                        end;
                                    FieldCaption("Inventoriable Costs, Total"):
                                        SetRange("Variance Type Filter");
                                end;
                            end;
                        else
                            SetRange("Item Ledger Entry Type Filter");
                            SetRange("Variance Type Filter");
                    end;
                DimOption::"Purch. Item Charge Spec.":
                    begin
                        SetRange("Variance Type Filter", "Variance Type Filter"::" ");
                        SetRange("Item Ledger Entry Type Filter", "Item Ledger Entry Type Filter"::Purchase);
                        SetRange("Item Charge No. Filter", DimCodeBuf.Code);
                    end;
                DimOption::"Sales Item Charge Spec.":
                    begin
                        SetRange("Variance Type Filter", "Variance Type Filter"::" ");
                        SetRange("Item Ledger Entry Type Filter", "Item Ledger Entry Type Filter"::Sale);
                        SetRange("Item Charge No. Filter", DimCodeBuf.Code);
                    end;
                else
                    OnSetFiltersElseCase(ItemBuffer, DimCodeBuf);
            end;
            if GetFilter("Item Ledger Entry Type Filter") = '' then
                SetFilter(
                  "Item Ledger Entry Type Filter", '<>%1',
                  "Item Ledger Entry Type Filter"::" ")
        end;
    end;

    local procedure Calculate(SetColumnFilter: Boolean) Amount: Decimal
    begin
        with ItemBuffer do begin
            case "Line Option" of
                "Line Option"::"Profit Calculation",
              "Line Option"::"Cost Specification":
                    case Rec.Name of
                        FieldCaption("Sales (LCY)"):
                            Amount := CalcSalesAmount(SetColumnFilter);
                        FieldCaption("COGS (LCY)"):
                            Amount := CalcCostAmount(SetColumnFilter);
                        FieldCaption("Non-Invtbl. Costs (LCY)"):
                            Amount := CalcCostAmountNonInvnt(SetColumnFilter);
                        FieldCaption("Profit (LCY)"):
                            Amount := CalcSalesAmount(SetColumnFilter) +
                              CalcCostAmount(SetColumnFilter) +
                              CalcCostAmountNonInvnt(SetColumnFilter);
                        FieldCaption("Profit %"):
                            if CalcSalesAmount(SetColumnFilter) <> 0 then
                                Amount := Round(100 * (CalcSalesAmount(SetColumnFilter) +
                                                       CalcCostAmount(SetColumnFilter) +
                                                       CalcCostAmountNonInvnt(SetColumnFilter)) /
                                    CalcSalesAmount(SetColumnFilter))
                            else
                                Amount := 0;
                        FieldCaption("Direct Cost (LCY)"), FieldCaption("Revaluation (LCY)"),
                      FieldCaption("Rounding (LCY)"), FieldCaption("Indirect Cost (LCY)"),
                      FieldCaption("Variance (LCY)"), FieldCaption("Inventory (LCY)"),
                      FieldCaption("Inventoriable Costs, Total"):
                            Amount := CalcCostAmount(SetColumnFilter);
                        else
                            Amount := 0;
                    end;
                "Line Option"::"Sales Item Charge Spec.":
                    Amount := CalcSalesAmount(SetColumnFilter);
                "Line Option"::"Purch. Item Charge Spec.":
                    Amount := CalcCostAmount(SetColumnFilter);
            end;
            if PerUnit then begin
                if ("Line Option" = "Line Option"::"Profit Calculation") and
                   (Rec.Name = FieldCaption("Profit %"))
                then
                    Qty := 1
                else
                    Qty := CalcQty(SetColumnFilter);
                if Qty <> 0 then
                    Amount := Amount / Abs(Qty)
                else
                    Amount := 0;
            end;
            if Rec.Name <> FieldCaption("Profit %") then
                Amount := MatrixMgt.RoundAmount(Amount, RoundingFactor);
        end;

        OnAfterCalculate(ItemBuffer, SetColumnFilter, Amount, Rec.Name, CalcSalesAmount(SetColumnFilter));
    end;

    local procedure CalcSalesAmount(SetColumnFilter: Boolean): Decimal
    begin
        SetCommonFilters(ItemBuffer);
        SetFilters(ItemBuffer, 0);
        if SetColumnFilter then
            SetFilters(ItemBuffer, 1);
        if IncludeExpected then begin
            ItemBuffer.CalcFields("Sales Amount (Actual)", "Sales Amount (Expected)");
            exit(ItemBuffer."Sales Amount (Actual)" + ItemBuffer."Sales Amount (Expected)");
        end;
        ItemBuffer.CalcFields("Sales Amount (Actual)");
        exit(ItemBuffer."Sales Amount (Actual)");
    end;

    local procedure CalcCostAmount(SetColumnFilter: Boolean): Decimal
    begin
        SetCommonFilters(ItemBuffer);
        SetFilters(ItemBuffer, 0);
        if SetColumnFilter then
            SetFilters(ItemBuffer, 1);
        if IncludeExpected then begin
            ItemBuffer.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
            exit(ItemBuffer."Cost Amount (Actual)" + ItemBuffer."Cost Amount (Expected)");
        end;
        ItemBuffer.CalcFields("Cost Amount (Actual)");
        exit(ItemBuffer."Cost Amount (Actual)");
    end;

    local procedure CalcCostAmountNonInvnt(SetColumnFilter: Boolean): Decimal
    var
        ValueEntry: Record "Value Entry";
        TotalCostAmountNonInvnt: Decimal;
    begin
        SetCommonFilters(ItemBuffer);
        SetFilters(ItemBuffer, 0);
        if SetColumnFilter then
            SetFilters(ItemBuffer, 1);
        ItemBuffer.SetRange("Item Ledger Entry Type Filter");

        CopyValueEntryFilters(ValueEntry);
        if ValueEntry.FindSet() then
            repeat
                case ValueEntry."Document Type" of
                    ValueEntry."Document Type"::"Purchase Credit Memo":
                        TotalCostAmountNonInvnt -= ValueEntry."Cost Amount (Non-Invtbl.)";
                    ValueEntry."Document Type"::"Purchase Invoice":
                        TotalCostAmountNonInvnt += GetSign(ValueEntry) * ValueEntry."Cost Amount (Non-Invtbl.)"
                    else
                        TotalCostAmountNonInvnt += ValueEntry."Cost Amount (Non-Invtbl.)";
                end;
            until ValueEntry.Next() = 0;

        exit(TotalCostAmountNonInvnt);
    end;

    local procedure CalcQty(SetColumnFilter: Boolean): Decimal
    begin
        SetCommonFilters(ItemBuffer);
        SetFilters(ItemBuffer, 0);
        if SetColumnFilter then
            SetFilters(ItemBuffer, 1);
        ItemBuffer.SetRange("Entry Type Filter");
        ItemBuffer.SetRange("Item Charge No. Filter");
        if IncludeExpected then begin
            ItemBuffer.CalcFields(Quantity);
            exit(ItemBuffer.Quantity);
        end;
        ItemBuffer.CalcFields("Invoiced Quantity");
        exit(ItemBuffer."Invoiced Quantity");
    end;

    procedure SetItem(var NewItem: Record Item)
    begin
        Item.Get(NewItem."No.");
        Item.CopyFilters(NewItem);
    end;

    procedure LoadMatrix(NewMatrixColumns: array[32] of Text[1024]; var NewMatrixRecords: array[32] of Record "Dimension Code Buffer"; CurrentNoOfMatrixColumns: Integer; NewRoundingFactor: Enum "Analysis Rounding Factor"; NewPerUnit: Boolean; NewIncludeExpected: Boolean; NewItemBuffer: Record "Item Statistics Buffer"; NewItem: Record Item; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type"; NewColumnDimCode: Text[30]; NewDateFilter: Text; NewItemFilter: Text; NewLocationFilter: Text; NewVariantFilter: Text)
    begin
        CopyArray(MATRIX_CaptionSet, NewMatrixColumns, 1);
        CopyArray(MatrixRecords, NewMatrixRecords, 1);
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        RoundingFactor := NewRoundingFactor;
        PerUnit := NewPerUnit;
        IncludeExpected := NewIncludeExpected;
        ItemBuffer := NewItemBuffer;
        Item := NewItem;
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        ColumnDimCode := NewColumnDimCode;
        DateFilter := NewDateFilter;
        ItemFilter := NewItemFilter;
        LocationFilter := NewLocationFilter;
        VariantFilter := NewVariantFilter;
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(RoundingFactor, false);
    end;

    local procedure MATRIX_OnDrillDown(_MATRIX_ColumnOrdinal: Integer)
    begin
        with ItemBuffer do
            if not (("Line Option" = "Line Option"::"Profit Calculation") and
                    ((Name = FieldCaption("Profit (LCY)")) or (Name = FieldCaption("Profit %"))) or
                    (("Line Option" = "Line Option"::"Cost Specification") and (Name = FieldCaption("Inventoriable Costs"))))
            then begin
                SetCommonFilters(ItemBuffer);
                SetFilters(ItemBuffer, 0);
                MATRIX_ColumnOrdinal := _MATRIX_ColumnOrdinal;
                SetFilters(ItemBuffer, 1);
                DrillDown();
            end;
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        CellAmount := Calculate(true);
        MATRIX_CellData[MATRIX_ColumnOrdinal] := CellAmount;
    end;

    local procedure MATRIX_OnFindRecord(Which: Text[1024]): Boolean
    begin
        exit(FindRec(ItemBuffer."Column Option", MatrixRecord, Which));
    end;

    local procedure MATRIX_OnNextRecord(Steps: Integer): Integer
    begin
        exit(NextRec(ItemBuffer."Column Option", MatrixRecord, Steps));
    end;

    local procedure NameOnFormat()
    begin
        NameIndent := Indentation;
    end;

    local procedure CopyValueEntryFilters(var ValueEntry: Record "Value Entry")
    begin
        ValueEntry.SetFilter("Item No.", ItemFilter);
        ValueEntry.SetFilter("Variant Code", VariantFilter);

        ValueEntry.SetFilter("Item Ledger Entry Type", ItemBuffer.GetFilter("Item Ledger Entry Type Filter"));
        ValueEntry.SetFilter("Variance Type", ItemBuffer.GetFilter("Variance Type Filter"));
        ValueEntry.SetFilter("Entry Type", ItemBuffer.GetFilter("Entry Type Filter"));
        ValueEntry.SetFilter("Global Dimension 1 Code", ItemBuffer.GetFilter("Global Dimension 1 Filter"));
        ValueEntry.SetFilter("Global Dimension 2 Code", ItemBuffer.GetFilter("Global Dimension 2 Filter"));
        ValueEntry.SetFilter("Item Charge No.", ItemBuffer.GetFilter("Item Charge No. Filter"));
        ValueEntry.SetFilter("Source Type", ItemBuffer.GetFilter("Source Type Filter"));
        ValueEntry.SetFilter("Source Code", ItemBuffer.GetFilter("Source No. Filter"));
        ValueEntry.SetFilter("Posting Date", ItemBuffer.GetFilter("Date Filter"));
        ValueEntry.SetFilter("Location Code", ItemBuffer.GetFilter("Location Filter"));
    end;

    local procedure GetSign(ValueEntry: Record "Value Entry"): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
        if (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Purchase) and
           (ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::Sale)
        then
            exit(1);
        exit(-1);
    end;

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersElseCase(var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var DimensionCodeBuffer: Record "Dimension Code Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIntegerLineSetFilter(var ItemBuffer: Record "Item Statistics Buffer"; var IntegerLine: Record "Integer");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyDimValueToBuf(var ItemBuffer: Record "Item Statistics Buffer"; var TheDimValue: Record "Integer"; var TheDimCodeBuf: Record "Dimension Code Buffer");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculate(var ItemBuffer: Record "Item Statistics Buffer"; SetColumnFilter: Boolean; var Amount: Decimal; Name: Text[100]; SalesAmount: Decimal);
    begin
    end;
}

