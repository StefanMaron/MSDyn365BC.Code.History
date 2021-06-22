page 5508 "Sales Credit Memo Line Entity"
{
    Caption = 'Sales Credit Memo Line Entity';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Sales Invoice Line Aggregate";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(sequence; "Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'sequence', Locked = true;

                    trigger OnValidate()
                    begin
                        if (xRec."Line No." <> "Line No.") and
                           (xRec."Line No." <> 0)
                        then
                            Error(CannotChangeLineNoErr);

                        RegisterFieldSet(FieldNo("Line No."));
                    end;
                }
                field(itemId; "Item Id")
                {
                    ApplicationArea = All;
                    Caption = 'itemId', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Type));
                        RegisterFieldSet(FieldNo("No."));
                        RegisterFieldSet(FieldNo("Item Id"));

                        Item.SetRange(Id, "Item Id");

                        if not Item.FindFirst then begin
                            InsertItem := true;
                            CheckIntegrationIdInUse;

                            Item.Id := "Item Id";
                            RegisterItemFieldSet(Item.FieldNo(Id));
                            exit;
                        end;

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
                        if "Account Id" <> EmptyGuid then
                            if Item."No." <> '' then
                                Error(BothItemIdAndAccountIdAreSpecifiedErr);
                        RegisterFieldSet(FieldNo(Type));
                        RegisterFieldSet(FieldNo("Account Id"));
                        RegisterFieldSet(FieldNo("No."));
                    end;
                }
                field(lineType; "API Type")
                {
                    ApplicationArea = All;
                    Caption = 'lineType', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Type));
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
                        if not InsertItem then
                            exit;

                        GraphMgtComplexTypes.ParseDocumentLineObjectDetailsFromJSON(
                          LineObjectDetailsJSON, Item."No.", Item.Description, Item."Description 2");

                        if Item."No." <> '' then
                            RegisterItemFieldSet(Item.FieldNo("No."));

                        RegisterFieldSet(FieldNo("No."));

                        if Item.Description <> '' then
                            RegisterItemFieldSet(Item.FieldNo(Description));

                        if Description = '' then begin
                            Description := Item.Description;
                            RegisterFieldSet(FieldNo(Description));
                        end;

                        if Item."Description 2" <> '' then begin
                            "Description 2" := Item."Description 2";
                            RegisterItemFieldSet(Item.FieldNo("Description 2"));
                            RegisterFieldSet(FieldNo("Description 2"));
                        end;
                    end;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'description';
                    ToolTip = 'Specifies the description of the sales credit memo line.';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Description));
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

                        if (UnitOfMeasureJSON = 'null') and ("Unit of Measure Id" <> BlankGUID) then
                            exit;

                        if "Unit of Measure Id" = BlankGUID then
                            "Unit of Measure Code" := ''
                        else begin
                            UnitOfMeasure.SetRange(Id, "Unit of Measure Id");
                            if not UnitOfMeasure.FindFirst then
                                Error(UnitOfMeasureIdDoesNotMatchAUnitOfMeasureErr);

                            "Unit of Measure Code" := UnitOfMeasure.Code;
                        end;

                        RegisterFieldSet(FieldNo("Unit of Measure Code"));

                        if InsertItem then
                            exit;

                        Item.SetRange(Id, "Item Id");
                        if Item.FindFirst then
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
                        Validate("Unit of Measure Id", UnitOfMeasureId);
                        SalesInvoiceAggregator.VerifyCanUpdateUOM(Rec);

                        if UnitOfMeasureJSON = 'null' then
                            TempUnitOfMeasure.Code := ''
                        else
                            GraphCollectionMgtItem.ParseJSONToUnitOfMeasure(UnitOfMeasureJSON, TempUnitOfMeasure);

                        if (UnitOfMeasureJSON = 'null') and (UnitOfMeasure.Code <> '') then
                            exit;
                        if (UnitOfMeasure.Code <> '') and (UnitOfMeasure.Code <> TempUnitOfMeasure.Code) then
                            Error(UnitOfMeasureValuesDontMatchErr);

                        "Unit of Measure Code" := TempUnitOfMeasure.Code;
                        RegisterFieldSet(FieldNo("Unit of Measure Code"));

                        if InsertItem then
                            exit;

                        Item.SetRange(Id, "Item Id");
                        if Item.FindFirst then begin
                            if UnitOfMeasureJSON = 'null' then
                                SalesInvoiceAggregator.UpdateUnitOfMeasure(Item, GraphMgtSalesInvLines.GetUnitOfMeasureJSON(Rec))
                            else
                                SalesInvoiceAggregator.UpdateUnitOfMeasure(Item, UnitOfMeasureJSON);
                        end;
                    end;
                }
                field(unitPrice; "Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'unitPrice', Locked = true;

                    trigger OnValidate()
                    begin
                        if InsertItem then begin
                            Item."Unit Price" := "Unit Price";
                            RegisterItemFieldSet(Item.FieldNo("Unit Price"));
                        end;

                        RegisterFieldSet(FieldNo("Unit Price"));
                    end;
                }
                field(quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'quantity', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Quantity));
                    end;
                }
                field(discountAmount; "Line Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'discountAmount', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Line Discount Amount"));
                    end;
                }
                field(discountPercent; "Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'discountPercent', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Line Discount %"));
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
                        RegisterFieldSet(FieldNo(Amount));
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
                        if InsertItem then begin
                            if GeneralLedgerSetup.UseVat then
                                exit;

                            Item."Tax Group Code" := CopyStr("Tax Code", 1, MaxStrLen(Item."Tax Group Code"));
                            RegisterItemFieldSet(Item.FieldNo("Tax Group Code"));
                        end;

                        if GeneralLedgerSetup.UseVat then begin
                            Validate("VAT Prod. Posting Group", CopyStr("Tax Code", 1, 20));
                            RegisterFieldSet(FieldNo("VAT Prod. Posting Group"));
                        end else begin
                            Validate("Tax Group Code", CopyStr("Tax Code", 1, 20));
                            RegisterFieldSet(FieldNo("Tax Group Code"));
                        end;
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
                        RegisterFieldSet(FieldNo("Amount Including VAT"));
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
                        RegisterFieldSet(FieldNo("Shipment Date"));
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
        SetCalculatedFields;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        GraphMgtSalCrMemoBuf.PropagateDeleteLine(Rec);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        DocumentIdFilter: Text;
        FilterView: Text;
    begin
        if not LinesLoaded then begin
            FilterView := GetView;
            DocumentIdFilter := GetFilter("Document Id");
            GraphMgtSalCrMemoBuf.LoadLines(Rec, DocumentIdFilter);
            SetView(FilterView);
            if not FindFirst then
                exit(false);
            LinesLoaded := true;
        end;

        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if InsertItem then
            InsertItemOnTheFly;

        GraphMgtSalCrMemoBuf.PropagateInsertLine(Rec, TempFieldBuffer);

        SetCalculatedFields;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if InsertItem then
            InsertItemOnTheFly;

        GraphMgtSalCrMemoBuf.PropagateModifyLine(Rec, TempFieldBuffer);

        SetCalculatedFields;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields;
        Validate(Type, Type::Item);
        RegisterFieldSet(FieldNo(Type));
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        TempItemFieldSet: Record "Field" temporary;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        UnitOfMeasureJSON: Text;
        LineObjectDetailsJSON: Text;
        LinesLoaded: Boolean;
        CannotChangeLineNoErr: Label 'The value for sequence cannot be modified. Delete and insert the line again.', Locked = true;
        InsertItem: Boolean;
        ItemWasDeletedErr: Label 'The item was deleted.';
        IdIsAlreadyUsedErr: Label 'The id is already in use used.';
        BothItemIdAndAccountIdAreSpecifiedErr: Label 'Both itemId and accountId are specified. Specify only one of them.';
        UnitOfMeasureValuesDontMatchErr: Label 'The unit of measure values do not match to a specific Unit of Measure.', Locked = true;
        UnitOfMeasureIdDoesNotMatchAUnitOfMeasureErr: Label 'The "unitOfMeasureId" does not match to a Unit of Measure.', Locked = true;
        UnitOfMeasureId: Guid;

    local procedure RegisterFieldSet(FieldNo: Integer)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        if TempFieldBuffer.FindLast then
            LastOrderNo := TempFieldBuffer.Order + 1;

        Clear(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := DATABASE::"Sales Invoice Line Aggregate";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure ClearCalculatedFields()
    begin
        TempFieldBuffer.Reset();
        TempFieldBuffer.DeleteAll();
        TempItemFieldSet.Reset();
        TempItemFieldSet.DeleteAll();

        Clear(Item);
        Clear(UnitOfMeasureJSON);
        Clear(InsertItem);
        Clear(LineObjectDetailsJSON);
        Clear(UnitOfMeasureId);
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
        if TempItemFieldSet.Get(DATABASE::Item, FieldNo) then
            exit;

        TempItemFieldSet.Init();
        TempItemFieldSet.TableNo := DATABASE::Item;
        TempItemFieldSet.Validate("No.", FieldNo);
        TempItemFieldSet.Insert(true);
    end;

    local procedure CheckIntegrationIdInUse()
    var
        IntegrationRecord: Record "Integration Record";
    begin
        if not IntegrationRecord.Get("Item Id") then
            exit;

        if IntegrationRecord."Table ID" = DATABASE::Item then
            Error(ItemWasDeletedErr);

        Error(IdIsAlreadyUsedErr);
    end;

    local procedure InsertItemOnTheFly()
    var
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
    begin
        GraphCollectionMgtItem.InsertItemFromSalesDocument(Item, TempItemFieldSet, UnitOfMeasureJSON);
        Validate("No.", Item."No.");

        if Description = '' then
            Description := Item.Description;
    end;
}

