codeunit 10151 "E-Invoice Cancel Request Batch"
{

    trigger OnRun()
    begin
        CancelRequestStatusBatch();
    end;

    local procedure CancelRequestStatusBatch()
    begin
        ProcessResponsePostedSalesInvoices();
        ProcessResponsePostedSalesCrMemos();
        ProcessResponsePostedServiceInvoices();
        ProcessResponsePostedServiceCrMemos();
        ProcessResponsePostedSalesShipments();
        ProcessResponsePostedTransferShipments();
        ProcessResponseCustomerLedgerEntries();
    end;

    local procedure ProcessResponsePostedSalesInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        SalesInvoiceHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesInvoiceHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          SalesInvoiceHeader."Electronic Document Status"::"Cancel In Progress",
          SalesInvoiceHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(SalesInvoiceHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponsePostedSalesCrMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        SalesCrMemoHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesCrMemoHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          SalesCrMemoHeader."Electronic Document Status"::"Cancel In Progress",
          SalesCrMemoHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(SalesCrMemoHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponsePostedServiceInvoices()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        ServiceInvoiceHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        ServiceInvoiceHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          ServiceInvoiceHeader."Electronic Document Status"::"Cancel In Progress",
          ServiceInvoiceHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(ServiceInvoiceHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponsePostedServiceCrMemos()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        ServiceCrMemoHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        ServiceCrMemoHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          ServiceCrMemoHeader."Electronic Document Status"::"Cancel In Progress",
          ServiceCrMemoHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(ServiceCrMemoHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponsePostedSalesShipments()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        TransferShipmentHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        TransferShipmentHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          TransferShipmentHeader."Electronic Document Status"::"Cancel In Progress",
          TransferShipmentHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(TransferShipmentHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponsePostedTransferShipments()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        SalesShipmentHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesShipmentHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          SalesShipmentHeader."Electronic Document Status"::"Cancel In Progress",
          SalesShipmentHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(SalesShipmentHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponseCustomerLedgerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        CustLedgerEntry.SetFilter("CFDI Cancellation ID", '<>%1', '');
        CustLedgerEntry.SetFilter(
          "Electronic Document Status", '%1|%2',
          CustLedgerEntry."Electronic Document Status"::"Cancel In Progress",
          CustLedgerEntry."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(CustLedgerEntry);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;
}

