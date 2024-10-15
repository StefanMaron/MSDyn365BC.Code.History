codeunit 11771 "Sending Document Handler"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Table, 112, 'OnBeforeSendRecords', '', false, false)]
    local procedure SendSalesInvoiceHeaderOnBeforeSendRecords(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; DocTxt: Text; var IsHandled: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        if IsHandled then
            exit;

        with SalesInvoiceHeader do begin
            if not "Prepayment Invoice" then
                exit;

            DocumentSendingProfile.SendCustomerRecords(
              ReportSelections.Usage::"S.Adv.Inv", SalesInvoiceHeader, CopyStr(DocTxt, 1, 150), "Bill-to Customer No.",
              "No.", FieldNo("Bill-to Customer No."), FieldNo("No."));
        end;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, 112, 'OnBeforeSendProfile', '', false, false)]
    local procedure SendSalesInvoiceHeaderOnBeforeSendProfile(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; DocTxt: Text; var IsHandled: Boolean; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        if IsHandled then
            exit;

        with SalesInvoiceHeader do begin
            if not "Prepayment Invoice" then
                exit;

            DocumentSendingProfile.Send(
              ReportSelections.Usage::"S.Adv.Inv", SalesInvoiceHeader, "No.", "Bill-to Customer No.",
              CopyStr(DocTxt, 1, 150), FieldNo("Bill-to Customer No."), FieldNo("No."));
        end;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, 112, 'OnBeforePrintRecords', '', false, false)]
    local procedure PrintSalesInvoiceHeaderOnBeforePrintRecords(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        if IsHandled then
            exit;

        with SalesInvoiceHeader do begin
            if not "Prepayment Invoice" then
                exit;

            DocumentSendingProfile.TrySendToPrinter(
              ReportSelections.Usage::"S.Adv.Inv", SalesInvoiceHeader, FieldNo("Bill-to Customer No."), ShowRequestPage)
        end;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, 112, 'OnBeforeEmailRecords', '', false, false)]
    local procedure EmailSalesInvoiceHeaderOnBeforeEmailRecords(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; DocTxt: Text; ShowDialog: Boolean; var IsHandled: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        if IsHandled then
            exit;

        with SalesInvoiceHeader do begin
            if not "Prepayment Invoice" then
                exit;

            DocumentSendingProfile.TrySendToEMail(
              ReportSelections.Usage::"S.Adv.Inv", SalesInvoiceHeader, FieldNo("No."),
              CopyStr(DocTxt, 1, 150), FieldNo("Bill-to Customer No."), ShowDialog)
        end;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, 114, 'OnBeforeSendRecords', '', false, false)]
    local procedure SendSalesCrMemoHeaderOnBeforeSendRecords(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocTxt: Text; var IsHandled: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        if IsHandled then
            exit;

        with SalesCrMemoHeader do begin
            if not "Prepayment Credit Memo" then
                exit;

            DocumentSendingProfile.SendCustomerRecords(
              ReportSelections.Usage::"S.Adv.CrM", SalesCrMemoHeader, CopyStr(DocTxt, 1, 150), "Bill-to Customer No.",
              "No.", FieldNo("Bill-to Customer No."), FieldNo("No."));
        end;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, 114, 'OnBeforeSendProfile', '', false, false)]
    local procedure SendSalesCrMemoHeaderOnBeforeSendProfile(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocTxt: Text; var IsHandled: Boolean; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        if IsHandled then
            exit;

        with SalesCrMemoHeader do begin
            if not "Prepayment Credit Memo" then
                exit;

            DocumentSendingProfile.Send(
              ReportSelections.Usage::"S.Adv.CrM", SalesCrMemoHeader, "No.", "Bill-to Customer No.",
              CopyStr(DocTxt, 1, 150), FieldNo("Bill-to Customer No."), FieldNo("No."));
        end;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, 114, 'OnBeforePrintRecords', '', false, false)]
    local procedure PrintSalesCrMemoHeaderOnBeforePrintRecords(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        if IsHandled then
            exit;

        with SalesCrMemoHeader do begin
            if not "Prepayment Credit Memo" then
                exit;

            DocumentSendingProfile.TrySendToPrinter(
              ReportSelections.Usage::"S.Adv.CrM", SalesCrMemoHeader, FieldNo("Bill-to Customer No."), ShowRequestPage)
        end;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, 114, 'OnBeforeEmailRecords', '', false, false)]
    local procedure EmailSalesCrMemoHeaderOnBeforeEmailRecords(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocTxt: Text; ShowDialog: Boolean; var IsHandled: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        if IsHandled then
            exit;

        with SalesCrMemoHeader do begin
            if not "Prepayment Credit Memo" then
                exit;

            DocumentSendingProfile.TrySendToEMail(
              ReportSelections.Usage::"S.Adv.CrM", SalesCrMemoHeader, FieldNo("No."),
              CopyStr(DocTxt, 1, 150), FieldNo("Bill-to Customer No."), ShowDialog)
        end;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, 122, 'OnBeforePrintRecords', '', false, false)]
    local procedure PrintPurchInvoiceHeaderOnBeforePrintRecords(var PurchInvHeader: Record "Purch. Inv. Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        if IsHandled then
            exit;

        with PurchInvHeader do begin
            if not "Prepayment Invoice" then
                exit;

            ReportSelections.PrintWithDialogForVend(
              ReportSelections.Usage::"P.Adv.Inv", PurchInvHeader, ShowRequestPage, FieldNo("Buy-from Vendor No."))
        end;

        IsHandled := true;
    end;
}

