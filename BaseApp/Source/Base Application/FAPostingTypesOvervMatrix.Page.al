page 9277 "FA Posting Types Overv. Matrix"
{
    Caption = 'FA Posting Types Overv. Matrix';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "FA Depreciation Book";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA No."; "FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                }
                field("Depreciation Book Code"; "Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation Book Code';
                    ToolTip = 'Specifies a depreciation book to assign to the fixed asset you have entered in the FA No. field.';
                }
                field(Description; Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the value in the Description field on the fixed asset card.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[1];
                    DrillDown = true;
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[2];
                    DrillDown = true;
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[3];
                    DrillDown = true;
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[4];
                    DrillDown = true;
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[5];
                    DrillDown = true;
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[6];
                    DrillDown = true;
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[7];
                    DrillDown = true;
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[8];
                    DrillDown = true;
                    Visible = Field8Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[9];
                    DrillDown = true;
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[10];
                    DrillDown = true;
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[11];
                    DrillDown = true;
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[12];
                    DrillDown = true;
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[13];
                    DrillDown = true;
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[14];
                    DrillDown = true;
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[15];
                    DrillDown = true;
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[16];
                    DrillDown = true;
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[17];
                    DrillDown = true;
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[18];
                    DrillDown = true;
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[19];
                    DrillDown = true;
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[20];
                    DrillDown = true;
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[21];
                    DrillDown = true;
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[22];
                    DrillDown = true;
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[23];
                    DrillDown = true;
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[24];
                    DrillDown = true;
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[25];
                    DrillDown = true;
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[26];
                    DrillDown = true;
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[27];
                    DrillDown = true;
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[28];
                    DrillDown = true;
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[29];
                    DrillDown = true;
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[30];
                    DrillDown = true;
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[31];
                    DrillDown = true;
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        MATRIX_OnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = All;
                    AutoFormatExpression = FormatStr;
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + MATRIX_CaptionSet[32];
                    DrillDown = true;
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
        area(navigation)
        {
            group("&Related Information")
            {
                Caption = '&Related Information';
                Image = RelatedInformation;
                action("Ledger E&ntries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ledger E&ntries';
                    Image = FixedAssetLedger;
                    Promoted = false;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    trigger OnAction()
                    var
                        FALedgEntry: Record "FA Ledger Entry";
                    begin
                        FALedgEntry.SetRange("FA No.", "FA No.");
                        FALedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code");

                        PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
                    end;
                }
                action("Error Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Error Ledger Entries';
                    Image = ErrorFALedgerEntries;
                    ToolTip = 'View the entries that have been posted as a result of you using the cancel function to cancel an entry.';

                    trigger OnAction()
                    var
                        FALedgEntry: Record "FA Ledger Entry";
                    begin
                        FALedgEntry.SetRange("Canceled from FA No.", "FA No.");
                        FALedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                        FALedgEntry.SetCurrentKey("Canceled from FA No.", "Depreciation Book Code");

                        PAGE.Run(PAGE::"FA Error Ledger Entries", FALedgEntry);
                    end;
                }
                action("Maintenance Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance Ledger Entries';
                    Image = MaintenanceLedgerEntries;
                    ToolTip = 'View the maintenance ledger entries for the selected fixed asset.';

                    trigger OnAction()
                    var
                        MaintLedgEntry: Record "Maintenance Ledger Entry";
                    begin
                        MaintLedgEntry.SetRange("FA No.", "FA No.");
                        MaintLedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                        MaintLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code");

                        PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintLedgEntry);
                    end;
                }
                separator(Action11)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';
                    ToolTip = 'View detailed historical information about the fixed asset.';

                    trigger OnAction()
                    var
                        FADeprBook: Record "FA Depreciation Book";
                    begin
                        FADeprBook.SetRange("FA No.", "FA No.");
                        FADeprBook.SetRange("Depreciation Book Code", "Depreciation Book Code");

                        PAGE.Run(PAGE::"Fixed Asset Statistics", FADeprBook);
                    end;
                }
                action("Main &Asset Statistics")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Main &Asset Statistics';
                    Image = StatisticsDocument;
                    ToolTip = 'View statistics for all the components that make up the main asset for the selected book. The left side of the General FastTab displays the main asset''s book value, depreciable basis and any maintenance expenses posted to the components that comprise the main asset. The right side shows the number of components for the main asset, the first date on which an acquisition and/or disposal entry was posted to one of the assets that comprise the main asset.';

                    trigger OnAction()
                    var
                        FADeprBook: Record "FA Depreciation Book";
                    begin
                        FADeprBook.SetRange("FA No.", "FA No.");
                        FADeprBook.SetRange("Depreciation Book Code", "Depreciation Book Code");

                        PAGE.Run(PAGE::"Main Asset Statistics", FADeprBook);
                    end;
                }
            }
        }
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

    trigger OnOpenPage()
    begin
        MATRIX_CurrentNoOfMatrixColumn := 32;
    end;

    var
        MatrixRecords: array[32] of Record "FA Matrix Posting Type";
        FALedgerEntry: Record "FA Ledger Entry";
        DP_Book2: Record "FA Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        MatrixMgt: Codeunit "Matrix Management";
        RoundingFactor: Option "None","1","1000","1000000";
        MATRIX_CurrentNoOfMatrixColumn: Integer;
        MATRIX_CellData: array[32] of Decimal;
        MATRIX_CaptionSet: array[32] of Text[80];
        DateFilter: Text;
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

    procedure Load(MatrixColumns1: array[32] of Text[80]; var MatrixRecords1: array[32] of Record "FA Matrix Posting Type"; CurrentNoOfMatrixColumns: Integer; DateFilterLocal: Text; RoundingFactorLocal: Option "None","1","1000","1000000")
    var
        i: Integer;
    begin
        for i := 1 to CurrentNoOfMatrixColumns do begin
            MATRIX_CaptionSet[i] := MatrixColumns1[i];
            MatrixRecords[i] := MatrixRecords1[i];
        end;
        MATRIX_CurrentNoOfMatrixColumn := CurrentNoOfMatrixColumns;
        DateFilter := DateFilterLocal;
        RoundingFactor := RoundingFactorLocal;
        RoundingFactorFormatString := MatrixMgt.GetFormatString(RoundingFactor, false);
    end;

    local procedure MATRIX_OnDrillDown(MATRIX_ColumnOrdinal: Integer)
    begin
        DP_Book2.SetRange("FA No.", "FA No.");
        DP_Book2.SetRange("Depreciation Book Code", "Depreciation Book Code");

        if DP_Book2.FindFirst then
            FALedgerEntry.SetRange("Depreciation Book Code", DP_Book2."Depreciation Book Code")
        else
            FALedgerEntry.SetRange("Depreciation Book Code");
        FALedgerEntry.SetFilter("FA Posting Date", DateFilter);
        FALedgerEntry.SetRange("FA No.", "FA No.");

        case MatrixRecords[MATRIX_ColumnOrdinal]."Entry No." of
            1:// 'Book Value'
                begin
                    FALedgerEntry.SetRange("Part of Book Value", true);
                    PAGE.Run(0, FALedgerEntry);
                end;
            2:// 'Acquisition Cost'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
                    PAGE.Run(0, FALedgerEntry);
                end;
            3:// 'Depreciation'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
                    PAGE.Run(0, FALedgerEntry);
                end;
            4:// 'Write-Down'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Write-Down");
                    PAGE.Run(0, FALedgerEntry);
                end;
            5:// 'Appreciation'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Appreciation);
                    PAGE.Run(0, FALedgerEntry);
                end;
            6:// 'Custom 1'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Custom 1");
                    PAGE.Run(0, FALedgerEntry);
                end;
            7:// 'Custom 2'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Custom 2");
                    PAGE.Run(0, FALedgerEntry);
                end;
            8:// 'Proceeds on Disposal'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal");
                    PAGE.Run(0, FALedgerEntry);
                end;
            9:// 'Gain/Loss'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Gain/Loss");
                    PAGE.Run(0, FALedgerEntry);
                end;
            10:// 'Depreciable Basis'
                begin
                    FALedgerEntry.SetRange("Part of Depreciable Basis", true);
                    PAGE.Run(0, FALedgerEntry);
                end;
            11:// 'Salvage Value'
                begin
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Salvage Value");
                    PAGE.Run(0, FALedgerEntry);
                end;
        end;
    end;

    local procedure MATRIX_OnAfterGetRecord(MATRIX_ColumnOrdinal: Integer)
    begin
        with FADeprBook do begin
            SetFilter("FA Posting Date Filter", DateFilter);
            SetRange("FA No.", Rec."FA No.");
            SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
            case MatrixRecords[MATRIX_ColumnOrdinal]."Entry No." of
                1:// 'Book Value'
                    begin
                        if FindFirst then
                            CalcBookValue;
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue("Book Value", RoundingFactor);
                    end;
                10:// 'Depreciable Basis'
                    begin
                        if FindFirst then
                            CalcFields("Depreciable Basis");
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue("Depreciable Basis", RoundingFactor);
                    end;
                2:// 'Acquisition Cost'
                    begin
                        if FindFirst then
                            CalcFields("Acquisition Cost");
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue("Acquisition Cost", RoundingFactor);
                    end;
                3:// 'Depreciation'
                    begin
                        if FindFirst then
                            CalcFields(Depreciation);
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue(Depreciation, RoundingFactor);
                    end;
                4:// 'Write-Down'
                    begin
                        if FindFirst then
                            CalcFields("Write-Down");
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue("Write-Down", RoundingFactor);
                    end;
                5:// 'Appreciation'
                    begin
                        if FindFirst then
                            CalcFields(Appreciation);
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue(Appreciation, RoundingFactor);
                    end;
                6:// 'Custom 1'
                    begin
                        if FindFirst then
                            CalcFields("Custom 1");
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue("Custom 1", RoundingFactor);
                    end;
                7:// 'Custom 2'
                    begin
                        if FindFirst then
                            CalcFields("Custom 2");
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue("Custom 2", RoundingFactor);
                    end;
                9:// 'Gain/Loss'
                    begin
                        if FindFirst then
                            CalcFields("Gain/Loss");
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue("Gain/Loss", RoundingFactor);
                    end;
                8:// 'Proceeds on Disposal'
                    begin
                        if FindFirst then
                            CalcFields("Proceeds on Disposal");
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue("Proceeds on Disposal", RoundingFactor);
                    end;
                11:// 'Salvage Value'
                    begin
                        if FindFirst then
                            CalcFields("Salvage Value");
                        MATRIX_CellData[MATRIX_ColumnOrdinal] := MatrixMgt.RoundValue("Salvage Value", RoundingFactor);
                    end;
            end;
        end;

        SetVisible;
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

    local procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;
}

