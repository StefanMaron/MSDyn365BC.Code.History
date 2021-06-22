codeunit 5529 "Purch. Inv. Aggregator"
{
    Permissions = TableData "Purch. Inv. Header" = rimd;

    trigger OnRun()
    begin
    end;

    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        DocumentIDNotSpecifiedErr: Label 'You must specify a document id to get the lines.', Locked = true;
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.', Locked = true;
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.', Locked = true;
        CannotModifyPostedInvioceErr: Label 'The invoice has been posted and can no longer be modified.', Locked = true;
        CannotInsertALineThatAlreadyExistsErr: Label 'You cannot insert a line with a duplicate sequence number.', Locked = true;
        CannotModifyALineThatDoesntExistErr: Label 'You cannot modify a line that does not exist.', Locked = true;
        CannotInsertPostedInvoiceErr: Label 'Invoices created through the API must be in Draft state.', Locked = true;
        CanOnlySetUOMForTypeItemErr: Label 'Unit of Measure can be set only for lines with type Item.', Locked = true;
        InvoiceIdIsNotSpecifiedErr: Label 'Invoice ID is not specified.', Locked = true;
        EntityIsNotFoundErr: Label 'Purchase Invoice Entity is not found.', Locked = true;
        AggregatorCategoryLbl: Label 'Purchase Invoice Aggregator', Locked = true;

    [EventSubscriber(ObjectType::Table, 38, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertPurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromPurchaseHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 38, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyPurchaseHeader(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if IsBackgroundPosting(Rec) then
            exit;

        InsertOrModifyFromPurchaseHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 38, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseHeader(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        TransferRecordIDs(Rec);

        if not PurchInvEntityAggregate.Get(Rec."No.", false) then
            exit;

        PurchInvEntityAggregate.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, 66, 'OnAfterResetRecalculateInvoiceDisc', '', false, false)]
    local procedure OnAfterResetRecalculateInvoiceDisc(var PurchaseHeader: Record "Purchase Header")
    begin
        if not CheckValidRecord(PurchaseHeader) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromPurchaseHeader(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Table, 39, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertPurchaseLine(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        ModifyTotalsPurchaseLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 39, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyPurchaseLine(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        ModifyTotalsPurchaseLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 39, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseLine(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", Rec."Document No.");
        PurchaseLine.SetRange("Document Type", Rec."Document Type");
        PurchaseLine.SetRange("Recalculate Invoice Disc.", true);

        if PurchaseLine.FindFirst then begin
            ModifyTotalsPurchaseLine(PurchaseLine);
            exit;
        end;

        PurchaseLine.SetRange("Recalculate Invoice Disc.");

        if not PurchaseLine.FindFirst then
            BlankTotals(Rec."Document No.", false);
    end;

    [EventSubscriber(ObjectType::Table, 122, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertPurchaseInvoiceHeader(var Rec: Record "Purch. Inv. Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromPurchaseInvoiceHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 122, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyPurchaseInvoiceHeader(var Rec: Record "Purch. Inv. Header"; var xRec: Record "Purch. Inv. Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromPurchaseInvoiceHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 122, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenamePurchaseInvoiceHeader(var Rec: Record "Purch. Inv. Header"; var xRec: Record "Purch. Inv. Header"; RunTrigger: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if not PurchInvEntityAggregate.Get(xRec."No.", true) then
            exit;

        PurchInvEntityAggregate.SetIsRenameAllowed(true);
        PurchInvEntityAggregate.Rename(Rec."No.", true);
    end;

    [EventSubscriber(ObjectType::Table, 122, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseInvoiceHeader(var Rec: Record "Purch. Inv. Header"; RunTrigger: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if not PurchInvEntityAggregate.Get(Rec."No.", true) then
            exit;

        PurchInvEntityAggregate.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, 70, 'OnAfterCalcPurchaseDiscount', '', false, false)]
    local procedure OnAfterCalculatePurchaseDiscountOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        if not CheckValidRecord(PurchaseHeader) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromPurchaseHeader(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Table, 25, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromVendLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 25, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; var xRec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromVendLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 25, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; var xRec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromVendLedgerEntry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 25, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SetStatusOptionFromVendLedgerEntry(Rec);
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

    [EventSubscriber(ObjectType::Codeunit, 90, 'OnBeforePurchInvHeaderInsert', '', false, false)]
    local procedure OnBeforePurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        IsRenameAllowed: Boolean;
    begin
        if PurchInvHeader.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if IsNullGuid(PurchHeader.SystemId) then begin
            SendTraceTag('00006TQ', AggregatorCategoryLbl, VERBOSITY::Error, InvoiceIdIsNotSpecifiedErr,
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        if PurchInvHeader."Pre-Assigned No." <> PurchHeader."No." then
            exit;

        if not PurchInvEntityAggregate.Get(PurchHeader."No.", false) then begin
            SendTraceTag('00006TR', AggregatorCategoryLbl, VERBOSITY::Error, EntityIsNotFoundErr,
              DATACLASSIFICATION::SystemMetadata);
            exit;
        end;

        if PurchInvEntityAggregate.Id <> PurchHeader.SystemId then
            exit;

        IsRenameAllowed := PurchInvEntityAggregate.GetIsRenameAllowed;
        PurchInvEntityAggregate.SetIsRenameAllowed(true);
        PurchInvEntityAggregate.Rename(PurchInvHeader."No.", true);
        PurchInvEntityAggregate.SetIsRenameAllowed(IsRenameAllowed);
        PurchInvHeader."Draft Invoice SystemId" := PurchHeader.SystemId;
    end;

    procedure PropagateOnInsert(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TargetRecordRef: RecordRef;
        DocTypeFieldRef: FieldRef;
        NoFieldRef: FieldRef;
    begin
        if PurchInvEntityAggregate.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if PurchInvEntityAggregate.Posted then
            Error(CannotInsertPostedInvoiceErr);

        TargetRecordRef.Open(DATABASE::"Purchase Header");

        DocTypeFieldRef := TargetRecordRef.Field(PurchaseHeader.FieldNo("Document Type"));
        DocTypeFieldRef.Value(PurchaseHeader."Document Type"::Invoice);

        NoFieldRef := TargetRecordRef.Field(PurchaseHeader.FieldNo("No."));

        TransferFieldsWithValidate(TempFieldBuffer, PurchInvEntityAggregate, TargetRecordRef);

        TargetRecordRef.Insert(true);

        // Save ship-to address because OnInsert trigger inserted company address instead
        TempFieldBuffer.SetRange("Table ID", DATABASE::"Purch. Inv. Entity Aggregate");
        TempFieldBuffer.SetFilter("Field ID", '%1|%2|%3|%4|%5|%6',
          PurchInvEntityAggregate.FieldNo("Ship-to Address"),
          PurchInvEntityAggregate.FieldNo("Ship-to Address 2"),
          PurchInvEntityAggregate.FieldNo("Ship-to City"),
          PurchInvEntityAggregate.FieldNo("Ship-to Country/Region Code"),
          PurchInvEntityAggregate.FieldNo("Ship-to County"),
          PurchInvEntityAggregate.FieldNo("Ship-to Post Code"));
        if TempFieldBuffer.FindSet then begin
            TransferFieldsWithValidate(TempFieldBuffer, PurchInvEntityAggregate, TargetRecordRef);
            TargetRecordRef.Modify(true);
        end;

        PurchInvEntityAggregate."No." := NoFieldRef.Value;
        PurchInvEntityAggregate.Get(PurchInvEntityAggregate."No.", PurchInvEntityAggregate.Posted);
    end;

    procedure PropagateOnModify(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        TargetRecordRef: RecordRef;
        Exists: Boolean;
    begin
        if PurchInvEntityAggregate.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if PurchInvEntityAggregate.Posted then
            Error(CannotModifyPostedInvioceErr);

        Exists := PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchInvEntityAggregate."No.");
        if Exists then
            TargetRecordRef.GetTable(PurchaseHeader)
        else
            TargetRecordRef.Open(DATABASE::"Purchase Header");

        TransferFieldsWithValidate(TempFieldBuffer, PurchInvEntityAggregate, TargetRecordRef);

        if Exists then
            TargetRecordRef.Modify(true)
        else
            TargetRecordRef.Insert(true);
    end;

    procedure PropagateOnDelete(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchInvEntityAggregate.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if PurchInvEntityAggregate.Posted then begin
            PurchInvHeader.Get(PurchInvEntityAggregate."No.");
            if PurchInvHeader."No. Printed" = 0 then
                PurchInvHeader."No. Printed" := 1;
            PurchInvHeader.Delete(true);
        end else begin
            PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchInvEntityAggregate."No.");
            PurchaseHeader.Delete(true);
        end;
    end;

    procedure UpdateAggregateTableRecords()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        if PurchaseHeader.FindSet then
            repeat
                InsertOrModifyFromPurchaseHeader(PurchaseHeader);
            until PurchaseHeader.Next = 0;

        if PurchInvHeader.FindSet then
            repeat
                InsertOrModifyFromPurchaseInvoiceHeader(PurchInvHeader);
            until PurchInvHeader.Next = 0;

        PurchInvEntityAggregate.SetRange(Posted, false);
        if PurchInvEntityAggregate.FindSet(true, false) then
            repeat
                if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchInvEntityAggregate."No.") then
                    PurchInvEntityAggregate.Delete(true);
            until PurchInvEntityAggregate.Next = 0;

        PurchInvEntityAggregate.SetRange(Posted, true);
        if PurchInvEntityAggregate.FindSet(true, false) then
            repeat
                if not PurchInvHeader.Get(PurchInvEntityAggregate."No.") then
                    PurchInvEntityAggregate.Delete(true);
            until PurchInvEntityAggregate.Next = 0;
    end;

    local procedure InsertOrModifyFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        RecordExists: Boolean;
    begin
        PurchInvEntityAggregate.LockTable();
        RecordExists := PurchInvEntityAggregate.Get(PurchaseHeader."No.", false);

        PurchInvEntityAggregate.TransferFields(PurchaseHeader, true);
        PurchInvEntityAggregate.Id := PurchaseHeader.SystemId;
        PurchInvEntityAggregate.Posted := false;
        PurchInvEntityAggregate.Status := PurchInvEntityAggregate.Status::Draft;
        AssignTotalsFromPurchaseHeader(PurchaseHeader, PurchInvEntityAggregate);
        PurchInvEntityAggregate.UpdateReferencedRecordIds;

        if RecordExists then
            PurchInvEntityAggregate.Modify(true)
        else
            PurchInvEntityAggregate.Insert(true);
    end;

    procedure GetPurchaseInvoiceHeaderId(var PurchInvHeader: Record "Purch. Inv. Header"): Guid
    begin
        if (not IsNullGuid(PurchInvHeader."Draft Invoice SystemId")) then
            exit(PurchInvHeader."Draft Invoice SystemId");

        exit(PurchInvHeader.SystemId);
    end;

    procedure GetPurchaseInvoiceHeaderFromId(Id: Text; var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    begin
        PurchInvHeader.SetFilter("Draft Invoice SystemId", Id);
        IF PurchInvHeader.FINDFIRST() THEN
            exit(true);

        PurchInvHeader.SetRange("Draft Invoice SystemId");
        PurchInvHeader.SetFilter(Id, Id);

        IF PurchInvHeader.FindFirst() then
            exit(true);

        exit(false);
    end;

    local procedure InsertOrModifyFromPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        RecordExists: Boolean;
    begin
        PurchInvEntityAggregate.LockTable();
        RecordExists := PurchInvEntityAggregate.Get(PurchInvHeader."No.", true);
        PurchInvEntityAggregate.TransferFields(PurchInvHeader, true);
        PurchInvEntityAggregate.Id := GetPurchaseInvoiceHeaderId(PurchInvHeader);

        PurchInvEntityAggregate.Posted := true;
        SetStatusOptionFromPurchaseInvoiceHeader(PurchInvHeader, PurchInvEntityAggregate);
        AssignTotalsFromPurchaseInvoiceHeader(PurchInvHeader, PurchInvEntityAggregate);
        PurchInvEntityAggregate.UpdateReferencedRecordIds;

        if RecordExists then
            PurchInvEntityAggregate.Modify(true)
        else
            PurchInvEntityAggregate.Insert(true);
    end;

    local procedure SetStatusOptionFromPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    begin
        PurchInvHeader.CalcFields(Cancelled, Closed, Corrective);
        if PurchInvHeader.Cancelled then begin
            PurchInvEntityAggregate.Status := PurchInvEntityAggregate.Status::Canceled;
            exit;
        end;

        if PurchInvHeader.Corrective then begin
            PurchInvEntityAggregate.Status := PurchInvEntityAggregate.Status::Corrective;
            exit;
        end;

        if PurchInvHeader.Closed then begin
            PurchInvEntityAggregate.Status := PurchInvEntityAggregate.Status::Paid;
            exit;
        end;

        PurchInvEntityAggregate.Status := PurchInvEntityAggregate.Status::Open;
    end;

    local procedure SetStatusOptionFromVendLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if not GraphMgtGeneralTools.IsApiEnabled then
            exit;

        PurchInvEntityAggregate.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        PurchInvEntityAggregate.SetRange(Posted, true);

        if not PurchInvEntityAggregate.FindSet(true) then
            exit;

        repeat
            UpdateStatusIfChanged(PurchInvEntityAggregate);
        until PurchInvEntityAggregate.Next = 0;
    end;

    local procedure SetStatusOptionFromCancelledDocument(var CancelledDocument: Record "Cancelled Document")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if not GraphMgtGeneralTools.IsApiEnabled then
            exit;

        case CancelledDocument."Source ID" of
            DATABASE::"Purch. Inv. Header":
                if not PurchInvEntityAggregate.Get(CancelledDocument."Cancelled Doc. No.", true) then
                    exit;
            DATABASE::"Purch. Cr. Memo Hdr.":
                if not PurchInvEntityAggregate.Get(CancelledDocument."Cancelled By Doc. No.", true) then
                    exit;
            else
                exit;
        end;

        UpdateStatusIfChanged(PurchInvEntityAggregate);
    end;

    procedure UpdateUnitOfMeasure(var Item: Record Item; JSONUnitOfMeasureTxt: Text)
    var
        TempFieldSet: Record "Field" temporary;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        ItemModified: Boolean;
    begin
        GraphCollectionMgtItem.UpdateOrCreateItemUnitOfMeasureFromSalesDocument(JSONUnitOfMeasureTxt, Item, TempFieldSet, ItemModified);

        if ItemModified then
            Item.Modify(true);
    end;

    local procedure UpdateStatusIfChanged(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        CurrentStatus: Option;
    begin
        PurchInvHeader.Get(PurchInvEntityAggregate."No.");
        CurrentStatus := PurchInvEntityAggregate.Status;

        SetStatusOptionFromPurchaseInvoiceHeader(PurchInvHeader, PurchInvEntityAggregate);
        if CurrentStatus <> PurchInvEntityAggregate.Status then
            PurchInvEntityAggregate.Modify(true);
    end;

    local procedure AssignTotalsFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");

        if not PurchaseLine.FindFirst then begin
            BlankTotals(PurchaseLine."Document No.", false);
            exit;
        end;

        AssignTotalsFromPurchaseLine(PurchaseLine, PurchInvEntityAggregate, PurchaseHeader);
    end;

    local procedure AssignTotalsFromPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");

        if not PurchInvLine.FindFirst then begin
            BlankTotals(PurchInvLine."Document No.", true);
            exit;
        end;

        AssignTotalsFromPurchaseInvoiceLine(PurchInvLine, PurchInvEntityAggregate);
    end;

    local procedure AssignTotalsFromPurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate"; var PurchaseHeader: Record "Purchase Header")
    var
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if PurchaseLine."VAT Calculation Type" = PurchaseLine."VAT Calculation Type"::"Sales Tax" then begin
            PurchInvEntityAggregate."Discount Applied Before Tax" := true;
            PurchInvEntityAggregate."Prices Including VAT" := false;
        end else
            PurchInvEntityAggregate."Discount Applied Before Tax" := not PurchaseHeader."Prices Including VAT";

        DocumentTotals.CalculatePurchaseTotals(TotalPurchaseLine, VATAmount, PurchaseLine);

        PurchInvEntityAggregate."Invoice Discount Amount" := TotalPurchaseLine."Inv. Discount Amount";
        PurchInvEntityAggregate.Amount := TotalPurchaseLine.Amount;
        PurchInvEntityAggregate."Total Tax Amount" := VATAmount;
        PurchInvEntityAggregate."Amount Including VAT" := TotalPurchaseLine."Amount Including VAT";
    end;

    local procedure AssignTotalsFromPurchaseInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        TotalPurchInvHeader: Record "Purch. Inv. Header";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if PurchInvLine."VAT Calculation Type" = PurchInvLine."VAT Calculation Type"::"Sales Tax" then
            PurchInvEntityAggregate."Discount Applied Before Tax" := true
        else begin
            PurchInvHeader.Get(PurchInvLine."Document No.");
            PurchInvEntityAggregate."Discount Applied Before Tax" := not PurchInvHeader."Prices Including VAT";
        end;

        DocumentTotals.CalculatePostedPurchInvoiceTotals(TotalPurchInvHeader, VATAmount, PurchInvLine);

        PurchInvEntityAggregate."Invoice Discount Amount" := TotalPurchInvHeader."Invoice Discount Amount";
        PurchInvEntityAggregate.Amount := TotalPurchInvHeader.Amount;
        PurchInvEntityAggregate."Total Tax Amount" := VATAmount;
        PurchInvEntityAggregate."Amount Including VAT" := TotalPurchInvHeader."Amount Including VAT";
    end;

    local procedure BlankTotals(DocumentNo: Code[20]; Posted: Boolean)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if not PurchInvEntityAggregate.Get(DocumentNo, Posted) then
            exit;

        PurchInvEntityAggregate."Invoice Discount Amount" := 0;
        PurchInvEntityAggregate."Total Tax Amount" := 0;

        PurchInvEntityAggregate.Amount := 0;
        PurchInvEntityAggregate."Amount Including VAT" := 0;
        PurchInvEntityAggregate.Modify();
    end;

    local procedure CheckValidRecord(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if PurchaseHeader.IsTemporary then
            exit(false);

        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice then
            exit(false);

        exit(true);
    end;

    local procedure ModifyTotalsPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchaseLine.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Invoice then
            exit;

        if not PurchInvEntityAggregate.Get(PurchaseLine."Document No.", false) then
            exit;

        if not PurchaseLine."Recalculate Invoice Disc." then
            exit;

        if not PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
            exit;

        AssignTotalsFromPurchaseLine(PurchaseLine, PurchInvEntityAggregate, PurchaseHeader);
        PurchInvEntityAggregate.Modify(true);
    end;

    local procedure TransferPurchaseInvoiceLineAggregateToPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchaseLine: Record "Purchase Line"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchaseLineRecordRef: RecordRef;
    begin
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Invoice;
        PurchaseLineRecordRef.GetTable(PurchaseLine);

        TransferFieldsWithValidate(TempFieldBuffer, PurchInvLineAggregate, PurchaseLineRecordRef);

        PurchaseLineRecordRef.SetTable(PurchaseLine);
    end;

    local procedure TransferRecordIDs(var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchInvHeader: Record "Purch. Inv. Header";
        IsRenameAllowed: Boolean;
    begin
        if IsNullGuid(PurchaseHeader.SystemId) then
            exit;

        PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseHeader."No.");
        if not PurchInvHeader.FindFirst then
            exit;

        if PurchInvHeader."Draft Invoice SystemId" = PurchaseHeader.SystemId then
            exit;

        if PurchInvEntityAggregate.Get(PurchInvHeader."No.", true) then
            PurchInvEntityAggregate.Delete(true);

        if PurchInvEntityAggregate.Get(PurchaseHeader."No.", false) then begin
            IsRenameAllowed := PurchInvEntityAggregate.GetIsRenameAllowed;
            PurchInvEntityAggregate.SetIsRenameAllowed(true);
            PurchInvEntityAggregate.Rename(PurchInvHeader."No.", true);
            PurchInvEntityAggregate.SetIsRenameAllowed(IsRenameAllowed);
        end;

        PurchInvHeader."Draft Invoice SystemId" := PurchaseHeader.SystemId;
        PurchInvHeader.Modify(true);
    end;

    local procedure TransferFieldsWithValidate(var TempFieldBuffer: Record "Field Buffer" temporary; RecordVariant: Variant; var TargetTableRecRef: RecordRef)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecRef: RecordRef;
        TargetFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, SourceRecRef);

        TempFieldBuffer.Reset();
        if not TempFieldBuffer.FindFirst then
            exit;

        repeat
            if TargetTableRecRef.FieldExist(TempFieldBuffer."Field ID") then begin
                SourceFieldRef := SourceRecRef.Field(TempFieldBuffer."Field ID");
                TargetFieldRef := TargetTableRecRef.Field(TempFieldBuffer."Field ID");
                if TargetFieldRef.Class = FieldClass::Normal then
                    if TargetFieldRef.Value <> SourceFieldRef.Value then
                        TargetFieldRef.Validate(SourceFieldRef.Value);
            end;
        until TempFieldBuffer.Next = 0;
    end;

    procedure RedistributeInvoiceDiscounts(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if PurchInvEntityAggregate.Posted then
            exit;

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchInvEntityAggregate."No.");
        PurchaseLine.SetRange("Recalculate Invoice Disc.", true);
        if PurchaseLine.FindFirst then
            CODEUNIT.Run(CODEUNIT::"Purch - Calc Disc. By Type", PurchaseLine);

        PurchInvEntityAggregate.Get(PurchInvEntityAggregate."No.", PurchInvEntityAggregate.Posted);
    end;

    procedure LoadLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; DocumentIdFilter: Text)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        if DocumentIdFilter = '' then
            Error(DocumentIDNotSpecifiedErr);

        PurchInvEntityAggregate.SetFilter(Id, DocumentIdFilter);
        if not PurchInvEntityAggregate.FindFirst then
            exit;

        if PurchInvEntityAggregate.Posted then
            LoadPurchaseInvoiceLines(PurchInvLineAggregate, PurchInvEntityAggregate)
        else
            LoadPurchaseLines(PurchInvLineAggregate, PurchInvEntityAggregate);
    end;

    local procedure LoadPurchaseInvoiceLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvEntityAggregate."No.");

        if PurchInvLine.FindSet(false, false) then
            repeat
                Clear(PurchInvLineAggregate);
                PurchInvLineAggregate.TransferFields(PurchInvLine, true);
                PurchInvLineAggregate.Id :=
                  SalesInvoiceAggregator.GetIdFromDocumentIdAndSequence(PurchInvEntityAggregate.Id, PurchInvLine."Line No.");
                PurchInvLineAggregate."Document Id" := PurchInvEntityAggregate.Id;
                if PurchInvLine."VAT Calculation Type" = PurchInvLine."VAT Calculation Type"::"Sales Tax" then
                    PurchInvLineAggregate."Tax Code" := PurchInvLine."Tax Group Code"
                else
                    PurchInvLineAggregate."Tax Code" := PurchInvLine."VAT Identifier";

                PurchInvLineAggregate."VAT %" := PurchInvLine."VAT %";
                PurchInvLineAggregate."Tax Amount" := PurchInvLine."Amount Including VAT" - PurchInvLine."VAT Base Amount";
                PurchInvLineAggregate."Currency Code" := PurchInvLine.GetCurrencyCode;
                PurchInvLineAggregate."Prices Including Tax" := PurchInvEntityAggregate."Prices Including VAT";
                PurchInvLineAggregate.UpdateReferencedRecordIds;
                UpdateLineAmountsFromPurchaseInvoiceLine(PurchInvLineAggregate);
                PurchInvLineAggregate.Insert(true);
            until PurchInvLine.Next = 0;
    end;

    local procedure LoadPurchaseLines(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchInvEntityAggregate."No.");

        if PurchaseLine.FindSet(false, false) then
            repeat
                TransferFromPurchaseLine(PurchInvLineAggregate, PurchInvEntityAggregate, PurchaseLine);
                PurchInvLineAggregate.Insert(true);
            until PurchaseLine.Next = 0;
    end;

    local procedure TransferFromPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate"; var PurchaseLine: Record "Purchase Line")
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        Clear(PurchInvLineAggregate);
        PurchInvLineAggregate.TransferFields(PurchaseLine, true);
        PurchInvLineAggregate."Document Id" := PurchInvEntityAggregate.Id;
        PurchInvLineAggregate.Id :=
          SalesInvoiceAggregator.GetIdFromDocumentIdAndSequence(PurchInvEntityAggregate.Id, PurchaseLine."Line No.");
        if PurchaseLine."VAT Calculation Type" = PurchaseLine."VAT Calculation Type"::"Sales Tax" then
            PurchInvLineAggregate."Tax Code" := PurchaseLine."Tax Group Code"
        else
            PurchInvLineAggregate."Tax Code" := PurchaseLine."VAT Identifier";

        PurchInvLineAggregate."VAT %" := PurchaseLine."VAT %";
        PurchInvLineAggregate."Tax Amount" := PurchaseLine."Amount Including VAT" - PurchaseLine."VAT Base Amount";
        PurchInvLineAggregate."Prices Including Tax" := PurchInvEntityAggregate."Prices Including VAT";
        PurchInvLineAggregate.UpdateReferencedRecordIds;
        UpdateLineAmountsFromPurchaseLine(PurchInvLineAggregate);
    end;

    procedure PropagateInsertLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseLine: Record "Purchase Line";
        LastUsedPurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchInvEntityAggregate);

        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Invoice;
        PurchaseLine."Document No." := PurchInvEntityAggregate."No.";

        if PurchInvLineAggregate."Line No." = 0 then begin
            LastUsedPurchaseLine.SetRange("Document No.", PurchInvEntityAggregate."No.");
            LastUsedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
            if LastUsedPurchaseLine.FindLast then
                PurchInvLineAggregate."Line No." := LastUsedPurchaseLine."Line No." + 10000
            else
                PurchInvLineAggregate."Line No." := 10000;

            PurchaseLine."Line No." := PurchInvLineAggregate."Line No.";
        end else
            if PurchaseLine.Get(PurchaseLine."Document Type"::Invoice, PurchInvEntityAggregate."No.", PurchInvLineAggregate."Line No.") then
                Error(CannotInsertALineThatAlreadyExistsErr);

        TransferPurchaseInvoiceLineAggregateToPurchaseLine(PurchInvLineAggregate, PurchaseLine, TempFieldBuffer);
        PurchaseLine.Insert(true);

        RedistributeInvoiceDiscounts(PurchInvEntityAggregate);

        PurchaseLine.Find;
        TransferFromPurchaseLine(PurchInvLineAggregate, PurchInvEntityAggregate, PurchaseLine);
    end;

    procedure PropagateModifyLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchInvEntityAggregate);

        if not PurchaseLine.Get(PurchaseLine."Document Type"::Invoice, PurchInvEntityAggregate."No.", PurchInvLineAggregate."Line No.") then
            Error(CannotModifyALineThatDoesntExistErr);

        TransferPurchaseInvoiceLineAggregateToPurchaseLine(PurchInvLineAggregate, PurchaseLine, TempFieldBuffer);

        PurchaseLine.Modify(true);

        RedistributeInvoiceDiscounts(PurchInvEntityAggregate);

        PurchaseLine.Find;
        TransferFromPurchaseLine(PurchInvLineAggregate, PurchInvEntityAggregate, PurchaseLine);
    end;

    procedure PropagateDeleteLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseLine: Record "Purchase Line";
    begin
        VerifyCRUDIsPossibleForLine(PurchInvLineAggregate, PurchInvEntityAggregate);

        if PurchaseLine.Get(PurchaseLine."Document Type"::Invoice, PurchInvEntityAggregate."No.", PurchInvLineAggregate."Line No.") then begin
            PurchaseLine.Delete(true);
            RedistributeInvoiceDiscounts(PurchInvEntityAggregate);
        end;
    end;

    local procedure VerifyCRUDIsPossibleForLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        SearchPurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        DocumentIDFilter: Text;
    begin
        if IsNullGuid(PurchInvLineAggregate."Document Id") then begin
            DocumentIDFilter := PurchInvLineAggregate.GetFilter("Document Id");
            if DocumentIDFilter = '' then
                Error(DocumentIDNotSpecifiedErr);
            PurchInvEntityAggregate.SetFilter(Id, DocumentIDFilter);
        end else
            PurchInvEntityAggregate.SetRange(Id, PurchInvLineAggregate."Document Id");

        if not PurchInvEntityAggregate.FindFirst then
            Error(DocumentDoesNotExistErr);

        SearchPurchInvEntityAggregate.Copy(PurchInvEntityAggregate);
        if SearchPurchInvEntityAggregate.Next <> 0 then
            Error(MultipleDocumentsFoundForIdErr);

        if PurchInvEntityAggregate.Posted then
            Error(CannotModifyPostedInvioceErr);
    end;

    local procedure UpdateLineAmountsFromPurchaseLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    begin
        PurchInvLineAggregate."Line Tax Amount" :=
          PurchInvLineAggregate."Line Amount Including Tax" - PurchInvLineAggregate."Line Amount Excluding Tax";
        UpdateInvoiceDiscountAmount(PurchInvLineAggregate);
    end;

    local procedure UpdateLineAmountsFromPurchaseInvoiceLine(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    begin
        PurchInvLineAggregate."Line Tax Amount" :=
          PurchInvLineAggregate."Line Amount Including Tax" - PurchInvLineAggregate."Line Amount Excluding Tax";
        UpdateInvoiceDiscountAmount(PurchInvLineAggregate);
    end;

    local procedure UpdateInvoiceDiscountAmount(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    begin
        if PurchInvLineAggregate."Prices Including Tax" then
            PurchInvLineAggregate."Inv. Discount Amount Excl. VAT" :=
              PurchInvLineAggregate."Line Amount Excluding Tax" - PurchInvLineAggregate.Amount
        else
            PurchInvLineAggregate."Inv. Discount Amount Excl. VAT" := PurchInvLineAggregate."Inv. Discount Amount";
    end;

    procedure VerifyCanUpdateUOM(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate")
    begin
        if PurchInvLineAggregate."API Type" <> PurchInvLineAggregate."API Type"::Item then
            Error(CanOnlySetUOMForTypeItemErr);
    end;

    local procedure CheckValidLineRecord(var PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if PurchaseLine.IsTemporary then
            exit(false);

        if not GraphMgtGeneralTools.IsApiEnabled then
            exit(false);

        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Invoice then
            exit(false);

        exit(true);
    end;

    local procedure IsBackgroundPosting(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if PurchaseHeader.IsTemporary then
            exit(false);

        exit(PurchaseHeader."Job Queue Status" in [PurchaseHeader."Job Queue Status"::"Scheduled for Posting", PurchaseHeader."Job Queue Status"::Posting]);
    end;
}

