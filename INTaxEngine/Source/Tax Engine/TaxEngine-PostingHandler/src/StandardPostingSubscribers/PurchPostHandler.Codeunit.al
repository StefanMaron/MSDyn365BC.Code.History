codeunit 20335 "Purch.-Post Handler"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    procedure OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    var
        TaxPostingBufferMgmt: Codeunit "Tax Posting Buffer Mgmt.";
    begin
        TaxPostingBufferMgmt.ClearPostingInstance();
        TaxPostingBufferMgmt.SetDocument(PurchaseHeader);
        TaxPostingBufferMgmt.CreateTaxID();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchCrMemoLineInsert', '', false, false)]
    procedure OnAfterPurchCrMemoLineInsert(
        var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchLine: Record "Purchase Line";
        var PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        TaxTransactionValue: Record "Tax Transaction Value";
        TempTaxTransactionValue: Record "Tax Transaction Value" temporary;
        TaxDocumentGLPosting: Codeunit "Tax Document GL Posting";
        TaxPostingBufferMgmt: Codeunit "Tax Posting Buffer Mgmt.";
    begin
        // Prepares Transaction value based on Quantity and and Qty to Invoice
        TaxDocumentGLPosting.PrepareTransactionValueToPost(
            PurchLine.RecordId(),
            PurchLine.Quantity,
            PurchCrMemoLine.Quantity,
            PurchCrMemoHdr."Currency Code",
            PurchCrMemoHdr."Currency Factor",
            TempTaxTransactionValue);

        // Updates Posting Buffers in Tax Posting Buffer Mgmt. Codeunit
        // Creates tax ledger if the configuration is set for Line / Component on Use Case
        TaxDocumentGLPosting.UpdateTaxPostingBuffer(
            TempTaxTransactionValue,
            PurchLine.RecordId(),
            TaxPostingBufferMgmt.GetTaxID(),
            PurchLine."Dimension Set ID",
            PurchLine."Gen. Bus. Posting Group",
            PurchLine."Gen. Prod. Posting Group",
            PurchLine.Quantity,
            PurchLine."Qty. to Invoice",
            PurchCrMemoHdr."Currency Code",
            PurchCrMemoHdr."Currency Factor",
            PurchCrMemoLine."Document No.",
            PurchCrMemoLine."Line No.");

        //Copies transaction value from upposted document to posted record ID
        TaxDocumentGLPosting.TransferTransactionValue(
            PurchLine.RecordId(),
            PurchCrMemoLine.RecordId(),
            TempTaxTransactionValue);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchInvLineInsert', '', false, false)]
    procedure OnAfterPurchInvLineInsert(
            PurchInvHeader: Record "Purch. Inv. Header";
            PurchLine: Record "Purchase Line";
            var PurchInvLine: Record "Purch. Inv. Line")
    var
        TaxTransactionValue: Record "Tax Transaction Value";
        TempTaxTransactionValue: Record "Tax Transaction Value" temporary;
        TaxDocumentGLPosting: Codeunit "Tax Document GL Posting";
        TaxPostingBufferMgmt: Codeunit "Tax Posting Buffer Mgmt.";
    begin
        // Prepares Transaction value based on Quantity and and Qty to Invoice
        TaxDocumentGLPosting.PrepareTransactionValueToPost(
            PurchLine.RecordId(),
            PurchLine.Quantity,
            PurchInvLine.Quantity,
            PurchInvHeader."Currency Code",
            PurchInvHeader."Currency Factor",
            TempTaxTransactionValue);

        // Updates Posting Buffers in Tax Posting Buffer Mgmt. Codeunit
        // Creates tax ledger if the configuration is set for Line / Component on Use Case
        TaxDocumentGLPosting.UpdateTaxPostingBuffer(
            TempTaxTransactionValue,
            PurchLine.RecordId(),
            TaxPostingBufferMgmt.GetTaxID(),
            PurchLine."Dimension Set ID",
            PurchLine."Gen. Bus. Posting Group",
            PurchLine."Gen. Prod. Posting Group",
            PurchLine.Quantity,
            PurchLine."Qty. to Invoice",
            PurchInvHeader."Currency Code",
            PurchInvHeader."Currency Factor",
            PurchInvLine."Document No.",
            PurchInvLine."Line No.");

        //Copies transaction value from upposted document to posted record ID
        TaxDocumentGLPosting.TransferTransactionValue(
            PurchLine.RecordId(),
            PurchInvLine.RecordId(),
            TempTaxTransactionValue);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostVendorEntry', '', false, false)]
    local procedure OnBeforePostVendorEntry(
        var GenJnlLine: Record "Gen. Journal Line";
        var PurchHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        TaxDocumentGLPosting: Codeunit "Tax Document GL Posting";
        TaxPostingBufferMgmt: Codeunit "Tax Posting Buffer Mgmt.";
    begin
        GenJnlLine."Tax ID" := TaxPostingBufferMgmt.GetTaxID();
    end;
}