report 17485 "Report FP to Excel"
{
    Caption = 'Report FP to Excel';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Employee; Employee)
        {
            DataItemTableView = SORTING("Birth Date", Gender, "Last Name", "No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                BDRangeNo: Integer;
            begin
                BDRangeNo := CalcEmployeeBDRange("Birth Date", Gender.AsInteger());
                if BDRangeNo = 0 then
                    CurrReport.Skip();

                CalcTaxAmounts("No.", 2, StartingDate, AmtByBDRange[1, BDRangeNo]);

                CalcTaxAmounts("No.", 3, StartingDate, AmtByBDRange[2, BDRangeNo]);
                CalcTaxAmounts("No.", 4, StartingDate, AmtByBDRange[2, BDRangeNo]);
                CalcTaxAmounts("No.", 21, StartingDate, AmtByBDRange[3, 1]);
                CalcTaxAmounts("No.", 22, StartingDate, AmtByBDRange[4, 1]);
                CalcTaxAmounts("No.", 15, StartingDate, AmtByBDRange[5, 1]);
                CalcTaxAmounts("No.", 16, StartingDate, AmtByBDRange[6, 1]);

                CalcExceededTaxAmounts("No.", 7, StartingDate, 2, AmtByBDRange[7, BDRangeNo]);
            end;

            trigger OnPostDataItem()
            var
                Totals: array[2, 4] of Decimal;
                BDRangeNo: Integer;
            begin
                ExcelMgt.OpenSheet('ï¿ßÔ2');

                Clear(Totals);
                BRangeMax := 2;
                AmtRangeMax := 3;

                for BDRangeNo := 1 to BRangeMax do begin
                    FillSection(Format(200 + BDRangeNo), AmtByBDRange[1, BDRangeNo]);
                    FillSection(Format(210 + BDRangeNo), AmtByBDRange[2, BDRangeNo]);
                    FillSection(Format(216 + BDRangeNo), AmtByBDRange[7, BDRangeNo]);
                end;

                FillSection(Format(241), AmtByBDRange[3, 1]);
                FillSection(Format(242), AmtByBDRange[4, 1]);
                FillSection(Format(243), AmtByBDRange[5, 1]);
                FillSection(Format(244), AmtByBDRange[6, 1]);

                ExcelMgt.FillCell('CurrDate', Format(ReportDate));
            end;

            trigger OnPreDataItem()
            var
                RepPeriod: Integer;
                Sex: Option ,Female,Male;
                i: Integer;
            begin
                ExcelMgt.OpenBookForUpdate(FileName);
                ExcelMgt.OpenSheet('ï¿ßÔ1');

                HumanSetup.Get();
                CompanyInfo.Get();
                RoundFactor := 1;
                SetBDRanges(DMY2Date(1, 1, 1870), DMY2Date(31, 12, 1966), Sex::Female, 1);
                SetBDRanges(DMY2Date(1, 1, 1870), DMY2Date(31, 12, 1966), Sex::Male, 1);
                SetBDRanges(DMY2Date(1, 1, 1967), DMY2Date(31, 12, 2010), Sex::Female, 2);
                SetBDRanges(DMY2Date(1, 1, 1967), DMY2Date(31, 12, 2010), Sex::Male, 2);

                // fill title
                if CompanyInfo."Pension Fund Registration No." <> '' then
                    ExcelMgt.FillCellsGroup('PFR',
                      CopyStr(CompanyInfo."Pension Fund Registration No.", 1, 3) +
                      CopyStr(CompanyInfo."Pension Fund Registration No.", 5, 3) +
                      CopyStr(CompanyInfo."Pension Fund Registration No.", 9, 6),
                      12, 0, '');

                RepPeriod := Quarter * 3 + 3;
                if RepPeriod = 12 then begin
                    RepPeriod := 0;
                    ExcelMgt.FillCellsGroup('RepPeriod', Format(12), 2, 0, '');
                end else
                    ExcelMgt.FillCellsGroup('RepPeriod', '0' + Format(RepPeriod), 2, 0, '');

                for i := 1 to 3 do
                    StartingDate[i] := DMY2Date(1, i + 3 * Quarter, Year);

                ExcelMgt.FillCell('CompanyName', CompanyInfo.Name);
                ExcelMgt.FillCellsGroup('Year', Format(Year), 4, 0, '');

                ExcelMgt.FillCellsGroup('TFMI', CompanyInfo."Medical Fund Registration No.", 15, 0, '');
                ExcelMgt.FillCellsGroup('KPP', CompanyInfo."KPP Code", 9, 0, '');
                ExcelMgt.FillCellsGroup('INN', CompanyInfo."VAT Registration No.", 12, 0, '0');
                ExcelMgt.FillCellsGroup('GSRN', CompanyInfo."OGRN Code", 13, 0, '');
                ExcelMgt.FillCellsGroup('PhoneNo', CompanyInfo."Phone No.", 15, 0, '0');
                ExcelMgt.FillCellsGroup('OKATO', CompanyInfo."OKATO Code", 11, 0, '');

                if CompanyInfo."OKVED Code" <> '' then
                    ExcelMgt.FillCellsGroup('OKVED',
                      CopyStr(CompanyInfo."OKVED Code", 1, 2) +
                      CopyStr(CompanyInfo."OKVED Code", 4, 2) +
                      CopyStr(CompanyInfo."OKVED Code", 7, 2),
                      6, 1, '');

                ExcelMgt.FillCellsGroup('OKPO', CompanyInfo."OKPO Code", 10, 0, '');
                ExcelMgt.FillCellsGroup('OKOPF', CompanyInfo."OKOPF Code", 2, 0, '');
                ExcelMgt.FillCellsGroup('OKFS', CompanyInfo."OKFS Code", 2, 0, '');

                FillCompanyAddress;
                ExcelMgt.FillCellsGroup('AverageQty', Format(Round(AverageListQuantity(Quarter * 3 + 3))), 6, 0, '0');
                ExcelMgt.FillCellsGroup('InsuranceQty', Format(CalcInsurancedPeople), 6, 0, '0');
                FillLiabilityPerson;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Year; Year)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Year';
                        ToolTip = 'Specifies the year.';
                    }
                    field(QuarterControl; Quarter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period';
                        OptionCaption = '1 quarter,1 half-year,9 months,year';
                    }
                    field(ReportDate; ReportDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Creation Date';
                        ToolTip = 'Specifies when the report was created.';
                    }
                    field(AgentFlag; AgentFlag)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Agent';

                        trigger OnValidate()
                        begin
                            AgentFlagOnAfterValidate;
                        end;
                    }
                    field(AgNameCont; AgentName)
                    {
                        ApplicationArea = All;
                        Caption = 'Agent Name';
                        Editable = true;
                        Visible = AgNameContVisible;
                    }
                    field(AgeDocCon; AgentDoc)
                    {
                        ApplicationArea = All;
                        Caption = 'Agent Document';
                        Editable = true;
                        Visible = AgeDocConVisible;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            Year := Date2DMY(WorkDate, 3);
            ReportDate := WorkDate;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HumanSetup."PF Report Template Code"));
    end;

    trigger OnPreReport()
    begin
        HumanSetup.Get();
        HumanSetup.TestField("PF Report Template Code");

        FileName := ExcelTemplate.OpenTemplate(HumanSetup."PF Report Template Code");

        CompanyInfo.Get();
    end;

    var
        CompanyInfo: Record "Company Information";
        HumanSetup: Record "Human Resources Setup";
        ExcelTemplate: Record "Excel Template";
        ExcelMgt: Codeunit "Excel Management";
        Quarter: Option;
        StartingDate: array[3] of Date;
        ReportDate: Date;
        RoundFactor: Decimal;
        BDRange: array[2, 3, 2] of Date;
        AmtByBDRange: array[7, 5, 5] of Decimal;
        BRangeMax: Integer;
        AmtRangeMax: Integer;
        Year: Integer;
        AgentFlag: Boolean;
        AgentName: Text[250];
        AgentDoc: Text[250];
        FileName: Text[250];
        [InDataSet]
        AgNameContVisible: Boolean;
        [InDataSet]
        AgeDocConVisible: Boolean;
        [InDataSet]
        AgeDocCon1Visible: Boolean;
        [InDataSet]
        AgNameCont1Visible: Boolean;

    [Scope('OnPrem')]
    procedure CalcTaxAmounts(EmployeeNo: Code[20]; FieldNo: Integer; Dates: array[3] of Date; var TaxAmounts: array[5] of Decimal)
    begin
        /** TODO
        SSTData.Reset();
        SSTData.SETRANGE("Employee No.",EmployeeNo);
        SSTData.SETRANGE(Year,DATE2DMY(Dates[3],3));
        SSTData.SETFILTER("Month No.",'<%1',DATE2DMY(Dates[1],2));
        SSTData.SETRANGE(Range,0);
        TaxAmounts[5] += SSTData.GetValue(FieldNo,1);
        TaxAmounts[4] := 0;
        FOR i := 1 TO 3 DO BEGIN
          SSTData.SETRANGE("Month No.",DATE2DMY(Dates[i],2));
          Amount := SSTData.GetValue(FieldNo,1);
          TaxAmounts[i] += Amount;
          TaxAmounts[4] += Amount;
        END;
        TaxAmounts[5] += TaxAmounts[4];
        */

    end;

    [Scope('OnPrem')]
    procedure CalcExceededTaxAmounts(EmployeeNo: Code[20]; FieldNo: Integer; Dates: array[3] of Date; Range: Integer; var TaxAmounts: array[5] of Decimal)
    begin
        /** TODO
        SSTData.Reset();
        SSTData.SETRANGE("Employee No.",EmployeeNo);
        SSTData.SETRANGE(Year,DATE2DMY(Dates[3],3));
        SSTData.SETRANGE("Month No.",DATE2DMY(Dates[1],2) - 1);
        SSTData.SETRANGE(Range,Range);
        TaxAmounts[5] += SSTData.GetValue(FieldNo,1);
        TaxAmounts[4] := 0;
        Amount := 0;
        
        SSTData.SETRANGE("Month No.",DATE2DMY(Dates[1],2) - 1);
        PrevAmount := SSTData.GetValue(FieldNo,1);
        
        FOR i := 1 TO 3 DO BEGIN
          SSTData.SETRANGE("Month No.",DATE2DMY(Dates[i],2));
          Amount := SSTData.GetValue(FieldNo,1);
          IF Amount > 0 THEN BEGIN
            TaxAmounts[i] += Amount - PrevAmount;
            TaxAmounts[4] += Amount - PrevAmount;
          END;
          PrevAmount := Amount;
        END;
        TaxAmounts[5] += TaxAmounts[4];
        **/

    end;

    [Scope('OnPrem')]
    procedure SetBDRanges(Date1: Date; Date2: Date; Sex: Option; RangeNo: Integer)
    begin
        BDRange[Sex, RangeNo, 1] := Date1;
        BDRange[Sex, RangeNo, 2] := Date2;
    end;

    [Scope('OnPrem')]
    procedure CalcEmployeeBDRange(BDate: Date; Sex: Option ,Female,Male) RangeNo: Integer
    begin
        if (BDate = 0D) or (Sex = 0) then
            exit(0);
        for RangeNo := 1 to 3 do
            if BDate in [BDRange[Sex, RangeNo, 1] .. BDRange[Sex, RangeNo, 2]] then
                exit(RangeNo);
    end;

    [Scope('OnPrem')]
    procedure FillCompanyAddress()
    var
        CompanyAddress: Record "Company Address";
    begin
        CompanyAddress.SetRange("Address Type", CompanyAddress."Address Type"::"Pension Fund");
        if CompanyAddress.FindFirst then begin
            ExcelMgt.FillCell('PostCode', CompanyAddress."Post Code");
            ExcelMgt.FillCell('Region', CompanyAddress."Region Name");
            ExcelMgt.FillCell('Area', CompanyAddress.County);
            ExcelMgt.FillCell('City', CompanyAddress.City);
            ExcelMgt.FillCell('Settlement', CompanyAddress.Settlement);
            ExcelMgt.FillCell('Street', CompanyAddress.Street);
            ExcelMgt.FillCell('House', CompanyAddress.House);
            ExcelMgt.FillCell('Building', CompanyAddress.Building);
            ExcelMgt.FillCell('Flat', CompanyAddress.Apartment);
        end;
    end;

    [Scope('OnPrem')]
    procedure AverageListQuantity(MonthStartQuarter: Integer) AverageList: Decimal
    var
        Employee: Record Employee;
        AverageHeadcountCalculation: Codeunit "Average Headcount Calculation";
        i: Integer;
        AvgAmount: Decimal;
    begin
        Employee.Reset();
        if Employee.Find('-') then
            repeat
                AvgAmount := 0;
                for i := 1 to MonthStartQuarter do
                    AvgAmount := AvgAmount + AverageHeadcountCalculation.CalcAvgCount(Employee."No.", DMY2Date(1, i, Year));
                AvgAmount := AvgAmount / MonthStartQuarter;

                AverageList := AverageList + AvgAmount;
            until Employee.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcInsurancedPeople(): Integer
    var
        AllEmployees: Record Employee;
    begin
        AllEmployees.SetFilter(Status, '<>%1', AllEmployees.Status::Terminated);
        AllEmployees.SetFilter("Social Security No.", '<>%1', '');
        AllEmployees.FindFirst;

        exit(AllEmployees.Count)
    end;

    [Scope('OnPrem')]
    procedure FillSection(SectionCode: Code[3]; AmtByBDRange: array[5] of Decimal)
    begin
        ExcelMgt.FillCell('Total' + SectionCode, Format(Round(AmtByBDRange[5], RoundFactor)));
        ExcelMgt.FillCell('FirstMonth' + SectionCode, Format(Round(AmtByBDRange[1], RoundFactor)));
        ExcelMgt.FillCell('SecondMonth' + SectionCode, Format(Round(AmtByBDRange[2], RoundFactor)));
        ExcelMgt.FillCell('ThirdMonth' + SectionCode, Format(Round(AmtByBDRange[3], RoundFactor)));
    end;

    [Scope('OnPrem')]
    procedure FillLiabilityPerson()
    var
        Employee: Record Employee;
    begin
        if ReportDate <> 0D then begin
            ExcelMgt.FillCellsGroup('CurrDay', Format(Date2DMY(ReportDate, 1)), 2, 0, '0');
            ExcelMgt.FillCellsGroup('CurrM', Format(Date2DMY(ReportDate, 2)), 2, 0, '0');
            ExcelMgt.FillCellsGroup('CurrY', Format(Date2DMY(ReportDate, 3)), 4, 0, '0');
        end;

        if AgentFlag then begin
            ExcelMgt.FillCell('Agent', AgentName);
            ExcelMgt.FillCell('Agentdocument', AgentDoc);
            ExcelMgt.FillCell('AgentFlag', '2');
        end else
            if Employee.Get(CompanyInfo."Director No.") then begin
                ExcelMgt.FillCell('Agent', Employee."Last Name" + ' ' + Employee."First Name" + ' ' + Employee."Middle Name");
                ExcelMgt.FillCell('AgentFlag', '1');
            end;
    end;

    local procedure AgentFlagOnAfterValidate()
    begin
        if AgentFlag then begin
            AgNameContVisible := true;
            AgeDocConVisible := true;
            AgeDocCon1Visible := true;
            AgNameCont1Visible := true;
            RequestOptionsPage.Update;
        end else begin
            AgNameContVisible := false;
            AgeDocConVisible := false;
            AgeDocCon1Visible := false;
            AgNameCont1Visible := false;
            RequestOptionsPage.Update;
        end;
    end;
}

