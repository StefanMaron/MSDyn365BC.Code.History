report 17451 "Spreadsheet Employee"
{
    Caption = 'Spreadsheet Employee';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Employee; Employee)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Code", "Statistics Group Code";

            trigger OnAfterGetRecord()
            begin
                PayrollLedgerEntry.Reset;
                PayrollLedgerEntry.SetCurrentKey("Employee No.", "Period Code", "Element Code");
                PayrollLedgerEntry.SetRange("Employee No.", "No.");
                PayrollLedgerEntry.SetRange("Period Code", PeriodCode);
                if PayrollLedgerEntry.FindSet then
                    repeat
                        if PayrollLedgerEntry."Payroll Amount" <> 0 then
                            if PayrollLedgerEntry."Print Priority" <> 0 then
                                if PayrollLedgerEntry."Element Type" <> PayrollLedgerEntry."Element Type"::"Income Tax" then begin
                                    PayrollCalcBuffer."No." := PayrollLedgerEntry."Employee No.";
                                    PayrollCalcBuffer."Element Code" := PayrollLedgerEntry."Element Code";

                                    case PayrollLedgerEntry."Element Type" of
                                        PayrollLedgerEntry."Element Type"::"Tax Deduction",
                                      PayrollLedgerEntry."Element Type"::Deduction:
                                            PayrollCalcBuffer.Amount := -PayrollLedgerEntry."Payroll Amount";
                                        else
                                            PayrollCalcBuffer.Amount := PayrollLedgerEntry."Payroll Amount";
                                    end;

                                    PayrollCalcBuffer."Print Priority" := PayrollLedgerEntry."Print Priority";
                                    PayrollCalcBuffer."Line No." := PayrollCalcBuffer."Line No." + 10000;
                                    PayrollCalcBuffer.Insert;
                                end;
                    until PayrollLedgerEntry.Next = 0;
            end;

            trigger OnPostDataItem()
            begin
                PayrollCalcBuffer.SetCurrentKey("Element Code", "No.");
                if PayrollCalcBuffer.FindSet then
                    repeat
                        if not ColumnBuffer.Get(PayrollCalcBuffer."Element Code") then begin
                            ColumnBuffer."Element Code" := PayrollCalcBuffer."Element Code";
                            PayrollElement.Get(ColumnBuffer."Element Code");
                            ColumnBuffer."Element Description" := PayrollElement.Description;
                            ColumnBuffer."Print Priority" := PayrollCalcBuffer."Print Priority";
                            ColumnBuffer.Insert;
                        end;
                    until PayrollCalcBuffer.Next = 0;

                PayrollCalcBuffer.SetCurrentKey("No.", "Print Priority", "Element Code");
                if PayrollCalcBuffer.FindSet then
                    repeat
                        if EmployeeBuffer."No." <> PayrollCalcBuffer."No." then begin
                            Employee.Get(PayrollCalcBuffer."No.");
                            EmployeeBuffer."No." := PayrollCalcBuffer."No.";
                            EmployeeBuffer."Last Name & Initials" := Employee."Last Name" + ' ' + Employee.Initials;
                            EmployeeBuffer."Appointment Name" := Employee.GetJobTitleName;
                            EmployeeBuffer.Insert;
                        end;
                    until PayrollCalcBuffer.Next = 0;

                EmployeeBuffer.Days :=
                  TimesheetMgt.GetTimesheetInfo(
                    "No.", HumanResSetup."Work Time Group Code",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 2);
                EmployeeBuffer.Hours :=
                  TimesheetMgt.GetTimesheetInfo(
                    "No.", HumanResSetup."Work Time Group Code",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 3);
                EmployeeBuffer."Hours Tariff" :=
                  TimesheetMgt.GetTimesheetInfo(
                    "No.", HumanResSetup."Tariff Work Group Code",
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date", 2);
            end;

            trigger OnPreDataItem()
            begin
                FilterText := Employee.GetFilters;

                CompanyInfo.Get;

                HumanResSetup.TestField("Work Time Group Code");
                HumanResSetup.TestField("Tariff Work Group Code");
            end;
        }
        dataitem(Line; "Integer")
        {
            DataItemTableView = SORTING(Number);
            dataitem(Column; "Integer")
            {
                DataItemTableView = SORTING(Number);

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        ColumnBuffer.FindSet
                    else
                        ColumnBuffer.Next;

                    PayrollCalcBuffer.SetRange("No.", EmployeeBuffer."No.");
                    PayrollCalcBuffer.SetRange("Element Code", ColumnBuffer."Element Code");
                    PayrollCalcBuffer.CalcSums(Amount);

                    FillCell(ExcelMgt.ColumnNo2Name(FirstColumnNo + Number) + Format(RowNo), FormatAmount(PayrollCalcBuffer.Amount), false, 1, 1);
                end;

                trigger OnPostDataItem()
                begin
                    RowNo += 1;
                end;

                trigger OnPreDataItem()
                begin
                    ColumnBuffer.SetCurrentKey("Print Priority");
                    SetRange(Number, 1, ColumnBuffer.Count);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    EmployeeBuffer.FindSet
                else
                    EmployeeBuffer.Next;

                FillCell('A' + Format(RowNo), Format(Number), false, 1, 0);
                FillCell('B' + Format(RowNo), EmployeeBuffer."No.", false, 1, 0);
                FillCell('C' + Format(RowNo), EmployeeBuffer."Last Name & Initials", false, 1, 0);
                FillCell('D' + Format(RowNo), EmployeeBuffer."Appointment Name", false, 1, 0);
                FillCell('E' + Format(RowNo), FormatAmount(EmployeeBuffer.Days), false, 1, 1);
                FillCell('F' + Format(RowNo), FormatAmount(EmployeeBuffer.Hours), false, 1, 1);
                FillCell('G' + Format(RowNo), FormatAmount(EmployeeBuffer."Hours Tariff"), false, 1, 1);
            end;

            trigger OnPreDataItem()
            var
                FirstCellToMergeName: Text[30];
                LastCellToMergeName: Text[30];
            begin
                SetRange(Number, 1, EmployeeBuffer.Count);

                RowNo := 5;

                FillCell('A' + Format(RowNo), '³ »/»', true, 1, 0);
                FillCell('B' + Format(RowNo), 'ÆáíÑ½ý¡Ù® ³', true, 1, 0);
                FillCell('C' + Format(RowNo), 'öá¼¿½¿´ ê.Ä.', true, 1, 0);
                FillCell('D' + Format(RowNo), 'çá¡¿¼áÑ¼á´ ñ«½ª¡«ßÔý', true, 1, 0);
                FillCell('E' + Format(RowNo), 'è«½-ó« «ÔÓáí. ñ¡Ñ®', true, 1, 0);
                FillCell('F' + Format(RowNo), 'è«½-ó« «ÔÓáí. þáß«ó', true, 1, 0);
                FillCell('G' + Format(RowNo), 'è«½-ó« «ÔÓáí. þáß«ó »« ÔáÓ¿õÒ', true, 1, 0);
                FillCell('H' + Format(RowNo), 'é¿ñÙ ñ«Õ«ñ«ó, ½ýú«Ô ¿ ÒñÑÓªá¡¿®', true, 1, 0);

                ExcelMgt.SetColumnSize('A' + Format(RowNo), 3);
                ExcelMgt.SetColumnSize('B' + Format(RowNo), 11);
                ExcelMgt.SetColumnSize('C' + Format(RowNo), 20);
                ExcelMgt.SetColumnSize('D' + Format(RowNo), 15);
                ExcelMgt.SetColumnSize('E' + Format(RowNo), 8);
                ExcelMgt.SetColumnSize('F' + Format(RowNo), 8);
                ExcelMgt.SetColumnSize('G' + Format(RowNo), 8);
                ExcelMgt.SetColumnSize('H' + Format(RowNo), 11);

                ExcelMgt.MergeCells('A' + Format(RowNo), 'A' + Format(RowNo + 1));
                ExcelMgt.MergeCells('B' + Format(RowNo), 'B' + Format(RowNo + 1));
                ExcelMgt.MergeCells('C' + Format(RowNo), 'C' + Format(RowNo + 1));
                ExcelMgt.MergeCells('D' + Format(RowNo), 'D' + Format(RowNo + 1));
                ExcelMgt.MergeCells('E' + Format(RowNo), 'E' + Format(RowNo + 1));
                ExcelMgt.MergeCells('F' + Format(RowNo), 'F' + Format(RowNo + 1));
                ExcelMgt.MergeCells('G' + Format(RowNo), 'G' + Format(RowNo + 1));

                FirstColumnNo := 7;

                if ColumnBuffer.Count > 1 then begin
                    FirstCellToMergeName := ExcelMgt.ColumnNo2Name(FirstColumnNo + 1) + Format(RowNo);
                    LastCellToMergeName := ExcelMgt.ColumnNo2Name(FirstColumnNo + ColumnBuffer.Count) + Format(RowNo);
                    ExcelMgt.MergeCells(FirstCellToMergeName, LastCellToMergeName);
                end;

                RowNo += 1;

                if ColumnBuffer.FindSet then
                    repeat
                        Counter += 1;
                        ColumnName := ExcelMgt.ColumnNo2Name(FirstColumnNo + Counter);
                        FillCell(ColumnName + Format(RowNo), ColumnBuffer."Element Description", true, 1, 0);
                        ExcelMgt.SetColumnSize(ColumnName + Format(RowNo), 11);
                    until ColumnBuffer.Next = 0;

                RowNo += 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PeriodCode; PeriodCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Pay Period';
                        TableRelation = "Payroll Period";

                        trigger OnValidate()
                        begin
                            PeriodCodeOnAfterValidate;
                        end;
                    }
                    field(PreviewMode; PreviewMode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview';
                        ToolTip = 'Specifies that the report can be previewed.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PeriodCode := PayrollPeriod.PeriodByDate(WorkDate);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook('Spreadsheet emploee.xlsx');
    end;

    trigger OnPreReport()
    begin
        HumanResSetup.Get;
        CompanyInfo.Get;

        if PreviewMode then
            DocNo := 'XXXXXXXXXX'
        else begin
            HumanResSetup.TestField("Paysheet Nos.");
            DocNo := NoSeriesMgt.GetNextNo(HumanResSetup."Paysheet Nos.", WorkDate, true);
        end;

        ExcelMgt.CreateBook;
        FillCell('A1', 'ÄÓúá¡¿ºáµ¿´: ' + LocalRepMgt.GetCompanyName, true, 0, 0);
        FillCell('A2', 'ÉáßþÑÔ¡á´ óÑñ«¼«ßÔý »« ºáÓ»½áÔÑ ß«ÔÓÒñ¡¿¬«ó ³ ' + DocNo, true, 0, 0);
        FillCell('A3', 'ôþÑÔ¡Ù® »ÑÓ¿«ñ ß ' +
          Format(PayrollPeriod."Starting Date") + ' »« ' +
          Format(PayrollPeriod."Ending Date"), true, 0, 0);
    end;

    var
        PayrollElement: Record "Payroll Element";
        HumanResSetup: Record "Human Resources Setup";
        CompanyInfo: Record "Company Information";
        PayrollCalcBuffer: Record "Payroll Calc List Column" temporary;
        PayrollLedgerEntry: Record "Payroll Ledger Entry";
        EmployeeBuffer: Record "Payroll Calc List Line" temporary;
        ColumnBuffer: Record "Payroll Calc List Header" temporary;
        PayrollPeriod: Record "Payroll Period";
        LocalRepMgt: Codeunit "Local Report Management";
        ExcelMgt: Codeunit "Excel Management";
        TimesheetMgt: Codeunit "Timesheet Management RU";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        PeriodCode: Code[10];
        FirstColumnNo: Integer;
        RowNo: Integer;
        Counter: Integer;
        DocNo: Code[10];
        FilterText: Text[200];
        ColumnName: Text[30];
        PreviewMode: Boolean;

    [Scope('OnPrem')]
    procedure FormatAmount(Amount: Decimal): Text[50]
    begin
        if Amount = 0 then
            exit('');

        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,1>'));
    end;

    [Scope('OnPrem')]
    procedure FillCell(CellName: Text[30]; CellValue: Text[250]; Bold: Boolean; Borders: Option "None",Thin,Medium; CellFormat: Option Text,Decimal)
    begin
        ExcelMgt.FillCell(CellName, CellValue);

        if CellFormat = CellFormat::Decimal then
            ExcelMgt.SetCellNumberFormat(CellName, '0,00');
    end;

    local procedure PeriodCodeOnAfterValidate()
    begin
        PayrollPeriod.Get(PeriodCode);
    end;
}

