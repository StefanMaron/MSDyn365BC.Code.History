report 17454 "Spreadsheet Addition & Deduct"
{
    Caption = 'Spreadsheet Addition & Deduct';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);

            trigger OnAfterGetRecord()
            begin
                AdditionDesc := '';
                DeductionDesc := '';
                AdditionAmount := 0;
                DeductionAmount := 0;
                if Number = 1 then begin
                    if AdditionBuffer.FindSet then
                        GetDataFromBuffer(AdditionBuffer, AdditionDesc, AdditionAmount);
                    if DeductionBuffer.FindSet then
                        GetDataFromBuffer(DeductionBuffer, DeductionDesc, DeductionAmount);
                end else begin
                    if AdditionBuffer.Next <> 0 then
                        GetDataFromBuffer(AdditionBuffer, AdditionDesc, AdditionAmount);
                    if DeductionBuffer.Next <> 0 then
                        GetDataFromBuffer(DeductionBuffer, DeductionDesc, DeductionAmount);
                end;

                DeductionAmount := -DeductionAmount;

                AdditionTotalAmount += AdditionAmount;
                DeductionTotalAmount += DeductionAmount;

                FillCell('A' + Format(RowNo), AdditionDesc, false, 1, 1);
                FillCell('B' + Format(RowNo), FormatAmount(AdditionAmount), false, 1, 1);
                FillCell('C' + Format(RowNo), DeductionDesc, false, 1, 1);
                FillCell('D' + Format(RowNo), FormatAmount(DeductionAmount), false, 1, 1);

                RowNo += 1;
            end;

            trigger OnPostDataItem()
            begin
                FillCell('C' + Format(RowNo), 'æá½ýñ« ¡áþá½ý¡«Ñ, ÓÒí.', true, 1, 0);
                FillCell('D' + Format(RowNo), FormatAmount(StartingBalance), true, 1, 1);
                RowNo += 1;

                FillCell('A' + Format(RowNo), 'êÔ«ú« ¡áþ¿ß½Ñ¡«, ÓÒí.', true, 1, 0);
                FillCell('B' + Format(RowNo), FormatAmount(AdditionTotalAmount), true, 1, 1);
                FillCell('C' + Format(RowNo), 'êÔ«ú« ÒñÑÓªá¡«, ÓÒí.', true, 1, 0);
                FillCell('D' + Format(RowNo), FormatAmount(DeductionTotalAmount + StartingBalance), true, 1, 1);
                RowNo += 1;

                FillCell('A' + Format(RowNo), 'è óÙñáþÑ, ÓÒí.', true, 1, 0);
                FillCell('B' + Format(RowNo),
                  FormatAmount(AdditionTotalAmount - DeductionTotalAmount - StartingBalance - EndingBalance), true, 1, 1);
                RowNo += 1;

                FillCell('A' + Format(RowNo), 'æá½ýñ« ¬«¡Ñþ¡«Ñ, ÓÒí.', true, 1, 0);
                FillCell('B' + Format(RowNo), FormatAmount(EndingBalance), true, 1, 1);
            end;

            trigger OnPreDataItem()
            begin
                HumanResSetup.Get;

                FillInElementsBuffer;
                AdditionBuffer.Reset;
                DeductionBuffer.Reset;
                AdditionBuffer.SetCurrentKey(Description);
                DeductionBuffer.SetCurrentKey(Description);
                AdditionBufferCount := AdditionBuffer.Count;
                DeductionBufferCount := DeductionBuffer.Count;

                if AdditionBufferCount >= DeductionBufferCount then
                    SetRange(Number, 1, AdditionBufferCount)
                else
                    SetRange(Number, 1, DeductionBufferCount);

                ExcelMgt.CreateBook;
                FillCell('A1', 'ÄÓúá¡¿ºáµ¿´: ' + LocalRepMngt.GetCompanyName, true, 0, 0);
                if OrgUnitCode <> '' then begin
                    OrganizationalUnit.Get(OrgUnitCode);
                    OrgUnitName := OrganizationalUnit.Name;
                end;
                FillCell('A2', 'Å«ñÓáºñÑ½Ñ¡¿Ñ: ' + OrgUnitName, true, 0, 0);
                FillCell('A3', 'æó«ñ¡á´ óÑñ«¼«ßÔý ¡áþ¿ß½Ñ¡¿® ¿ ÒñÑÓªá¡¿® ³ ' + DocumentNo, true, 0, 0);
                FillCell('A4', 'ºá ' + PayrollPeriod.Name, true, 0, 0);

                ExcelMgt.SetColumnSize('A6', 30);
                ExcelMgt.SetColumnSize('B6', 11);
                ExcelMgt.SetColumnSize('C6', 30);
                ExcelMgt.SetColumnSize('D6', 11);

                FillCell('A6', 'ìá¿¼Ñ¡«óá¡Ñ ¡áþ¿ß½Ñ¡¿®', true, 1, 0);
                FillCell('B6', 'æÒ¼¼á', true, 1, 0);
                FillCell('C6', 'ìá¿¼Ñ¡«óá¡Ñ ÒñÑÓªá¡¿®', true, 1, 0);
                FillCell('D6', 'æÒ¼¼á', true, 1, 0);
                RowNo := 7;
            end;
        }
        dataitem(OtherIncome; "Integer")
        {
            DataItemTableView = SORTING(Number);

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OtherIncomeBuffer.FindSet
                else
                    OtherIncomeBuffer.Next;

                RowNo += 1;

                FillCell('A' + Format(RowNo), OtherIncomeBuffer.Description, false, 1, 1);
                FillCell('B' + Format(RowNo), FormatAmount(OtherIncomeBuffer."Amount 1"), false, 1, 1);
            end;

            trigger OnPreDataItem()
            begin
                OtherIncomeBuffer.Reset;
                OtherIncomeBuffer.SetCurrentKey(Description);
                SetRange(Number, 1, OtherIncomeBuffer.Count);

                if OtherIncomeBuffer.Count >= 1 then begin
                    RowNo += 1;
                    FillCell('A' + Format(RowNo), 'ÅÓ«þ¿Ñ ñ«Õ«ñÙ', true, 0, 0);
                end;
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
                        TableRelation = "Payroll Period";

                        trigger OnValidate()
                        begin
                            PeriodCodeOnAfterValidate;
                        end;
                    }
                    field(OrgUnitCode; OrgUnitCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Org. Unit Code';
                        TableRelation = "Organizational Unit";
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
        ExcelMgt.DownloadBook('Spreadsheet Addition & Deduct.xlsx');
    end;

    var
        OrganizationalUnit: Record "Organizational Unit";
        PayrollDocLine: Record "Payroll Document Line";
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        HumanResSetup: Record "Human Resources Setup";
        AdditionBuffer: Record "Element Buffer" temporary;
        DeductionBuffer: Record "Element Buffer" temporary;
        OtherIncomeBuffer: Record "Element Buffer" temporary;
        PayrollPeriod: Record "Payroll Period";
        LocalRepMngt: Codeunit "Local Report Management";
        ExcelMgt: Codeunit "Excel Management";
        PeriodCode: Code[10];
        StartingBalance: Decimal;
        EndingBalance: Decimal;
        AdditionAmount: Decimal;
        DeductionAmount: Decimal;
        AdditionTotalAmount: Decimal;
        DeductionTotalAmount: Decimal;
        AdditionBufferCount: Integer;
        DeductionBufferCount: Integer;
        RowNo: Integer;
        OrgUnitCode: Code[20];
        DocumentNo: Code[20];
        AdditionDesc: Text[50];
        DeductionDesc: Text[50];
        OrgUnitName: Text[50];
        DataSource: Option "Posted Entries","Payroll Documents";

    [Scope('OnPrem')]
    procedure FillInElementsBuffer()
    var
        PayrollElement: Record "Payroll Element";
    begin
        case DataSource of
            DataSource::"Payroll Documents":
                begin
                    PayrollDocLine.Reset;
                    PayrollDocLine.SetRange("Period Code", PeriodCode);
                    PayrollDocLine.SetFilter("Payroll Amount", '<>0');
                    if OrgUnitCode <> '' then
                        PayrollDocLine.SetRange("Org. Unit Code", OrgUnitCode);
                    if PayrollDocLine.FindSet then
                        repeat
                            PayrollElement.Get(PayrollDocLine."Element Code");
                            if PayrollDocLine."Print Priority" = 74 then // Other income
                                UpdateBuffer(OtherIncomeBuffer, PayrollElement, PayrollDocLine."Payroll Amount")
                            else
                                if PayrollDocLine."Payroll Amount" > 0 then
                                    UpdateBuffer(AdditionBuffer, PayrollElement, PayrollDocLine."Payroll Amount")
                                else
                                    UpdateBuffer(DeductionBuffer, PayrollElement, PayrollDocLine."Payroll Amount");

                        until PayrollDocLine.Next = 0;
                end;
            DataSource::"Posted Entries":
                begin
                    PayrollLedgEntry.Reset;
                    PayrollLedgEntry.SetRange("Period Code", PeriodCode);
                    if OrgUnitCode <> '' then
                        PayrollLedgEntry.SetRange("Org. Unit Code", OrgUnitCode);
                    if PayrollLedgEntry.FindSet then
                        repeat
                            PayrollElement.Get(PayrollLedgEntry."Element Code");
                            if PayrollLedgEntry."Print Priority" = 74 then  // Other income
                                UpdateBuffer(OtherIncomeBuffer, PayrollElement, PayrollLedgEntry."Payroll Amount")
                            else
                                if PayrollLedgEntry."Payroll Amount" > 0 then
                                    UpdateBuffer(AdditionBuffer, PayrollElement, PayrollLedgEntry."Payroll Amount")
                                else
                                    UpdateBuffer(DeductionBuffer, PayrollElement, PayrollLedgEntry."Payroll Amount");
                        until PayrollLedgEntry.Next = 0;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateBuffer(var Buffer: Record "Element Buffer"; PayrollElement: Record "Payroll Element"; Amount: Decimal)
    var
        EntryNo: Integer;
    begin
        Buffer.Reset;
        if Buffer.FindLast then;
        EntryNo := Buffer."Entry No." + 1;
        Buffer.SetRange("Element Code", PayrollElement.Code);
        if Buffer.FindFirst then begin
            Buffer."Amount 1" += Amount;
            Buffer.Modify;
        end else begin
            Buffer."Entry No." := EntryNo;
            Buffer."Element Code" := PayrollElement.Code;
            Buffer.Description := PayrollElement.Description;
            Buffer."Amount 1" := Amount;
            Buffer.Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcAmount(ElementCode: Code[20]): Decimal
    begin
        case DataSource of
            DataSource::"Payroll Documents":
                begin
                    PayrollDocLine.Reset;
                    PayrollDocLine.SetRange("Element Code", ElementCode);
                    if OrgUnitCode <> '' then
                        PayrollDocLine.SetRange("Org. Unit Code", OrgUnitCode);
                    PayrollDocLine.SetRange("Period Code", PeriodCode);
                    PayrollDocLine.CalcSums("Payroll Amount");
                    exit(PayrollDocLine."Payroll Amount");
                end;
            DataSource::"Posted Entries":
                begin
                    PayrollLedgEntry.Reset;
                    PayrollLedgEntry.SetCurrentKey(
                      "Org. Unit Code", "Element Type", "Element Code", "Posting Date", "Period Code");
                    PayrollLedgEntry.SetRange("Element Code", ElementCode);
                    if OrgUnitCode <> '' then
                        PayrollLedgEntry.SetRange("Org. Unit Code", OrgUnitCode);
                    PayrollLedgEntry.SetRange("Period Code", PeriodCode);
                    PayrollLedgEntry.CalcSums("Payroll Amount");
                    exit(PayrollLedgEntry."Payroll Amount");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDataFromBuffer(Buffer: Record "Element Buffer"; var Description: Text[50]; var Amount: Decimal)
    begin
        Description := Buffer.Description;
        Amount := Buffer."Amount 1";
    end;

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

