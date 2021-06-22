codeunit 2129 "O365 Export Invoices + Email"
{

    trigger OnRun()
    begin
    end;

    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        NoInvoicesExportedErr: Label 'There were no invoices to export.';
        InvoicesExportedMsg: Label 'Your exported invoices have been sent.';
        AttachmentNameTxt: Label 'Invoices.xlsx';
        ExportInvoicesEmailSubjectTxt: Label 'Please find the invoices summary and price details from %1 date until %2 date in the attached Excel book.', Comment = '%1 = Start Date, %2 =End Date';
        InvoiceNoFieldTxt: Label 'Invoice No.';
        CustomerNameFieldTxt: Label 'Customer Name';
        AddressFieldTxt: Label 'Address';
        CityFieldTxt: Label 'City';
        CountyFieldTxt: Label 'County';
        CountryRegionCodeFieldTxt: Label 'Country/Region Code';
        InvoiceDateFieldTxt: Label 'Invoice Date';
        NetTotalFieldTxt: Label 'Net Total';
        TotalIncludingVatFieldTxt: Label 'Total Including VAT';
        VatPercentFieldTxt: Label 'VAT %', Comment = 'The heading used when exporting the invoice lines';
        InvoicesSummaryHeaderTxt: Label 'Invoices Summary';
        ItemsHeaderTxt: Label 'Prices';
        InvoicesSheetNameTxt: Label 'Invoices';
        CellBold: Boolean;
        RowNo: Integer;
        LineRowNo: Integer;
        VATAmountTxt: Label 'VAT Amount';
        InvoiceStatusTxt: Label 'Status';
        ExportInvoicesCategoryLbl: Label 'AL Export Invoices', Locked = true;
        ExportInvoicesFailedNoInvoicesTxt: Label 'Export Invoices failed, there are no invoices.', Locked = true;
        ExportInvoicesSuccessTxt: Label 'Export Invoices succeeded.', Locked = true;
        ExportInvoicesFailedSendingTxt: Label 'Export Invoices failed sending.', Locked = true;

    [Scope('OnPrem')]
    procedure ExportInvoicesToExcelandEmail(StartDate: Date; EndDate: Date; Email: Text[80])
    var
        TempEmailItem: Record "Email Item" temporary;
        FileManagement: Codeunit "File Management";
        EmailSuccess: Boolean;
        ServerFileName: Text;
    begin
        SalesInvoiceHeader.SetRange("Document Date", StartDate, EndDate);

        if not SalesInvoiceHeader.FindSet then begin
            SendTraceTag('000023Z', ExportInvoicesCategoryLbl, VERBOSITY::Normal,
              ExportInvoicesFailedNoInvoicesTxt, DATACLASSIFICATION::SystemMetadata);
            Error(NoInvoicesExportedErr);
        end;

        TempExcelBuffer.Reset();
        InsertHeaderTextForSalesInvoices;
        InsertHeaderTextForSalesLines;
        InsertSalesInvoices;

        ServerFileName := FileManagement.ServerTempFileName('xlsx');
        TempExcelBuffer.CreateBook(ServerFileName, InvoicesSheetNameTxt);
        TempExcelBuffer.WriteSheet(InvoicesSheetNameTxt, CompanyName, UserId);
        TempExcelBuffer.CloseBook;

        CODEUNIT.Run(CODEUNIT::"O365 Setup Email");

        with TempEmailItem do begin
            Validate("Send to", Email);
            Validate(Subject, StrSubstNo(ExportInvoicesEmailSubjectTxt, StartDate, EndDate));
            "Attachment File Path" := CopyStr(ServerFileName, 1, 250);
            Validate("Attachment Name", AttachmentNameTxt);
            EmailSuccess := Send(true);
        end;

        if EmailSuccess then begin
            SendTraceTag('0000240', ExportInvoicesCategoryLbl, VERBOSITY::Normal,
              ExportInvoicesSuccessTxt, DATACLASSIFICATION::SystemMetadata);
            Message(InvoicesExportedMsg);
        end else
            SendTraceTag('0000241', ExportInvoicesCategoryLbl, VERBOSITY::Warning,
              ExportInvoicesFailedSendingTxt, DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Variant)
    begin
        TempExcelBuffer.EnterCell(TempExcelBuffer, RowNo, ColumnNo, CellValue, CellBold, false, false);
    end;

    local procedure InsertSalesInvoiceSummary()
    begin
        EnterCell(RowNo, 1, SalesInvoiceHeader."No.");
        EnterCell(RowNo, 2, SalesInvoiceHeader."Sell-to Customer Name");
        EnterCell(RowNo, 3, SalesInvoiceHeader."Sell-to Address");
        EnterCell(RowNo, 4, SalesInvoiceHeader."Sell-to City");
        EnterCell(RowNo, 5, SalesInvoiceHeader."Sell-to County");
        EnterCell(RowNo, 6, SalesInvoiceHeader."Sell-to Country/Region Code");
        EnterCell(RowNo, 7, SalesInvoiceHeader."VAT Registration No.");
        EnterCell(RowNo, 8, SalesInvoiceHeader."Document Date");
        EnterCell(RowNo, 9, SalesInvoiceHeader."Due Date");
        EnterCell(RowNo, 10, SalesInvoiceHeader.GetWorkDescription);
        EnterCell(RowNo, 11, SalesInvoiceHeader.Amount);
        EnterCell(RowNo, 12, SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount);
        EnterCell(RowNo, 13, SalesInvoiceHeader."Amount Including VAT");
        EnterCell(RowNo, 14, SalesInvoiceHeader."Invoice Discount Amount");
        EnterCell(RowNo, 15, GetDocumentStatus(SalesInvoiceHeader));
    end;

    local procedure InsertSalesLineItem()
    begin
        EnterCell(LineRowNo, 1, SalesInvoiceLine."Document No.");
        EnterCell(LineRowNo, 2, SalesInvoiceHeader."Sell-to Customer Name");
        EnterCell(LineRowNo, 3, SalesInvoiceLine.Description);
        EnterCell(LineRowNo, 4, SalesInvoiceLine.Quantity);
        EnterCell(LineRowNo, 5, SalesInvoiceLine."Unit of Measure");
        EnterCell(LineRowNo, 6, SalesInvoiceLine."Unit Price");
        EnterCell(LineRowNo, 7, SalesInvoiceLine."Tax Group Code");
        EnterCell(LineRowNo, 8, SalesInvoiceLine."VAT %");
        EnterCell(LineRowNo, 9, SalesInvoiceLine.Amount);
        EnterCell(LineRowNo, 10, SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount);
        EnterCell(LineRowNo, 11, SalesInvoiceLine."Amount Including VAT");
        EnterCell(LineRowNo, 12, SalesInvoiceLine."Line Discount Amount");
    end;

    local procedure InsertHeaderTextForSalesInvoices()
    begin
        CellBold := true;
        RowNo := 1;
        EnterCell(RowNo, 1, InvoicesSummaryHeaderTxt);

        RowNo := RowNo + 1;
        EnterCell(RowNo, 1, InvoiceNoFieldTxt);
        EnterCell(RowNo, 2, CustomerNameFieldTxt);
        EnterCell(RowNo, 3, AddressFieldTxt);
        EnterCell(RowNo, 4, CityFieldTxt);
        EnterCell(RowNo, 5, CountyFieldTxt);
        EnterCell(RowNo, 6, CountryRegionCodeFieldTxt);
        EnterCell(RowNo, 7, SalesInvoiceHeader.FieldCaption("VAT Registration No."));
        EnterCell(RowNo, 8, InvoiceDateFieldTxt);
        EnterCell(RowNo, 9, SalesInvoiceHeader.FieldCaption("Due Date"));
        EnterCell(RowNo, 10, SalesInvoiceHeader.FieldCaption("Work Description"));
        EnterCell(RowNo, 11, NetTotalFieldTxt);
        EnterCell(RowNo, 12, VATAmountTxt);
        EnterCell(RowNo, 13, TotalIncludingVatFieldTxt);
        EnterCell(RowNo, 14, SalesInvoiceHeader.FieldCaption("Invoice Discount Amount"));
        EnterCell(RowNo, 15, InvoiceStatusTxt);

        CellBold := false;
    end;

    local procedure InsertHeaderTextForSalesLines()
    var
        NumberOfEmptyLines: Integer;
    begin
        CellBold := true;
        NumberOfEmptyLines := 5;
        LineRowNo := SalesInvoiceHeader.Count + NumberOfEmptyLines;
        EnterCell(LineRowNo, 1, ItemsHeaderTxt);

        LineRowNo := LineRowNo + 1;
        EnterCell(LineRowNo, 1, InvoiceNoFieldTxt);
        EnterCell(LineRowNo, 2, CustomerNameFieldTxt);
        EnterCell(LineRowNo, 3, SalesInvoiceLine.FieldCaption(Description));
        EnterCell(LineRowNo, 4, SalesInvoiceLine.FieldCaption(Quantity));
        EnterCell(LineRowNo, 5, SalesInvoiceLine.FieldCaption("Unit of Measure"));
        EnterCell(LineRowNo, 6, SalesInvoiceLine.FieldCaption("Unit Price"));
        EnterCell(LineRowNo, 7, SalesInvoiceLine.FieldCaption("Tax Group Code"));
        EnterCell(LineRowNo, 8, VatPercentFieldTxt);
        EnterCell(LineRowNo, 9, SalesInvoiceLine.FieldCaption(Amount));
        EnterCell(LineRowNo, 10, VATAmountTxt);
        EnterCell(LineRowNo, 11, SalesInvoiceLine.FieldCaption("Amount Including VAT"));
        EnterCell(LineRowNo, 12, SalesInvoiceLine.FieldCaption("Line Discount Amount"));
        CellBold := false;
    end;

    local procedure InsertSalesInvoices()
    begin
        if SalesInvoiceHeader.FindSet then begin
            repeat
                RowNo := RowNo + 1;
                SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT", "Work Description", "Invoice Discount Amount");
                InsertSalesInvoiceSummary;
                SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
                if SalesInvoiceLine.FindSet then begin
                    repeat
                        LineRowNo := LineRowNo + 1;
                        InsertSalesLineItem;
                    until SalesInvoiceLine.Next = 0;
                end;
            until SalesInvoiceHeader.Next = 0;
        end;
    end;

    local procedure GetDocumentStatus(SalesInvoiceHeader: Record "Sales Invoice Header") Status: Text
    var
        O365SalesDocument: Record "O365 Sales Document";
    begin
        O365SalesDocument.SetRange("No.", SalesInvoiceHeader."No.");
        O365SalesDocument.SetRange(Posted, true);
        if O365SalesDocument.OnFind('+') then
            Status := O365SalesDocument."Outstanding Status";
    end;
}

