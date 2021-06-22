page 9297 "Inventory - G/L Recon Matrix"
{
    Caption = 'Inventory - G/L Reconciliation';
    DataCaptionExpression = GetCaption;
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
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = TotalEmphasize;
                    ToolTip = 'Specifies the name.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    Style = Strong;
                    StyleExpr = TotalEmphasize;
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    Style = Strong;
                    StyleExpr = TotalEmphasize;
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    Style = Strong;
                    StyleExpr = TotalEmphasize;
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    Style = Strong;
                    StyleExpr = TRUE;
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    Style = Strong;
                    StyleExpr = TRUE;
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    Style = Strong;
                    StyleExpr = TRUE;
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    Style = Strong;
                    StyleExpr = TRUE;
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    Visible = Field8Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Basic, Suite;
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
        MATRIX_CurrentColumnOrdinal: Integer;
    begin
        MATRIX_CurrentColumnOrdinal := 0;
        while MATRIX_CurrentColumnOrdinal < MATRIX_CurrentNoOfMatrixColumn do begin
            MATRIX_CurrentColumnOrdinal := MATRIX_CurrentColumnOrdinal + 1;
            MATRIX_OnAfterGetRecord(MATRIX_CurrentColumnOrdinal);
        end;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        with InvtReportHeader do begin
            if "Line Option" = "Line Option"::"Balance Sheet" then begin
                if (ItemFilter = '') and (LocationFilter = '') then begin
                    if ShowWarning then
                        RowIntegerLine.SetRange(Number, 1, 7)
                    else
                        RowIntegerLine.SetRange(Number, 1, 6)
                end else
                    RowIntegerLine.SetRange(Number, 1, 4)
            end else
                if "Line Option" = "Line Option"::"Income Statement" then
                    if (ItemFilter = '') and (LocationFilter = '') then begin
                        if ShowWarning then
                            RowIntegerLine.SetRange(Number, 1, 18)
                        else
                            RowIntegerLine.SetRange(Number, 1, 17)
                    end else
                        RowIntegerLine.SetRange(Number, 1, 15);
            exit(FindRec("Line Option", Rec, Which, true));
        end;
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
        exit(NextRec(InvtReportHeader."Line Option", Rec, Steps, true));
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();

        InvtReportHeader.SetFilter("Item Filter", ItemFilter);
        InvtReportHeader.SetFilter("Location Filter", LocationFilter);
        InvtReportHeader.SetFilter("Posting Date Filter", DateFilter);
        InvtReportHeader."Show Warning" := ShowWarning;

        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := Text004;
            ColumnDimCode := Text005;
        end;
        InvtReportHeader."Line Option" := DimCodeToOption(LineDimCode);
        InvtReportHeader."Column Option" := DimCodeToOption(ColumnDimCode);

        GetInvtReport.SetReportHeader(InvtReportHeader);
        GetInvtReport.Run(InvtReportEntry);
        SetVisible;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        InvtReportHeader: Record "Inventory Report Header";
        InvtReportEntry: Record "Inventory Report Entry" temporary;
        RowIntegerLine: Record "Integer";
        ColIntegerLine: Record "Integer";
        MatrixRecords: array[32] of Record "Dimension Code Buffer";
        GetInvtReport: Codeunit "Get Inventory Report";
        LineDimCode: Text[20];
        ColumnDimCode: Text[20];
        DateFilter: Text;
        Text000: Label '<Sign><Integer Thousand><Decimals,3>', Locked = true;
        ItemFilter: Text;
        LocationFilter: Text;
        CellAmount: Decimal;
        GLSetupRead: Boolean;
        Text004: Label 'Income Statement';
        Text005: Label 'Balance Sheet';
        ShowWarning: Boolean;
        Text006: Label 'Expected Cost Setup';
        Text007: Label 'Post Cost to G/L';
        Text008: Label 'Compression';
        Text009: Label 'Posting Group';
        Text010: Label 'Direct Posting';
        Text011: Label 'Posting Date';
        Text012: Label 'Closed Fiscal Year';
        Text013: Label 'Similar Accounts';
        Text014: Label 'Deleted Accounts';
        Text016: Label 'The program is not set up to use expected cost posting. Therefore, inventory interim G/L accounts are empty and this causes a difference between inventory and G/L totals.';
        CostAmountsNotPostedTxt: Label 'Some of the cost amounts in the inventory ledger have not yet been posted to the G/L. You must run the Post Cost to G/L batch job to reconcile the ledgers.';
        EntriesCompressedTxt: Label 'Some inventory or G/L entries have been date compressed.';
        ReassigningAccountsTxt: Label 'You have possibly restructured your chart of accounts by re-assigning inventory related accounts in the General or Inventory Posting Setup.';
        PostedDirectlyTxt: Label 'Some inventory costs have been posted directly to a G/L account, bypassing the inventory subledger.';
        Text021: Label 'There is a discrepancy between the posting date of the value entry and the associated G/L entry within the reporting period.';
        PostedInClosedFiscalYearTxt: Label 'Some of the cost amounts are posted in a closed fiscal year. Therefore, the inventory related totals are different from their related G/L accounts in the income statement.';
        Text023: Label 'You have possibly defined one G/L account for different inventory transactions.';
        Text024: Label 'You have possibly restructured your chart of accounts by deleting one or more inventory related G/L accounts.';
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Text[250];
        MATRIX_CaptionSet: array[32] of Text[80];
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
        TotalEmphasize: Boolean;

    local procedure DimCodeToOption(DimCode: Text[30]): Integer
    begin
        case DimCode of
            '':
                exit(-1);
            Text005:
                exit(0);
            Text004:
                exit(1);
            else
                exit(-1);
        end;
    end;

    local procedure FindRec(DimOption: Option "Balance Sheet","Income Statement"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; IsRow: Boolean): Boolean
    var
        Found: Boolean;
    begin
        case DimOption of
            DimOption::"Balance Sheet",
          DimOption::"Income Statement":
                if IsRow then begin
                    if Evaluate(RowIntegerLine.Number, DimCodeBuf.Code) then;
                    Found := RowIntegerLine.Find(Which);
                    if Found then
                        CopyDimValueToBuf(RowIntegerLine, DimCodeBuf, IsRow);
                end else begin
                    if Evaluate(ColIntegerLine.Number, DimCodeBuf.Code) then;
                    Found := ColIntegerLine.Find(Which);
                    if Found then
                        CopyDimValueToBuf(ColIntegerLine, DimCodeBuf, IsRow);
                end;
        end;
        exit(Found);
    end;

    local procedure NextRec(DimOption: Option "Balance Sheet","Income Statement"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; IsRow: Boolean): Integer
    var
        ResultSteps: Integer;
    begin
        case DimOption of
            DimOption::"Balance Sheet",
          DimOption::"Income Statement":
                if IsRow then begin
                    if Evaluate(RowIntegerLine.Number, DimCodeBuf.Code) then;
                    ResultSteps := RowIntegerLine.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(RowIntegerLine, DimCodeBuf, IsRow);
                end else begin
                    if Evaluate(ColIntegerLine.Number, DimCodeBuf.Code) then;
                    ResultSteps := ColIntegerLine.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(ColIntegerLine, DimCodeBuf, IsRow);
                end;
        end;
        exit(ResultSteps);
    end;

    local procedure CopyDimValueToBuf(var TheDimValue: Record "Integer"; var TheDimCodeBuf: Record "Dimension Code Buffer"; IsRow: Boolean)
    begin
        with InvtReportEntry do
            case true of
                ((InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Balance Sheet") and IsRow) or
              ((InvtReportHeader."Column Option" = InvtReportHeader."Column Option"::"Balance Sheet") and not IsRow):
                    case TheDimValue.Number of
                        1:
                            InsertRow('1', FieldCaption(Inventory), 0, false, TheDimCodeBuf);
                        2:
                            InsertRow('2', FieldCaption("Inventory (Interim)"), 0, false, TheDimCodeBuf);
                        3:
                            InsertRow('3', FieldCaption("WIP Inventory"), 0, false, TheDimCodeBuf);
                        4:
                            InsertRow('4', FieldCaption(Total), 0, true, TheDimCodeBuf);
                        5:
                            InsertRow('5', FieldCaption("G/L Total"), 0, true, TheDimCodeBuf);
                        6:
                            InsertRow('6', FieldCaption(Difference), 0, true, TheDimCodeBuf);
                        7:
                            InsertRow('7', FieldCaption(Warning), 0, true, TheDimCodeBuf);
                    end;
                ((InvtReportHeader."Line Option" = InvtReportHeader."Line Option"::"Income Statement") and IsRow) or
              ((InvtReportHeader."Column Option" = InvtReportHeader."Column Option"::"Income Statement") and not IsRow):
                    case TheDimValue.Number of
                        1:
                            InsertRow('1', FieldCaption("Inventory To WIP"), 0, false, TheDimCodeBuf);
                        2:
                            InsertRow('2', FieldCaption("WIP To Interim"), 0, false, TheDimCodeBuf);
                        3:
                            InsertRow('3', FieldCaption("COGS (Interim)"), 0, false, TheDimCodeBuf);
                        4:
                            InsertRow('4', FieldCaption("Direct Cost Applied"), 0, false, TheDimCodeBuf);
                        5:
                            InsertRow('5', FieldCaption("Overhead Applied"), 0, false, TheDimCodeBuf);
                        6:
                            InsertRow('6', FieldCaption("Inventory Adjmt."), 0, false, TheDimCodeBuf);
                        7:
                            InsertRow('7', FieldCaption("Invt. Accrual (Interim)"), 0, false, TheDimCodeBuf);
                        8:
                            InsertRow('8', FieldCaption(COGS), 0, false, TheDimCodeBuf);
                        9:
                            InsertRow('9', FieldCaption("Purchase Variance"), 0, false, TheDimCodeBuf);
                        10:
                            InsertRow('10', FieldCaption("Material Variance"), 0, false, TheDimCodeBuf);
                        11:
                            InsertRow('11', FieldCaption("Capacity Variance"), 0, false, TheDimCodeBuf);
                        12:
                            InsertRow('12', FieldCaption("Subcontracted Variance"), 0, false, TheDimCodeBuf);
                        13:
                            InsertRow('13', FieldCaption("Capacity Overhead Variance"), 0, false, TheDimCodeBuf);
                        14:
                            InsertRow('14', FieldCaption("Mfg. Overhead Variance"), 0, false, TheDimCodeBuf);
                        15:
                            InsertRow('15', FieldCaption(Total), 0, true, TheDimCodeBuf);
                        16:
                            InsertRow('16', FieldCaption("G/L Total"), 0, true, TheDimCodeBuf);
                        17:
                            InsertRow('17', FieldCaption(Difference), 0, true, TheDimCodeBuf);
                        18:
                            InsertRow('18', FieldCaption(Warning), 0, true, TheDimCodeBuf);
                    end;
            end
    end;

    local procedure InsertRow(Code1: Code[10]; Name1: Text[80]; Indentation1: Integer; Bold1: Boolean; var TheDimCodeBuf: Record "Dimension Code Buffer")
    begin
        with TheDimCodeBuf do begin
            Init;
            Code := Code1;
            Name := CopyStr(Name1, 1, MaxStrLen(Name));
            Indentation := Indentation1;
            "Show in Bold" := Bold1;
        end;
    end;

    local procedure Calculate(MATRIX_ColumnOrdinal: Integer) Amount: Decimal
    begin
        GetGLSetup;
        with InvtReportEntry do begin
            case true of
                FieldCaption("G/L Total") in [Name, MatrixRecords[MATRIX_ColumnOrdinal].Name]:
                    SetRange(Type, Type::"G/L Account");
                FieldCaption(Difference) in [Name, MatrixRecords[MATRIX_ColumnOrdinal].Name],
              FieldCaption(Warning) in [Name, MatrixRecords[MATRIX_ColumnOrdinal].Name]:
                    SetRange(Type, Type::" ");
                else
                    SetRange(Type, Type::Item);
            end;
            case InvtReportHeader."Line Option" of
                InvtReportHeader."Line Option"::"Balance Sheet",
              InvtReportHeader."Line Option"::"Income Statement":
                    case Name of
                        FieldCaption(Total), FieldCaption("G/L Total"), FieldCaption(Difference):
                            case MatrixRecords[MATRIX_ColumnOrdinal].Name of
                                FieldCaption(Inventory):
                                    begin
                                        CalcSums(Inventory);
                                        Amount := Inventory;
                                    end;
                                FieldCaption("WIP Inventory"):
                                    begin
                                        CalcSums("WIP Inventory");
                                        Amount := "WIP Inventory";
                                    end;
                                FieldCaption("Inventory (Interim)"):
                                    begin
                                        CalcSums("Inventory (Interim)");
                                        Amount := "Inventory (Interim)";
                                    end;
                            end;
                        FieldCaption("COGS (Interim)"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption("Inventory (Interim)"),
                                                                                FieldCaption(Difference)]
                                then begin
                                    CalcSums("COGS (Interim)");
                                    Amount := "COGS (Interim)";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Direct Cost Applied"):
                            case MatrixRecords[MATRIX_ColumnOrdinal].Name of
                                FieldCaption(Total), FieldCaption("G/L Total"), FieldCaption(Difference):
                                    begin
                                        CalcSums("Direct Cost Applied");
                                        Amount := "Direct Cost Applied";
                                    end;
                                FieldCaption(Inventory):
                                    begin
                                        CalcSums("Direct Cost Applied Actual");
                                        Amount := "Direct Cost Applied Actual";
                                    end;
                                FieldCaption("WIP Inventory"):
                                    begin
                                        CalcSums("Direct Cost Applied WIP");
                                        Amount := "Direct Cost Applied WIP";
                                    end;
                            end;
                        FieldCaption("Overhead Applied"):
                            case MatrixRecords[MATRIX_ColumnOrdinal].Name of
                                FieldCaption(Total), FieldCaption("G/L Total"), FieldCaption(Difference):
                                    begin
                                        CalcSums("Overhead Applied");
                                        Amount := "Overhead Applied";
                                    end;
                                FieldCaption(Inventory):
                                    begin
                                        CalcSums("Overhead Applied Actual");
                                        Amount := "Overhead Applied Actual";
                                    end;
                                FieldCaption("WIP Inventory"):
                                    begin
                                        CalcSums("Overhead Applied WIP");
                                        Amount := "Overhead Applied WIP";
                                    end;
                            end;
                        FieldCaption("Inventory Adjmt."):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption(Inventory), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Inventory Adjmt.");
                                    Amount := "Inventory Adjmt.";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Invt. Accrual (Interim)"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption("Inventory (Interim)"), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Invt. Accrual (Interim)");
                                    Amount := "Invt. Accrual (Interim)";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption(COGS):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption(Inventory), FieldCaption(Difference)]
                                then begin
                                    CalcSums(COGS);
                                    Amount := COGS;
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Purchase Variance"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption(Inventory), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Purchase Variance");
                                    Amount := "Purchase Variance";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Material Variance"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption(Inventory), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Material Variance");
                                    Amount := "Material Variance";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Capacity Variance"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption(Inventory), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Capacity Variance");
                                    Amount := "Capacity Variance";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Subcontracted Variance"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption(Inventory), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Subcontracted Variance");
                                    Amount := "Subcontracted Variance";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Capacity Overhead Variance"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption(Inventory), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Capacity Overhead Variance");
                                    Amount := "Capacity Overhead Variance";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Mfg. Overhead Variance"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption(Inventory), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Mfg. Overhead Variance");
                                    Amount := "Mfg. Overhead Variance";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Direct Cost Applied Actual"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption(Inventory), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Direct Cost Applied Actual");
                                    Amount := "Direct Cost Applied Actual";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Direct Cost Applied WIP"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption("WIP Inventory"), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Direct Cost Applied WIP");
                                    Amount := "Direct Cost Applied WIP";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Overhead Applied WIP"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                                FieldCaption("WIP Inventory"), FieldCaption(Difference)]
                                then begin
                                    CalcSums("Overhead Applied WIP");
                                    Amount := "Overhead Applied WIP";
                                end else
                                    Amount := 0;
                            end;
                        FieldCaption("Inventory To WIP"):
                            if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption("G/L Total"),
                                                                            FieldCaption("WIP Inventory"),
                                                                            FieldCaption(Inventory)]
                            then begin
                                CalcSums("Inventory To WIP");
                                Amount := "Inventory To WIP";
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Inventory) then
                                    Amount := -Amount;
                            end else
                                Amount := 0;
                        FieldCaption("WIP To Interim"):
                            begin
                                if MatrixRecords[MATRIX_ColumnOrdinal].Name in [FieldCaption("G/L Total"),
                                                                                FieldCaption("WIP Inventory"),
                                                                                FieldCaption("Inventory (Interim)")]
                                then begin
                                    CalcSums("WIP To Interim");
                                    Amount := "WIP To Interim";
                                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption("WIP Inventory") then
                                        Amount := -Amount;
                                end else
                                    Amount := 0;
                            end;
                    end;
            end;
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure GetWarningText(TheField: Text[80]; ShowType: Option ReturnAsText,ShowAsMessage): Text[250]
    begin
        with InvtReportEntry do begin
            if "Expected Cost Posting Warning" then
                if TheField in [FieldCaption("Inventory (Interim)"),
                                FieldCaption("Invt. Accrual (Interim)"),
                                FieldCaption("COGS (Interim)"),
                                FieldCaption("Invt. Accrual (Interim)"),
                                FieldCaption("WIP Inventory")]
                then begin
                    if ShowType = ShowType::ReturnAsText then
                        exit(Text006);
                    exit(Text016);
                end;
            if "Cost is Posted to G/L Warning" then begin
                if ShowType = ShowType::ReturnAsText then
                    exit(Text007);
                exit(CostAmountsNotPostedTxt);
            end;
            if "Compression Warning" then begin
                if ShowType = ShowType::ReturnAsText then
                    exit(Text008);
                exit(EntriesCompressedTxt);
            end;
            if "Posting Group Warning" then begin
                if ShowType = ShowType::ReturnAsText then
                    exit(Text009);
                exit(ReassigningAccountsTxt);
            end;
            if "Direct Postings Warning" then begin
                if ShowType = ShowType::ReturnAsText then
                    exit(Text010);
                exit(PostedDirectlyTxt);
            end;
            if "Posting Date Warning" then begin
                if ShowType = ShowType::ReturnAsText then
                    exit(Text011);
                exit(Text021);
            end;
            if "Closing Period Overlap Warning" then begin
                if ShowType = ShowType::ReturnAsText then
                    exit(Text012);
                exit(PostedInClosedFiscalYearTxt);
            end;
            if "Similar Accounts Warning" then begin
                if ShowType = ShowType::ReturnAsText then
                    exit(Text013);
                exit(Text023);
            end;
            if "Deleted G/L Accounts Warning" then begin
                if ShowType = ShowType::ReturnAsText then
                    exit(Text014);
                exit(Text024);
            end;
        end;
    end;

    local procedure ShowWarningText(ShowType: Option ReturnAsText,ShowAsMessage; MATRIX_ColumnOrdinal: Integer): Text[250]
    var
        Text: Text[250];
    begin
        with InvtReportEntry do
            case Name of
                FieldCaption(Warning):
                    case MatrixRecords[MATRIX_ColumnOrdinal].Name of
                        FieldCaption(Inventory):
                            if Inventory <> 0 then
                                Text := GetWarningText(FieldCaption(Inventory), ShowType);
                        FieldCaption("WIP Inventory"):
                            if "WIP Inventory" <> 0 then
                                Text := GetWarningText(FieldCaption("WIP Inventory"), ShowType);
                        FieldCaption("Inventory (Interim)"):
                            if "Inventory (Interim)" <> 0 then
                                Text := GetWarningText(FieldCaption("Inventory (Interim)"), ShowType);
                    end;
                FieldCaption("COGS (Interim)"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "COGS (Interim)" <> 0 then
                            Text := GetWarningText(FieldCaption("COGS (Interim)"), ShowType);
                FieldCaption("Direct Cost Applied"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Direct Cost Applied" <> 0 then
                            Text := GetWarningText(FieldCaption("Direct Cost Applied"), ShowType);
                FieldCaption("Overhead Applied"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Overhead Applied" <> 0 then
                            Text := GetWarningText(FieldCaption("Overhead Applied"), ShowType);
                FieldCaption("Inventory Adjmt."):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Inventory Adjmt." <> 0 then
                            Text := GetWarningText(FieldCaption("Inventory Adjmt."), ShowType);
                FieldCaption("Invt. Accrual (Interim)"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Invt. Accrual (Interim)" <> 0 then
                            Text := GetWarningText(FieldCaption("Invt. Accrual (Interim)"), ShowType);
                FieldCaption(COGS):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if COGS <> 0 then
                            Text := GetWarningText(FieldCaption(COGS), ShowType);
                FieldCaption("Purchase Variance"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Purchase Variance" <> 0 then
                            Text := GetWarningText(FieldCaption("Purchase Variance"), ShowType);
                FieldCaption("Material Variance"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Material Variance" <> 0 then
                            Text := GetWarningText(FieldCaption("Material Variance"), ShowType);
                FieldCaption("Capacity Variance"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Capacity Variance" <> 0 then
                            Text := GetWarningText(FieldCaption("Capacity Variance"), ShowType);
                FieldCaption("Subcontracted Variance"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Subcontracted Variance" <> 0 then
                            Text := GetWarningText(FieldCaption("Subcontracted Variance"), ShowType);
                FieldCaption("Capacity Overhead Variance"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Capacity Overhead Variance" <> 0 then
                            Text := GetWarningText(FieldCaption("Capacity Overhead Variance"), ShowType);
                FieldCaption("Mfg. Overhead Variance"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Mfg. Overhead Variance" <> 0 then
                            Text := GetWarningText(FieldCaption("Mfg. Overhead Variance"), ShowType);
                FieldCaption("Direct Cost Applied Actual"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Direct Cost Applied Actual" <> 0 then
                            Text := GetWarningText(FieldCaption("Direct Cost Applied Actual"), ShowType);
                FieldCaption("Direct Cost Applied WIP"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Direct Cost Applied WIP" <> 0 then
                            Text := GetWarningText(FieldCaption("Direct Cost Applied WIP"), ShowType);
                FieldCaption("Overhead Applied WIP"):
                    if MatrixRecords[MATRIX_ColumnOrdinal].Name = FieldCaption(Warning) then
                        if "Overhead Applied WIP" <> 0 then
                            Text := GetWarningText(FieldCaption("Overhead Applied WIP"), ShowType);
            end;

        if ShowType = ShowType::ReturnAsText then
            exit(Text);
        Message(Text);
    end;

    local procedure GetCaption(): Text[250]
    var
        ObjTransl: Record "Object Translation";
        SourceTableName: Text[100];
        LocationTableName: Text[100];
    begin
        SourceTableName := '';
        LocationTableName := '';
        if ItemFilter <> '' then
            SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 27);
        if LocationFilter <> '' then
            LocationTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 14);
        exit(StrSubstNo('%1 %2 %3 %4', SourceTableName, ItemFilter, LocationTableName, LocationFilter));
    end;

    procedure Load(MatrixColumns1: array[32] of Text[100]; var MatrixRecords1: array[32] of Record "Dimension Code Buffer"; CurrentNoOfMatrixColumns: Integer; ShowWarningLocal: Boolean; DateFilterLocal: Text; ItemFilterLocal: Text; LocationFilterLocal: Text)
    begin
        CopyArray(MATRIX_CaptionSet, MatrixColumns1, 1);
        CopyArray(MatrixRecords, MatrixRecords1, 1);
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        ShowWarning := ShowWarningLocal;
        DateFilter := DateFilterLocal;
        ItemFilter := ItemFilterLocal;
        LocationFilter := LocationFilterLocal;
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    begin
        GetGLSetup;

        with InvtReportEntry do begin
            if FieldCaption(Warning) = MATRIX_CaptionSet[MATRIX_ColumnOrdinal] then begin
                ShowWarningText(1, MATRIX_ColumnOrdinal);
                exit;
            end;

            Reset;
            if FieldCaption("G/L Total") in [MATRIX_CaptionSet[MATRIX_ColumnOrdinal], Name] then
                SetRange(Type, Type::"G/L Account")
            else
                SetRange(Type, Type::Item);

            SetFilter("Posting Date Filter", InvtReportHeader.GetFilter("Posting Date Filter"));
            SetFilter("Location Filter", InvtReportHeader.GetFilter("Location Filter"));

            if FieldCaption(Warning) in [Name, MATRIX_CaptionSet[MATRIX_ColumnOrdinal]] then begin
                ShowWarningText(1, MATRIX_ColumnOrdinal);
                exit;
            end;

            case InvtReportHeader."Line Option" of
                InvtReportHeader."Line Option"::"Balance Sheet",
              InvtReportHeader."Line Option"::"Income Statement":
                    case Name of
                        FieldCaption(Total), FieldCaption("G/L Total"):
                            case MATRIX_CaptionSet[MATRIX_ColumnOrdinal] of
                                FieldCaption(Inventory):
                                    begin
                                        SetFilter(Inventory, '<>%1', 0);
                                        PAGE.Run(0, InvtReportEntry, Inventory);
                                    end;
                                FieldCaption("WIP Inventory"):
                                    begin
                                        SetFilter("WIP Inventory", '<>%1', 0);
                                        PAGE.Run(0, InvtReportEntry, "WIP Inventory");
                                    end;
                                FieldCaption("Inventory (Interim)"):
                                    begin
                                        SetFilter("Inventory (Interim)", '<>%1', 0);
                                        PAGE.Run(0, InvtReportEntry, "Inventory (Interim)");
                                    end;
                            end;
                        FieldCaption("COGS (Interim)"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption("Inventory (Interim)")]
                            then begin
                                SetFilter("COGS (Interim)", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "COGS (Interim)");
                            end;
                        FieldCaption("Direct Cost Applied"):
                            case MATRIX_CaptionSet[MATRIX_ColumnOrdinal] of
                                FieldCaption(Total), FieldCaption("G/L Total"):
                                    begin
                                        SetFilter("Direct Cost Applied", '<>%1', 0);
                                        PAGE.Run(0, InvtReportEntry, "Direct Cost Applied");
                                    end;
                                FieldCaption(Inventory):
                                    begin
                                        SetFilter("Direct Cost Applied Actual", '<>%1', 0);
                                        PAGE.Run(0, InvtReportEntry, "Direct Cost Applied Actual");
                                    end;
                                FieldCaption("WIP Inventory"):
                                    begin
                                        SetFilter("Direct Cost Applied WIP", '<>%1', 0);
                                        PAGE.Run(0, InvtReportEntry, "Direct Cost Applied WIP");
                                    end;
                            end;
                        FieldCaption("Overhead Applied"):
                            case MATRIX_CaptionSet[MATRIX_ColumnOrdinal] of
                                FieldCaption(Total), FieldCaption("G/L Total"):
                                    begin
                                        SetFilter("Overhead Applied", '<>%1', 0);
                                        PAGE.Run(0, InvtReportEntry, "Overhead Applied");
                                    end;
                                FieldCaption(Inventory):
                                    begin
                                        SetFilter("Overhead Applied Actual", '<>%1', 0);
                                        PAGE.Run(0, InvtReportEntry, "Overhead Applied Actual");
                                    end;
                                FieldCaption("WIP Inventory"):
                                    begin
                                        SetFilter("Overhead Applied WIP", '<>%1', 0);
                                        PAGE.Run(0, InvtReportEntry, "Overhead Applied WIP");
                                    end;
                            end;
                        FieldCaption("Inventory Adjmt."):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption(Inventory)]
                            then begin
                                SetFilter("Inventory Adjmt.", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Inventory Adjmt.");
                            end;
                        FieldCaption("Invt. Accrual (Interim)"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption("Inventory (Interim)")]
                            then begin
                                SetFilter("Invt. Accrual (Interim)", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Invt. Accrual (Interim)");
                            end;
                        FieldCaption(COGS):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption(Inventory)]
                            then begin
                                SetFilter(COGS, '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, COGS);
                            end;
                        FieldCaption("Purchase Variance"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption(Inventory)]
                            then begin
                                SetFilter("Purchase Variance", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Purchase Variance");
                            end;
                        FieldCaption("Material Variance"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption(Inventory)]
                            then begin
                                SetFilter("Material Variance", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Material Variance");
                            end;
                        FieldCaption("Capacity Variance"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption(Inventory)]
                            then begin
                                SetFilter("Capacity Variance", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Capacity Variance");
                            end;
                        FieldCaption("Subcontracted Variance"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption(Inventory)]
                            then begin
                                SetFilter("Subcontracted Variance", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Subcontracted Variance");
                            end;
                        FieldCaption("Capacity Overhead Variance"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption(Inventory)]
                            then begin
                                SetFilter("Capacity Overhead Variance", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Capacity Overhead Variance");
                            end;
                        FieldCaption("Mfg. Overhead Variance"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption(Inventory)]
                            then begin
                                SetFilter("Mfg. Overhead Variance", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Mfg. Overhead Variance");
                            end;
                        FieldCaption("Direct Cost Applied Actual"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption(Inventory)]
                            then begin
                                SetFilter("Direct Cost Applied Actual", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Direct Cost Applied Actual");
                            end;
                        FieldCaption("Direct Cost Applied WIP"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption("WIP Inventory")]
                            then begin
                                SetFilter("Direct Cost Applied WIP", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Direct Cost Applied WIP");
                            end;
                        FieldCaption("Overhead Applied WIP"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption(Total), FieldCaption("G/L Total"),
                                                                           FieldCaption("WIP Inventory")]
                            then begin
                                SetFilter("Overhead Applied WIP", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Overhead Applied WIP");
                            end;
                        FieldCaption("Inventory To WIP"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption("G/L Total"),
                                                                           FieldCaption("WIP Inventory"), FieldCaption(Inventory)]
                            then begin
                                SetFilter("Inventory To WIP", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "Inventory To WIP");
                            end;
                        FieldCaption("WIP To Interim"):
                            if MATRIX_CaptionSet[MATRIX_ColumnOrdinal] in [FieldCaption("G/L Total"),
                                                                           FieldCaption("WIP Inventory"),
                                                                           FieldCaption("Inventory (Interim)")]
                            then begin
                                SetFilter("WIP To Interim", '<>%1', 0);
                                PAGE.Run(0, InvtReportEntry, "WIP To Interim");
                            end;
                    end;
            end;
            Reset;
        end;
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        CellAmount := Calculate(MATRIX_ColumnOrdinal);
        if CellAmount <> 0 then
            MATRIX_CellData[MATRIX_ColumnOrdinal] := Format(CellAmount, 0, Text000)
        else
            MATRIX_CellData[MATRIX_ColumnOrdinal] := '';

        with InvtReportEntry do begin
            TotalEmphasize := "Show in Bold";

            if FieldCaption(Warning) in [Name, MatrixRecords[MATRIX_ColumnOrdinal].Name] then begin
                SetRange(Type, Type::" ");
                if FindFirst then;
                case InvtReportHeader."Line Option" of
                    InvtReportHeader."Line Option"::"Balance Sheet",
                  InvtReportHeader."Line Option"::"Income Statement":
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := ShowWarningText(0, MATRIX_ColumnOrdinal);
                end;
            end;
        end;
    end;

    procedure SetVisible()
    begin
        Field1Visible := MATRIX_CaptionSet[1] <> '';
        Field2Visible := MATRIX_CaptionSet[2] <> '';
        Field3Visible := MATRIX_CaptionSet[3] <> '';
        Field4Visible := MATRIX_CaptionSet[4] <> '';
        Field5Visible := MATRIX_CaptionSet[5] <> '';
        Field6Visible := MATRIX_CaptionSet[6] <> '';
        Field7Visible := MATRIX_CaptionSet[7] <> '';
        Field8Visible := MATRIX_CaptionSet[8] <> '';
        Field9Visible := MATRIX_CaptionSet[9] <> '';
        Field10Visible := MATRIX_CaptionSet[10] <> '';
        Field11Visible := MATRIX_CaptionSet[11] <> '';
        Field12Visible := MATRIX_CaptionSet[12] <> '';
        Field13Visible := MATRIX_CaptionSet[13] <> '';
        Field14Visible := MATRIX_CaptionSet[14] <> '';
        Field15Visible := MATRIX_CaptionSet[15] <> '';
        Field16Visible := MATRIX_CaptionSet[16] <> '';
        Field17Visible := MATRIX_CaptionSet[17] <> '';
        Field18Visible := MATRIX_CaptionSet[18] <> '';
        Field19Visible := MATRIX_CaptionSet[19] <> '';
        Field20Visible := MATRIX_CaptionSet[20] <> '';
        Field21Visible := MATRIX_CaptionSet[21] <> '';
        Field22Visible := MATRIX_CaptionSet[22] <> '';
        Field23Visible := MATRIX_CaptionSet[23] <> '';
        Field24Visible := MATRIX_CaptionSet[24] <> '';
        Field25Visible := MATRIX_CaptionSet[25] <> '';
        Field26Visible := MATRIX_CaptionSet[26] <> '';
        Field27Visible := MATRIX_CaptionSet[27] <> '';
        Field28Visible := MATRIX_CaptionSet[28] <> '';
        Field29Visible := MATRIX_CaptionSet[29] <> '';
        Field30Visible := MATRIX_CaptionSet[30] <> '';
        Field31Visible := MATRIX_CaptionSet[31] <> '';
        Field32Visible := MATRIX_CaptionSet[32] <> '';
    end;
}

