report 17495 "Employee Vacation Balance"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Employee Vacation Balance';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Employee; Employee)
        {
            DataItemTableView = SORTING("No.");

            trigger OnAfterGetRecord()
            var
                VacationCalculation: Codeunit "Vacation Days Calculation";
                CellColumn: Code[10];
            begin
                CellColumn := 'A';

                FillCell(CellColumn, RowCounter, "No.");
                FillCell(CellColumn, RowCounter, "Short Name");
                FillCell(CellColumn, RowCounter, "Job Title");
                FillCell(CellColumn, RowCounter, TimeActivityCode);

                FillCell(CellColumn, RowCounter, Format(Round(
                      VacationCalculation.CalculateVacationDays("No.", ReportToDate, TimeActivityCode), 0.01)));
                FillCell(CellColumn, RowCounter, Format(Round(
                      VacationCalculation.CalculateUsedVacationDays("No.", ReportToDate, TimeActivityCode), 0.01)));
                FillCell(CellColumn, RowCounter, Format(Round(
                      VacationCalculation.CalculateUnusedVacationDays("No.", ReportToDate, TimeActivityCode), 0.01)));

                RowCounter += 1;
            end;

            trigger OnPreDataItem()
            var
                Text001: Label 'Unused Calendar Days';
                Employee: Record Employee;
                EmployeeAbsenceEntry: Record "Employee Absence Entry";
                CellColumn: Code[10];
            begin
                ExcelMgt.FillCell('A1', EmployeeAbsenceEntry.FieldCaption("Time Activity Code"));
                ExcelMgt.FillCell('B1', TimeActivityCode);
                ExcelMgt.FillCell('C1', Format(ReportToDate));

                RowCounter := 3;
                CellColumn := 'A';

                ExcelMgt.SetColumnSize(CellColumn + Format(RowCounter), 15);
                FillCell(CellColumn, RowCounter, EmployeeAbsenceEntry.FieldCaption("Employee No."));
                ExcelMgt.SetColumnSize(CellColumn + Format(RowCounter), 15);
                FillCell(CellColumn, RowCounter, Employee.FieldCaption("Short Name"));
                ExcelMgt.SetColumnSize(CellColumn + Format(RowCounter), 15);
                FillCell(CellColumn, RowCounter, Employee.FieldCaption("Job Title"));
                ExcelMgt.SetColumnSize(CellColumn + Format(RowCounter), 15);
                FillCell(CellColumn, RowCounter, EmployeeAbsenceEntry.FieldCaption("Time Activity Code"));
                ExcelMgt.SetColumnSize(CellColumn + Format(RowCounter), 15);
                FillCell(CellColumn, RowCounter, EmployeeAbsenceEntry.FieldCaption("Calendar Days"));
                ExcelMgt.SetColumnSize(CellColumn + Format(RowCounter), 15);
                FillCell(CellColumn, RowCounter, EmployeeAbsenceEntry.FieldCaption("Used Calendar Days"));
                ExcelMgt.SetColumnSize(CellColumn + Format(RowCounter), 15);
                FillCell(CellColumn, RowCounter, Text001);

                ExcelMgt.BoldRow(RowCounter);

                RowCounter += 1;
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
                    field(TimeActivityCode; TimeActivityCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Time Activity Code';
                        TableRelation = "Time Activity";
                    }
                    field(ReportToDate; ReportToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Date';
                        ToolTip = 'Specifies when the report was created.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ReportToDate := Today;
    end;

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook('Employee vacation balance.xlsx');
    end;

    trigger OnPreReport()
    begin
        ExcelMgt.CreateBook;
        ExcelMgt.OpenSheetByNumber(1);
    end;

    var
        ExcelMgt: Codeunit "Excel Management";
        RowCounter: Integer;
        TimeActivityCode: Code[10];
        ReportToDate: Date;

    [Scope('OnPrem')]
    procedure FillCell(var CellColumn: Code[10]; RowCounter: Integer; CellText: Text[250])
    begin
        ExcelMgt.FillCell(CellColumn + Format(RowCounter), CellText);
        CellColumn := ExcelMgt.GetNextColumn(CellColumn, 1);
    end;
}

