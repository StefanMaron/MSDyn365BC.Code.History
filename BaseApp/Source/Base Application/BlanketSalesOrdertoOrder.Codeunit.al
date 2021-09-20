codeunit 87 "Blanket Sales Order to Order"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        Cust: Record Customer;
        TempSalesLine: Record "Sales Line" temporary;
        SalesCommentLine: Record "Sales Comment Line";
        ATOLink: Record "Assemble-to-Order Link";
        PrepmtMgt: Codeunit "Prepayment Mgt.";
        RecordLinkManagement: Codeunit "Record Link Management";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        Reservation: Page Reservation;
        ShouldRedistributeInvoiceAmount: Boolean;
        CreditLimitExceeded: Boolean;
        IsHandled: Boolean;
        SuppressCommit: Boolean;
    begin
        OnBeforeRun(Rec, HideValidationDialog);

        TestField("Document Type", "Document Type"::"Blanket Order");
        ShouldRedistributeInvoiceAmount := SalesCalcDiscountByType.ShouldRedistributeInvoiceDiscountAmount(Rec);

        Cust.Get("Sell-to Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, "Document Type"::Order, true, false);

        ValidateSalesPersonOnSalesHeader(Rec, true, false);

        CheckForBlockedLines;

        if QtyToShipIsZero then
            Error(Text002);

        SalesSetup.Get();

        CheckAvailability(Rec);

        CreditLimitExceeded := CreateSalesHeader(Rec, Cust."Prepayment %");

        BlanketOrderSalesLine.Reset();
        BlanketOrderSalesLine.SetRange("Document Type", "Document Type");
        BlanketOrderSalesLine.SetRange("Document No.", "No.");
        OnRunOnAfterBlanketOrderSalesLineSetFilters(BlanketOrderSalesLine);
        if BlanketOrderSalesLine.FindSet then begin
            TempSalesLine.DeleteAll();
            repeat
                OnBeforeHandlingBlanketOrderSalesLine(BlanketOrderSalesLine);
                if (BlanketOrderSalesLine.Type = BlanketOrderSalesLine.Type::" ") or (BlanketOrderSalesLine."Qty. to Ship" <> 0) then begin
                    SalesLine.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
                    SalesLine.SetRange("Blanket Order No.", BlanketOrderSalesLine."Document No.");
                    SalesLine.SetRange("Blanket Order Line No.", BlanketOrderSalesLine."Line No.");
                    QuantityOnOrders := 0;
                    if SalesLine.FindSet then
                        repeat
                            if (SalesLine."Document Type" = SalesLine."Document Type"::"Return Order") or
                               ((SalesLine."Document Type" = SalesLine."Document Type"::"Credit Memo") and
                                (SalesLine."Return Receipt No." = ''))
                            then
                                QuantityOnOrders := QuantityOnOrders - SalesLine."Outstanding Qty. (Base)"
                            else
                                if (SalesLine."Document Type" = SalesLine."Document Type"::Order) or
                                   ((SalesLine."Document Type" = SalesLine."Document Type"::Invoice) and
                                    (SalesLine."Shipment No." = ''))
                                then
                                    QuantityOnOrders := QuantityOnOrders + SalesLine."Outstanding Qty. (Base)";
                        until SalesLine.Next() = 0;

                    CheckBlanketOrderLineQuantity();

                    SalesOrderLine := BlanketOrderSalesLine;
                    OnRunOnBeforeResetQuantityFields(BlanketOrderSalesLine, SalesOrderLine);
                    ResetQuantityFields(SalesOrderLine);
                    SalesOrderLine."Document Type" := SalesOrderHeader."Document Type";
                    SalesOrderLine."Document No." := SalesOrderHeader."No.";
                    SalesOrderLine."Blanket Order No." := "No.";
                    SalesOrderLine."Blanket Order Line No." := BlanketOrderSalesLine."Line No.";
                    if (SalesOrderLine."No." <> '') and (SalesOrderLine.Type <> SalesOrderLine.Type::" ") then begin
                        SalesOrderLine.Amount := 0;
                        SalesOrderLine."Amount Including VAT" := 0;
                        SalesOrderLineValidateQuantity(SalesOrderLine, BlanketOrderSalesLine);
                        SalesOrderLine.Validate("Shipment Date", BlanketOrderSalesLine."Shipment Date");
                        OnRunOnAfterSalesOrderLineValidateShipmentDate(BlanketOrderSalesLine, SalesOrderLine);
                        SalesOrderLine.Validate("Unit Price", BlanketOrderSalesLine."Unit Price");
                        SalesOrderLine."Allow Invoice Disc." := BlanketOrderSalesLine."Allow Invoice Disc.";
                        SalesOrderLine."Allow Line Disc." := BlanketOrderSalesLine."Allow Line Disc.";
                        SalesOrderLine.Validate("Line Discount %", BlanketOrderSalesLine."Line Discount %");
                        if SalesOrderLine.Quantity <> 0 then
                            SalesOrderLine.Validate("Inv. Discount Amount", BlanketOrderSalesLine."Inv. Discount Amount");
                        OnRunOnBeforeSalesLineReserveTransferSaleLineToSalesLine(BlanketOrderSalesLine, SalesOrderLine);
                        SalesLineReserve.TransferSaleLineToSalesLine(
                          BlanketOrderSalesLine, SalesOrderLine, BlanketOrderSalesLine."Qty. to Ship (Base)");
                    end;

                    if Cust."Prepayment %" <> 0 then
                        SalesOrderLine."Prepayment %" := Cust."Prepayment %";
                    PrepmtMgt.SetSalesPrepaymentPct(SalesOrderLine, SalesOrderHeader."Posting Date");
                    SalesOrderLine.Validate("Prepayment %");

                    SalesOrderLine."Shortcut Dimension 1 Code" := BlanketOrderSalesLine."Shortcut Dimension 1 Code";
                    SalesOrderLine."Shortcut Dimension 2 Code" := BlanketOrderSalesLine."Shortcut Dimension 2 Code";
                    SalesOrderLine."Dimension Set ID" := BlanketOrderSalesLine."Dimension Set ID";
                    if ATOLink.AsmExistsForSalesLine(BlanketOrderSalesLine) then begin
                        SalesOrderLine."Qty. to Assemble to Order" := SalesOrderLine.Quantity;
                        SalesOrderLine."Qty. to Asm. to Order (Base)" := SalesOrderLine."Quantity (Base)";
                    end;
                    SalesOrderLine.DefaultDeferralCode;
                    if IsSalesOrderLineToBeInserted(SalesOrderLine) then begin
                        OnBeforeInsertSalesOrderLine(SalesOrderLine, SalesOrderHeader, BlanketOrderSalesLine, Rec);
                        SalesOrderLine.Insert();
                        OnAfterInsertSalesOrderLine(SalesOrderLine, SalesOrderHeader, BlanketOrderSalesLine, Rec);
                    end;

                    if ATOLink.AsmExistsForSalesLine(BlanketOrderSalesLine) then
                        ATOLink.MakeAsmOrderLinkedToSalesOrderLine(BlanketOrderSalesLine, SalesOrderLine);

                    IsHandled := false;
                    OnRunOnBeforeValidateBlanketOrderSalesLineQtytoShip(BlanketOrderSalesLine, SalesOrderLine, SalesOrderHeader, Rec, IsHandled);
                    if not IsHandled then
                        if BlanketOrderSalesLine."Qty. to Ship" <> 0 then begin
                            BlanketOrderSalesLine.Validate("Qty. to Ship", 0);
                            BlanketOrderSalesLine.Modify();
                            AutoReserve(SalesOrderLine, TempSalesLine);
                        end;
                end;
            until BlanketOrderSalesLine.Next() = 0;
        end;

        OnAfterInsertAllSalesOrderLines(Rec, SalesOrderHeader);

        if SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" then begin
            SalesOrderHeader."Posting Date" := 0D;
            SalesOrderHeader.Modify();
        end;

        if SalesSetup."Copy Comments Blanket to Order" then begin
            SalesCommentLine.CopyComments(
              SalesCommentLine."Document Type"::"Blanket Order".AsInteger(), SalesOrderHeader."Document Type".AsInteger(), "No.", SalesOrderHeader."No.");
            RecordLinkManagement.CopyLinks(Rec, SalesOrderHeader);
        end;

        if not (ShouldRedistributeInvoiceAmount or SalesSetup."Calc. Inv. Discount") then
            SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(SalesOrderHeader);

        if (not HideValidationDialog) and (not CreditLimitExceeded) then
            CustCheckCreditLimit.BlanketSalesOrderToOrderCheck(SalesOrderHeader);

        OnBeforeReserveItemsManuallyLoop(Rec, SalesOrderHeader, TempSalesLine, SuppressCommit);
        if not SuppressCommit then
            Commit();

        if GuiAllowed then
            if TempSalesLine.Find('-') then
                if Confirm(Text003, true) then
                    repeat
                        Clear(Reservation);
                        Reservation.SetReservSource(TempSalesLine);
                        Reservation.RunModal();
                        Find;
                    until TempSalesLine.Next() = 0;

        Clear(CustCheckCreditLimit);
        Clear(ItemCheckAvail);

        OnAfterRun(Rec, SalesOrderHeader);
    end;

    var
        QuantityCheckErr: Label '%1 of %2 %3 in %4 %5 cannot be more than %6.\%7\%8 - %9 = %6.', Comment = '%1: FIELDCAPTION("Qty. to Ship (Base)"); %2: Field(Type); %3: Field(No.); %4: FIELDCAPTION("Line No."); %5: Field(Line No.); %6: Decimal Qty Difference; %7: Text001; %8: Field(Outstanding Qty. (Base)); %9: Decimal Quantity On Orders';
        Text001: Label '%1 - Unposted %1 = Possible %2';
        BlanketOrderSalesLine: Record "Sales Line";
        SalesLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        UOMMgt: Codeunit "Unit of Measure Management";
        QuantityOnOrders: Decimal;
        Text002: Label 'There is nothing to create.';
        Text003: Label 'Full automatic reservation was not possible.\Reserve items manually?';

    protected var
        HideValidationDialog: Boolean;

    local procedure SalesOrderLineValidateQuantity(var SalesOrderLine: Record "Sales Line"; BlanketOrderSalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesOrderLineValidateQuantity(SalesOrderLine, BlanketOrderSalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesOrderLine.Validate(Quantity, BlanketOrderSalesLine."Qty. to Ship");
    end;

    local procedure CheckBlanketOrderLineQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBlanketOrderLineQuantity(BlanketOrderSalesLine, QuantityOnOrders, IsHandled);
        if IsHandled then
            exit;

        if (Abs(BlanketOrderSalesLine."Qty. to Ship (Base)" + QuantityOnOrders +
              BlanketOrderSalesLine."Qty. Shipped (Base)") >
            Abs(BlanketOrderSalesLine."Quantity (Base)")) or
           (BlanketOrderSalesLine."Quantity (Base)" * BlanketOrderSalesLine."Outstanding Qty. (Base)" < 0)
        then
            Error(
              QuantityCheckErr,
              BlanketOrderSalesLine.FieldCaption("Qty. to Ship (Base)"),
              BlanketOrderSalesLine.Type, BlanketOrderSalesLine."No.",
              BlanketOrderSalesLine.FieldCaption("Line No."), BlanketOrderSalesLine."Line No.",
              BlanketOrderSalesLine."Outstanding Qty. (Base)" - QuantityOnOrders,
              StrSubstNo(
                Text001,
                BlanketOrderSalesLine.FieldCaption("Outstanding Qty. (Base)"),
                BlanketOrderSalesLine.FieldCaption("Qty. to Ship (Base)")),
              BlanketOrderSalesLine."Outstanding Qty. (Base)", QuantityOnOrders);
    end;

    local procedure CreateSalesHeader(SalesHeader: Record "Sales Header"; PrepmtPercent: Decimal) CreditLimitExceeded: Boolean
    begin
        OnBeforeCreateSalesHeader(SalesHeader);

        with SalesHeader do begin
            SalesOrderHeader := SalesHeader;
            SalesOrderHeader."Document Type" := SalesOrderHeader."Document Type"::Order;
            if not HideValidationDialog then
                CreditLimitExceeded := CustCheckCreditLimit.SalesHeaderCheck(SalesOrderHeader);

            SalesOrderHeader."No. Printed" := 0;
            SalesOrderHeader.Status := SalesOrderHeader.Status::Open;
            SalesOrderHeader."No." := '';

            SalesOrderLine.LockTable();
            OnBeforeInsertSalesOrderHeader(SalesOrderHeader, SalesHeader);
            SalesOrderHeader.Insert(true);

            if "Order Date" = 0D then
                SalesOrderHeader."Order Date" := WorkDate
            else
                SalesOrderHeader."Order Date" := "Order Date";
            if "Posting Date" <> 0D then
                SalesOrderHeader."Posting Date" := "Posting Date";
            if SalesOrderHeader."Posting Date" = 0D then
                SalesOrderHeader."Posting Date" := WorkDate;

            SalesOrderHeader.InitFromSalesHeader(SalesHeader);
            SalesOrderHeader.Validate("Posting Date");
            SalesOrderHeader."Outbound Whse. Handling Time" := "Outbound Whse. Handling Time";
            SalesOrderHeader.Reserve := Reserve;

            SalesOrderHeader."Prepayment %" := PrepmtPercent;

            OnBeforeSalesOrderHeaderModify(SalesOrderHeader, SalesHeader);
            SalesOrderHeader.Modify();
        end;
    end;

    local procedure ResetQuantityFields(var TempSalesLine: Record "Sales Line")
    begin
        TempSalesLine.Quantity := 0;
        TempSalesLine."Quantity (Base)" := 0;
        TempSalesLine."Qty. Shipped Not Invoiced" := 0;
        TempSalesLine."Quantity Shipped" := 0;
        TempSalesLine."Quantity Invoiced" := 0;
        TempSalesLine."Qty. Shipped Not Invd. (Base)" := 0;
        TempSalesLine."Qty. Shipped (Base)" := 0;
        TempSalesLine."Qty. Invoiced (Base)" := 0;
        TempSalesLine."Outstanding Quantity" := 0;
        TempSalesLine."Outstanding Qty. (Base)" := 0;

        OnAfterResetQuantityFields(TempSalesLine);
    end;

    procedure GetSalesOrderHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader := SalesOrderHeader;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure AutoReserve(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        with SalesLine do
            if (Type = Type::Item) and
               (Reserve = Reserve::Always) and
               ("No." <> '')
            then begin
                TestField("Shipment Date");
                ReservMgt.SetReservSource(SalesLine);
                ReservMgt.AutoReserve(FullAutoReservation, '', "Shipment Date", "Qty. to Ship", "Qty. to Ship (Base)");
                Find;
                if not FullAutoReservation then begin
                    TempSalesLine.TransferFields(SalesLine);
                    TempSalesLine.Insert();
                end;
            end;
    end;

    local procedure CheckAvailability(BlanketOrderSalesHeader: Record "Sales Header")
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        with BlanketOrderSalesLine do begin
            SetRange("Document Type", BlanketOrderSalesHeader."Document Type");
            SetRange("Document No.", BlanketOrderSalesHeader."No.");
            SetRange(Type, Type::Item);
            SetFilter("No.", '<>%1', '');
            if FindSet then
                repeat
                    if "Qty. to Ship" > 0 then begin
                        SalesLine := BlanketOrderSalesLine;
                        ResetQuantityFields(SalesLine);
                        SalesLine.Quantity := "Qty. to Ship";
                        SalesLine."Quantity (Base)" := Round(SalesLine.Quantity * SalesLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                        SalesLine."Qty. to Ship" := SalesLine.Quantity;
                        SalesLine."Qty. to Ship (Base)" := SalesLine."Quantity (Base)";
                        SalesLine.InitOutstanding;
                        if ATOLink.AsmExistsForSalesLine(BlanketOrderSalesLine) then begin
                            SalesLine."Qty. to Assemble to Order" := SalesLine.Quantity;
                            SalesLine."Qty. to Asm. to Order (Base)" := SalesLine."Quantity (Base)";
                            SalesLine."Outstanding Quantity" -= SalesLine."Qty. to Assemble to Order";
                            SalesLine."Outstanding Qty. (Base)" -= SalesLine."Qty. to Asm. to Order (Base)";
                        end;

                        if not HideValidationDialog then
                            CheckSalesLineItemAvailability();
                    end;
                until Next() = 0;
        end;
    end;

    local procedure CheckSalesLineItemAvailability()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLineItemAvailability(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if ItemCheckAvail.SalesLineCheck(SalesLine) then
            ItemCheckAvail.RaiseUpdateInterruptedError;
    end;

    local procedure IsSalesOrderLineToBeInserted(SalesOrderLine: Record "Sales Line"): Boolean
    var
        AttachedToSalesLine: Record "Sales Line";
    begin
        if SalesOrderLine."Attached to Line No." = 0 then
            exit(true);
        exit(
          AttachedToSalesLine.Get(
            SalesOrderLine."Document Type", SalesOrderLine."Document No.", SalesOrderLine."Attached to Line No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var SalesHeader: Record "Sales Header"; var HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; var BlanketOrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; BlanketOrderSalesLine: Record "Sales Line"; BlanketOrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; BlanketOrderSalesLine: Record "Sales Line"; BlanketOrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllSalesOrderLines(var BlanketOrderSalesHeader: Record "Sales Header"; var OrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetQuantityFields(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlanketOrderLineQuantity(var BlanketOrderSalesLine: Record "Sales Line"; QuantityOnOrders: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLineItemAvailability(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandlingBlanketOrderSalesLine(var BlanketOrderSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesOrderLineValidateQuantity(var SalesOrderLine: Record "Sales Line"; BlanketOrderSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesOrderHeaderModify(var SalesOrderHeader: Record "Sales Header"; BlanketOrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReserveItemsManuallyLoop(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterBlanketOrderSalesLineSetFilters(var BlanketOrderSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesOrderLineValidateShipmentDate(BlanketOrderSalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSalesLineReserveTransferSaleLineToSalesLine(var BlanketOrderSalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeResetQuantityFields(var BlanketOrderSalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeValidateBlanketOrderSalesLineQtytoShip(var BlanketOrderSalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; BlanketOrderSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

