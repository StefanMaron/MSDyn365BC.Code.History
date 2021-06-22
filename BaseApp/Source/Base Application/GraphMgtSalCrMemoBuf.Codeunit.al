codeunit 5508 "Graph Mgt - Sal. Cr. Memo Buf."
{
    Permissions = TableData "Sales Cr.Memo Header" = rimd;

    trigger OnRun()
    begin
    end;

    var
        DocumentIDNotSpecifiedErr: Label 'You must specify a document id to get the lines.';
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.';
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.';
        CannotModifyPostedCrMemoErr: Label 'The credit memo has been posted and can no longer be modified.';
        CannotInsertALineThatAlreadyExistsErr: Label 'You cannot insert a line because a line already exists.';
        CannotModifyALineThatDoesntExistErr: Label 'You cannot modify a line that does not exist.';
        CannotInsertPostedCrMemoErr: Label 'Credit memos created through the API must be in Draft state.';
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CreditMemoIdIsNotSpecifiedErr: Label 'Credit Memo ID is not specified.', Locked = true;
        EntityIsNotFoundErr: Label 'Sales Credit Memo Entity is not found.', Locked = true;
        AggregatorCategoryLbl: Label 'Sales Credit Memo Aggregator', Locked = true;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromSalesHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySalesHeader(var Rec: Record "Sales Header"; var xRec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if IsBackgroundPosting(Rec) then
            exit;

        InsertOrModifyFromSalesHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        TransferRecordIDs(Rec);

        if not SalesCrMemoEntityBuffer.Get(Rec."No.") then
            exit;

        SalesCrMemoEntityBuffer.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, 56, 'OnAfterResetRecalculateInvoiceDisc', '', false, false)]
    local procedure OnAfterResetRecalculateCreditMemoDisc(var SalesHeader: Record "Sales Header")
    begin
        if not CheckValidRecord(SalesHeader) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromSalesHeader(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSalesLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        UpdateCompletelyShipped(Rec);
        ModifyTotalsSalesLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySalesLine(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        UpdateCompletelyShipped(Rec);
        ModifyTotalsSalesLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesLine(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        UpdateCompletelyShipped(Rec);

        SalesLine.SetRange("Document No.", Rec."Document No.");
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Recalculate Invoice Disc.", true);

        if SalesLine.FindFirst then begin
            ModifyTotalsSalesLine(SalesLine);
            exit;
        end;

        SalesLine.SetRange("Recalculate Invoice Disc.");

        if not SalesLine.FindFirst then
            BlankTotals(Rec."Document No.", false);
    end;

    [EventSubscriber(ObjectType::Table, 114, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSalesCreditMemoHeader(var Rec: Record "Sales Cr.Memo Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromSalesCreditMemoHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 114, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySalesCreditMemoHeader(var Rec: Record "Sales Cr.Memo Header"; var xRec: Record "Sales Cr.Memo Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromSalesCreditMemoHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 114, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameSalesCreditMemoHeader(var Rec: Record "Sales Cr.Memo Header"; var xRec: Record "Sales Cr.Memo Header"; RunTrigger: Boolean)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if not SalesCrMemoEntityBuffer.Get(xRec."No.", true) then
            exit;

        SalesCrMemoEntityBuffer.SetIsRenameAllowed(true);
        SalesCrMemoEntityBuffer.Rename(Rec."No.", true);
    end;

    [EventSubscriber(ObjectType::Table, 114, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesCreditMemoHeader(var Rec: Record "Sales Cr.Memo Header"; RunTrigger: Boolean)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if not SalesCrMemoEntityBuffer.Get(Rec."No.", true) then
            exit;

        SalesCrMemoEntityBuffer.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, 60, 'OnAfterCalcSalesDiscount', '', false, false)]
    local procedure OnAfterCalculateSalesDiscountOnSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        if not CheckValidRecord(SalesHeader) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromSalesHeader(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Table, 21, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertCustomerLedgerEntry(var Rec: Record "Cust. Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromCustLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 21, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCustomerLedgerEntry(var Rec: Record "Cust. Ledger Entry"; var xRec: Record "Cust. Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromCustLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 21, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameCustomerLedgerEntry(var Rec: Record "Cust. Ledger Entry"; var xRec: Record "Cust. Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromCustLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 21, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteCustomerLedgerEntry(var Rec: Record "Cust. Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromCustLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 1900, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertCancelledDocument(var Rec: Record "Cancelled Document"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromCancelledDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 1900, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCancelledDocument(var Rec: Record "Cancelled Document"; var xRec: Record "Cancelled Document"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromCancelledDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 1900, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameCancelledDocument(var Rec: Record "Cancelled Document"; var xRec: Record "Cancelled Document"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromCancelledDocument(xRec);
        SetStatusOptionFromCancelledDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 1900, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteCancelledDocument(var Rec: Record "Cancelled Document"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromCancelledDocument(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnBeforeSalesCrMemoHeaderInsert', '', false, false)]
    local procedure OnBeforeSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        IsRenameAllowed: Boolean;
    begin
        if SalesCrMemoHeader.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if IsNullGuid(SalesHeader.SystemId) then begin
            SendTraceTag('00006TN', AggregatorCategoryLbl, VERBOSITY::Error, CreditMemoIdIsNotSpecifiedErr,
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        if SalesCrMemoHeader."Pre-Assigned No." <> SalesHeader."No." then
            exit;

        if not SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false) then begin
            SendTraceTag('00006TO', AggregatorCategoryLbl, VERBOSITY::Error, EntityIsNotFoundErr,
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        if SalesCrMemoEntityBuffer.Id <> SalesHeader.Id then
            exit;

        IsRenameAllowed := SalesCrMemoEntityBuffer.GetIsRenameAllowed;
        SalesCrMemoEntityBuffer.SetIsRenameAllowed(true);
        SalesCrMemoEntityBuffer.Rename(SalesCrMemoHeader."No.", true);
        SalesCrMemoEntityBuffer.SetIsRenameAllowed(IsRenameAllowed);
        SalesCrMemoHeader."Draft Cr. Memo SystemId" := SalesHeader.SystemId;
    end;

    procedure PropagateOnInsert(var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesHeader: Record "Sales Header";
        TypeHelper: Codeunit "Type Helper";
        TargetRecordRef: RecordRef;
        DocTypeFieldRef: FieldRef;
        NoFieldRef: FieldRef;
    begin
        if SalesCrMemoEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if SalesCrMemoEntityBuffer.Posted then
            Error(CannotInsertPostedCrMemoErr);

        TargetRecordRef.Open(DATABASE::"Sales Header");

        DocTypeFieldRef := TargetRecordRef.Field(SalesHeader.FieldNo("Document Type"));
        DocTypeFieldRef.Value(SalesHeader."Document Type"::"Credit Memo");

        NoFieldRef := TargetRecordRef.Field(SalesHeader.FieldNo("No."));

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, SalesCrMemoEntityBuffer, TargetRecordRef);

        TargetRecordRef.Insert(true);

        SalesCrMemoEntityBuffer."No." := NoFieldRef.Value;
        SalesCrMemoEntityBuffer.Get(SalesCrMemoEntityBuffer."No.", SalesCrMemoEntityBuffer.Posted);
    end;

    procedure PropagateOnModify(var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesHeader: Record "Sales Header";
        TypeHelper: Codeunit "Type Helper";
        TargetRecordRef: RecordRef;
        Exists: Boolean;
    begin
        if SalesCrMemoEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if SalesCrMemoEntityBuffer.Posted then
            Error(CannotModifyPostedCrMemoErr);

        Exists := SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesCrMemoEntityBuffer."No.");
        if Exists then
            TargetRecordRef.GetTable(SalesHeader)
        else
            TargetRecordRef.Open(DATABASE::"Sales Header");

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, SalesCrMemoEntityBuffer, TargetRecordRef);

        if Exists then
            TargetRecordRef.Modify(true)
        else
            TargetRecordRef.Insert(true);
    end;

    procedure PropagateOnDelete(var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
    begin
        if SalesCrMemoEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if SalesCrMemoEntityBuffer.Posted then begin
            SalesCrMemoHeader.Get(SalesCrMemoEntityBuffer."No.");
            if SalesCrMemoHeader."No. Printed" = 0 then
                SalesCrMemoHeader."No. Printed" := 1;
            SalesCrMemoHeader.Delete(true);
        end else begin
            SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesCrMemoEntityBuffer."No.");
            SalesHeader.Delete(true);
        end;
    end;

    procedure UpdateBufferTableRecords()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        if SalesHeader.FindSet then
            repeat
                InsertOrModifyFromSalesHeader(SalesHeader);
            until SalesHeader.Next = 0;

        if SalesCrMemoHeader.FindSet then
            repeat
                InsertOrModifyFromSalesCreditMemoHeader(SalesCrMemoHeader);
            until SalesCrMemoHeader.Next = 0;

        SalesCrMemoEntityBuffer.SetRange(Posted, false);
        if SalesCrMemoEntityBuffer.FindSet(true, false) then
            repeat
                if not SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesCrMemoEntityBuffer."No.") then
                    SalesCrMemoEntityBuffer.Delete(true);
            until SalesCrMemoEntityBuffer.Next = 0;

        SalesCrMemoEntityBuffer.SetRange(Posted, true);
        if SalesCrMemoEntityBuffer.FindSet(true, false) then
            repeat
                if not SalesCrMemoHeader.Get(SalesCrMemoEntityBuffer."No.") then
                    SalesCrMemoEntityBuffer.Delete(true);
            until SalesCrMemoEntityBuffer.Next = 0;
    end;

    local procedure InsertOrModifyFromSalesHeader(var SalesHeader: Record "Sales Header")
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        RecordExists: Boolean;
    begin
        SalesCrMemoEntityBuffer.LockTable();
        RecordExists := SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false);

        SalesCrMemoEntityBuffer.TransferFields(SalesHeader, true);
        SalesCrMemoEntityBuffer.Id := SalesHeader.SystemId;
        SalesCrMemoEntityBuffer.Posted := false;
        SetStatusOptionFromSalesHeader(SalesHeader, SalesCrMemoEntityBuffer);
        AssignTotalsFromSalesHeader(SalesHeader, SalesCrMemoEntityBuffer);
        SalesCrMemoEntityBuffer.UpdateReferencedRecordIds;

        if RecordExists then
            SalesCrMemoEntityBuffer.Modify(true)
        else
            SalesCrMemoEntityBuffer.Insert(true);
    end;

    procedure GetSalesCrMemoHeaderId(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Guid
    begin
        if (not IsNullGuid(SalesCrMemoHeader."Draft Cr. Memo SystemId")) then
            exit(SalesCrMemoHeader."Draft Cr. Memo SystemId");

        exit(SalesCrMemoHeader.Id);
    end;

    procedure GetSalesCrMemoHeaderFromId(Id: Text; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
    begin
        SalesCrMemoHeader.SetFilter("Draft Cr. Memo SystemId", Id);
        IF SalesCrMemoHeader.FINDFIRST() THEN
            exit(true);

        SalesCrMemoHeader.SetRange("Draft Cr. Memo SystemId");
        SalesCrMemoHeader.SetFilter(Id, Id);

        IF SalesCrMemoHeader.FindFirst() then
            exit(true);

        exit(false);
    end;

    local procedure InsertOrModifyFromSalesCreditMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        RecordExists: Boolean;
    begin
        SalesCrMemoEntityBuffer.LockTable();
        RecordExists := SalesCrMemoEntityBuffer.Get(SalesCrMemoHeader."No.", true);
        SalesCrMemoEntityBuffer.TransferFields(SalesCrMemoHeader, true);
        SalesCrMemoEntityBuffer.Id := GetSalesCrMemoHeaderId(SalesCrMemoHeader);

        SalesCrMemoEntityBuffer.Posted := true;
        SetStatusOptionFromSalesCreditMemoHeader(SalesCrMemoHeader, SalesCrMemoEntityBuffer);
        AssignTotalsFromSalesCreditMemoHeader(SalesCrMemoHeader, SalesCrMemoEntityBuffer);
        SalesCrMemoEntityBuffer.UpdateReferencedRecordIds;

        if RecordExists then
            SalesCrMemoEntityBuffer.Modify(true)
        else
            SalesCrMemoEntityBuffer.Insert(true);
    end;

    local procedure SetStatusOptionFromSalesCreditMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    begin
        SalesCrMemoHeader.CalcFields(Cancelled, Corrective, Paid);
        if SalesCrMemoHeader.Cancelled then begin
            SalesCrMemoEntityBuffer.Status := SalesCrMemoEntityBuffer.Status::Canceled;
            exit;
        end;

        if SalesCrMemoHeader.Corrective then begin
            SalesCrMemoEntityBuffer.Status := SalesCrMemoEntityBuffer.Status::Corrective;
            exit;
        end;

        if SalesCrMemoHeader.Paid then begin
            SalesCrMemoEntityBuffer.Status := SalesCrMemoEntityBuffer.Status::Paid;
            exit;
        end;

        SalesCrMemoEntityBuffer.Status := SalesCrMemoEntityBuffer.Status::Open;
    end;

    local procedure SetStatusOptionFromSalesHeader(var SalesHeader: Record "Sales Header"; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    begin
        if SalesHeader.Status = SalesHeader.Status::"Pending Approval" then begin
            SalesCrMemoEntityBuffer.Status := SalesCrMemoEntityBuffer.Status::"In Review";
            exit;
        end;

        if (SalesHeader.Status = SalesHeader.Status::Released) or
           (SalesHeader.Status = SalesHeader.Status::"Pending Prepayment")
        then begin
            SalesCrMemoEntityBuffer.Status := SalesCrMemoEntityBuffer.Status::Open;
            exit;
        end;

        SalesCrMemoEntityBuffer.Status := SalesCrMemoEntityBuffer.Status::Draft;
    end;

    local procedure SetStatusOptionFromCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        if not GraphMgtGeneralTools.IsApiEnabled then
            exit;

        SalesCrMemoEntityBuffer.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        SalesCrMemoEntityBuffer.SetRange(Posted, true);

        if not SalesCrMemoEntityBuffer.FindSet(true) then
            exit;

        repeat
            UpdateStatusIfChanged(SalesCrMemoEntityBuffer);
        until SalesCrMemoEntityBuffer.Next = 0;
    end;

    local procedure SetStatusOptionFromCancelledDocument(var CancelledDocument: Record "Cancelled Document")
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        if not GraphMgtGeneralTools.IsApiEnabled then
            exit;

        case CancelledDocument."Source ID" of
            DATABASE::"Sales Cr.Memo Header":
                if not SalesCrMemoEntityBuffer.Get(CancelledDocument."Cancelled Doc. No.", true) then
                    exit;
            DATABASE::"Sales Invoice Header":
                if not SalesCrMemoEntityBuffer.Get(CancelledDocument."Cancelled By Doc. No.", true) then
                    exit;
            else
                exit;
        end;

        UpdateStatusIfChanged(SalesCrMemoEntityBuffer);
    end;

    local procedure UpdateStatusIfChanged(var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CurrentStatus: Option;
    begin
        SalesCrMemoHeader.Get(SalesCrMemoEntityBuffer."No.");
        CurrentStatus := SalesCrMemoEntityBuffer.Status;

        SetStatusOptionFromSalesCreditMemoHeader(SalesCrMemoHeader, SalesCrMemoEntityBuffer);
        if CurrentStatus <> SalesCrMemoEntityBuffer.Status then
            SalesCrMemoEntityBuffer.Modify(true);
    end;

    local procedure AssignTotalsFromSalesHeader(var SalesHeader: Record "Sales Header"; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");

        if not SalesLine.FindFirst then begin
            BlankTotals(SalesLine."Document No.", false);
            exit;
        end;

        AssignTotalsFromSalesLine(SalesLine, SalesCrMemoEntityBuffer, SalesHeader);
    end;

    local procedure AssignTotalsFromSalesCreditMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");

        if not SalesCrMemoLine.FindFirst then begin
            BlankTotals(SalesCrMemoLine."Document No.", true);
            exit;
        end;

        AssignTotalsFromSalesCreditMemoLine(SalesCrMemoLine, SalesCrMemoEntityBuffer);
    end;

    local procedure AssignTotalsFromSalesLine(var SalesLine: Record "Sales Line"; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer"; var SalesHeader: Record "Sales Header")
    var
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Sales Tax" then begin
            SalesCrMemoEntityBuffer."Discount Applied Before Tax" := true;
            SalesCrMemoEntityBuffer."Prices Including VAT" := false;
        end else
            SalesCrMemoEntityBuffer."Discount Applied Before Tax" := not SalesHeader."Prices Including VAT";

        DocumentTotals.CalculateSalesTotals(TotalSalesLine, VATAmount, SalesLine);

        SalesCrMemoEntityBuffer."Invoice Discount Amount" := TotalSalesLine."Inv. Discount Amount";
        SalesCrMemoEntityBuffer.Amount := TotalSalesLine.Amount;
        SalesCrMemoEntityBuffer."Total Tax Amount" := VATAmount;
        SalesCrMemoEntityBuffer."Amount Including VAT" := TotalSalesLine."Amount Including VAT";
    end;

    local procedure AssignTotalsFromSalesCreditMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TotalSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if SalesCrMemoLine."VAT Calculation Type" = SalesCrMemoLine."VAT Calculation Type"::"Sales Tax" then
            SalesCrMemoEntityBuffer."Discount Applied Before Tax" := true
        else begin
            SalesCrMemoHeader.Get(SalesCrMemoLine."Document No.");
            SalesCrMemoEntityBuffer."Discount Applied Before Tax" := not SalesCrMemoHeader."Prices Including VAT";
        end;

        DocumentTotals.CalculatePostedSalesCreditMemoTotals(TotalSalesCrMemoHeader, VATAmount, SalesCrMemoLine);

        SalesCrMemoEntityBuffer."Invoice Discount Amount" := TotalSalesCrMemoHeader."Invoice Discount Amount";
        SalesCrMemoEntityBuffer.Amount := TotalSalesCrMemoHeader.Amount;
        SalesCrMemoEntityBuffer."Total Tax Amount" := VATAmount;
        SalesCrMemoEntityBuffer."Amount Including VAT" := TotalSalesCrMemoHeader."Amount Including VAT";
    end;

    local procedure BlankTotals(DocumentNo: Code[20]; Posted: Boolean)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        if not SalesCrMemoEntityBuffer.Get(DocumentNo, Posted) then
            exit;

        SalesCrMemoEntityBuffer."Invoice Discount Amount" := 0;
        SalesCrMemoEntityBuffer."Total Tax Amount" := 0;

        SalesCrMemoEntityBuffer.Amount := 0;
        SalesCrMemoEntityBuffer."Amount Including VAT" := 0;
        SalesCrMemoEntityBuffer.Modify();
    end;

    local procedure CheckValidRecord(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if SalesHeader.IsTemporary then
            exit(false);

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::"Credit Memo" then
            exit(false);

        exit(true);
    end;

    local procedure CheckValidLineRecord(var SalesLine: Record "Sales Line"): Boolean
    begin
        if SalesLine.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit(false);

        if SalesLine."Document Type" <> SalesLine."Document Type"::"Credit Memo" then
            exit(false);

        exit(true);
    end;

    local procedure ModifyTotalsSalesLine(var SalesLine: Record "Sales Line")
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesHeader: Record "Sales Header";
    begin
        if SalesLine.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if SalesLine."Document Type" <> SalesLine."Document Type"::"Credit Memo" then
            exit;

        if not SalesCrMemoEntityBuffer.Get(SalesLine."Document No.", false) then
            exit;

        if not SalesLine."Recalculate Invoice Disc." then
            exit;

        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit;

        AssignTotalsFromSalesLine(SalesLine, SalesCrMemoEntityBuffer, SalesHeader);
        SalesCrMemoEntityBuffer.Modify(true);
    end;

    local procedure TransferSalesCreditMemoLineAggregateToSalesLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesLine: Record "Sales Line"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        TypeHelper: Codeunit "Type Helper";
        SalesLineRecordRef: RecordRef;
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
        SalesLineRecordRef.GetTable(SalesLine);

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, SalesInvoiceLineAggregate, SalesLineRecordRef);

        SalesLineRecordRef.SetTable(SalesLine);
    end;

    local procedure TransferRecordIDs(var SalesHeader: Record "Sales Header")
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IntegrationManagement: Codeunit "Integration Management";
        IsRenameAllowed: Boolean;
    begin
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        if not SalesCrMemoHeader.FindFirst then
            exit;

        if SalesCrMemoHeader."Draft Cr. Memo SystemId" = SalesHeader.SystemId then
            exit;

        if SalesCrMemoEntityBuffer.Get(SalesCrMemoHeader."No.", true) then
            SalesCrMemoEntityBuffer.Delete(true);

        if SalesCrMemoEntityBuffer.Get(SalesHeader."No.", false) then begin
            IsRenameAllowed := SalesCrMemoEntityBuffer.GetIsRenameAllowed;
            SalesCrMemoEntityBuffer.SetIsRenameAllowed(true);
            SalesCrMemoEntityBuffer.Rename(SalesCrMemoHeader."No.", true);
            SalesCrMemoEntityBuffer.SetIsRenameAllowed(IsRenameAllowed);
        end;

        SalesCrMemoHeader."Draft Cr. Memo SystemId" := SalesHeader.SystemId;
        SalesCrMemoHeader.Modify(true);
    end;

    procedure RedistributeCreditMemoDiscounts(var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        if SalesCrMemoEntityBuffer.Posted then
            exit;

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesCrMemoEntityBuffer."No.");
        SalesLine.SetRange("Recalculate Invoice Disc.", true);
        if SalesLine.FindFirst then
            CODEUNIT.Run(CODEUNIT::"Sales - Calc Discount By Type", SalesLine);

        SalesCrMemoEntityBuffer.Get(SalesCrMemoEntityBuffer."No.", SalesCrMemoEntityBuffer.Posted);
    end;

    procedure LoadLines(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; DocumentIdFilter: Text)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        if DocumentIdFilter = '' then
            Error(DocumentIDNotSpecifiedErr);

        SalesCrMemoEntityBuffer.SetFilter(Id, DocumentIdFilter);
        if not SalesCrMemoEntityBuffer.FindFirst then
            exit;

        if SalesCrMemoEntityBuffer.Posted then
            LoadSalesCreditMemoLines(SalesInvoiceLineAggregate, SalesCrMemoEntityBuffer)
        else
            LoadSalesLines(SalesInvoiceLineAggregate, SalesCrMemoEntityBuffer);
    end;

    local procedure LoadSalesCreditMemoLines(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoEntityBuffer."No.");

        if SalesCrMemoLine.FindSet(false, false) then
            repeat
                Clear(SalesInvoiceLineAggregate);
                SalesInvoiceLineAggregate.TransferFields(SalesCrMemoLine, true);
                SalesInvoiceLineAggregate.Id :=
                  SalesInvoiceAggregator.GetIdFromDocumentIdAndSequence(SalesCrMemoEntityBuffer.Id, SalesCrMemoLine."Line No.");
                SalesInvoiceLineAggregate."Document Id" := SalesCrMemoEntityBuffer.Id;
                SalesInvoiceAggregator.SetTaxGroupIdAndCode(
                  SalesInvoiceLineAggregate,
                  SalesCrMemoLine."Tax Group Code",
                  SalesCrMemoLine."VAT Prod. Posting Group",
                  SalesCrMemoLine."VAT Identifier");
                SalesInvoiceLineAggregate."VAT %" := SalesCrMemoLine."VAT %";
                SalesInvoiceLineAggregate."Tax Amount" := SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine."VAT Base Amount";
                SalesInvoiceLineAggregate."Currency Code" := SalesCrMemoLine.GetCurrencyCode;
                SalesInvoiceLineAggregate."Prices Including Tax" := SalesCrMemoEntityBuffer."Prices Including VAT";
                SalesInvoiceLineAggregate.UpdateReferencedRecordIds;
                UpdateLineAmountsFromSalesInvoiceLine(SalesInvoiceLineAggregate, SalesCrMemoLine);
                SalesInvoiceLineAggregate.Insert(true);
            until SalesCrMemoLine.Next = 0;
    end;

    local procedure LoadSalesLines(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", SalesCrMemoEntityBuffer."No.");

        if SalesLine.FindSet(false, false) then
            repeat
                TransferFromSalesLine(SalesInvoiceLineAggregate, SalesLine, SalesCrMemoEntityBuffer);
                SalesInvoiceLineAggregate.Insert(true);
            until SalesLine.Next = 0;
    end;

    local procedure TransferFromSalesLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesLine: Record "Sales Line"; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        SalesInvoiceAggregator.TransferFromSalesLineToAggregateLine(
          SalesInvoiceLineAggregate, SalesLine, SalesCrMemoEntityBuffer.Id, SalesCrMemoEntityBuffer."Prices Including VAT");
    end;

    procedure PropagateInsertLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesLine: Record "Sales Line";
        LastUsedSalesLine: Record "Sales Line";
    begin
        VerifyCRUDIsPossibleForLine(SalesInvoiceLineAggregate, SalesCrMemoEntityBuffer);

        SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
        SalesLine."Document No." := SalesCrMemoEntityBuffer."No.";

        if SalesInvoiceLineAggregate."Line No." = 0 then begin
            LastUsedSalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
            LastUsedSalesLine.SetRange("Document No.", SalesCrMemoEntityBuffer."No.");
            if LastUsedSalesLine.FindLast then
                SalesInvoiceLineAggregate."Line No." := LastUsedSalesLine."Line No." + 10000
            else
                SalesInvoiceLineAggregate."Line No." := 10000;

            SalesLine."Line No." := SalesInvoiceLineAggregate."Line No.";
        end else
            if SalesLine.Get(SalesLine."Document Type"::"Credit Memo", SalesCrMemoEntityBuffer."No.", SalesInvoiceLineAggregate."Line No.") then
                Error(CannotInsertALineThatAlreadyExistsErr);

        TransferSalesCreditMemoLineAggregateToSalesLine(SalesInvoiceLineAggregate, SalesLine, TempFieldBuffer);
        SalesLine.Insert(true);

        RedistributeCreditMemoDiscounts(SalesCrMemoEntityBuffer);

        SalesLine.Find;
        TransferFromSalesLine(SalesInvoiceLineAggregate, SalesLine, SalesCrMemoEntityBuffer);
    end;

    procedure PropagateModifyLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesLine: Record "Sales Line";
    begin
        VerifyCRUDIsPossibleForLine(SalesInvoiceLineAggregate, SalesCrMemoEntityBuffer);

        if not SalesLine.Get(SalesLine."Document Type"::"Credit Memo", SalesCrMemoEntityBuffer."No.", SalesInvoiceLineAggregate."Line No.") then
            Error(CannotModifyALineThatDoesntExistErr);

        TransferSalesCreditMemoLineAggregateToSalesLine(SalesInvoiceLineAggregate, SalesLine, TempFieldBuffer);

        SalesLine.Modify(true);

        RedistributeCreditMemoDiscounts(SalesCrMemoEntityBuffer);

        SalesLine.Find;
        TransferFromSalesLine(SalesInvoiceLineAggregate, SalesLine, SalesCrMemoEntityBuffer);
    end;

    procedure PropagateDeleteLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate")
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        SalesLine: Record "Sales Line";
    begin
        VerifyCRUDIsPossibleForLine(SalesInvoiceLineAggregate, SalesCrMemoEntityBuffer);

        if SalesLine.Get(SalesLine."Document Type"::"Credit Memo", SalesCrMemoEntityBuffer."No.", SalesInvoiceLineAggregate."Line No.") then begin
            SalesLine.Delete(true);
            RedistributeCreditMemoDiscounts(SalesCrMemoEntityBuffer);
        end;
    end;

    local procedure VerifyCRUDIsPossibleForLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        SearchSalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        DocumentIDFilter: Text;
    begin
        if IsNullGuid(SalesInvoiceLineAggregate."Document Id") then begin
            DocumentIDFilter := SalesInvoiceLineAggregate.GetFilter("Document Id");
            if DocumentIDFilter = '' then
                Error(DocumentIDNotSpecifiedErr);
            SalesCrMemoEntityBuffer.SetFilter(Id, DocumentIDFilter);
        end else
            SalesCrMemoEntityBuffer.SetRange(Id, SalesInvoiceLineAggregate."Document Id");

        if not SalesCrMemoEntityBuffer.FindFirst then
            Error(DocumentDoesNotExistErr);

        SearchSalesCrMemoEntityBuffer.Copy(SalesCrMemoEntityBuffer);
        if SearchSalesCrMemoEntityBuffer.Next <> 0 then
            Error(MultipleDocumentsFoundForIdErr);

        if SalesCrMemoEntityBuffer.Posted then
            Error(CannotModifyPostedCrMemoErr);
    end;

    local procedure UpdateCompletelyShipped(var SalesLine: Record "Sales Line")
    var
        SearchSalesLine: Record "Sales Line";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        CompletelyShipped: Boolean;
    begin
        SearchSalesLine.Copy(SalesLine);
        SearchSalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SearchSalesLine.SetRange("Document No.", SalesLine."Document No.");
        SearchSalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SearchSalesLine.SetRange("Location Code", SalesLine."Location Code");
        SearchSalesLine.SetRange("Completely Shipped", false);

        CompletelyShipped := not SearchSalesLine.FindFirst;

        if not SalesCrMemoEntityBuffer.Get(SalesLine."Document No.") then
            exit;
        if SalesCrMemoEntityBuffer."Completely Shipped" <> CompletelyShipped then begin
            SalesCrMemoEntityBuffer."Completely Shipped" := CompletelyShipped;
            SalesCrMemoEntityBuffer.Modify(true);
        end;
    end;

    local procedure UpdateLineAmountsFromSalesInvoiceLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        SalesInvoiceLineAggregate."Line Amount Excluding Tax" := SalesCrMemoLine.GetLineAmountExclVAT;
        SalesInvoiceLineAggregate."Line Amount Including Tax" := SalesCrMemoLine.GetLineAmountInclVAT;
        SalesInvoiceLineAggregate."Line Tax Amount" :=
          SalesInvoiceLineAggregate."Line Amount Including Tax" - SalesInvoiceLineAggregate."Line Amount Excluding Tax";
        SalesInvoiceAggregator.UpdateInvoiceDiscountAmount(SalesInvoiceLineAggregate);
    end;

    local procedure IsBackgroundPosting(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if SalesHeader.IsTemporary then
            exit(false);

        exit(SalesHeader."Job Queue Status" in [SalesHeader."Job Queue Status"::"Scheduled for Posting", SalesHeader."Job Queue Status"::Posting]);
    end;
}

