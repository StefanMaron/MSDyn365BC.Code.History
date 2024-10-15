codeunit 5496 "Graph Mgt - Sales Order Buffer"
{

    trigger OnRun()
    begin
    end;

    var
        DocumentIDNotSpecifiedErr: Label 'You must specify a document id to get the lines.', Locked = true;
        DocumentDoesNotExistErr: Label 'No document with the specified ID exists.', Locked = true;
        MultipleDocumentsFoundForIdErr: Label 'Multiple documents have been found for the specified criteria.', Locked = true;
        CannotInsertALineThatAlreadyExistsErr: Label 'You cannot insert a line because a line already exists.', Locked = true;
        CannotModifyALineThatDoesntExistErr: Label 'You cannot modify a line that does not exist.', Locked = true;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";

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

        InsertOrModifyFromSalesHeader(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
    begin
        if not CheckValidRecord(Rec) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        if not SalesOrderEntityBuffer.Get(Rec."No.") then
            exit;
        SalesOrderEntityBuffer.Delete;
    end;

    [EventSubscriber(ObjectType::Codeunit, 56, 'OnAfterResetRecalculateInvoiceDisc', '', false, false)]
    local procedure OnAfterResetRecalculateInvoiceDisc(var SalesHeader: Record "Sales Header")
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
        ModifyTotalsSalesLine(Rec, true);
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySalesLine(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if not CheckValidLineRecord(Rec) then
            exit;

        UpdateCompletelyShipped(Rec);
        ModifyTotalsSalesLine(Rec, Rec."Recalculate Invoice Disc.");
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
            ModifyTotalsSalesLine(SalesLine, true);
            exit;
        end;

        SalesLine.SetRange("Recalculate Invoice Disc.");

        if not SalesLine.FindFirst then
            BlankTotals(Rec."Document No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, 60, 'OnAfterCalcSalesDiscount', '', false, false)]
    local procedure OnAfterCalculateSalesDiscountOnSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        if not CheckValidRecord(SalesHeader) or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        InsertOrModifyFromSalesHeader(SalesHeader);
    end;

    procedure PropagateOnInsert(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesHeader: Record "Sales Header";
        TypeHelper: Codeunit "Type Helper";
        TargetRecordRef: RecordRef;
        DocTypeFieldRef: FieldRef;
    begin
        if SalesOrderEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        TargetRecordRef.Open(DATABASE::"Sales Header");

        DocTypeFieldRef := TargetRecordRef.Field(SalesHeader.FieldNo("Document Type"));
        DocTypeFieldRef.Value(SalesHeader."Document Type"::Order);

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, SalesOrderEntityBuffer, TargetRecordRef);

        // SetTable does not transfer globals, which will affect the logic in OnInsert trigger. We have to insert here and modify latter.
        TargetRecordRef.Insert(true);

        SalesHeader.Get(TargetRecordRef.RecordId());
        SalesHeader.CopySellToAddressToBillToAddress;
        SalesHeader.SetDefaultPaymentServices;
        SalesHeader.Modify(true);

        SalesOrderEntityBuffer."No." := SalesHeader."No.";
        SalesOrderEntityBuffer.Get(SalesOrderEntityBuffer."No.");
    end;

    procedure PropagateOnModify(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesHeader: Record "Sales Header";
        TypeHelper: Codeunit "Type Helper";
        TargetRecordRef: RecordRef;
        Exists: Boolean;
    begin
        if SalesOrderEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        Exists := SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderEntityBuffer."No.");
        if Exists then
            TargetRecordRef.GetTable(SalesHeader)
        else
            TargetRecordRef.Open(DATABASE::"Sales Header");

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, SalesOrderEntityBuffer, TargetRecordRef);

        TargetRecordRef.SetTable(SalesHeader);
        SalesHeader.CopySellToAddressToBillToAddress;

        if Exists then
            SalesHeader.Modify(true)
        else begin
            SalesHeader.SetDefaultPaymentServices;
            SalesHeader.Insert(true);
        end;
    end;

    procedure PropagateOnDelete(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        SalesHeader: Record "Sales Header";
    begin
        if SalesOrderEntityBuffer.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit;

        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderEntityBuffer."No.");
        SalesHeader.Delete(true);
    end;

    procedure UpdateBufferTableRecords()
    var
        SalesHeader: Record "Sales Header";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        if SalesHeader.FindSet then
            repeat
                InsertOrModifyFromSalesHeader(SalesHeader);
            until SalesHeader.Next = 0;

        if SalesOrderEntityBuffer.FindSet(true, false) then
            repeat
                if not SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderEntityBuffer."No.") then
                    SalesOrderEntityBuffer.Delete(true);
            until SalesOrderEntityBuffer.Next = 0;
    end;

    local procedure InsertOrModifyFromSalesHeader(var SalesHeader: Record "Sales Header")
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        RecordExists: Boolean;
    begin
        SalesOrderEntityBuffer.LockTable;
        RecordExists := SalesOrderEntityBuffer.Get(SalesHeader."No.");

        SalesOrderEntityBuffer.TransferFields(SalesHeader, true);
        SetStatusOptionFromSalesHeader(SalesHeader, SalesOrderEntityBuffer);
        AssignTotalsFromSalesHeader(SalesHeader, SalesOrderEntityBuffer);
        SalesOrderEntityBuffer.UpdateReferencedRecordIds;

        if RecordExists then
            SalesOrderEntityBuffer.Modify(true)
        else
            SalesOrderEntityBuffer.Insert(true);
    end;

    local procedure SetStatusOptionFromSalesHeader(var SalesHeader: Record "Sales Header"; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    begin
        if SalesHeader.Status = SalesHeader.Status::"Pending Approval" then begin
            SalesOrderEntityBuffer.Status := SalesOrderEntityBuffer.Status::"In Review";
            exit;
        end;

        if (SalesHeader.Status = SalesHeader.Status::Released) or
           (SalesHeader.Status = SalesHeader.Status::"Pending Prepayment")
        then begin
            SalesOrderEntityBuffer.Status := SalesOrderEntityBuffer.Status::Open;
            exit;
        end;

        SalesOrderEntityBuffer.Status := SalesOrderEntityBuffer.Status::Draft;
    end;

    local procedure AssignTotalsFromSalesHeader(var SalesHeader: Record "Sales Header"; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");

        if not SalesLine.FindFirst then begin
            BlankTotals(SalesLine."Document No.");
            exit;
        end;

        AssignTotalsFromSalesLine(SalesLine, SalesOrderEntityBuffer, SalesHeader);
    end;

    local procedure AssignTotalsFromSalesLine(var SalesLine: Record "Sales Line"; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer"; var SalesHeader: Record "Sales Header")
    var
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Sales Tax" then begin
            SalesOrderEntityBuffer."Discount Applied Before Tax" := true;
            SalesOrderEntityBuffer."Prices Including VAT" := false;
        end else
            SalesOrderEntityBuffer."Discount Applied Before Tax" := not SalesHeader."Prices Including VAT";

        DocumentTotals.CalculateSalesTotals(TotalSalesLine, VATAmount, SalesLine);

        SalesOrderEntityBuffer."Invoice Discount Amount" := TotalSalesLine."Inv. Discount Amount";
        SalesOrderEntityBuffer.Amount := TotalSalesLine.Amount;
        SalesOrderEntityBuffer."Total Tax Amount" := VATAmount;
        SalesOrderEntityBuffer."Amount Including VAT" := TotalSalesLine."Amount Including VAT";
    end;

    local procedure BlankTotals(DocumentNo: Code[20])
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
    begin
        if not SalesOrderEntityBuffer.Get(DocumentNo) then
            exit;

        SalesOrderEntityBuffer."Invoice Discount Amount" := 0;
        SalesOrderEntityBuffer."Total Tax Amount" := 0;

        SalesOrderEntityBuffer.Amount := 0;
        SalesOrderEntityBuffer."Amount Including VAT" := 0;
        SalesOrderEntityBuffer.Modify;
    end;

    local procedure CheckValidRecord(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if SalesHeader.IsTemporary then
            exit(false);

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit(false);

        exit(true);
    end;

    local procedure CheckValidLineRecord(var SalesLine: Record "Sales Line"): Boolean
    begin
        if SalesLine.IsTemporary or (not GraphMgtGeneralTools.IsApiEnabled) then
            exit(false);

        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            exit(false);

        exit(true);
    end;

    local procedure ModifyTotalsSalesLine(var SalesLine: Record "Sales Line"; RecalculateInvoiceDiscount: Boolean)
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesHeader: Record "Sales Header";
    begin
        if not SalesOrderEntityBuffer.Get(SalesLine."Document No.") then
            exit;

        if not RecalculateInvoiceDiscount then
            exit;

        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit;

        AssignTotalsFromSalesLine(SalesLine, SalesOrderEntityBuffer, SalesHeader);
        SalesOrderEntityBuffer.Modify(true);
    end;

    local procedure TransferSalesInvoiceLineAggregateToSalesLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesLine: Record "Sales Line"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        TypeHelper: Codeunit "Type Helper";
        SalesLineRecordRef: RecordRef;
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLineRecordRef.GetTable(SalesLine);

        TypeHelper.TransferFieldsWithValidate(TempFieldBuffer, SalesInvoiceLineAggregate, SalesLineRecordRef);

        SalesLineRecordRef.SetTable(SalesLine);
    end;

    procedure RedistributeInvoiceDiscounts(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderEntityBuffer."No.");
        SalesLine.SetRange("Recalculate Invoice Disc.", true);
        if SalesLine.FindFirst then
            CODEUNIT.Run(CODEUNIT::"Sales - Calc Discount By Type", SalesLine);

        SalesOrderEntityBuffer.Get(SalesOrderEntityBuffer."No.");
    end;

    procedure LoadLines(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; DocumentIdFilter: Text)
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
    begin
        if DocumentIdFilter = '' then
            Error(DocumentIDNotSpecifiedErr);

        SalesOrderEntityBuffer.SetFilter(Id, DocumentIdFilter);
        if not SalesOrderEntityBuffer.FindFirst then
            exit;

        LoadSalesLines(SalesInvoiceLineAggregate, SalesOrderEntityBuffer);
    end;

    local procedure LoadSalesLines(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderEntityBuffer."No.");

        if SalesLine.FindSet(false, false) then
            repeat
                TransferFromSalesLine(SalesInvoiceLineAggregate, SalesOrderEntityBuffer, SalesLine);
                SalesInvoiceLineAggregate.Insert(true);
            until SalesLine.Next = 0;
    end;

    local procedure TransferFromSalesLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer"; var SalesLine: Record "Sales Line")
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        Clear(SalesInvoiceLineAggregate);
        SalesInvoiceLineAggregate.TransferFields(SalesLine, true);
        SalesInvoiceLineAggregate.Id :=
          SalesInvoiceAggregator.GetIdFromDocumentIdAndSequence(SalesOrderEntityBuffer.Id, SalesLine."Line No.");
        SalesInvoiceLineAggregate."Document Id" := SalesOrderEntityBuffer.Id;
        SalesInvoiceAggregator.SetTaxGroupIdAndCode(
          SalesInvoiceLineAggregate,
          SalesLine."Tax Group Code",
          SalesLine."VAT Prod. Posting Group",
          SalesLine."VAT Identifier");
        SalesInvoiceLineAggregate."VAT %" := SalesLine."VAT %";
        SalesInvoiceLineAggregate."Tax Amount" := SalesLine."Amount Including VAT" - SalesLine."VAT Base Amount";
        SalesInvoiceLineAggregate.UpdateReferencedRecordIds;
        UpdateLineAmountsFromSalesLine(SalesInvoiceLineAggregate, SalesLine);
    end;

    procedure PropagateInsertLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesLine: Record "Sales Line";
        LastUsedSalesLine: Record "Sales Line";
    begin
        VerifyCRUDIsPossibleForLine(SalesInvoiceLineAggregate, SalesOrderEntityBuffer);

        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := SalesOrderEntityBuffer."No.";

        if SalesInvoiceLineAggregate."Line No." = 0 then begin
            LastUsedSalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
            LastUsedSalesLine.SetRange("Document No.", SalesOrderEntityBuffer."No.");
            if LastUsedSalesLine.FindLast then
                SalesInvoiceLineAggregate."Line No." := LastUsedSalesLine."Line No." + 10000
            else
                SalesInvoiceLineAggregate."Line No." := 10000;

            SalesLine."Line No." := SalesInvoiceLineAggregate."Line No.";
        end else
            if SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderEntityBuffer."No.", SalesInvoiceLineAggregate."Line No.") then
                Error(CannotInsertALineThatAlreadyExistsErr);

        TransferSalesInvoiceLineAggregateToSalesLine(SalesInvoiceLineAggregate, SalesLine, TempFieldBuffer);
        SalesLine.Insert(true);

        RedistributeInvoiceDiscounts(SalesOrderEntityBuffer);

        SalesLine.Find;
        TransferFromSalesLine(SalesInvoiceLineAggregate, SalesOrderEntityBuffer, SalesLine);
    end;

    procedure PropagateModifyLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var TempFieldBuffer: Record "Field Buffer" temporary)
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesLine: Record "Sales Line";
    begin
        VerifyCRUDIsPossibleForLine(SalesInvoiceLineAggregate, SalesOrderEntityBuffer);

        if not SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderEntityBuffer."No.", SalesInvoiceLineAggregate."Line No.") then
            Error(CannotModifyALineThatDoesntExistErr);

        TransferSalesInvoiceLineAggregateToSalesLine(SalesInvoiceLineAggregate, SalesLine, TempFieldBuffer);

        SalesLine.Modify(true);

        RedistributeInvoiceDiscounts(SalesOrderEntityBuffer);

        SalesLine.Find;
        TransferFromSalesLine(SalesInvoiceLineAggregate, SalesOrderEntityBuffer, SalesLine);
    end;

    procedure PropagateDeleteLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate")
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        SalesLine: Record "Sales Line";
    begin
        VerifyCRUDIsPossibleForLine(SalesInvoiceLineAggregate, SalesOrderEntityBuffer);

        if SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderEntityBuffer."No.", SalesInvoiceLineAggregate."Line No.") then begin
            SalesLine.Delete(true);
            RedistributeInvoiceDiscounts(SalesOrderEntityBuffer);
        end;
    end;

    local procedure VerifyCRUDIsPossibleForLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        SearchSalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        DocumentIDFilter: Text;
    begin
        if IsNullGuid(SalesInvoiceLineAggregate."Document Id") then begin
            DocumentIDFilter := SalesInvoiceLineAggregate.GetFilter("Document Id");
            if DocumentIDFilter = '' then
                Error(DocumentIDNotSpecifiedErr);
            SalesOrderEntityBuffer.SetFilter(Id, DocumentIDFilter);
        end else
            SalesOrderEntityBuffer.SetRange(Id, SalesInvoiceLineAggregate."Document Id");

        if not SalesOrderEntityBuffer.FindFirst then
            Error(DocumentDoesNotExistErr);

        SearchSalesOrderEntityBuffer.Copy(SalesOrderEntityBuffer);
        if SearchSalesOrderEntityBuffer.Next <> 0 then
            Error(MultipleDocumentsFoundForIdErr);
    end;

    local procedure UpdateCompletelyShipped(var SalesLine: Record "Sales Line")
    var
        SearchSalesLine: Record "Sales Line";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        CompletelyShipped: Boolean;
    begin
        SearchSalesLine.Copy(SalesLine);
        SearchSalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SearchSalesLine.SetRange("Document No.", SalesLine."Document No.");
        SearchSalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SearchSalesLine.SetRange("Location Code", SalesLine."Location Code");
        SearchSalesLine.SetRange("Completely Shipped", false);

        CompletelyShipped := not SearchSalesLine.FindFirst;

        if not SalesOrderEntityBuffer.Get(SalesLine."Document No.") then
            exit;
        if SalesOrderEntityBuffer."Completely Shipped" <> CompletelyShipped then begin
            SalesOrderEntityBuffer."Completely Shipped" := CompletelyShipped;
            SalesOrderEntityBuffer.Modify(true);
        end;
    end;

    local procedure UpdateLineAmountsFromSalesLine(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"; var SalesLine: Record "Sales Line")
    begin
        SalesInvoiceLineAggregate."Line Amount Excluding Tax" := SalesLine.GetLineAmountExclVAT;
        SalesInvoiceLineAggregate."Line Amount Including Tax" := SalesLine.GetLineAmountInclVAT;
        SalesInvoiceLineAggregate."Line Tax Amount" :=
          SalesInvoiceLineAggregate."Line Amount Including Tax" - SalesInvoiceLineAggregate."Line Amount Excluding Tax";
        UpdateInvoiceDiscountAmount(SalesInvoiceLineAggregate);
    end;

    local procedure UpdateInvoiceDiscountAmount(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate")
    begin
        if SalesInvoiceLineAggregate."Prices Including Tax" then
            SalesInvoiceLineAggregate."Inv. Discount Amount Excl. VAT" :=
              SalesInvoiceLineAggregate."Line Amount Excluding Tax" - SalesInvoiceLineAggregate.Amount
        else
            SalesInvoiceLineAggregate."Inv. Discount Amount Excl. VAT" := SalesInvoiceLineAggregate."Inv. Discount Amount";
    end;
}

