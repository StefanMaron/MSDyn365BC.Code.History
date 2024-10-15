report 17452 Spreadsheet
{
    Caption = 'Spreadsheet';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Organizational Unit"; "Organizational Unit")
        {
            DataItemTableView = WHERE(Type = CONST(Unit));
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            begin
                case DataSource of
                    DataSource::"Payroll Documents":
                        begin
                            PayrollDocLine.SetRange("Org. Unit Code", Code);
                            PayrollDocLine.SetRange("Period Code", PeriodCode);

                            PayrollDocLine.SetFilter("Element Type", '%1|%2',
                              PayrollDocLine."Element Type"::Wage,
                              PayrollDocLine."Element Type"::Bonus);
                            PayrollDocLine.CalcSums(Amount);
                            AddedAmount := PayrollDocLine.Amount;

                            PayrollDocLine.SetFilter("Element Type", '%1|%2',
                              PayrollDocLine."Element Type"::"Income Tax",
                              PayrollDocLine."Element Type"::Deduction);
                            PayrollDocLine.CalcSums(Amount);
                            DeductedAmount := Abs(PayrollDocLine.Amount);

                            ToPayAmount := AddedAmount - DeductedAmount;
                        end;
                    DataSource::"Posted Entries":
                        begin
                            PayrollLedgEntry.SetCurrentKey(
                              "Org. Unit Code", "Element Type", "Element Code", "Posting Date", "Period Code");
                            PayrollLedgEntry.SetRange("Org. Unit Code", Code);
                            PayrollLedgEntry.SetRange("Period Code", PeriodCode);
                            PayrollLedgEntry.SetFilter("Element Type", '%1|%2',
                              PayrollLedgEntry."Element Type"::Wage,
                              PayrollLedgEntry."Element Type"::Bonus);
                            PayrollLedgEntry.CalcSums("Payroll Amount");
                            AddedAmount := PayrollLedgEntry."Payroll Amount";
                            PayrollLedgEntry.SetFilter("Element Type", '%1|%2',
                              PayrollLedgEntry."Element Type"::"Income Tax",
                              PayrollLedgEntry."Element Type"::Deduction);
                            PayrollLedgEntry.CalcSums("Payroll Amount");
                            DeductedAmount := Abs(PayrollLedgEntry."Payroll Amount");

                            ToPayAmount := AddedAmount - DeductedAmount;
                        end;
                end;

                TotalAddedAmount += AddedAmount;
                TotalDeductedAmount += DeductedAmount;
                TotalToPayAmount += ToPayAmount;

                FillCell('A' + Format(RowNo), Format(RowNo - 5), false, 1, 0);
                FillCell('B' + Format(RowNo), Code, false, 1, 0);
                FillCell('C' + Format(RowNo), Name, false, 1, 0);
                FillCell('D' + Format(RowNo), FormatAmount(AddedAmount), false, 1, 1);
                FillCell('E' + Format(RowNo), FormatAmount(DeductedAmount), false, 1, 1);
                FillCell('F' + Format(RowNo), FormatAmount(ToPayAmount), false, 1, 1);

                RowNo += 1;
            end;

            trigger OnPostDataItem()
            begin
                ExcelMgt.MergeCells('A' + Format(RowNo), 'C' + Format(RowNo));
                FillCell('A' + Format(RowNo), 'êÔ«ú« »« «Óúá¡¿ºáµ¿¿, ÓÒí.', true, 1, 0);

                FillCell('D' + Format(RowNo), FormatAmount(TotalAddedAmount), true, 1, 1);
                FillCell('E' + Format(RowNo), FormatAmount(TotalDeductedAmount), true, 1, 1);
                FillCell('F' + Format(RowNo), FormatAmount(TotalToPayAmount), true, 1, 1);
            end;

            trigger OnPreDataItem()
            begin
                ExcelMgt.CreateBook;
                FillCell('A1', 'ÄÓúá¡¿ºáµ¿´: ' + LocalRepMngt.GetCompanyName, true, 0, 0);
                FillCell('A2', 'æó«ñ¡á´ óÑñ«¼«ßÔý »« »ÓÑñ»Ó¿´Ô¿¯ ³ ' + DocumentNo, true, 0, 0);
                FillCell('A3', StrSubstNo('ôþÑÔ¡Ù® »ÑÓ¿«ñ «Ô %1 ñ« %2',
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date"), true, 0, 0);

                FillCell('A5', '³ »/»', true, 1, 0);
                FillCell('B5', 'è«ñ »«ñÓáºñÑ½Ñ¡¿´', true, 1, 0);
                FillCell('C5', 'ìá¿¼Ñ¡«óá¡¿Ñ »«ñÓáºñÑ½Ñ¡¿´', true, 1, 0);
                FillCell('D5', 'êÔ«ú« ¡áþ¿ß½Ñ¡«', true, 1, 0);
                FillCell('E5', 'êÔ«ú« ÒñÑÓªá¡«', true, 1, 0);
                FillCell('F5', 'êÔ«ú« ¬ óÙ»½áÔÑ', true, 1, 0);

                ExcelMgt.SetColumnSize('A5', 3);
                ExcelMgt.SetColumnSize('B5', 10);
                ExcelMgt.SetColumnSize('C5', 30);
                ExcelMgt.SetColumnSize('D5', 11);
                ExcelMgt.SetColumnSize('E5', 11);
                ExcelMgt.SetColumnSize('F5', 11);

                RowNo := 6;
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
                    field(DataSource; DataSource)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Data Source';
                        OptionCaption = 'Posted Entries,Payroll Documents';
                    }
                    field(PeriodCode; PeriodCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Pay Period';

                        trigger OnValidate()
                        begin
                            PeriodCodeOnAfterValidate;
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
            PeriodCode := PayrollPeriod.PeriodByDate(WorkDate);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook('Spreadsheet.xlsx');
    end;

    var
        PayrollDocLine: Record "Payroll Document Line";
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        PayrollPeriod: Record "Payroll Period";
        LocalRepMngt: Codeunit "Local Report Management";
        ExcelMgt: Codeunit "Excel Management";
        DataSource: Option "Posted Entries","Payroll Documents";
        PeriodCode: Code[10];
        DocumentNo: Code[20];
        RowNo: Integer;
        AddedAmount: Decimal;
        DeductedAmount: Decimal;
        ToPayAmount: Decimal;
        TotalAddedAmount: Decimal;
        TotalDeductedAmount: Decimal;
        TotalToPayAmount: Decimal;

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

