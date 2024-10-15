report 17453 "Spreadsheet Account"
{
    Caption = 'Spreadsheet Account';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    Buffer.FindSet
                else
                    Buffer.Next;

                FillCell('A' + Format(RowNo), Format(Number), false, 1, 0);
                FillCell('B' + Format(RowNo), Buffer.Description, false, 1, 0);
                FillCell('C' + Format(RowNo), Buffer."Account No. 1", false, 1, 0);
                FillCell('D' + Format(RowNo), Buffer."Account No. 2", false, 1, 0);
                FillCell('E' + Format(RowNo), FormatAmount(Buffer."Amount 1"), false, 1, 1);
                FillCell('F' + Format(RowNo), FormatAmount(Buffer."Amount 2"), false, 1, 1);

                TotalTaxAmount += Buffer."Amount 1";
                TotalPaymentAmount += Buffer."Amount 2";
                RowNo += 1;
            end;

            trigger OnPostDataItem()
            begin
                ExcelMgt.MergeCells('A' + Format(RowNo), 'D' + Format(RowNo));
                FillCell('A' + Format(RowNo), 'êÔ«ú«, ÓÒí.', true, 1, 0);

                FillCell('E' + Format(RowNo), FormatAmount(TotalTaxAmount), true, 1, 1);
                FillCell('F' + Format(RowNo), FormatAmount(TotalPaymentAmount), true, 1, 1);
            end;

            trigger OnPreDataItem()
            begin
                FillInBuffer;

                Buffer.Reset;
                Buffer.SetCurrentKey(Description);
                SetRange(Number, 1, Buffer.Count);

                ExcelMgt.CreateBook;
                ExcelMgt.OpenSheetByNumber(1);
                FillCell('A1', 'ÄÓúá¡¿ºáµ¿´: ' + LocalRepMngt.GetCompanyName, true, 0, 0);
                if OrgUnitCode <> '' then begin
                    OrganizationalUnit.Get(OrgUnitCode);
                    OrgUnitName := OrganizationalUnit.Name;
                end;
                FillCell('A2', 'Å«ñÓáºñÑ½Ñ¡¿Ñ: ' + OrgUnitName, true, 0, 0);
                FillCell('A3', 'æó«ñ¡á´ óÑñ«¼«ßÔý »Ó«ó«ñ«¬ »« »ÓÑñ»Ó¿´Ô¿¯ ³ ' + DocumentNo, true, 0, 0);
                FillCell('A4', StrSubstNo('ôþÑÔ¡Ù® »ÑÓ¿«ñ «Ô %1 ñ« %2',
                    PayrollPeriod."Starting Date", PayrollPeriod."Ending Date"), true, 0, 0);

                FillCell('A6', '³ »/»', true, 1, 0);
                FillCell('B6', 'ö¿¡á¡ß«óá´ «»ÑÓáµ¿´', true, 1, 0);
                FillCell('C6', 'æþÑÔ - ñÑíÑÔ', true, 1, 0);
                FillCell('D6', 'æþÑÔ - ¬ÓÑñ¿Ô', true, 1, 0);
                FillCell('E6', 'ö«¡ñ «»½áÔÙ ÔÓÒñá', true, 1, 0);
                FillCell('F6', 'ÉÑºÒ½ýÔáÔ', true, 1, 0);

                ExcelMgt.SetColumnSize('A6', 3);
                ExcelMgt.SetColumnSize('B6', 36);
                ExcelMgt.SetColumnSize('C6', 10);
                ExcelMgt.SetColumnSize('D6', 10);
                ExcelMgt.SetColumnSize('E6', 11);
                ExcelMgt.SetColumnSize('F6', 11);

                RowNo := 7;
            end;
        }
        dataitem(AgregateEntries; "Integer")
        {
            DataItemTableView = SORTING(Number);

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    AgregateBuffer.FindSet
                else
                    AgregateBuffer.Next;

                FillCell('A' + Format(RowNo), AgregateBuffer."Account No. 1", false, 1, 0);
                FillCell('B' + Format(RowNo), AgregateBuffer."Account No. 2", false, 1, 0);
                FillCell('C' + Format(RowNo), FormatAmount(AgregateBuffer."Number 1"), false, 1, 0);
                FillCell('D' + Format(RowNo), FormatAmount(AgregateBuffer."Amount 1"), false, 1, 1);
                FillCell('E' + Format(RowNo), FormatAmount(AgregateBuffer."Amount 2"), false, 1, 1);

                RowNo += 1;
            end;

            trigger OnPostDataItem()
            begin
                ExcelMgt.MergeCells('A' + Format(RowNo), 'C' + Format(RowNo));
                FillCell('A' + Format(RowNo), 'êÔ«ú«, ÓÒí.', true, 1, 0);

                FillCell('D' + Format(RowNo), FormatAmount(TotalTaxAmount), true, 1, 1);
                FillCell('E' + Format(RowNo), FormatAmount(TotalPaymentAmount), true, 1, 1);
            end;

            trigger OnPreDataItem()
            begin
                EntryNo := 0;
                if Buffer.FindSet then
                    repeat
                        AgregateBuffer.SetRange("Account No. 1", Buffer."Account No. 1");
                        AgregateBuffer.SetRange("Account No. 2", Buffer."Account No. 2");
                        if AgregateBuffer.FindFirst then begin
                            AgregateBuffer."Amount 1" += Buffer."Amount 1";
                            AgregateBuffer."Amount 2" += Buffer."Amount 2";
                            AgregateBuffer."Number 1" += 1;
                            AgregateBuffer.Modify;
                        end else begin
                            EntryNo += 1;
                            AgregateBuffer."Entry No." := EntryNo;
                            AgregateBuffer."Account No. 1" := Buffer."Account No. 1";
                            AgregateBuffer."Account No. 2" := Buffer."Account No. 2";
                            AgregateBuffer."Amount 1" := Buffer."Amount 1";
                            AgregateBuffer."Amount 2" := Buffer."Amount 2";
                            AgregateBuffer."Number 1" := 1;
                            AgregateBuffer.Insert;
                        end;
                    until Buffer.Next = 0;

                AgregateBuffer.Reset;

                SetRange(Number, 1, AgregateBuffer.Count);

                ExcelMgt.OpenSheetByNumber(2);
                FillCell('A1', 'êÔ«ú¿ »« »Ó«ó«ñ¬á¼', true, 0, 0);

                FillCell('A3', 'æþÑÔ - ñÑíÑÔ', true, 1, 0);
                FillCell('B3', 'æþÑÔ - ¬ÓÑñ¿Ô', true, 1, 0);
                FillCell('C3', 'è«½¿þÑßÔó« »Ó«ó«ñ«¬', true, 1, 0);
                FillCell('D3', 'ö«¡ñ «»½áÔÙ ÔÓÒñá', true, 1, 0);
                FillCell('E3', 'ÉÑºÒ½ýÔáÔ', true, 1, 0);

                ExcelMgt.SetColumnSize('A3', 10);
                ExcelMgt.SetColumnSize('B3', 10);
                ExcelMgt.SetColumnSize('C3', 12);
                ExcelMgt.SetColumnSize('D3', 11);
                ExcelMgt.SetColumnSize('E3', 11);

                RowNo := 4;
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
        ExcelMgt.DownloadBook('Spreadsheet account.xlsx');
    end;

    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        OrganizationalUnit: Record "Organizational Unit";
        PayrollElement: Record "Payroll Element";
        PayrollDocLine: Record "Payroll Document Line";
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        PayrollPostingGroup: Record "Payroll Posting Group";
        Buffer: Record "Element Buffer" temporary;
        AgregateBuffer: Record "Element Buffer" temporary;
        PayrollPeriod: Record "Payroll Period";
        LocalRepMngt: Codeunit "Local Report Management";
        ExcelMgt: Codeunit "Excel Management";
        DataSource: Option "Posted Entries","Payroll Documents";
        PeriodCode: Code[10];
        OrgUnitCode: Code[20];
        DocumentNo: Code[20];
        OrgUnitName: Text[50];
        RowNo: Integer;
        EntryNo: Integer;
        TotalTaxAmount: Decimal;
        TotalPaymentAmount: Decimal;

    [Scope('OnPrem')]
    procedure FillInBuffer()
    begin
        case DataSource of
            DataSource::"Posted Entries":
                begin
                    PayrollLedgEntry.SetRange("Period Code", PeriodCode);
                    if OrgUnitCode <> '' then
                        PayrollLedgEntry.SetRange("Org. Unit Code", OrgUnitCode);
                    if PayrollLedgEntry.FindSet then
                        repeat
                            UpdateBuffer(
                              PayrollLedgEntry."Element Code",
                              PayrollLedgEntry."Posting Group",
                              PayrollLedgEntry."Taxable Amount",
                              PayrollLedgEntry."Payroll Amount")
                        until PayrollLedgEntry.Next = 0;
                end;
            DataSource::"Payroll Documents":
                begin
                    PayrollDocLine.SetRange("Period Code", PeriodCode);
                    if OrgUnitCode <> '' then
                        PayrollDocLine.SetRange("Org. Unit Code", OrgUnitCode);
                    if PayrollDocLine.FindSet then
                        repeat
                            UpdateBuffer(
                              PayrollDocLine."Element Code",
                              PayrollDocLine."Posting Group",
                              PayrollDocLine."Taxable Amount",
                              PayrollDocLine."Payroll Amount")
                        until PayrollDocLine.Next = 0;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateBuffer(ElementCode: Code[20]; PayrollPostingGroupCode: Code[20]; TaxableAmount: Decimal; PayrollAmount: Decimal)
    var
        DebitAccountNo: Code[20];
        CreditAccountNo: Code[20];
    begin
        PayrollElement.Get(ElementCode);
        PayrollPostingGroup.Get(PayrollPostingGroupCode);
        DebitAccountNo := PayrollPostingGroup."Account No.";
        case PayrollPostingGroup."Account Type" of
            PayrollPostingGroup."Account Type"::"G/L Account":
                CreditAccountNo := PayrollPostingGroup."Account No.";
            PayrollPostingGroup."Account Type"::Vendor:
                begin
                    PayrollPostingGroup.TestField("Account No.");
                    Vendor.Get(PayrollPostingGroup."Account No.");
                    Vendor.TestField("Vendor Posting Group");
                    VendorPostingGroup.Get(Vendor."Vendor Posting Group");
                    CreditAccountNo := VendorPostingGroup."Payables Account";
                end;
        end;

        Buffer.Reset;
        if Buffer.FindLast then;
        EntryNo := Buffer."Entry No." + 1;
        Buffer.SetRange("Element Code", ElementCode);
        Buffer.SetRange("Account No. 1", DebitAccountNo);
        Buffer.SetRange("Account No. 2", CreditAccountNo);
        if Buffer.FindFirst then begin
            Buffer."Amount 1" += TaxableAmount;
            Buffer."Amount 2" += PayrollAmount;
            Buffer.Modify;
        end else begin
            Buffer."Entry No." := EntryNo;
            Buffer."Element Code" := ElementCode;
            Buffer."Account No. 1" := DebitAccountNo;
            Buffer."Account No. 2" := CreditAccountNo;
            Buffer."Amount 1" := TaxableAmount;
            Buffer."Amount 2" := PayrollAmount;
            Buffer.Description := PayrollElement.Description;
            Buffer.Insert;
        end;
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
}

