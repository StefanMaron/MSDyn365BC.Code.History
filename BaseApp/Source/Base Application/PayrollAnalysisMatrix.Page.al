page 35661 "Payroll Analysis Matrix"
{
    Caption = 'Payroll Analysis Matrix';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Payroll Analysis Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Row No."; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Field1; MatrixData[1])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[1];
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(1);
                    end;
                }
                field(Field2; MatrixData[2])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[2];
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(2);
                    end;
                }
                field(Field3; MatrixData[3])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[3];
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(3);
                    end;
                }
                field(Field4; MatrixData[4])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[4];
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(4);
                    end;
                }
                field(Field5; MatrixData[5])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[5];
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(5);
                    end;
                }
                field(Field6; MatrixData[6])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[6];
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(6);
                    end;
                }
                field(Field7; MatrixData[7])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[7];
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(7);
                    end;
                }
                field(Field8; MatrixData[8])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[8];
                    Visible = Field8Visible;

                    trigger OnAssistEdit()
                    begin
                        FieldDrillDown(8);
                    end;
                }
                field(Field9; MatrixData[9])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[9];
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(9);
                    end;
                }
                field(Field10; MatrixData[10])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[10];
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(10);
                    end;
                }
                field(Field11; MatrixData[11])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[11];
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(11);
                    end;
                }
                field(Field12; MatrixData[12])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[12];
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(12);
                    end;
                }
                field(Field13; MatrixData[13])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[13];
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(13);
                    end;
                }
                field(Field14; MatrixData[14])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[14];
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(14);
                    end;
                }
                field(Field15; MatrixData[15])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[15];
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(15);
                    end;
                }
                field(Field16; MatrixData[16])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[16];
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(16);
                    end;
                }
                field(Field17; MatrixData[17])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[17];
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(17);
                    end;
                }
                field(Field18; MatrixData[18])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[18];
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(18);
                    end;
                }
                field(Field19; MatrixData[19])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[19];
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(19);
                    end;
                }
                field(Field20; MatrixData[20])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[20];
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(20);
                    end;
                }
                field(Field21; MatrixData[21])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[21];
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(21);
                    end;
                }
                field(Field22; MatrixData[22])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[22];
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(22);
                    end;
                }
                field(Field23; MatrixData[23])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[23];
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(23);
                    end;
                }
                field(Field24; MatrixData[24])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[24];
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(24);
                    end;
                }
                field(Field25; MatrixData[25])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[25];
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(25);
                    end;
                }
                field(Field26; MatrixData[26])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[26];
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(26);
                    end;
                }
                field(Field27; MatrixData[27])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[27];
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(27);
                    end;
                }
                field(Field28; MatrixData[28])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[28];
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(28);
                    end;
                }
                field(Field29; MatrixData[29])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[29];
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(29);
                    end;
                }
                field(Field30; MatrixData[30])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[30];
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(30);
                    end;
                }
                field(Field31; MatrixData[31])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[31];
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(31);
                    end;
                }
                field(Field32; MatrixData[32])
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    CaptionClass = '3,' + MatrixColumnCaptions[32];
                    Visible = Field32Visible;

                    trigger OnDrillDown()
                    begin
                        FieldDrillDown(32);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        i := 1;

        if PayrollAnalysisColumn.Find('-') then begin
            repeat
                if i <= ArrayLen(MatrixData) then begin
                    if Expression = '' then
                        MatrixData[i] := 0
                    else
                        MatrixData[i] := PayrollAnalysisReportMgt.CalcCell(Rec, PayrollAnalysisColumn, false);
                    CachedFormattedText[i] := Format(MatrixData[i]);
                    CachedContainsError[i] := FindError(MatrixData[i], CachedFormattedText[i]);
                end;
                i := i + 1;
            until PayrollAnalysisColumn.Next = 0;
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
        PayrollAnalysisColumn.SetRange("Analysis Column Template", PayrollAnalysisColumn."Analysis Column Template");
        PayrollAnalysisColumn.SetRange("Line No.", FirstLineNo, LastLineNo);
        SetVisible;
    end;

    var
        PayrollAnalysisColumn: Record "Payroll Analysis Column";
        PayrollAnalysisColumn2: Record "Payroll Analysis Column";
        PayrollAnalysisReportMgt: Codeunit "Payroll Analysis Report Mgt.";
        MatrixColumnCaptions: array[32] of Text[1024];
        i: Integer;
        MatrixData: array[32] of Decimal;
        ShowError: Option "None","Division by Zero","Period Error","Invalid Formula","Cyclic Formula",All;
        Text001: Label '* ERROR *';
        Text002: Label 'Not Available';
        Text004: Label 'Invalid Formula';
        Text005: Label 'Cyclic Formula';
        FirstLineNo: Integer;
        LastLineNo: Integer;
        CachedFormattedText: array[32] of Text[1024];
        CachedContainsError: array[32] of Boolean;
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

    [Scope('OnPrem')]
    procedure Load(PayrollAnalysisColumn1: Record "Payroll Analysis Column"; MatrixColumnCaptions1: array[32] of Text[1024]; ShowError1: Option "None","Division by Zero","Period Error","Invalid Formula","Cyclic Formula",All; FirstLineNo1: Integer; LastLineNo1: Integer)
    begin
        PayrollAnalysisColumn.Copy(PayrollAnalysisColumn1);
        CopyArray(MatrixColumnCaptions, MatrixColumnCaptions1, 1);
        ShowError := ShowError1;

        FirstLineNo := FirstLineNo1;
        LastLineNo := LastLineNo1;
    end;

    local procedure GetHorizontalRecord(HorizontalRecordOrdinal: Integer; var HorizontalRecord: Record "Payroll Analysis Column")
    var
        n: Integer;
    begin
        n := 1;
        if HorizontalRecord.Find('-') then
            while n <> HorizontalRecordOrdinal do begin
                n := n + 1;
                HorizontalRecord.Next;
            end;
    end;

    [Scope('OnPrem')]
    procedure FindError(var Value: Decimal; var Text: Text[1024]): Boolean
    begin
        Evaluate(Value, Text);
        if Value = 0 then
            Text := '';
        if PayrollAnalysisReportMgt.GetDivisionError then begin
            if ShowError in [ShowError::"Division by Zero", ShowError::All] then begin
                Text := Text001;
                exit(true);
            end;
            Text := '';
            Value := 0;
        end;
        if PayrollAnalysisReportMgt.GetPeriodError then begin
            if ShowError in [ShowError::"Period Error", ShowError::All] then begin
                Text := Text002;
                exit(true);
            end;
            Text := '';
            Value := 0;
        end;
        if PayrollAnalysisReportMgt.GetFormulaError then begin
            if ShowError in [ShowError::"Invalid Formula", ShowError::All] then begin
                Text := Text004;
                exit(true);
            end;
            Text := '';
            Value := 0;
        end;
        if PayrollAnalysisReportMgt.GetCyclicError then begin
            if ShowError in [ShowError::"Cyclic Formula", ShowError::All] then begin
                Text := Text005;
                exit(true);
            end;
            Text := '';
            Value := 0;
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure FieldDrillDown(ColumnID: Integer)
    begin
        PayrollAnalysisColumn2.Copy(PayrollAnalysisColumn);
        GetHorizontalRecord(ColumnID, PayrollAnalysisColumn2);
        PayrollAnalysisReportMgt.CalcCell(Rec, PayrollAnalysisColumn2, true);
    end;

    [Scope('OnPrem')]
    procedure SetVisible()
    begin
        Field1Visible := MatrixColumnCaptions[1] <> '';
        Field2Visible := MatrixColumnCaptions[2] <> '';
        Field3Visible := MatrixColumnCaptions[3] <> '';
        Field4Visible := MatrixColumnCaptions[4] <> '';
        Field5Visible := MatrixColumnCaptions[5] <> '';
        Field6Visible := MatrixColumnCaptions[6] <> '';
        Field7Visible := MatrixColumnCaptions[7] <> '';
        Field8Visible := MatrixColumnCaptions[8] <> '';
        Field9Visible := MatrixColumnCaptions[9] <> '';
        Field10Visible := MatrixColumnCaptions[10] <> '';
        Field11Visible := MatrixColumnCaptions[11] <> '';
        Field12Visible := MatrixColumnCaptions[12] <> '';
        Field13Visible := MatrixColumnCaptions[13] <> '';
        Field14Visible := MatrixColumnCaptions[14] <> '';
        Field15Visible := MatrixColumnCaptions[15] <> '';
        Field16Visible := MatrixColumnCaptions[16] <> '';
        Field17Visible := MatrixColumnCaptions[17] <> '';
        Field18Visible := MatrixColumnCaptions[18] <> '';
        Field19Visible := MatrixColumnCaptions[19] <> '';
        Field20Visible := MatrixColumnCaptions[20] <> '';
        Field21Visible := MatrixColumnCaptions[21] <> '';
        Field22Visible := MatrixColumnCaptions[22] <> '';
        Field23Visible := MatrixColumnCaptions[23] <> '';
        Field24Visible := MatrixColumnCaptions[24] <> '';
        Field25Visible := MatrixColumnCaptions[25] <> '';
        Field26Visible := MatrixColumnCaptions[26] <> '';
        Field27Visible := MatrixColumnCaptions[27] <> '';
        Field28Visible := MatrixColumnCaptions[28] <> '';
        Field29Visible := MatrixColumnCaptions[29] <> '';
        Field30Visible := MatrixColumnCaptions[30] <> '';
        Field31Visible := MatrixColumnCaptions[31] <> '';
        Field32Visible := MatrixColumnCaptions[32] <> '';
    end;
}

