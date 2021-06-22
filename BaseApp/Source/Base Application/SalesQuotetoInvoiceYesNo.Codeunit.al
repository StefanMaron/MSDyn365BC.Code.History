codeunit 1304 "Sales-Quote to Invoice Yes/No"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        InvoiceSalesHeader: Record "Sales Header";
        SalesQuoteToInvoice: Codeunit "Sales-Quote to Invoice";
        OfficeMgt: Codeunit "Office Management";
    begin
        TestField("Document Type", "Document Type"::Quote);
        if GuiAllowed then
            if not Confirm(ConfirmConvertToInvoiceQst, false) then
                exit;

        SalesQuoteToInvoice.Run(Rec);
        SalesQuoteToInvoice.GetSalesInvoiceHeader(InvoiceSalesHeader);

        Commit();

        if GuiAllowed then
            if OfficeMgt.AttachAvailable then
                PAGE.Run(PAGE::"Sales Invoice", InvoiceSalesHeader)
            else
                if Confirm(StrSubstNo(OpenNewInvoiceQst, InvoiceSalesHeader."No."), true) then
                    PAGE.Run(PAGE::"Sales Invoice", InvoiceSalesHeader);
    end;

    var
        ConfirmConvertToInvoiceQst: Label 'Do you want to convert the quote to an invoice?';
        OpenNewInvoiceQst: Label 'The quote has been converted to invoice %1. Do you want to open the new invoice?';
}

