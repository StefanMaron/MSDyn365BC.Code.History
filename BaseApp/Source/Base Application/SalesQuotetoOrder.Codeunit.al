codeunit 86 "Sales-Quote to Order"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        Cust: Record Customer;
        SalesCommentLine: Record "Sales Comment Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        RecordLinkManagement: Codeunit "Record Link Management";
        ShouldRedistributeInvoiceAmount: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(Rec);

        TestField("Document Type", "Document Type"::Quote);
        ShouldRedistributeInvoiceAmount := SalesCalcDiscountByType.ShouldRedistributeInvoiceDiscountAmount(Rec);

        OnCheckSalesPostRestrictions;

        Cust.Get("Sell-to Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, "Document Type"::Order, true, false);
        if "Sell-to Customer No." <> "Bill-to Customer No." then begin
            Cust.Get("Bill-to Customer No.");
            Cust.CheckBlockedCustOnDocs(Cust, "Document Type"::Order, true, false);
        end;
        CalcFields("Amount Including VAT", "Work Description");

        ValidateSalesPersonOnSalesHeader(Rec, true, false);

        CheckForBlockedLines;

        CheckInProgressOpportunities(Rec);

        CreateSalesHeader(Rec, Cust."Prepayment %");

        TransferQuoteToOrderLines(SalesQuoteLine, Rec, SalesOrderLine, SalesOrderHeader, Cust);
        OnAfterInsertAllSalesOrderLines(SalesOrderLine, Rec);

        SalesSetup.Get();
        case SalesSetup."Archive Quotes" of
            SalesSetup."Archive Quotes"::Always:
                ArchiveManagement.ArchSalesDocumentNoConfirm(Rec);
            SalesSetup."Archive Quotes"::Question:
                ArchiveManagement.ArchiveSalesDocument(Rec);
        end;

        if SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" then begin
            SalesOrderHeader."Posting Date" := 0D;
            SalesOrderHeader.Modify();
        end;

        SalesCommentLine.CopyComments("Document Type", SalesOrderHeader."Document Type", "No.", SalesOrderHeader."No.");
        RecordLinkManagement.CopyLinks(Rec, SalesOrderHeader);

        AssignItemCharges("Document Type", "No.", SalesOrderHeader."Document Type", SalesOrderHeader."No.");

        MoveWonLostOpportunites(Rec, SalesOrderHeader);

        ApprovalsMgmt.CopyApprovalEntryQuoteToOrder(RecordId, SalesOrderHeader."No.", SalesOrderHeader.RecordId);

        IsHandled := false;
        OnBeforeDeleteSalesQuote(Rec, SalesOrderHeader, IsHandled, SalesQuoteLine);
        if not IsHandled then begin
            ApprovalsMgmt.DeleteApprovalEntries(RecordId);
            DeleteLinks;
            Delete;
            SalesQuoteLine.DeleteAll();
        end;

        if not ShouldRedistributeInvoiceAmount then
            SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(SalesOrderHeader);

        OnAfterOnRun(Rec, SalesOrderHeader);
    end;

    var
        Text000: Label 'An open %1 is linked to this %2. The %1 has to be closed before the %2 can be converted to an %3. Do you want to close the %1 now and continue the conversion?', Comment = 'An open Opportunity is linked to this Quote. The Opportunity has to be closed before the Quote can be converted to an Order. Do you want to close the Opportunity now and continue the conversion?';
        Text001: Label 'An open %1 is still linked to this %2. The conversion to an %3 was aborted.', Comment = 'An open Opportunity is still linked to this Quote. The conversion to an Order was aborted.';
        SalesQuoteLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";

    local procedure CreateSalesHeader(SalesHeader: Record "Sales Header"; PrepmtPercent: Decimal)
    begin
        OnBeforeCreateSalesHeader(SalesHeader);

        with SalesHeader do begin
            SalesOrderHeader := SalesHeader;
            SalesOrderHeader."Document Type" := SalesOrderHeader."Document Type"::Order;

            SalesOrderHeader."No. Printed" := 0;
            SalesOrderHeader.Status := SalesOrderHeader.Status::Open;
            SalesOrderHeader."No." := '';
            SalesOrderHeader."Quote No." := "No.";
            SalesOrderLine.LockTable();
            OnBeforeInsertSalesOrderHeader(SalesOrderHeader, SalesHeader);
            SalesOrderHeader.Insert(true);

            SalesOrderHeader."Order Date" := "Order Date";
            if "Posting Date" <> 0D then
                SalesOrderHeader."Posting Date" := "Posting Date";

            SalesOrderHeader.InitFromSalesHeader(SalesHeader);
            SalesOrderHeader."Outbound Whse. Handling Time" := "Outbound Whse. Handling Time";
            SalesOrderHeader.Reserve := Reserve;

            SalesOrderHeader."Prepayment %" := PrepmtPercent;
            if SalesOrderHeader."Posting Date" = 0D then
                SalesOrderHeader."Posting Date" := WorkDate;
            OnBeforeModifySalesOrderHeader(SalesOrderHeader, SalesHeader);
            SalesOrderHeader.Modify();
        end;
    end;

    local procedure AssignItemCharges(FromDocType: Option; FromDocNo: Code[20]; ToDocType: Option; ToDocNo: Code[20])
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", FromDocType);
        ItemChargeAssgntSales.SetRange("Document No.", FromDocNo);
        while ItemChargeAssgntSales.FindFirst do begin
            ItemChargeAssgntSales.Delete();
            ItemChargeAssgntSales."Document Type" := SalesOrderHeader."Document Type";
            ItemChargeAssgntSales."Document No." := SalesOrderHeader."No.";
            if not (ItemChargeAssgntSales."Applies-to Doc. Type" in
                    [ItemChargeAssgntSales."Applies-to Doc. Type"::Shipment,
                     ItemChargeAssgntSales."Applies-to Doc. Type"::"Return Receipt"])
            then begin
                ItemChargeAssgntSales."Applies-to Doc. Type" := ToDocType;
                ItemChargeAssgntSales."Applies-to Doc. No." := ToDocNo;
            end;
            ItemChargeAssgntSales.Insert();
        end;
    end;

    procedure GetSalesOrderHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader2 := SalesOrderHeader;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        if NewHideValidationDialog then
            exit;
    end;

    local procedure CheckInProgressOpportunities(var SalesHeader: Record "Sales Header")
    var
        Opp: Record Opportunity;
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Opp.Reset();
        Opp.SetCurrentKey("Sales Document Type", "Sales Document No.");
        Opp.SetRange("Sales Document Type", Opp."Sales Document Type"::Quote);
        Opp.SetRange("Sales Document No.", SalesHeader."No.");
        Opp.SetRange(Status, Opp.Status::"In Progress");
        if Opp.FindFirst then begin
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(
                   Text000, Opp.TableCaption, Opp."Sales Document Type"::Quote,
                   Opp."Sales Document Type"::Order), true)
            then
                Error('');
            TempOpportunityEntry.DeleteAll();
            TempOpportunityEntry.Init();
            TempOpportunityEntry.Validate("Opportunity No.", Opp."No.");
            TempOpportunityEntry."Sales Cycle Code" := Opp."Sales Cycle Code";
            TempOpportunityEntry."Contact No." := Opp."Contact No.";
            TempOpportunityEntry."Contact Company No." := Opp."Contact Company No.";
            TempOpportunityEntry."Salesperson Code" := Opp."Salesperson Code";
            TempOpportunityEntry."Campaign No." := Opp."Campaign No.";
            TempOpportunityEntry."Action Taken" := TempOpportunityEntry."Action Taken"::Won;
            TempOpportunityEntry."Calcd. Current Value (LCY)" := TempOpportunityEntry.GetSalesDocValue(SalesHeader);
            TempOpportunityEntry."Cancel Old To Do" := true;
            TempOpportunityEntry."Wizard Step" := 1;
            TempOpportunityEntry.Insert();
            TempOpportunityEntry.SetRange("Action Taken", TempOpportunityEntry."Action Taken"::Won);
            PAGE.RunModal(PAGE::"Close Opportunity", TempOpportunityEntry);
            Opp.Reset();
            Opp.SetCurrentKey("Sales Document Type", "Sales Document No.");
            Opp.SetRange("Sales Document Type", Opp."Sales Document Type"::Quote);
            Opp.SetRange("Sales Document No.", SalesHeader."No.");
            Opp.SetRange(Status, Opp.Status::"In Progress");
            if Opp.FindFirst then
                Error(Text001, Opp.TableCaption, Opp."Sales Document Type"::Quote, Opp."Sales Document Type"::Order);
            Commit();
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        end;
    end;

    local procedure MoveWonLostOpportunites(var SalesQuoteHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    var
        Opp: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
    begin
        Opp.Reset();
        Opp.SetCurrentKey("Sales Document Type", "Sales Document No.");
        Opp.SetRange("Sales Document Type", Opp."Sales Document Type"::Quote);
        Opp.SetRange("Sales Document No.", SalesQuoteHeader."No.");
        if Opp.FindFirst then
            if Opp.Status = Opp.Status::Won then begin
                Opp."Sales Document Type" := Opp."Sales Document Type"::Order;
                Opp."Sales Document No." := SalesOrderHeader."No.";
                Opp.Modify();
                OpportunityEntry.Reset();
                OpportunityEntry.SetCurrentKey(Active, "Opportunity No.");
                OpportunityEntry.SetRange(Active, true);
                OpportunityEntry.SetRange("Opportunity No.", Opp."No.");
                if OpportunityEntry.FindFirst then begin
                    OpportunityEntry."Calcd. Current Value (LCY)" := OpportunityEntry.GetSalesDocValue(SalesOrderHeader);
                    OpportunityEntry.Modify();
                end;
            end else
                if Opp.Status = Opp.Status::Lost then begin
                    Opp."Sales Document Type" := Opp."Sales Document Type"::" ";
                    Opp."Sales Document No." := '';
                    Opp.Modify();
                end;
    end;

    local procedure TransferQuoteToOrderLines(var SalesQuoteLine: Record "Sales Line"; var SalesQuoteHeader: Record "Sales Header"; var SalesOrderLine: Record "Sales Line"; var SalesOrderHeader: Record "Sales Header"; Customer: Record Customer)
    var
        ATOLink: Record "Assemble-to-Order Link";
        PrepmtMgt: Codeunit "Prepayment Mgt.";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsHandled: Boolean;
    begin
        SalesQuoteLine.Reset();
        SalesQuoteLine.SetRange("Document Type", SalesQuoteHeader."Document Type");
        SalesQuoteLine.SetRange("Document No.", SalesQuoteHeader."No.");
        OnTransferQuoteToOrderLinesOnAfterSetFilters(SalesQuoteLine, SalesQuoteHeader);
        if SalesQuoteLine.FindSet then
            repeat
                IsHandled := false;
                OnBeforeTransferQuoteLineToOrderLineLoop(SalesQuoteLine, SalesQuoteHeader, SalesOrderHeader, IsHandled);
                if not IsHandled then begin
                    SalesOrderLine := SalesQuoteLine;
                    SalesOrderLine."Document Type" := SalesOrderHeader."Document Type";
                    SalesOrderLine."Document No." := SalesOrderHeader."No.";
                    SalesOrderLine."Shortcut Dimension 1 Code" := SalesQuoteLine."Shortcut Dimension 1 Code";
                    SalesOrderLine."Shortcut Dimension 2 Code" := SalesQuoteLine."Shortcut Dimension 2 Code";
                    SalesOrderLine."Dimension Set ID" := SalesQuoteLine."Dimension Set ID";
                    if Customer."Prepayment %" <> 0 then
                        SalesOrderLine."Prepayment %" := Customer."Prepayment %";
                    PrepmtMgt.SetSalesPrepaymentPct(SalesOrderLine, SalesOrderHeader."Posting Date");
                    SalesOrderLine.Validate("Prepayment %");
                    if SalesOrderLine."No." <> '' then
                        SalesOrderLine.DefaultDeferralCode;
                    OnBeforeInsertSalesOrderLine(SalesOrderLine, SalesOrderHeader, SalesQuoteLine, SalesQuoteHeader);
                    SalesOrderLine.Insert();
                    OnAfterInsertSalesOrderLine(SalesOrderLine, SalesOrderHeader, SalesQuoteLine, SalesQuoteHeader);
                    ATOLink.MakeAsmOrderLinkedToSalesOrderLine(SalesQuoteLine, SalesOrderLine);
                    SalesLineReserve.TransferSaleLineToSalesLine(
                      SalesQuoteLine, SalesOrderLine, SalesQuoteLine."Outstanding Qty. (Base)");
                    SalesLineReserve.VerifyQuantity(SalesOrderLine, SalesQuoteLine);
                    if SalesOrderLine.Reserve = SalesOrderLine.Reserve::Always then
                        SalesOrderLine.AutoReserve;
                end;
            until SalesQuoteLine.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesQuote(var QuoteSalesHeader: Record "Sales Header"; var OrderSalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesQuoteLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; SalesQuoteLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllSalesOrderLines(var SalesOrderLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; SalesQuoteLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferQuoteLineToOrderLineLoop(var SalesQuoteLine: Record "Sales Line"; var SalesQuoteHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferQuoteToOrderLinesOnAfterSetFilters(var SalesQuoteLine: Record "Sales Line"; var SalesQuoteHeader: Record "Sales Header")
    begin
    end;
}

