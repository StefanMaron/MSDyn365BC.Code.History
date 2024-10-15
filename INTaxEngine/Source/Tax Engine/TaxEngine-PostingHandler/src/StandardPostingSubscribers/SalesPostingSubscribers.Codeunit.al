codeunit 20336 "Sales Posting Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header")
    var
        TaxPostingBufferMgmt: Codeunit "Tax Posting Buffer Mgmt.";
    begin
        TaxPostingBufferMgmt.ClearPostingInstance();
        TaxPostingBufferMgmt.SetDocument(SalesHeader);
        TaxPostingBufferMgmt.CreateTaxID();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesCrMemoLineInsert', '', false, false)]
    procedure OnAfterSalesCrMemoLineInsert(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesLine: Record "Sales Line"; var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        TaxTransactionValue: Record "Tax Transaction Value";
        TempTaxTransactionValue: Record "Tax Transaction Value" temporary;
        TaxDocumentGLPosting: Codeunit "Tax Document GL Posting";
        TaxPostingBufferMgmt: Codeunit "Tax Posting Buffer Mgmt.";
    begin
        // Prepares Transaction value based on Quantity and and Qty to Invoice
        TaxDocumentGLPosting.PrepareTransactionValueToPost(
            SalesLine.RecordId(),
            SalesLine.Quantity,
            SalesCrMemoLine.Quantity,
            SalesCrMemoHeader."Currency Code",
            SalesCrMemoHeader."Currency Factor",
            TempTaxTransactionValue);

        // Updates Posting Buffers in Tax Posting Buffer Mgmt. Codeunit
        // Creates tax ledger if the configuration is set for Line / Component on Use Case
        TaxDocumentGLPosting.UpdateTaxPostingBuffer(
            TempTaxTransactionValue,
            SalesLine.RecordId(),
            TaxPostingBufferMgmt.GetTaxID(),
            SalesLine."Dimension Set ID",
            SalesLine."Gen. Bus. Posting Group",
            SalesLine."Gen. Prod. Posting Group",
            SalesLine.Quantity,
            SalesLine."Qty. to Invoice",
            SalesCrMemoHeader."Currency Code",
            SalesCrMemoHeader."Currency Factor",
            SalesCrMemoLine."Document No.",
            SalesCrMemoLine."Line No.");

        //Copies transaction value from upposted document to posted record ID
        TaxDocumentGLPosting.TransferTransactionValue(
            SalesLine.RecordId(),
            SalesCrMemoLine.RecordId(),
            TempTaxTransactionValue);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvLineInsert', '', false, false)]
    procedure OnAfterSalesInvLineInsert(SalesInvHeader: Record "Sales Invoice Header"; SalesLine: Record "Sales Line"; var SalesInvLine: Record "Sales Invoice Line")
    var
        TaxTransactionValue: Record "Tax Transaction Value";
        TempTaxTransactionValue: Record "Tax Transaction Value" temporary;
        TaxDocumentGLPosting: Codeunit "Tax Document GL Posting";
        TaxPostingBufferMgmt: Codeunit "Tax Posting Buffer Mgmt.";
    begin
        // Prepares Transaction value based on Quantity and and Qty to Invoice
        TaxDocumentGLPosting.PrepareTransactionValueToPost(
            SalesLine.RecordId(),
            SalesLine.Quantity,
            SalesInvLine.Quantity,
            SalesInvHeader."Currency Code",
            SalesInvHeader."Currency Factor",
            TempTaxTransactionValue);

        // Updates Posting Buffers in Tax Posting Buffer Mgmt. Codeunit
        // Creates tax ledger if the configuration is set for Line / Component on Use Case
        TaxDocumentGLPosting.UpdateTaxPostingBuffer(
            TempTaxTransactionValue,
            SalesLine.RecordId(),
            TaxPostingBufferMgmt.GetTaxID(),
            SalesLine."Dimension Set ID",
            SalesLine."Gen. Bus. Posting Group",
            SalesLine."Gen. Prod. Posting Group",
            SalesLine.Quantity,
            SalesLine."Qty. to Invoice",
            SalesInvHeader."Currency Code",
            SalesInvHeader."Currency Factor",
            SalesInvLine."Document No.",
            SalesInvLine."Line No.");

        //Copies transaction value from upposted document to posted record ID
        TaxDocumentGLPosting.TransferTransactionValue(
            SalesLine.RecordId(),
            SalesInvLine.RecordId(),
            TempTaxTransactionValue);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostCustomerEntry', '', false, false)]
    local procedure OnBeforePostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header")
    var
        TaxPostingBufferMgmt: Codeunit "Tax Posting Buffer Mgmt.";
    begin
        GenJnlLine."Tax ID" := TaxPostingBufferMgmt.GetTaxID();
    end;
}