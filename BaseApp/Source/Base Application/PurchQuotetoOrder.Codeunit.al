codeunit 96 "Purch.-Quote to Order"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        Vend: Record Vendor;
        PurchCommentLine: Record "Purch. Comment Line";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ArchiveManagement: Codeunit ArchiveManagement;
        RecordLinkManagement: Codeunit "Record Link Management";
        ShouldRedistributeInvoiceAmount: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeRun(Rec);

        TestField("Document Type", "Document Type"::Quote);
        ShouldRedistributeInvoiceAmount := PurchCalcDiscByType.ShouldRedistributeInvoiceDiscountAmount(Rec);

        CheckPurchasePostRestrictions();

        Vend.Get("Buy-from Vendor No.");
        Vend.CheckBlockedVendOnDocs(Vend, false);

        ValidatePurchaserOnPurchHeader(Rec, true, false);

        CheckForBlockedLines;

        CreatePurchHeader(Rec, Vend."Prepayment %");

        TransferQuoteToOrderLines(PurchQuoteLine, Rec, PurchOrderLine, PurchOrderHeader, Vend);
        OnAfterInsertAllPurchOrderLines(PurchOrderLine, Rec);

        PurchSetup.Get();
        case PurchSetup."Archive Quotes" of
            PurchSetup."Archive Quotes"::Always:
                ArchiveManagement.ArchPurchDocumentNoConfirm(Rec);
            PurchSetup."Archive Quotes"::Question:
                ArchiveManagement.ArchivePurchDocument(Rec);
        end;

        if PurchSetup."Default Posting Date" = PurchSetup."Default Posting Date"::"No Date" then begin
            PurchOrderHeader."Posting Date" := 0D;
            PurchOrderHeader.Modify();
        end;

        PurchCommentLine.CopyComments("Document Type".AsInteger(), PurchOrderHeader."Document Type".AsInteger(), "No.", PurchOrderHeader."No.");
        RecordLinkManagement.CopyLinks(Rec, PurchOrderHeader);

        AssignItemCharges("Document Type", "No.", PurchOrderHeader."Document Type", PurchOrderHeader."No.");

        ApprovalsMgmt.CopyApprovalEntryQuoteToOrder(RecordId, PurchOrderHeader."No.", PurchOrderHeader.RecordId);

        IsHandled := false;
        OnBeforeDeletePurchQuote(Rec, PurchOrderHeader, IsHandled);
        if not IsHandled then begin
            ApprovalsMgmt.DeleteApprovalEntries(RecordId);
            PurchCommentLine.DeleteComments("Document Type".AsInteger(), "No.");
            DeleteLinks;
            Delete;
            PurchQuoteLine.DeleteAll();
        end;

        if not ShouldRedistributeInvoiceAmount then
            PurchCalcDiscByType.ResetRecalculateInvoiceDisc(PurchOrderHeader);

        OnAfterRun(Rec, PurchOrderHeader);
    end;

    var
        PurchQuoteLine: Record "Purchase Line";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PrepmtMgt: Codeunit "Prepayment Mgt.";

    local procedure CreatePurchHeader(PurchHeader: Record "Purchase Header"; PrepmtPercent: Decimal)
    begin
        OnBeforeCreatePurchHeader(PurchHeader);

        with PurchHeader do begin
            PurchOrderHeader := PurchHeader;
            PurchOrderHeader."Document Type" := PurchOrderHeader."Document Type"::Order;
            PurchOrderHeader."No. Printed" := 0;
            PurchOrderHeader.Status := PurchOrderHeader.Status::Open;
            PurchOrderHeader."No." := '';
            PurchOrderHeader."Quote No." := "No.";

            OnCreatePurchHeaderOnBeforeInitRecord(PurchOrderHeader, PurchHeader);
            PurchOrderHeader.InitRecord();

            PurchOrderLine.LockTable();
            OnCreatePurchHeaderOnBeforePurchOrderHeaderInsert(PurchOrderHeader, PurchHeader);
            PurchOrderHeader.Insert(true);

            PurchOrderHeader."Order Date" := "Order Date";
            if "Posting Date" <> 0D then
                PurchOrderHeader."Posting Date" := "Posting Date";

            PurchOrderHeader.InitFromPurchHeader(PurchHeader);
            PurchOrderHeader."Inbound Whse. Handling Time" := "Inbound Whse. Handling Time";

            PurchOrderHeader."Prepayment %" := PrepmtPercent;
            if PurchOrderHeader."Posting Date" = 0D then
                PurchOrderHeader."Posting Date" := WorkDate;
            OnCreatePurchHeaderOnBeforePurchOrderHeaderModify(PurchOrderHeader, PurchHeader);
            PurchOrderHeader.Modify();
        end;

        OnAfterCreatePurchHeader(PurchOrderHeader, PurchHeader);
    end;

    local procedure AssignItemCharges(FromDocType: Enum "Purchase Document Type"; FromDocNo: Code[20]; ToDocType: Enum "Purchase Applies-to Document Type"; ToDocNo: Code[20])
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetRange("Document Type", FromDocType);
        ItemChargeAssgntPurch.SetRange("Document No.", FromDocNo);
        while ItemChargeAssgntPurch.FindFirst do begin
            ItemChargeAssgntPurch.Delete();
            ItemChargeAssgntPurch."Document Type" := PurchOrderHeader."Document Type";
            ItemChargeAssgntPurch."Document No." := PurchOrderHeader."No.";
            if not (ItemChargeAssgntPurch."Applies-to Doc. Type" in
                    [ItemChargeAssgntPurch."Applies-to Doc. Type"::Receipt,
                     ItemChargeAssgntPurch."Applies-to Doc. Type"::"Return Shipment"])
            then begin
                ItemChargeAssgntPurch."Applies-to Doc. Type" := ToDocType;
                ItemChargeAssgntPurch."Applies-to Doc. No." := ToDocNo;
            end;
            ItemChargeAssgntPurch.Insert();
        end;
    end;

    procedure GetPurchOrderHeader(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader := PurchOrderHeader;
    end;

    local procedure TransferQuoteToOrderLines(var PurchQuoteLine: Record "Purchase Line"; var PurchQuoteHeader: Record "Purchase Header"; var PurchOrderLine: Record "Purchase Line"; var PurchOrderHeader: Record "Purchase Header"; Vend: Record Vendor)
    var
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        IsHandled: Boolean;
    begin
        PurchQuoteLine.SetRange("Document Type", PurchQuoteHeader."Document Type");
        PurchQuoteLine.SetRange("Document No.", PurchQuoteHeader."No.");
        if PurchQuoteLine.FindSet() then
            repeat
                IsHandled := false;
                OnBeforeTransferQuoteLineToOrderLineLoop(PurchQuoteLine, PurchQuoteHeader, PurchOrderHeader, IsHandled);
                if not IsHandled then begin
                    PurchOrderLine := PurchQuoteLine;
                    PurchOrderLine."Document Type" := PurchOrderHeader."Document Type";
                    PurchOrderLine."Document No." := PurchOrderHeader."No.";
                    PurchLineReserve.TransferPurchLineToPurchLine(
                      PurchQuoteLine, PurchOrderLine, PurchQuoteLine."Outstanding Qty. (Base)");
                    PurchOrderLine."Shortcut Dimension 1 Code" := PurchQuoteLine."Shortcut Dimension 1 Code";
                    PurchOrderLine."Shortcut Dimension 2 Code" := PurchQuoteLine."Shortcut Dimension 2 Code";
                    PurchOrderLine."Dimension Set ID" := PurchQuoteLine."Dimension Set ID";
                    PurchOrderLine."Transaction Type" := PurchOrderHeader."Transaction Type";
                    if Vend."Prepayment %" <> 0 then
                        PurchOrderLine."Prepayment %" := Vend."Prepayment %";
                    PrepmtMgt.SetPurchPrepaymentPct(PurchOrderLine, PurchOrderHeader."Posting Date");
                    ValidatePurchOrderLinePrepaymentPct(PurchOrderLine);
                    PurchOrderLine.DefaultDeferralCode;
                    OnBeforeInsertPurchOrderLine(PurchOrderLine, PurchOrderHeader, PurchQuoteLine, PurchQuoteHeader);
                    PurchOrderLine.Insert();
                    OnAfterInsertPurchOrderLine(PurchQuoteLine, PurchOrderLine);
                    PurchLineReserve.VerifyQuantity(PurchOrderLine, PurchQuoteLine);
                end;
            until PurchQuoteLine.Next() = 0;
    end;

    local procedure ValidatePurchOrderLinePrepaymentPct(var PurchOrderLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidatePurchOrderLinePrepaymentPct(PurchOrderLine, IsHandled);
        if IsHandled then
            exit;

        PurchOrderLine.Validate("Prepayment %");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var PurchaseHeader: Record "Purchase Header"; PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchQuote(var QuotePurchHeader: Record "Purchase Header"; var OrderPurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; PurchQuoteLine: Record "Purchase Line"; PurchQuoteHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPurchOrderLine(var PurchaseQuoteLine: Record "Purchase Line"; var PurchaseOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllPurchOrderLines(var PurchOrderLine: Record "Purchase Line"; PurchQuoteHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferQuoteLineToOrderLineLoop(var PurchQuoteLine: Record "Purchase Line"; var PurchQuoteHeader: Record "Purchase Header"; var PurchOrderHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePurchOrderLinePrepaymentPct(var PurchOrderLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchHeaderOnBeforeInitRecord(var PurchOrderHeader: Record "Purchase Header"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchHeaderOnBeforePurchOrderHeaderInsert(var PurchOrderHeader: Record "Purchase Header"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchHeaderOnBeforePurchOrderHeaderModify(var PurchOrderHeader: Record "Purchase Header"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchHeader(var PurchOrderHeader: Record "Purchase Header"; PurchHeader: Record "Purchase Header")
    begin
    end;
}

