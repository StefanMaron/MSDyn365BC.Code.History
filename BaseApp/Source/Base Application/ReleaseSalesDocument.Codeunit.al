codeunit 414 "Release Sales Document"
{
    TableNo = "Sales Header";
    Permissions = TableData "Sales Header" = rm;

    trigger OnRun()
    begin
        SalesHeader.Copy(Rec);
        Code;
        Rec := SalesHeader;
    end;

    var
        Text001: Label 'There is nothing to release for the document of type %1 with the number %2.';
        SalesSetup: Record "Sales & Receivables Setup";
        InvtSetup: Record "Inventory Setup";
        SalesHeader: Record "Sales Header";
        WhseSalesRelease: Codeunit "Whse.-Sales Release";
        Text002: Label 'This document can only be released when the approval process is complete.';
        Text003: Label 'The approval process must be cancelled or completed to reopen this document.';
        Text005: Label 'There are unpaid prepayment invoices that are related to the document of type %1 with the number %2.';
        Text046: Label 'The %1 does not match the quantity defined in item tracking.';
        Text12402: Label 'Item Tracking does not match for line %1, %2 %3, %4 %5';
        UnpostedPrepaymentAmountsErr: Label 'There are unposted prepayment amounts on the document of type %1 with the number %2.', Comment = '%1 - Document Type; %2 - Document No.';
        PreviewMode: Boolean;
        SkipCheckReleaseRestrictions: Boolean;

    local procedure "Code"() LinesWereModified: Boolean
    var
        SalesLine: Record "Sales Line";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        NotOnlyDropShipment: Boolean;
        PostingDate: Date;
        PrintPostedDocuments: Boolean;
        IsHandled: Boolean;
    begin
        with SalesHeader do begin
            if Status = Status::Released then
                exit;

            IsHandled := false;
            OnBeforeReleaseSalesDoc(SalesHeader, PreviewMode, IsHandled);
            if IsHandled then
                exit;
            if not (PreviewMode or SkipCheckReleaseRestrictions) then
                CheckSalesReleaseRestrictions;

            IsHandled := false;
            OnBeforeCheckCustomerCreated(SalesHeader, IsHandled);
            if not IsHandled then
                if "Document Type" = "Document Type"::Quote then
                    if CheckCustomerCreated(true) then
                        Get("Document Type"::Quote, "No.")
                    else
                        exit;

            TestField("Sell-to Customer No.");
            TestAgreement(SalesHeader);

            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "No.");
            SalesLine.SetFilter(Type, '>0');
            SalesLine.SetFilter(Quantity, '<>0');
            OnBeforeSalesLineFind(SalesLine, SalesHeader);
            if not SalesLine.Find('-') then
                Error(Text001, "Document Type", "No.");
            InvtSetup.Get();
            if InvtSetup."Location Mandatory" then begin
                SalesLine.SetRange(Type, SalesLine.Type::Item);
                if SalesLine.FindSet then
                    repeat
                        if SalesLine.IsInventoriableItem then
                            SalesLine.TestField("Location Code");
                        OnCodeOnAfterSalesLineCheck(SalesLine);
                    until SalesLine.Next = 0;
                SalesLine.SetFilter(Type, '>0');
            end;

            OnCodeOnAfterCheck(SalesHeader, SalesLine, LinesWereModified);

            SalesLine.SetRange("Drop Shipment", false);
            NotOnlyDropShipment := SalesLine.FindFirst;
            SalesLine.SetRange("Drop Shipment");
            TestTrackingSpecification(SalesHeader, SalesLine);
            SalesLine.Reset();

            OnBeforeCalcInvDiscount(SalesHeader, PreviewMode);

            SalesSetup.Get();
            if SalesSetup."Calc. Inv. Discount" then begin
                PostingDate := "Posting Date";
                PrintPostedDocuments := "Print Posted Documents";
                CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
                LinesWereModified := true;
                Get("Document Type", "No.");
                "Print Posted Documents" := PrintPostedDocuments;
                if PostingDate <> "Posting Date" then
                    Validate("Posting Date", PostingDate);
            end;

            IsHandled := false;
            OnBeforeModifySalesDoc(SalesHeader, PreviewMode, IsHandled);
            if IsHandled then
                exit;

            if PrepaymentMgt.TestSalesPrepayment(SalesHeader) and ("Document Type" = "Document Type"::Order) then begin
                Status := Status::"Pending Prepayment";
                Modify(true);
                OnAfterReleaseSalesDoc(SalesHeader, PreviewMode, LinesWereModified);
                exit;
            end;
            Status := Status::Released;

            LinesWereModified := LinesWereModified or CalcAndUpdateVATOnLines(SalesHeader, SalesLine);

            OnAfterUpdateSalesDocLines(SalesHeader, LinesWereModified, PreviewMode);

            ReleaseATOs(SalesHeader);
            OnAfterReleaseATOs(SalesHeader, SalesLine, PreviewMode);

            Modify(true);

            if NotOnlyDropShipment then
                if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                    WhseSalesRelease.Release(SalesHeader);

            OnAfterReleaseSalesDoc(SalesHeader, PreviewMode, LinesWereModified);
        end;
    end;

    procedure Reopen(var SalesHeader: Record "Sales Header")
    begin
        OnBeforeReopenSalesDoc(SalesHeader, PreviewMode);

        with SalesHeader do begin
            if Status = Status::Open then
                exit;
            Status := Status::Open;

            if "Document Type" <> "Document Type"::Order then
                ReopenATOs(SalesHeader);

            OnReopenOnBeforeSalesHeaderModify(SalesHeader);
            Modify(true);
            if "Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"] then
                WhseSalesRelease.Reopen(SalesHeader);
        end;

        OnAfterReopenSalesDoc(SalesHeader, PreviewMode);
    end;

    procedure PerformManualRelease(var SalesHeader: Record "Sales Header")
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        OnPerformManualReleaseOnBeforeTestSalesPrepayment(SalesHeader, PreviewMode);
        if PrepaymentMgt.TestSalesPrepayment(SalesHeader) then
            Error(UnpostedPrepaymentAmountsErr, SalesHeader."Document Type", SalesHeader."No.");

        OnBeforeManualReleaseSalesDoc(SalesHeader, PreviewMode);
        PerformManualCheckAndRelease(SalesHeader);
        OnAfterManualReleaseSalesDoc(SalesHeader, PreviewMode);
    end;

    procedure PerformManualCheckAndRelease(var SalesHeader: Record "Sales Header")
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        IsHandled: Boolean;
    begin
        OnBeforePerformManualCheckAndRelease(SalesHeader, PreviewMode);

        with SalesHeader do
            if ("Document Type" = "Document Type"::Order) and PrepaymentMgt.TestSalesPayment(SalesHeader) then begin
                if TestStatusIsNotPendingPrepayment then begin
                    Status := Status::"Pending Prepayment";
                    Modify;
                    Commit();
                end;
                Error(Text005, "Document Type", "No.");
            end;

        if ApprovalsMgmt.IsSalesHeaderPendingApproval(SalesHeader) then
            Error(Text002);

        IsHandled := false;
        OnBeforePerformManualRelease(SalesHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);

        OnAfterPerformManualCheckAndRelease(SalesHeader, PreviewMode);
    end;

    procedure PerformManualReopen(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader.Status = SalesHeader.Status::"Pending Approval" then
            Error(Text003);

        OnBeforeManualReOpenSalesDoc(SalesHeader, PreviewMode);
        Reopen(SalesHeader);
        OnAfterManualReOpenSalesDoc(SalesHeader, PreviewMode);
    end;

    local procedure ReleaseATOs(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet then
            repeat
                if SalesLine.AsmToOrderExists(AsmHeader) then
                    CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AsmHeader);
            until SalesLine.Next = 0;
    end;

    local procedure ReopenATOs(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        ReleaseAssemblyDocument: Codeunit "Release Assembly Document";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet then
            repeat
                if SalesLine.AsmToOrderExists(AsmHeader) then
                    ReleaseAssemblyDocument.Reopen(AsmHeader);
            until SalesLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure TestAgreement(SalesHeader: Record "Sales Header")
    var
        Cust: Record Customer;
    begin
        if (SalesHeader."Document Type" = SalesHeader."Document Type"::Quote) or
          (SalesHeader."Document Type" = SalesHeader."Document Type"::"Blanket Order")
        then
            exit;

        Cust.Get(SalesHeader."Sell-to Customer No.");
        case Cust."Agreement Posting" of
            Cust."Agreement Posting"::Mandatory:
                SalesHeader.TestField("Agreement No.");
            Cust."Agreement Posting"::"No Agreement":
                SalesHeader.TestField("Agreement No.", '');
        end;
    end;

    [Scope('OnPrem')]
    procedure TestTrackingSpecification(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        SalesLineToCheck: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        CDTrackingSetup: Record "CD Tracking Setup";
        Item: Record Item;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ErrorFieldCaption: Text[250];
        SignFactor: Integer;
        SalesLineQtyHandled: Decimal;
        SalesLineQtyToHandle: Decimal;
        TrackingQtyHandled: Decimal;
        TrackingQtyToHandle: Decimal;
        Inbound: Boolean;
        CheckSalesLine: Boolean;
    begin
        // if a SalesLine is posted with ItemTracking then the whole quantity of
        // the regarding SalesLine has to be post with Item-Tracking

        if SalesHeader."Document Type" in
          [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::"Return Order"] = false
        then
            exit;

        TrackingQtyToHandle := 0;
        TrackingQtyHandled := 0;

        SalesLineToCheck.Copy(SalesLine);
        SalesLineToCheck.SetRange(Type, SalesLineToCheck.Type::Item);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            SalesLineToCheck.SetFilter("Qty. to Ship", '<>%1', 0);
            ErrorFieldCaption := SalesLineToCheck.FieldCaption("Qty. to Ship");
        end else begin
            SalesLineToCheck.SetFilter("Return Qty. to Receive", '<>%1', 0);
            ErrorFieldCaption := SalesLineToCheck.FieldCaption("Return Qty. to Receive");
        end;

        if SalesLineToCheck.FindSet then begin
            ReservationEntry."Source Type" := DATABASE::"Sales Line";
            ReservationEntry."Source Subtype" := SalesHeader."Document Type";
            SignFactor := CreateReservEntry.SignFactor(ReservationEntry);
            repeat
                // Only Item where no SerialNo or LotNo is required
                Item.Get(SalesLineToCheck."No.");
                if Item."Item Tracking Code" <> '' then begin
                    Inbound := (SalesLineToCheck.Quantity * SignFactor) > 0;
                    ItemTrackingCode.Code := Item."Item Tracking Code";
                    if CDTrackingSetup.Get(Item."Item Tracking Code", SalesLineToCheck."Location Code") then;
                    ItemTrackingManagement.GetItemTrackingSetup(ItemTrackingCode, CDTrackingSetup, 1, Inbound, ItemTrackingSetup);
                    CheckSalesLine := ItemTrackingSetup."CD No. Required" and CDTrackingSetup."CD Sales Check on Release";
                    if CheckSalesLine then
                        if not GetTrackingQuantities(SalesLineToCheck, 0, TrackingQtyToHandle, TrackingQtyHandled) then
                            if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
                                Error(Text12402,
                                  SalesLineToCheck."Line No.", Format(SalesLineToCheck.Type), SalesLineToCheck."No.",
                                  SalesLineToCheck.FieldCaption("Qty. to Ship"), SalesLineToCheck."Qty. to Ship")
                            else
                                Error(Text12402,
                                  SalesLineToCheck."Line No.", Format(SalesLineToCheck.Type), SalesLineToCheck."No.",
                                  SalesLineToCheck.FieldCaption("Return Qty. to Receive"), SalesLineToCheck."Return Qty. to Receive")
                end else
                    CheckSalesLine := false;

                TrackingQtyToHandle := 0;
                TrackingQtyHandled := 0;

                if CheckSalesLine then begin
                    if CDTrackingSetup."CD Info. Must Exist" then
                        GetTrackingQuantities(SalesLineToCheck, 2, TrackingQtyToHandle, TrackingQtyHandled);
                    GetTrackingQuantities(SalesLineToCheck, 1, TrackingQtyToHandle, TrackingQtyHandled);
                    TrackingQtyToHandle := TrackingQtyToHandle * SignFactor;
                    TrackingQtyHandled := TrackingQtyHandled * SignFactor;
                    if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
                        SalesLineQtyToHandle := SalesLineToCheck."Qty. to Ship (Base)";
                        SalesLineQtyHandled := SalesLineToCheck."Qty. Shipped (Base)";
                    end else begin
                        SalesLineQtyToHandle := SalesLineToCheck."Return Qty. to Receive (Base)";
                        SalesLineQtyHandled := SalesLineToCheck."Return Qty. Received (Base)";
                    end;
                    if ((TrackingQtyHandled + TrackingQtyToHandle) <> (SalesLineQtyHandled + SalesLineQtyToHandle)) or
                       (TrackingQtyToHandle <> SalesLineQtyToHandle)
                    then
                        Error(Text046, ErrorFieldCaption);
                end;
            until SalesLineToCheck.Next = 0;
        end;
    end;

    local procedure GetTrackingQuantities(SalesLine: Record "Sales Line"; FunctionType: Option CheckTrackingExists,GetQty,CheckTempCDNo; var TrackingQtyToHandle: Decimal; var TrackingQtyHandled: Decimal): Boolean
    var
        Item: Record Item;
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        CDNoInfo: Record "CD No. Information";
        CDTrackingSetup: Record "CD Tracking Setup";
    begin
        with TrackingSpecification do begin
            SetCurrentKey("Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
            SetRange("Source Type", DATABASE::"Sales Line");
            SetRange("Source Subtype", SalesLine."Document Type");
            SetRange("Source ID", SalesLine."Document No.");
            SetRange("Source Batch Name", '');
            SetRange("Source Prod. Order Line", 0);
            SetRange("Source Ref. No.", SalesLine."Line No.");
        end;
        with ReservEntry do begin
            SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line");
            SetRange("Source ID", SalesLine."Document No.");
            SetRange("Source Ref. No.", SalesLine."Line No.");
            SetRange("Source Type", DATABASE::"Sales Line");
            SetRange("Source Subtype", SalesLine."Document Type");
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
                            if (ReservEntry."Lot No." <> '') or (ReservEntry."Serial No." <> '') or (ReservEntry."CD No." <> '') then
                                TrackingQtyToHandle := TrackingQtyToHandle + ReservEntry."Qty. to Handle (Base)";
                        until ReservEntry.Next = 0;
                end;
            FunctionType::CheckTempCDNo:
                begin
                    if ReservEntry.FindSet then
                        repeat
                            if ReservEntry."CD No." <> '' then begin
                                Item.Get(ReservEntry."Item No.");
                                CDTrackingSetup.Get(Item."Item Tracking Code", ReservEntry."Location Code");
                                CDNoInfo.Get(CDNoInfo.Type::Item, ReservEntry."Item No.", ReservEntry."Variant Code", ReservEntry."CD No.");
                                if not CDTrackingSetup."Allow Temporary CD No." then
                                    CDNoInfo.TestField("Temporary CD No.", false);
                            end;
                        until ReservEntry.Next = 0;
                end;
        end;
    end;

    procedure ReleaseSalesHeader(var SalesHdr: Record "Sales Header"; Preview: Boolean) LinesWereModified: Boolean
    begin
        PreviewMode := Preview;
        SalesHeader.Copy(SalesHdr);
        LinesWereModified := Code;
        SalesHdr := SalesHeader;
    end;

    procedure SetSkipCheckReleaseRestrictions()
    begin
        SkipCheckReleaseRestrictions := true;
    end;

    procedure CalcAndUpdateVATOnLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line") LinesWereModified: Boolean
    var
        TempVATAmountLine0: Record "VAT Amount Line" temporary;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
    begin
        SalesLine.SetSalesHeader(SalesHeader);
        // 0 = General, 1 = Invoicing, 2 = Shipping
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, TempVATAmountLine0, false);
        SalesLine.CalcVATAmountLines(1, SalesHeader, SalesLine, TempVATAmountLine1, false);
        LinesWereModified :=
          SalesLine.UpdateVATOnLines(0, SalesHeader, SalesLine, TempVATAmountLine0) or
          SalesLine.UpdateVATOnLines(1, SalesHeader, SalesLine, TempVATAmountLine1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscount(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeManualReOpenSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualRelease(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineFind(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManualReOpenSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPerformManualCheckAndRelease(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseATOs(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesDocLines(var SalesHeader: Record "Sales Header"; var LinesWereModified: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheck(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var LinesWereModified: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterSalesLineCheck(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerCreated(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualCheckAndRelease(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReopenOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPerformManualReleaseOnBeforeTestSalesPrepayment(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean)
    begin
    end;
}

