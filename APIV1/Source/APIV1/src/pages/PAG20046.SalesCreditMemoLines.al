page 20046 "APIV1 - Sales Credit Mem Lines"
{
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = 5476;
    SourceTableTemporary = true;
    ODataKeyFields = Id;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;

                    trigger OnValidate()
                    begin
                        IF xRec.Id <> Id THEN
                            ERROR(CannotChangeIdNoErr);
                    end;
                }
                field(documentId; "Document Id")
                {
                    ApplicationArea = All;
                    Caption = 'documentId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF xRec."Document Id" <> "Document Id" THEN
                            ERROR(CannotChangeDocumentIdNoErr);
                    end;
                }
                field(sequence; "Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'sequence', Locked = true;

                    trigger OnValidate()
                    begin
                        IF (xRec."Line No." <> "Line No.") AND
                           (xRec."Line No." <> 0)
                        THEN
                            ERROR(CannotChangeLineNoErr);

                        RegisterFieldSet(FIELDNO("Line No."));
                    end;
                }
                field(itemId; "Item Id")
                {
                    ApplicationArea = All;
                    Caption = 'itemId', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Type));
                        RegisterFieldSet(FIELDNO("No."));
                        RegisterFieldSet(FIELDNO("Item Id"));

                        Item.SETRANGE(Id, "Item Id");

                        IF NOT Item.FINDFIRST() THEN BEGIN
                            InsertItem := TRUE;
                            CheckIntegrationIdInUse();

                            Item.Id := "Item Id";
                            RegisterItemFieldSet(Item.FIELDNO(Id));
                            EXIT;
                        END;

                        "No." := Item."No.";
                    end;
                }
                field(accountId; "Account Id")
                {
                    ApplicationArea = All;
                    Caption = 'accountId', Locked = true;

                    trigger OnValidate()
                    var
                        EmptyGuid: Guid;
                    begin
                        IF "Account Id" <> EmptyGuid THEN
                            IF Item."No." <> '' THEN
                                ERROR(BothItemIdAndAccountIdAreSpecifiedErr);
                        RegisterFieldSet(FIELDNO(Type));
                        RegisterFieldSet(FIELDNO("Account Id"));
                        RegisterFieldSet(FIELDNO("No."));
                    end;
                }
                field(lineType; "API Type")
                {
                    ApplicationArea = All;
                    Caption = 'lineType', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Type));
                    end;
                }
                field(lineDetails; LineObjectDetailsJSON)
                {
                    ApplicationArea = All;
                    Caption = 'lineDetails', Locked = true;
                    ODataEDMType = 'DOCUMENTLINEOBJECTDETAILS';
                    ToolTip = 'Specifies details about the line.';

                    trigger OnValidate()
                    var
                        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
                    begin
                        IF NOT InsertItem THEN
                            EXIT;

                        GraphMgtComplexTypes.ParseDocumentLineObjectDetailsFromJSON(
                          LineObjectDetailsJSON, Item."No.", Item.Description, Item."Description 2");

                        IF Item."No." <> '' THEN
                            RegisterItemFieldSet(Item.FIELDNO("No."));

                        RegisterFieldSet(FIELDNO("No."));

                        IF Item.Description <> '' THEN
                            RegisterItemFieldSet(Item.FIELDNO(Description));

                        IF Description = '' THEN BEGIN
                            Description := Item.Description;
                            RegisterFieldSet(FIELDNO(Description));
                        END;

                        IF Item."Description 2" <> '' THEN BEGIN
                            "Description 2" := Item."Description 2";
                            RegisterItemFieldSet(Item.FIELDNO("Description 2"));
                            RegisterFieldSet(FIELDNO("Description 2"));
                        END;
                    end;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'description';
                    ToolTip = 'Specifies the description of the sales credit memo line.';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Description));
                    end;
                }
                field(unitOfMeasureId; UnitOfMeasureId)
                {
                    ApplicationArea = All;
                    Caption = 'UnitOfMeasureId', Locked = true;
                    ToolTip = 'Specifies Unit of Measure.';

                    trigger OnValidate()
                    var
                        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
                        GraphMgtSalesInvLines: Codeunit "Graph Mgt - Sales Inv. Lines";
                        BlankGUID: Guid;
                    begin
                        SalesInvoiceAggregator.VerifyCanUpdateUOM(Rec);

                        IF (UnitOfMeasureJSON = 'null') AND ("Unit of Measure Id" <> BlankGUID) THEN
                            EXIT;

                        IF "Unit of Measure Id" = BlankGUID THEN
                            "Unit of Measure Code" := ''
                        ELSE BEGIN
                            UnitOfMeasure.SETRANGE(Id, "Unit of Measure Id");
                            IF NOT UnitOfMeasure.FINDFIRST() THEN
                                ERROR(UnitOfMeasureIdDoesNotMatchAUnitOfMeasureErr);

                            "Unit of Measure Code" := UnitOfMeasure.Code;
                        END;

                        RegisterFieldSet(FIELDNO("Unit of Measure Code"));

                        IF InsertItem THEN
                            EXIT;

                        Item.SETRANGE(Id, "Item Id");
                        IF Item.FINDFIRST() THEN
                            SalesInvoiceAggregator.UpdateUnitOfMeasure(Item, GraphMgtSalesInvLines.GetUnitOfMeasureJSON(Rec));
                    end;
                }
                field(unitOfMeasure; UnitOfMeasureJSON)
                {
                    ApplicationArea = All;
                    Caption = 'unitOfMeasure', Locked = true;
                    ODataEDMType = 'ITEM-UOM';
                    ToolTip = 'Specifies Unit of Measure.';

                    trigger OnValidate()
                    var
                        TempUnitOfMeasure: Record "Unit of Measure" temporary;
                        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
                        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
                        GraphMgtSalesInvLines: Codeunit "Graph Mgt - Sales Inv. Lines";
                    begin
                        VALIDATE("Unit of Measure Id", UnitOfMeasureId);
                        SalesInvoiceAggregator.VerifyCanUpdateUOM(Rec);

                        IF UnitOfMeasureJSON = 'null' THEN
                            TempUnitOfMeasure.Code := ''
                        ELSE
                            GraphCollectionMgtItem.ParseJSONToUnitOfMeasure(UnitOfMeasureJSON, TempUnitOfMeasure);

                        IF (UnitOfMeasureJSON = 'null') AND (UnitOfMeasure.Code <> '') THEN
                            EXIT;
                        IF (UnitOfMeasure.Code <> '') AND (UnitOfMeasure.Code <> TempUnitOfMeasure.Code) THEN
                            ERROR(UnitOfMeasureValuesDontMatchErr);

                        "Unit of Measure Code" := TempUnitOfMeasure.Code;
                        RegisterFieldSet(FIELDNO("Unit of Measure Code"));

                        IF InsertItem THEN
                            EXIT;

                        Item.SETRANGE(Id, "Item Id");
                        IF Item.FINDFIRST() THEN
                            IF UnitOfMeasureJSON = 'null' THEN
                                SalesInvoiceAggregator.UpdateUnitOfMeasure(Item, GraphMgtSalesInvLines.GetUnitOfMeasureJSON(Rec))
                            ELSE
                                SalesInvoiceAggregator.UpdateUnitOfMeasure(Item, UnitOfMeasureJSON);
                    end;
                }
                field(unitPrice; "Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'unitPrice', Locked = true;

                    trigger OnValidate()
                    begin
                        IF InsertItem THEN BEGIN
                            Item."Unit Price" := "Unit Price";
                            RegisterItemFieldSet(Item.FIELDNO("Unit Price"));
                        END;

                        RegisterFieldSet(FIELDNO("Unit Price"));
                    end;
                }
                field(quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'quantity', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Quantity));
                    end;
                }
                field(discountAmount; "Line Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'discountAmount', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Line Discount Amount"));
                    end;
                }
                field(discountPercent; "Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'discountPercent', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Line Discount %"));
                    end;
                }
                field(discountAppliedBeforeTax; "Discount Applied Before Tax")
                {
                    ApplicationArea = All;
                    Caption = 'discountAppliedBeforeTax', Locked = true;
                    Editable = false;
                }
                field(amountExcludingTax; "Line Amount Excluding Tax")
                {
                    ApplicationArea = All;
                    Caption = 'amountExcludingTax', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Amount));
                    end;
                }
                field(taxCode; "Tax Code")
                {
                    ApplicationArea = All;
                    Caption = 'taxCode', Locked = true;

                    trigger OnValidate()
                    var
                        GeneralLedgerSetup: Record "General Ledger Setup";
                    begin
                        IF InsertItem THEN BEGIN
                            IF GeneralLedgerSetup.UseVat() THEN
                                EXIT;

                            Item."Tax Group Code" := COPYSTR("Tax Code", 1, MAXSTRLEN(Item."Tax Group Code"));
                            RegisterItemFieldSet(Item.FIELDNO("Tax Group Code"));
                        END;

                        IF GeneralLedgerSetup.UseVat() THEN BEGIN
                            VALIDATE("VAT Prod. Posting Group", COPYSTR("Tax Code", 1, 20));
                            RegisterFieldSet(FIELDNO("VAT Prod. Posting Group"));
                        END ELSE BEGIN
                            VALIDATE("Tax Group Code", COPYSTR("Tax Code", 1, 20));
                            RegisterFieldSet(FIELDNO("Tax Group Code"));
                        END;
                    end;
                }
                field(taxPercent; "VAT %")
                {
                    ApplicationArea = All;
                    Caption = 'taxPercent', Locked = true;
                    Editable = false;
                }
                field(totalTaxAmount; "Line Tax Amount")
                {
                    ApplicationArea = All;
                    Caption = 'totalTaxAmount', Locked = true;
                    Editable = false;
                }
                field(amountIncludingTax; "Line Amount Including Tax")
                {
                    ApplicationArea = All;
                    Caption = 'amountIncludingTax', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Amount Including VAT"));
                    end;
                }
                field(invoiceDiscountAllocation; "Inv. Discount Amount Excl. VAT")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDiscountAllocation', Locked = true;
                    Editable = false;
                }
                field(netAmount; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'netAmount', Locked = true;
                    Editable = false;
                }
                field(netTaxAmount; "Tax Amount")
                {
                    ApplicationArea = All;
                    Caption = 'netTaxAmount', Locked = true;
                    Editable = false;
                }
                field(netAmountIncludingTax; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'netAmountIncludingTax', Locked = true;
                    Editable = false;
                }
                field(shipmentDate; "Shipment Date")
                {
                    ApplicationArea = All;
                    Caption = 'shipmentDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Shipment Date"));
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        GraphMgtSalCrMemoBuf.PropagateDeleteLine(Rec);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        GraphMgtSalesInvLines: Codeunit "Graph Mgt - Sales Inv. Lines";
        DocumentIdFilter: Text;
        IdFilter: Text;
        FilterView: Text;
    begin
        IF NOT LinesLoaded THEN BEGIN
            FilterView := GETVIEW();
            IdFilter := GETFILTER(Id);
            DocumentIdFilter := GETFILTER("Document Id");
            IF (IdFilter = '') AND (DocumentIdFilter = '') THEN
                ERROR(IDOrDocumentIdShouldBeSpecifiedForLinesErr);
            IF IdFilter <> '' THEN
                DocumentIdFilter := GraphMgtSalesInvLines.GetDocumentIdFilterFromIdFilter(IdFilter)
            ELSE
                DocumentIdFilter := GETFILTER("Document Id");
            GraphMgtSalCrMemoBuf.LoadLines(Rec, DocumentIdFilter);
            SETVIEW(FilterView);
            IF NOT FINDFIRST() THEN
                EXIT(FALSE);
            LinesLoaded := TRUE;
        END;

        EXIT(TRUE);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        IF InsertItem THEN
            InsertItemOnTheFly();

        GraphMgtSalCrMemoBuf.PropagateInsertLine(Rec, TempFieldBuffer);

        SetCalculatedFields();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        IF InsertItem THEN
            InsertItemOnTheFly();

        GraphMgtSalCrMemoBuf.PropagateModifyLine(Rec, TempFieldBuffer);

        SetCalculatedFields();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
        VALIDATE(Type, Type::Item);
        RegisterFieldSet(FIELDNO(Type));
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        TempItemFieldSet: Record 2000000041 temporary;
        Item: Record "Item";
        UnitOfMeasure: Record "Unit of Measure";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        UnitOfMeasureJSON: Text;
        LineObjectDetailsJSON: Text;
        LinesLoaded: Boolean;
        IDOrDocumentIdShouldBeSpecifiedForLinesErr: Label 'You must specify an Id or a Document Id to get the lines.', Locked = true;
        CannotChangeIdNoErr: Label 'The value for id cannot be modified.', Locked = true;
        CannotChangeDocumentIdNoErr: Label 'The value for documentId cannot be modified.', Locked = true;
        CannotChangeLineNoErr: Label 'The value for sequence cannot be modified. Delete and insert the line again.', Locked = true;
        InsertItem: Boolean;
        ItemWasDeletedErr: Label 'The item was deleted.';
        IdIsAlreadyUsedErr: Label 'The id is already in use.';
        BothItemIdAndAccountIdAreSpecifiedErr: Label 'Both itemId and accountId are specified. Specify only one of them.';
        UnitOfMeasureValuesDontMatchErr: Label 'The unit of measure values do not match to a specific Unit of Measure.', Locked = true;
        UnitOfMeasureIdDoesNotMatchAUnitOfMeasureErr: Label 'The "unitOfMeasureId" does not match to a Unit of Measure.', Locked = true;
        UnitOfMeasureId: Guid;

    local procedure RegisterFieldSet(FieldNo: Integer)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        IF TempFieldBuffer.FINDLAST() THEN
            LastOrderNo := TempFieldBuffer.Order + 1;

        CLEAR(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := DATABASE::"Sales Invoice Line Aggregate";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.INSERT();
    end;

    local procedure ClearCalculatedFields()
    begin
        TempFieldBuffer.RESET();
        TempFieldBuffer.DELETEALL();
        TempItemFieldSet.RESET();
        TempItemFieldSet.DELETEALL();

        CLEAR(Item);
        CLEAR(UnitOfMeasureJSON);
        CLEAR(InsertItem);
        CLEAR(LineObjectDetailsJSON);
        CLEAR(UnitOfMeasureId);
    end;

    local procedure SetCalculatedFields()
    var
        GraphMgtSalesInvLines: Codeunit "Graph Mgt - Sales Inv. Lines";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        LineObjectDetailsJSON := GraphMgtComplexTypes.GetSalesLineDescriptionComplexType(Rec);
        UnitOfMeasureJSON := GraphMgtSalesInvLines.GetUnitOfMeasureJSON(Rec);
        UnitOfMeasureId := "Unit of Measure Id";
    end;

    local procedure RegisterItemFieldSet(FieldNo: Integer)
    begin
        IF TempItemFieldSet.GET(DATABASE::Item, FieldNo) THEN
            EXIT;

        TempItemFieldSet.INIT();
        TempItemFieldSet.TableNo := DATABASE::Item;
        TempItemFieldSet.VALIDATE("No.", FieldNo);
        TempItemFieldSet.INSERT(TRUE);
    end;

    local procedure CheckIntegrationIdInUse()
    var
        IntegrationRecord: Record "Integration Record";
    begin
        IF NOT IntegrationRecord.GET("Item Id") THEN
            EXIT;

        IF IntegrationRecord."Table ID" = DATABASE::Item THEN
            ERROR(ItemWasDeletedErr);

        ERROR(IdIsAlreadyUsedErr);
    end;

    local procedure InsertItemOnTheFly()
    var
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
    begin
        GraphCollectionMgtItem.InsertItemFromSalesDocument(Item, TempItemFieldSet, UnitOfMeasureJSON);
        VALIDATE("No.", Item."No.");

        IF Description = '' THEN
            Description := Item.Description;
    end;
}

















