report 17376 "Average Employee Count"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Average Employee Count';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
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
                        MinValue = 1;
                        ToolTip = 'Specifies the year.';
                    }
                    field(ReportingDate; ReportingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reporting Date';
                        ToolTip = 'Specifies when the report was created.';
                    }
                    field(Representative; Representative)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Representative';

                        trigger OnValidate()
                        begin
                            if not Representative then begin
                                RepresentativeName := '';
                                RepresentativeDocument := '';
                            end;
                        end;
                    }
                    field(RepresentativeName; RepresentativeName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Representative Name';

                        trigger OnValidate()
                        begin
                            CheckRepresentative;
                        end;
                    }
                    field(RepresentativeDocument; RepresentativeDocument)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Representative Document';

                        trigger OnValidate()
                        begin
                            CheckRepresentative;
                        end;
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
            ReportingDate := WorkDate;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not TestMode then
            ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(HRSetup."Avg. Headcount Template Code"))
        else
            ExcelMgt.CloseBook;
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        HRSetup.Get();
        HRSetup.TestField("Avg. Headcount Template Code");

        AnalyzableDate := DMY2Date(31, 12, Year);
        FileName := ExcelTemplate.OpenTemplate(HRSetup."Avg. Headcount Template Code");
        ExcelMgt.OpenBookForUpdate(FileName);
        ExcelMgt.OpenSheet('стр.1');

        FillCellsGroup('AN2', 12, CompanyInfo."VAT Registration No.");
        FillCellsGroup('AN5', 9, CompanyInfo."KPP Code");
        FillCellsGroup('CF5', 3, '001');

        ExcelMgt.FillCell('C15', LocalRepMgt.GetCompanyName);

        FillDate('CC23', AnalyzableDate);

        if Employee.FindSet then
            repeat
                AvrHeadQty += AverageHeadcountCalculation.CalcAvgCount(Employee."No.", AnalyzableDate);
            until Employee.Next() = 0;

        AvrHeadQtyText := Format(Round(AvrHeadQty, 1), 0, 1);
        AvrHeadQtyText := PadStr('', 6 - StrLen(AvrHeadQtyText), '0') + AvrHeadQtyText;
        FillCellsGroup('T27', 6, AvrHeadQtyText);

        if Employee.Get(CompanyInfo."Director No.") then
            ExcelMgt.FillCell('S34', Employee.GetFullNameOnDate(ReportingDate));

        FillDate('AH37', ReportingDate);

        if Representative then begin
            FillDate('AH48', ReportingDate);
            ExcelMgt.FillCell('C45', RepresentativeName);
            ExcelMgt.FillCell('C51', RepresentativeDocument);
        end;
    end;

    var
        CompanyInfo: Record "Company Information";
        Employee: Record Employee;
        HRSetup: Record "Human Resources Setup";
        ExcelTemplate: Record "Excel Template";
        LocalRepMgt: Codeunit "Local Report Management";
        ExcelMgt: Codeunit "Excel Management";
        AverageHeadcountCalculation: Codeunit "Average Headcount Calculation";
        Year: Integer;
        AvrHeadQty: Decimal;
        Representative: Boolean;
        AnalyzableDate: Date;
        ReportingDate: Date;
        RepresentativeName: Text[250];
        RepresentativeDocument: Text[250];
        Text001: Label 'Representative must be Yes.';
        FileName: Text[250];
        AvrHeadQtyText: Text[30];
        TestMode: Boolean;

    [Scope('OnPrem')]
    procedure CheckRepresentative()
    begin
        if not Representative then
            Error(Text001);
    end;

    [Scope('OnPrem')]
    procedure FillCellsGroup(FirstCellName: Text[30]; CellsQty: Integer; CellValue: Text[250])
    var
        CurrCellName: Text[30];
        i: Integer;
    begin
        CurrCellName := FirstCellName;
        for i := 1 to CellsQty do begin
            ExcelMgt.FillCell(CurrCellName, Format(CellValue[i]));
            CurrCellName := ExcelMgt.GetNextColumnCellName(CurrCellName);
        end;
    end;

    [Scope('OnPrem')]
    procedure FillDate(FirstCellName: Text[30]; DateToExport: Date)
    begin
        FillCellsGroup(FirstCellName, 10, Format(DateToExport, 0, '<Day,2>=<Month,2>=<Year4>'));
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
        Year := Date2DMY(WorkDate, 3);
    end;
}

