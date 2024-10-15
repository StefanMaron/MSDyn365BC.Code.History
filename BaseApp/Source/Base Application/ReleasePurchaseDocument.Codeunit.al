codeunit 415 "Release Purchase Document"
{
    TableNo = "Purchase Header";
    Permissions = TableData "Purchase Header" = rm;

    trigger OnRun()
    begin
        PurchaseHeader.Copy(Rec);
        Code;
        Rec := PurchaseHeader;
    end;

    var
        Text001: Label 'There is nothing to release for the document of type %1 with the number %2.';
        PurchSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
        WhsePurchRelease: Codeunit "Whse.-Purch. Release";
        Text002: Label 'This document can only be released when the approval process is complete.';
        Text003: Label 'The approval process must be cancelled or completed to reopen this document.';
        Text005: Label 'There are unpaid prepayment invoices that are related to the document of type %1 with the number %2.';
        Text046: Label 'The %1 does not match the quantity defined in item tracking.';
        Text12401: Label 'Item Tracking does not match for line %1, %2 %3, %4 %5';
        UnpostedPrepaymentAmountsErr: Label 'There are unposted prepayment amounts on the document of type %1 with the number %2.', Comment = '%1 - Document Type; %2 - Document No.';
        PreviewMode: Boolean;
        SkipCheckReleaseRestrictions: Boolean;

    local procedure "Code"() LinesWereModified: Boolean
    var
        PurchLine: Record "Purchase Line";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        NotOnlyDropShipment: Boolean;
        PostingDate: Date;
        PrintPostedDocuments: Boolean;
        IsHandled: Boolean;
    begin
        with PurchaseHeader do begin
            if Status = Status::Released then
                exit;

            OnBeforeReleasePurchaseDoc(PurchaseHeader, PreviewMode);
            if not (PreviewMode or SkipCheckReleaseRestrictions) then
                CheckPurchaseReleaseRestrictions;

            TestField("Buy-from Vendor No.");
            TestAgreement(PurchaseHeader);

            PurchLine.SetRange("Document Type", "Document Type");
            PurchLine.SetRange("Document No.", "No.");
            PurchLine.SetFilter(Type, '>0');
            PurchLine.SetFilter(Quantity, '<>0');
            if not PurchLine.Find('-') then
                Error(Text001, "Document Type", "No.");
            InvtSetup.Get();
            if InvtSetup."Location Mandatory" then begin
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                if PurchLine.Find('-') then
                    repeat
                        if PurchLine.IsInventoriableItem then
                            PurchLine.TestField("Location Code");
                    until PurchLine.Next = 0;
                PurchLine.SetFilter(Type, '>0');
            end;

            OnCodeOnAfterCheck(PurchaseHeader, PurchLine, LinesWereModified);

            PurchLine.SetRange("Drop Shipment", false);
            NotOnlyDropShipment := PurchLine.Find('-');
            PurchLine.SetRange("Drop Shipment");
            TestTrackingSpecification(PurchaseHeader, PurchLine);
            PurchLine.Reset();

            OnBeforeCalcInvDiscount(PurchaseHeader, PreviewMode);

            PurchSetup.Get();
            if PurchSetup."Calc. Inv. Discount" then begin
                PostingDate := "Posting Date";
                PrintPostedDocuments := "Print Posted Documents";
                CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchLine);
                LinesWereModified := true;
                Get("Document Type", "No.");
                "Print Posted Documents" := PrintPostedDocuments;
                if PostingDate <> "Posting Date" then
                    Validate("Posting Date", PostingDate);
            end;

            IsHandled := false;
            OnBeforeModifyPurchDoc(PurchaseHeader, PreviewMode, IsHandled);
            if IsHandled then
                exit;

            if PrepaymentMgt.TestPurchasePrepayment(PurchaseHeader) and ("Document Type" = "Document Type"::Order) then begin
                Status := Status::"Pending Prepayment";
                Modify(true);
                OnAfterReleasePurchaseDoc(PurchaseHeader, PreviewMode, LinesWereModified);
                exit;
            end;
            Status := Status::Released;

            LinesWereModified := LinesWereModified or CalcAndUpdateVATOnLines(PurchaseHeader, PurchLine);

            OnCodeOnBeforeModifyHeader(PurchaseHeader, PurchLine, PreviewMode, LinesWereModified);

            Modify(true);

            if NotOnlyDropShipment then
                if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                    WhsePurchRelease.Release(PurchaseHeader);

            OnAfterReleasePurchaseDoc(PurchaseHeader, PreviewMode, LinesWereModified);
        end;
    end;

    procedure Reopen(var PurchHeader: Record "Purchase Header")
    begin
        OnBeforeReopenPurchaseDoc(PurchHeader, PreviewMode);

        with PurchHeader do begin
            if Status = Status::Open then
                exit;
            if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                WhsePurchRelease.Reopen(PurchHeader);
            Status := Status::Open;

            Modify(true);
        end;

        OnAfterReopenPurchaseDoc(PurchHeader, PreviewMode);
    end;

    procedure PerformManualRelease(var PurchHeader: Record "Purchase Header")
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        OnPerformManualReleaseOnBeforeTestPurchasePrepayment(PurchHeader, PreviewMode);
        if PrepaymentMgt.TestPurchasePrepayment(PurchHeader) then
            Error(UnpostedPrepaymentAmountsErr, PurchHeader."Document Type", PurchHeader."No.");

        OnBeforeManualReleasePurchaseDoc(PurchHeader, PreviewMode);
        PerformManualCheckAndRelease(PurchHeader);
        OnAfterManualReleasePurchaseDoc(PurchHeader, PreviewMode);
    end;

    procedure PerformManualCheckAndRelease(var PurchHeader: Record "Purchase Header")
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        IsHandled: Boolean;
    begin
        OnBeforePerformManualCheckAndRelease(PurchHeader, PreviewMode);

        with PurchHeader do
            if ("Document Type" = "Document Type"::Order) and PrepaymentMgt.TestPurchasePayment(PurchHeader) then begin
                if TestStatusIsNotPendingPrepayment then begin
                    Status := Status::"Pending Prepayment";
                    Modify;
                    Commit();
                end;
                Error(Text005, "Document Type", "No.");
            end;

        if ApprovalsMgmt.IsPurchaseHeaderPendingApproval(PurchHeader) then
            Error(Text002);

        IsHandled := false;
        OnBeforePerformManualRelease(PurchHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchHeader);
    end;

    procedure PerformManualReopen(var PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader.Status = PurchHeader.Status::"Pending Approval" then
            Error(Text003);

        OnBeforeManualReopenPurchaseDoc(PurchHeader, PreviewMode);
        Reopen(PurchHeader);
        OnAfterManualReopenPurchaseDoc(PurchHeader, PreviewMode);
    end;

    [Scope('OnPrem')]
    procedure TestAgreement(PurchHeader: Record "Purchase Header")
    var
        Vend: Record Vendor;
    begin
        if (PurchHeader."Document Type" = PurchHeader."Document Type"::Quote) or
          (PurchHeader."Document Type" = PurchHeader."Document Type"::"Blanket Order")
        then
            exit;

        Vend.Get(PurchHeader."Buy-from Vendor No.");
        case Vend."Agreement Posting" of
            Vend."Agreement Posting"::Mandatory:
                PurchHeader.TestField("Agreement No.");
            Vend."Agreement Posting"::"No Agreement":
                PurchHeader.TestField("Agreement No.", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure TestTrackingSpecification(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        PurchLineToCheck: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        CDTrackingSetup: Record "CD Tracking Setup";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ErrorFieldCaption: Text[250];
        SignFactor: Integer;
        PurchLineQtyHandled: Decimal;
        PurchLineQtyToHandle: Decimal;
        TrackingQtyHandled: Decimal;
        TrackingQtyToHandle: Decimal;
        Inbound: Boolean;
        CheckPurchLine: Boolean;
    begin
        // if a PurchaseLine is posted with ItemTracking then the whole quantity of
        // the regarding PurchaseLine has to be post with Item-Tracking

        if not
          ((PurchHeader."Document Type" = PurchHeader."Document Type"::Order) or
           (PurchHeader."Document Type" = PurchHeader."Document Type"::"Return Order"))
        then
            exit;

        TrackingQtyToHandle := 0;
        TrackingQtyHandled := 0;

        PurchLineToCheck.Copy(PurchLine);
        PurchLineToCheck.SetRange(Type, PurchLineToCheck.Type::Item);
        if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then begin
            PurchLineToCheck.SetFilter("Qty. to Receive", '<>%1', 0);
            ErrorFieldCaption := PurchLineToCheck.FieldCaption("Qty. to Receive");
        end else begin
            PurchLineToCheck.SetFilter("Return Qty. to Ship", '<>%1', 0);
            ErrorFieldCaption := PurchLineToCheck.FieldCaption("Return Qty. to Ship");
        end;

        if PurchLineToCheck.FindSet then begin
            ReservationEntry."Source Type" := DATABASE::"Purchase Line";
            ReservationEntry."Source Subtype" := PurchHeader."Document Type".AsInteger();
            SignFactor := CreateReservEntry.SignFactor(ReservationEntry);
            repeat
                // Only Item where no SerialNo or LotNo is required
                Item.Get(PurchLineToCheck."No.");
                if Item."Item Tracking Code" <> '' then begin
                    Inbound := (PurchLineToCheck.Quantity * SignFactor) > 0;
                    ItemTrackingCode.Code := Item."Item Tracking Code";
                    if CDTrackingSetup.Get(Item."Item Tracking Code", PurchLineToCheck."Location Code") then;
                    ItemTrackingManagement.GetItemTrackingSetup(ItemTrackingCode, CDTrackingSetup, 0, Inbound, ItemTrackingSetup);
                    CheckPurchLine := ItemTrackingSetup."CD No. Required" and CDTrackingSetup."CD Purchase Check on Release";
                    if CheckPurchLine then
                        if not GetTrackingQuantities(PurchLineToCheck, 0, TrackingQtyToHandle, TrackingQtyHandled) then
                            if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then
                                Error(Text12401,
                                  PurchLineToCheck."Line No.", Format(PurchLineToCheck.Type), PurchLineToCheck."No.",
                                  PurchLineToCheck.FieldCaption("Qty. to Receive"), PurchLineToCheck."Qty. to Receive")
                            else
                                Error(Text12401,
                                  PurchLineToCheck."Line No.", Format(PurchLineToCheck.Type), PurchLineToCheck."No.",
                                  PurchLineToCheck.FieldCaption("Qty. to Receive"), PurchLineToCheck."Return Qty. to Ship")
                end else
                    CheckPurchLine := false;

                TrackingQtyToHandle := 0;
                TrackingQtyHandled := 0;

                if CheckPurchLine then begin
                    GetTrackingQuantities(PurchLineToCheck, 1, TrackingQtyToHandle, TrackingQtyHandled);
                    TrackingQtyToHandle := TrackingQtyToHandle * SignFactor;
                    TrackingQtyHandled := TrackingQtyHandled * SignFactor;
                    if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then begin
                        PurchLineQtyToHandle := PurchLineToCheck."Qty. to Receive (Base)";
                        PurchLineQtyHandled := PurchLineToCheck."Qty. Received (Base)";
                    end else begin
                        PurchLineQtyToHandle := PurchLineToCheck."Return Qty. to Ship (Base)";
                        PurchLineQtyHandled := PurchLineToCheck."Return Qty. Shipped (Base)";
                    end;
                    if ((TrackingQtyHandled + TrackingQtyToHandle) <> (PurchLineQtyHandled + PurchLineQtyToHandle)) or
                       (TrackingQtyToHandle <> PurchLineQtyToHandle)
                    then
                        Error(Text046, ErrorFieldCaption);
                end;
            until PurchLineToCheck.Next = 0;
        end;
    end;

    local procedure GetTrackingQuantities(PurchLine: Record "Purchase Line"; FunctionType: Option CheckTrackingExists,GetQty; var TrackingQtyToHandle: Decimal; var TrackingQtyHandled: Decimal): Boolean
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
    begin
        with TrackingSpecification do begin
            SetCurrentKey("Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
            SetRange("Source Type", DATABASE::"Purchase Line");
            SetRange("Source Subtype", PurchLine."Document Type");
            SetRange("Source ID", PurchLine."Document No.");
            SetRange("Source Batch Name", '');
            SetRange("Source Prod. Order Line", 0);
            SetRange("Source Ref. No.", PurchLine."Line No.");
        end;
        with ReservEntry do begin
            SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line");
            SetRange("Source ID", PurchLine."Document No.");
            SetRange("Source Ref. No.", PurchLine."Line No.");
            SetRange("Source Type", DATABASE::"Purchase Line");
            SetRange("Source Subtype", PurchLine."Document Type");
            SetRange("Source Batch Name", '');
            SetRange("Source Prod. Order Line", 0);
        end;

        case FunctionType of
            FunctionType::CheckTrackingExists:
                begin
                    TrackingSpecification.SetRange(Correction, false);
                    if not TrackingSpecification.IsEmpty then
                        exit(true);
                    ReservEntry.SetFilter("Serial No.", '<>%1', '');
                    if not ReservEntry.IsEmpty then
                        exit(true);
                    ReservEntry.SetRange("Serial No.");
                    ReservEntry.SetFilter("Lot No.", '<>%1', '');
                    if not ReservEntry.IsEmpty then
                        exit(true);
                    ReservEntry.SetRange("Lot No.");
                    ReservEntry.SetFilter("CD No.", '<>%1', '');
                    if not ReservEntry.IsEmpty then
                        exit(true);
                end;
            FunctionType::GetQty:
                begin
                    TrackingSpecification.CalcSums("Quantity Handled (Base)");
                    TrackingQtyHandled := TrackingSpecification."Quantity Handled (Base)";
                    if ReservEntry.FindSet then
                        repeat
                            if (ReservEntry."Lot No." <> '') or (ReservEntry."Serial No." <> '') or
                              (ReservEntry."CD No." <> '')
                            then
                                TrackingQtyToHandle := TrackingQtyToHandle + ReservEntry."Qty. to Handle (Base)";
                        until ReservEntry.Next = 0;
                end;
        end;
    end;

    procedure ReleasePurchaseHeader(var PurchHdr: Record "Purchase Header"; Preview: Boolean) LinesWereModified: Boolean
    begin
        PreviewMode := Preview;
        PurchaseHeader.Copy(PurchHdr);
        LinesWereModified := Code;
        PurchHdr := PurchaseHeader;
    end;

    procedure CalcAndUpdateVATOnLines(var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line") LinesWereModified: Boolean
    var
        TempVATAmountLine0: Record "VAT Amount Line" temporary;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
    begin
        PurchLine.SetPurchHeader(PurchaseHeader);
        PurchLine.CalcVATAmountLines(0, PurchaseHeader, PurchLine, TempVATAmountLine0);
        PurchLine.CalcVATAmountLines(1, PurchaseHeader, PurchLine, TempVATAmountLine1);
        LinesWereModified :=
          PurchLine.UpdateVATOnLines(0, PurchaseHeader, PurchLine, TempVATAmountLine0) or
          PurchLine.UpdateVATOnLines(1, PurchaseHeader, PurchLine, TempVATAmountLine1);
    end;

    procedure SetSkipCheckReleaseRestrictions()
    begin
        SkipCheckReleaseRestrictions := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscount(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualCheckAndRelease(var PurchHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualRelease(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheck(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var LinesWereModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeModifyHeader(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPerformManualReleaseOnBeforeTestPurchasePrepayment(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    begin
    end;
}

