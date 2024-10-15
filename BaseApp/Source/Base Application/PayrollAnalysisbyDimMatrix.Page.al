page 35663 "Payroll Analysis by Dim Matrix"
{
    Caption = 'Payroll Analysis by Dim Matrix';
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
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
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

                    trigger OnDrillDown()
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

    trigger OnAfterGetCurrRecord()
    begin
        Steps := 1;
        ApplyColumnFilter;
        Which := '-';

        PayrollAnalysisMgt.FindRec(
          PayrollAnalysisView, ColumnDimOption, DimCodeBufferColumn3, Which,
          ElementFilter1, ElementGroupFilter1, EmployeeFilter1, OrgUnitFilter1,
          PeriodType, DateFilter1, PeriodInitialized, InternalDateFilter,
          Dim1Filter1, Dim2Filter1, Dim3Filter1, Dim4Filter1);

        i := 1;
        while (i <= NoOfRecords) and (i <= ArrayLen(MatrixColumnCaptions)) do begin
            MatrixData[i] := CalcAmt(DimCodeBufferColumn3, ValueType, true);
            PayrollAnalysisMgt.NextRec(
              PayrollAnalysisView, ColumnDimOption, DimCodeBufferColumn3, Steps,
              ElementFilter1, ElementGroupFilter1, EmployeeFilter1, OrgUnitFilter1,
              PeriodType, DateFilter1,
              Dim1Filter1, Dim2Filter1, Dim3Filter1, Dim4Filter1);
            i := i + 1;
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        Steps := 1;
        ApplyColumnFilter;
        Which := '-';

        PayrollAnalysisMgt.FindRec(
          PayrollAnalysisView, ColumnDimOption, DimCodeBufferColumn3, Which,
          ElementFilter1, ElementGroupFilter1, EmployeeFilter1, OrgUnitFilter1,
          PeriodType, DateFilter1, PeriodInitialized, InternalDateFilter,
          Dim1Filter1, Dim2Filter1, Dim3Filter1, Dim4Filter1);

        i := 1;
        while (i <= NoOfRecords) and (i <= ArrayLen(MatrixColumnCaptions)) do begin
            MatrixData[i] := CalcAmt(DimCodeBufferColumn3, ValueType, true);
            PayrollAnalysisMgt.NextRec(
              PayrollAnalysisView, ColumnDimOption, DimCodeBufferColumn3, Steps,
              ElementFilter1, ElementGroupFilter1, EmployeeFilter1, OrgUnitFilter1,
              PeriodType, DateFilter1,
              Dim1Filter1, Dim2Filter1, Dim3Filter1, Dim4Filter1);
            i := i + 1;
        end;
        MatrixData1OnFormat(Format(MatrixData[1]));
        MatrixData2OnFormat(Format(MatrixData[2]));
        MatrixData3OnFormat(Format(MatrixData[3]));
        MatrixData4OnFormat(Format(MatrixData[4]));
        MatrixData5OnFormat(Format(MatrixData[5]));
        MatrixData6OnFormat(Format(MatrixData[6]));
        MatrixData7OnFormat(Format(MatrixData[7]));
        MatrixData8OnFormat(Format(MatrixData[8]));
        MatrixData9OnFormat(Format(MatrixData[9]));
        MatrixData10OnFormat(Format(MatrixData[10]));
        MatrixData11OnFormat(Format(MatrixData[11]));
        MatrixData12OnFormat(Format(MatrixData[12]));
        MatrixData13OnFormat(Format(MatrixData[13]));
        MatrixData14OnFormat(Format(MatrixData[14]));
        MatrixData15OnFormat(Format(MatrixData[15]));
        MatrixData16OnFormat(Format(MatrixData[16]));
        MatrixData17OnFormat(Format(MatrixData[17]));
        MatrixData18OnFormat(Format(MatrixData[18]));
        MatrixData19OnFormat(Format(MatrixData[19]));
        MatrixData20OnFormat(Format(MatrixData[20]));
        MatrixData21OnFormat(Format(MatrixData[21]));
        MatrixData22OnFormat(Format(MatrixData[22]));
        MatrixData23OnFormat(Format(MatrixData[23]));
        MatrixData24OnFormat(Format(MatrixData[24]));
        MatrixData25OnFormat(Format(MatrixData[25]));
        MatrixData26OnFormat(Format(MatrixData[26]));
        MatrixData27OnFormat(Format(MatrixData[27]));
        MatrixData28OnFormat(Format(MatrixData[28]));
        MatrixData29OnFormat(Format(MatrixData[29]));
        MatrixData30OnFormat(Format(MatrixData[30]));
        MatrixData31OnFormat(Format(MatrixData[31]));
        MatrixData32OnFormat(Format(MatrixData[32]));
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(
          PayrollAnalysisMgt.FindRec(
            PayrollAnalysisView, LineDimOption, Rec, Which,
            ElementFilter, ElementGroupFilter, EmployeeFilter, OrgUnitFilter,
            PeriodType, DateFilter, PeriodInitialized, InternalDateFilter,
            Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter));
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
        exit(
          PayrollAnalysisMgt.NextRec(
            PayrollAnalysisView, LineDimOption, Rec, Steps,
            ElementFilter, ElementGroupFilter, EmployeeFilter, OrgUnitFilter,
            PeriodType, DateFilter,
            Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter));
    end;

    trigger OnOpenPage()
    begin
        ApplyColumnFilter;

        Field1Visible := 1 <= NoOfRecords;
        Field2Visible := 2 <= NoOfRecords;
        Field3Visible := 3 <= NoOfRecords;
        Field4Visible := 4 <= NoOfRecords;
        Field5Visible := 5 <= NoOfRecords;
        Field6Visible := 6 <= NoOfRecords;
        Field7Visible := 7 <= NoOfRecords;
        Field8Visible := 8 <= NoOfRecords;
        Field9Visible := 9 <= NoOfRecords;
        Field10Visible := 10 <= NoOfRecords;
        Field11Visible := 11 <= NoOfRecords;
        Field12Visible := 12 <= NoOfRecords;
        Field13Visible := 13 <= NoOfRecords;
        Field14Visible := 14 <= NoOfRecords;
        Field15Visible := 15 <= NoOfRecords;
        Field16Visible := 16 <= NoOfRecords;
        Field17Visible := 17 <= NoOfRecords;
        Field18Visible := 18 <= NoOfRecords;
        Field19Visible := 19 <= NoOfRecords;
        Field20Visible := 20 <= NoOfRecords;
        Field21Visible := 21 <= NoOfRecords;
        Field22Visible := 22 <= NoOfRecords;
        Field23Visible := 23 <= NoOfRecords;
        Field24Visible := 24 <= NoOfRecords;
        Field25Visible := 25 <= NoOfRecords;
        Field26Visible := 26 <= NoOfRecords;
        Field27Visible := 27 <= NoOfRecords;
        Field28Visible := 28 <= NoOfRecords;
        Field29Visible := 29 <= NoOfRecords;
        Field30Visible := 30 <= NoOfRecords;
        Field31Visible := 31 <= NoOfRecords;
        Field32Visible := 32 <= NoOfRecords;

        GLSetup.Get;
        NormalFormatString := StrSubstNo(Text001, GLSetup."Amount Decimal Places");
    end;

    var
        PayrollAnalysisView: Record "Payroll Analysis View";
        AVBreakdownBuffer: Record "Dimension Code Amount Buffer" temporary;
        DimCodeBufferColumn: Record "Dimension Code Buffer";
        DimCodeBufferColumn3: Record "Dimension Code Buffer";
        PayrollStatisticsBuffer: Record "Payroll Statistics Buffer";
        GLSetup: Record "General Ledger Setup";
        PayrollAnalysisMgt: Codeunit "Payroll Analysis Management";
        RoundingFactor: Option "None","1","1000","1000000";
        ValueType: Option "Payroll Amount","Taxable Amount";
        LineDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4";
        ColumnDimOption: Option Element,"Element Group",Employee,"Org. Unit",Period,"Dimension 1","Dimension 2","Dimension 3","Dimension 4";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        UsePFAccumSystemFilter: Option " ",Yes,No;
        CurrentPayrollAnalysisViewCode: Code[10];
        ElementTypeFilter: Text;
        ElementFilter: Text;
        ElementGroupFilter: Text;
        EmployeeFilter: Text;
        OrgUnitFilter: Text;
        Dim1Filter: Text;
        Dim2Filter: Text;
        Dim3Filter: Text;
        Dim4Filter: Text;
        DateFilter: Text;
        MatrixColumnCaptions: array[32] of Text;
        InternalDateFilter: Text;
        Which: Text;
        NormalFormatString: Text[80];
        ShowOppositeSign: Boolean;
        PeriodInitialized: Boolean;
        i: Integer;
        Steps: Integer;
        NoOfRecords: Integer;
        MatrixData: array[32] of Decimal;
        Text001: Label '<Precision,%1><Standard Format,0>';
        ElementTypeFilter1: Text;
        ElementFilter1: Text;
        ElementGroupFilter1: Text;
        EmployeeFilter1: Text;
        OrgUnitFilter1: Text;
        Dim1Filter1: Text;
        Dim2Filter1: Text;
        Dim3Filter1: Text;
        Dim4Filter1: Text;
        DateFilter1: Text;
        FirstColumn: Text;
        LastColumn: Text;
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
    procedure LoadVariables(PayrollAnalysisView1: Record "Payroll Analysis View"; LineDimOption1: Option; ColumnDimOption1: Option; PeriodType1: Option; ValueType1: Option; RoundingFactor1: Option; MatrixColumnCaptions1: array[32] of Text[1024]; ShowOppositeSign1: Boolean; PeriodInitialized1: Boolean; FirstColumn1: Text; LastColumn1: Text; NoOfRecordsLocal: Integer)
    begin
        Clear(MatrixColumnCaptions);
        PayrollAnalysisView.Copy(PayrollAnalysisView1);

        CurrentPayrollAnalysisViewCode := PayrollAnalysisView.Code;

        LineDimOption := LineDimOption1;
        ColumnDimOption := ColumnDimOption1;

        PeriodType := PeriodType1;
        ShowOppositeSign := ShowOppositeSign1;

        CopyArray(MatrixColumnCaptions, MatrixColumnCaptions1, 1);

        PeriodInitialized := PeriodInitialized1;
        PeriodType := PeriodType1;
        ValueType := ValueType1;
        RoundingFactor := RoundingFactor1;

        FirstColumn := FirstColumn1;
        LastColumn := LastColumn1;

        NoOfRecords := NoOfRecordsLocal;
    end;

    [Scope('OnPrem')]
    procedure LoadFilters(ElementTypeFilter1: Text[250]; ElementFilter1: Code[250]; ElementGroupFilter1: Code[250]; EmployeeFilter1: Code[250]; OrgUnitFilter1: Code[250]; UsePFAccumSystemFilter1: Option " ",Yes,No; Dim1Filter1: Code[250]; Dim2Filter1: Code[250]; Dim3Filter1: Code[250]; Dim4Filter1: Code[250]; DateFilter2: Text[30]; InternalDateFilter1: Text[30])
    begin
        ElementTypeFilter := ElementTypeFilter1;
        ElementFilter := ElementFilter1;
        ElementGroupFilter := ElementGroupFilter1;
        EmployeeFilter := EmployeeFilter1;
        OrgUnitFilter := OrgUnitFilter1;
        UsePFAccumSystemFilter := UsePFAccumSystemFilter1;
        Dim1Filter := Dim1Filter1;
        Dim2Filter := Dim2Filter1;
        Dim3Filter := Dim3Filter1;
        Dim4Filter := Dim4Filter1;
        DateFilter := DateFilter2;
        InternalDateFilter := InternalDateFilter1;
    end;

    local procedure CalcAmt(DimCodeBufferColumn1: Record "Dimension Code Buffer"; ValueType: Integer; SetColFilter: Boolean): Decimal
    var
        Amt: Decimal;
        AmtFromBuffer: Boolean;
    begin
        if SetColFilter then
            if AVBreakdownBuffer.Get(Code, DimCodeBufferColumn1.Code) then begin
                Amt := AVBreakdownBuffer.Amount;
                AmtFromBuffer := true;
            end;

        if not AmtFromBuffer then begin
            PayrollAnalysisMgt.SetCalcAmountParameters(
              CurrentPayrollAnalysisViewCode,
              LineDimOption,
              Rec,
              ColumnDimOption,
              DimCodeBufferColumn1);

            Amt := PayrollAnalysisMgt.CalcAmount(
                SetColFilter, ValueType,
                PayrollStatisticsBuffer,
                ElementTypeFilter, ElementFilter, ElementGroupFilter, EmployeeFilter, OrgUnitFilter, UsePFAccumSystemFilter,
                DateFilter, Dim1Filter, Dim2Filter, Dim3Filter, Dim3Filter);

            if SetColFilter then begin
                AVBreakdownBuffer."Line Code" := Code;
                AVBreakdownBuffer."Column Code" := DimCodeBufferColumn1.Code;
                AVBreakdownBuffer.Amount := Amt;
                AVBreakdownBuffer.Insert;
            end;
        end;

        if ShowOppositeSign then
            Amt := -Amt;
        exit(Amt);
    end;

    local procedure FieldDrillDown(Ordinal: Integer)
    begin
        Clear(DimCodeBufferColumn3);
        Which := '-';

        PayrollAnalysisMgt.FindRec(
          PayrollAnalysisView, ColumnDimOption, DimCodeBufferColumn3, Which,
          ElementFilter, ElementGroupFilter, EmployeeFilter, OrgUnitFilter,
          PeriodType, DateFilter1, PeriodInitialized, InternalDateFilter,
          Dim1Filter1, Dim2Filter1, Dim3Filter1, Dim4Filter);

        Steps := Ordinal - 1;
        PayrollAnalysisMgt.NextRec(
          PayrollAnalysisView, ColumnDimOption, DimCodeBufferColumn3, Steps,
          ElementFilter1, ElementGroupFilter1, EmployeeFilter1, OrgUnitFilter1,
          PeriodType, DateFilter1,
          Dim1Filter1, Dim2Filter1, Dim3Filter1, Dim4Filter);

        PayrollAnalysisMgt.DrillDown(
          PayrollStatisticsBuffer, CurrentPayrollAnalysisViewCode,
          ElementTypeFilter1, ElementFilter1, ElementGroupFilter1, EmployeeFilter1, OrgUnitFilter1, UsePFAccumSystemFilter,
          DateFilter1, Dim1Filter1, Dim2Filter1, Dim3Filter1, Dim4Filter1,
          LineDimOption, Rec,
          ColumnDimOption, DimCodeBufferColumn3,
          true, ValueType);
    end;

    [Scope('OnPrem')]
    procedure ApplyColumnFilter()
    begin
        Clear(ElementTypeFilter1);
        Clear(ElementFilter1);
        Clear(ElementGroupFilter1);
        Clear(EmployeeFilter1);
        Clear(OrgUnitFilter1);
        Clear(DateFilter1);
        Clear(Dim1Filter1);
        Clear(Dim2Filter1);
        Clear(Dim3Filter1);
        Clear(Dim4Filter1);

        case ColumnDimOption of
            ColumnDimOption::Element:
                begin
                    ElementTypeFilter1 := ElementTypeFilter;
                    if ElementFilter <> '' then
                        ElementFilter1 := ElementFilter + '&';
                    ElementFilter1 := ElementFilter1 + Format(FirstColumn) + '..' + Format(LastColumn);
                    ElementGroupFilter1 := ElementGroupFilter;
                    EmployeeFilter1 := EmployeeFilter;
                    OrgUnitFilter1 := OrgUnitFilter;
                    DateFilter1 := DateFilter;
                    Dim1Filter1 := Dim1Filter;
                    Dim2Filter1 := Dim2Filter;
                    Dim3Filter1 := Dim3Filter;
                    Dim4Filter1 := Dim4Filter;
                end;
            ColumnDimOption::"Element Group":
                begin
                    ElementTypeFilter1 := ElementTypeFilter;
                    ElementFilter1 := ElementFilter;
                    if ElementGroupFilter <> '' then
                        ElementGroupFilter1 := ElementGroupFilter + '&';
                    ElementGroupFilter1 := ElementGroupFilter1 + Format(FirstColumn) + '..' + Format(LastColumn);
                    EmployeeFilter1 := EmployeeFilter;
                    OrgUnitFilter1 := OrgUnitFilter;
                    DateFilter1 := DateFilter;
                    Dim1Filter1 := Dim1Filter;
                    Dim2Filter1 := Dim2Filter;
                    Dim3Filter1 := Dim3Filter;
                    Dim4Filter1 := Dim4Filter;
                end;
            ColumnDimOption::Employee:
                begin
                    ElementTypeFilter1 := ElementTypeFilter;
                    ElementFilter1 := ElementFilter;
                    ElementGroupFilter1 := ElementGroupFilter;
                    if EmployeeFilter <> '' then
                        EmployeeFilter1 := EmployeeFilter + '&';
                    EmployeeFilter1 := EmployeeFilter1 + Format(FirstColumn) + '..' + Format(LastColumn);
                    OrgUnitFilter1 := OrgUnitFilter;
                    DateFilter1 := DateFilter;
                    Dim1Filter1 := Dim1Filter;
                    Dim2Filter1 := Dim2Filter;
                    Dim3Filter1 := Dim3Filter;
                    Dim4Filter1 := Dim4Filter;
                end;
            ColumnDimOption::"Org. Unit":
                begin
                    ElementTypeFilter1 := ElementTypeFilter;
                    ElementFilter1 := ElementFilter;
                    ElementGroupFilter1 := ElementGroupFilter;
                    EmployeeFilter1 := EmployeeFilter;
                    if OrgUnitFilter <> '' then
                        OrgUnitFilter1 := OrgUnitFilter + '&';
                    OrgUnitFilter1 := OrgUnitFilter1 + Format(FirstColumn) + '..' + Format(LastColumn);
                    DateFilter1 := DateFilter;
                    Dim1Filter1 := Dim1Filter;
                    Dim2Filter1 := Dim2Filter;
                    Dim3Filter1 := Dim3Filter;
                    Dim4Filter1 := Dim4Filter;
                end;
            ColumnDimOption::Period:
                begin
                    ElementTypeFilter1 := ElementTypeFilter;
                    ElementFilter1 := ElementFilter;
                    ElementGroupFilter1 := ElementGroupFilter;
                    EmployeeFilter1 := EmployeeFilter;
                    OrgUnitFilter1 := OrgUnitFilter;
                    if DateFilter <> '' then
                        DateFilter1 := DateFilter
                    else
                        DateFilter1 := Format(FirstColumn) + '..' + Format(LastColumn);
                    Dim1Filter1 := Dim1Filter;
                    Dim2Filter1 := Dim2Filter;
                    Dim3Filter1 := Dim3Filter;
                    Dim4Filter1 := Dim4Filter;
                end;
            ColumnDimOption::"Dimension 1":
                begin
                    ElementTypeFilter1 := ElementTypeFilter;
                    ElementFilter1 := ElementFilter;
                    ElementGroupFilter1 := ElementGroupFilter;
                    EmployeeFilter1 := EmployeeFilter;
                    OrgUnitFilter1 := OrgUnitFilter;
                    DateFilter1 := DateFilter;
                    if Dim1Filter <> '' then
                        Dim1Filter1 := Dim1Filter + '&';
                    Dim1Filter1 := Dim1Filter1 + Format(FirstColumn) + '..' + Format(LastColumn);
                    Dim2Filter1 := Dim2Filter;
                    Dim3Filter1 := Dim3Filter;
                    Dim4Filter1 := Dim4Filter;
                end;
            ColumnDimOption::"Dimension 2":
                begin
                    ElementTypeFilter1 := ElementTypeFilter;
                    ElementFilter1 := ElementFilter;
                    ElementGroupFilter1 := ElementGroupFilter;
                    EmployeeFilter1 := EmployeeFilter;
                    OrgUnitFilter1 := OrgUnitFilter;
                    DateFilter1 := DateFilter;
                    Dim1Filter1 := Dim1Filter;
                    if Dim2Filter <> '' then
                        Dim2Filter1 := Dim2Filter + '&';
                    Dim2Filter1 := Dim2Filter1 + Format(FirstColumn) + '..' + Format(LastColumn);
                    Dim3Filter1 := Dim3Filter;
                    Dim4Filter1 := Dim4Filter;
                end;
            ColumnDimOption::"Dimension 3":
                begin
                    ElementTypeFilter1 := ElementTypeFilter;
                    ElementFilter1 := ElementFilter;
                    ElementGroupFilter1 := ElementGroupFilter;
                    EmployeeFilter1 := EmployeeFilter;
                    OrgUnitFilter1 := OrgUnitFilter;
                    DateFilter1 := DateFilter;
                    Dim1Filter1 := Dim1Filter;
                    Dim2Filter1 := Dim2Filter;
                    if Dim3Filter <> '' then
                        Dim3Filter1 := Dim3Filter + '&';
                    Dim3Filter1 := Dim3Filter1 + Format(FirstColumn) + '..' + Format(LastColumn);
                    Dim4Filter1 := Dim4Filter;
                end;
            ColumnDimOption::"Dimension 4":
                begin
                    ElementTypeFilter1 := ElementTypeFilter;
                    ElementFilter1 := ElementFilter;
                    ElementGroupFilter1 := ElementGroupFilter;
                    EmployeeFilter1 := EmployeeFilter;
                    OrgUnitFilter1 := OrgUnitFilter;
                    DateFilter1 := DateFilter;
                    Dim1Filter1 := Dim1Filter;
                    Dim2Filter1 := Dim2Filter;
                    Dim3Filter1 := Dim3Filter;
                    if Dim4Filter <> '' then
                        Dim4Filter1 := Dim4Filter + '&';
                    Dim4Filter1 := Dim4Filter1 + Format(FirstColumn) + '..' + Format(LastColumn);
                end;
        end;
    end;

    local procedure MatrixData1OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData2OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData3OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData4OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData5OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData6OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData7OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData8OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData9OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData10OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData11OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData12OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData13OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData14OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData15OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData16OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData17OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData18OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData19OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData20OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData21OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData22OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData23OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData24OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData25OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData26OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData27OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData28OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData29OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData30OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData31OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;

    local procedure MatrixData32OnFormat(Text: Text[1024])
    begin
        PayrollAnalysisMgt.FormatAmount(Text, RoundingFactor);
    end;
}

