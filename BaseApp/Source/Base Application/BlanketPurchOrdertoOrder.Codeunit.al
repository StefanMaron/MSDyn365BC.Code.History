codeunit 97 "Blanket Purch. Order to Order"
{
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        Vend: Record Vendor;
        PurchCommentLine: Record "Purch. Comment Line";
        PrepmtMgt: Codeunit "Prepayment Mgt.";
        RecordLinkManagement: Codeunit "Record Link Management";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        ShouldRedistributeInvoiceAmount: Boolean;
    begin
        OnBeforeRun(Rec);

        TestField("Document Type", "Document Type"::"Blanket Order");
        ShouldRedistributeInvoiceAmount := PurchCalcDiscByType.ShouldRedistributeInvoiceDiscountAmount(Rec);

        Vend.Get("Buy-from Vendor No.");
        Vend.CheckBlockedVendOnDocs(Vend, false);

        ValidatePurchaserOnPurchHeader(Rec, true, false);

        CheckForBlockedLines;

        if QtyToReceiveIsZero then
            Error(Text002);

        PurchSetup.Get();

        CreatePurchHeader(Rec, Vend."Prepayment %");

        PurchBlanketOrderLine.Reset();
        PurchBlanketOrderLine.SetRange("Document Type", "Document Type");
        PurchBlanketOrderLine.SetRange("Document No.", "No.");
        if PurchBlanketOrderLine.FindSet then
            repeat
                if (PurchBlanketOrderLine.Type = PurchBlanketOrderLine.Type::" ") or
                   (PurchBlanketOrderLine."Qty. to Receive" <> 0)
                then begin
                    PurchLine.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
                    PurchLine.SetRange("Blanket Order No.", PurchBlanketOrderLine."Document No.");
                    PurchLine.SetRange("Blanket Order Line No.", PurchBlanketOrderLine."Line No.");
                    QuantityOnOrders := 0;
                    if PurchLine.FindSet then
                        repeat
                            if (PurchLine."Document Type" = PurchLine."Document Type"::"Return Order") or
                               ((PurchLine."Document Type" = PurchLine."Document Type"::"Credit Memo") and
                                (PurchLine."Return Shipment No." = ''))
                            then
                                QuantityOnOrders := QuantityOnOrders - PurchLine."Outstanding Qty. (Base)"
                            else
                                if (PurchLine."Document Type" = PurchLine."Document Type"::Order) or
                                   ((PurchLine."Document Type" = PurchLine."Document Type"::Invoice) and
                                    (PurchLine."Receipt No." = ''))
                                then
                                    QuantityOnOrders := QuantityOnOrders + PurchLine."Outstanding Qty. (Base)";
                        until PurchLine.Next = 0;

                    CheckBlanketOrderLineQuantity();

                    PurchOrderLine := PurchBlanketOrderLine;
                    ResetQuantityFields(PurchOrderLine);
                    PurchOrderLine."Document Type" := PurchOrderHeader."Document Type";
                    PurchOrderLine."Document No." := PurchOrderHeader."No.";
                    PurchOrderLine."Blanket Order No." := "No.";
                    PurchOrderLine."Blanket Order Line No." := PurchBlanketOrderLine."Line No.";

                    if (PurchOrderLine."No." <> '') and (PurchOrderLine.Type <> 0) then begin
                        PurchOrderLine.Amount := 0;
                        PurchOrderLine."Amount Including VAT" := 0;
                        PurchOrderLine.Validate(Quantity, PurchBlanketOrderLine."Qty. to Receive");
                        if PurchBlanketOrderLine."Expected Receipt Date" <> 0D then
                            PurchOrderLine.Validate("Expected Receipt Date", PurchBlanketOrderLine."Expected Receipt Date")
                        else
                            PurchOrderLine.Validate("Order Date", PurchOrderHeader."Order Date");
                        PurchOrderLine.Validate("Direct Unit Cost", PurchBlanketOrderLine."Direct Unit Cost");
                        PurchOrderLine.Validate("Line Discount %", PurchBlanketOrderLine."Line Discount %");
                        if PurchOrderLine.Quantity <> 0 then
                            PurchOrderLine.Validate("Inv. Discount Amount", PurchBlanketOrderLine."Inv. Discount Amount");
                        PurchBlanketOrderLine.CalcFields("Reserved Qty. (Base)");
                        if PurchBlanketOrderLine."Reserved Qty. (Base)" <> 0 then
                            ReservePurchLine.TransferPurchLineToPurchLine(
                              PurchBlanketOrderLine, PurchOrderLine, -PurchBlanketOrderLine."Qty. to Receive (Base)");
                    end;

                    if Vend."Prepayment %" <> 0 then
                        PurchOrderLine."Prepayment %" := Vend."Prepayment %";
                    PrepmtMgt.SetPurchPrepaymentPct(PurchOrderLine, PurchOrderHeader."Posting Date");
                    PurchOrderLine.Validate("Prepayment %");

                    PurchOrderLine."Shortcut Dimension 1 Code" := PurchBlanketOrderLine."Shortcut Dimension 1 Code";
                    PurchOrderLine."Shortcut Dimension 2 Code" := PurchBlanketOrderLine."Shortcut Dimension 2 Code";
                    PurchOrderLine."Dimension Set ID" := PurchBlanketOrderLine."Dimension Set ID";
                    PurchOrderLine.DefaultDeferralCode;
                    if IsPurchOrderLineToBeInserted(PurchOrderLine) then begin
                        OnBeforeInsertPurchOrderLine(PurchOrderLine, PurchOrderHeader, PurchBlanketOrderLine, Rec);
                        PurchOrderLine.Insert();
                        OnAfterPurchOrderLineInsert(PurchOrderLine, PurchBlanketOrderLine);
                    end;

                    if PurchBlanketOrderLine."Qty. to Receive" <> 0 then begin
                        PurchBlanketOrderLine.Validate("Qty. to Receive", 0);
                        PurchBlanketOrderLine.Modify();
                    end;
                end;
            until PurchBlanketOrderLine.Next = 0;

        OnAfterInsertAllPurchOrderLines(Rec, PurchOrderHeader);

        if PurchSetup."Default Posting Date" = PurchSetup."Default Posting Date"::"No Date" then begin
            PurchOrderHeader."Posting Date" := 0D;
            PurchOrderHeader.Modify();
        end;

        if PurchSetup."Copy Comments Blanket to Order" then begin
            PurchCommentLine.CopyComments(
              PurchCommentLine."Document Type"::"Blanket Order", PurchOrderHeader."Document Type", "No.", PurchOrderHeader."No.");
            RecordLinkManagement.CopyLinks(Rec, PurchOrderHeader);
        end;

        if not (ShouldRedistributeInvoiceAmount or PurchSetup."Calc. Inv. Discount") then
            PurchCalcDiscByType.ResetRecalculateInvoiceDisc(PurchOrderHeader);

        Commit();

        OnAfterRun(Rec, PurchOrderHeader);
    end;

    var
        QuantityCheckErr: Label '%1 of %2 %3 in %4 %5 cannot be more than %6.\%7\%8 - %9 = %6.', Comment = '%1: FIELDCAPTION("Qty. to Receive (Base)"); %2: Field(Type); %3: Field(No.); %4: FIELDCAPTION("Line No."); %5: Field(Line No.); %6: Decimal Qty Difference; %7: Text001; %8: Field(Outstanding Qty. (Base)); %9: Decimal Quantity On Orders';
        Text001: Label '%1 - Unposted %1 = Possible %2';
        PurchBlanketOrderLine: Record "Purchase Line";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchLine: Record "Purchase Line";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        QuantityOnOrders: Decimal;
        Text002: Label 'There is nothing to create.';

    local procedure CheckBlanketOrderLineQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBlanketOrderLineQuantity(PurchBlanketOrderLine, QuantityOnOrders, IsHandled);
        if IsHandled then
            exit;

        if (Abs(PurchBlanketOrderLine."Qty. to Receive (Base)" + QuantityOnOrders +
            PurchBlanketOrderLine."Qty. Received (Base)") >
            Abs(PurchBlanketOrderLine."Quantity (Base)")) or
           (PurchBlanketOrderLine."Quantity (Base)" * PurchBlanketOrderLine."Outstanding Qty. (Base)" < 0)
        then
            Error(
              QuantityCheckErr,
              PurchBlanketOrderLine.FieldCaption("Qty. to Receive (Base)"),
              PurchBlanketOrderLine.Type, PurchBlanketOrderLine."No.",
              PurchBlanketOrderLine.FieldCaption("Line No."), PurchBlanketOrderLine."Line No.",
              PurchBlanketOrderLine."Outstanding Qty. (Base)" - QuantityOnOrders,
              StrSubstNo(
                Text001,
                PurchBlanketOrderLine.FieldCaption("Outstanding Qty. (Base)"),
                PurchBlanketOrderLine.FieldCaption("Qty. to Receive (Base)")),
              PurchBlanketOrderLine."Outstanding Qty. (Base)", QuantityOnOrders);
    end;

    local procedure CreatePurchHeader(PurchHeader: Record "Purchase Header"; PrepmtPercent: Decimal)
    begin
        OnBeforeCreatePurchHeader(PurchHeader);

        with PurchHeader do begin
            PurchOrderHeader := PurchHeader;
            PurchOrderHeader."Document Type" := PurchOrderHeader."Document Type"::Order;
            PurchOrderHeader."No. Printed" := 0;
            PurchOrderHeader.Status := PurchOrderHeader.Status::Open;
            PurchOrderHeader."No." := '';
            PurchOrderHeader.InitRecord;
            PurchOrderLine.LockTable();
            OnBeforeInsertPurchOrderHeader(PurchOrderHeader, PurchHeader);
            PurchOrderHeader.Insert(true);

            if "Order Date" = 0D then
                PurchOrderHeader."Order Date" := WorkDate
            else
                PurchOrderHeader."Order Date" := "Order Date";
            if "Posting Date" <> 0D then
                PurchOrderHeader."Posting Date" := "Posting Date";
            if PurchOrderHeader."Posting Date" = 0D then
                PurchOrderHeader."Posting Date" := WorkDate;

            PurchOrderHeader.InitFromPurchHeader(PurchHeader);
            PurchOrderHeader.Validate("Posting Date");

            PurchOrderHeader."Prepayment %" := PrepmtPercent;
            OnBeforePurchOrderHeaderModify(PurchOrderHeader, PurchHeader);
            PurchOrderHeader.Modify();
        end;
    end;

    local procedure ResetQuantityFields(var TempPurchLine: Record "Purchase Line")
    begin
        TempPurchLine.Quantity := 0;
        TempPurchLine."Quantity (Base)" := 0;
        TempPurchLine."Qty. Rcd. Not Invoiced" := 0;
        TempPurchLine."Quantity Received" := 0;
        TempPurchLine."Quantity Invoiced" := 0;
        TempPurchLine."Qty. Rcd. Not Invoiced (Base)" := 0;
        TempPurchLine."Qty. Received (Base)" := 0;
        TempPurchLine."Qty. Invoiced (Base)" := 0;

        OnAfterResetQuantityFields(TempPurchLine);
    end;

    procedure GetPurchOrderHeader(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader := PurchOrderHeader;
    end;

    local procedure IsPurchOrderLineToBeInserted(PurchOrderLine: Record "Purchase Line"): Boolean
    var
        AttachedToPurchaseLine: Record "Purchase Line";
    begin
        if PurchOrderLine."Attached to Line No." = 0 then
            exit(true);
        exit(
          AttachedToPurchaseLine.Get(
            PurchOrderLine."Document Type", PurchOrderLine."Document No.", PurchOrderLine."Attached to Line No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchOrderLineInsert(var PurchaseLine: Record "Purchase Line"; var BlanketOrderPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var PurchaseHeader: Record "Purchase Header"; var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetQuantityFields(var TempPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlanketOrderLineQuantity(var PurchBlanketOrderLine: Record "Purchase Line"; QuantityOnOrders: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchOrderHeader(var PurchOrderHeader: Record "Purchase Header"; BlanketOrderPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; var BlanketOrderPurchLine: Record "Purchase Line"; BlanketOrderPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllPurchOrderLines(BlanketOrderPurchHeader: Record "Purchase Header"; OrderPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderHeaderModify(var PurchOrderHeader: Record "Purchase Header"; BlanketOrderPurchHeader: Record "Purchase Header")
    begin
    end;
}

