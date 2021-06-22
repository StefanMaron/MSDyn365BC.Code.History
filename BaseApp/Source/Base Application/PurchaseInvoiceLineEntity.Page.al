page 5528 "Purchase Invoice Line Entity"
{
    Caption = 'Purchase Invoice Line Entity';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Purch. Inv. Line Aggregate";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(sequence; "Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'sequence', Locked = true;

                    trigger OnValidate()
                    begin
                        if (xRec."Line No." <> "Line No.") and (xRec."Line No." <> 0) then
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
                            RegisterFieldSet(Item.FieldNo(Id));
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
                    ToolTip = 'Specifies the description of the purchase invoice line.';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Description));
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
                        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
                        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
                    begin
                        PurchInvAggregator.VerifyCanUpdateUOM(Rec);
                        GraphCollectionMgtItem.ParseJSONToUnitOfMeasure(UnitOfMeasureJSON, TempUnitOfMeasure);
                        "Unit of Measure Code" := TempUnitOfMeasure.Code;
                        RegisterFieldSet(FieldNo("Unit of Measure Code"));

                        if InsertItem then
                            exit;

                        PurchInvAggregator.UpdateUnitOfMeasure(Item, UnitOfMeasureJSON);
                    end;
                }
                field(unitCost; "Direct Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'directUnitCost', Locked = true;

                    trigger OnValidate()
                    begin
                        if InsertItem then begin
                            Item."Unit Cost" := "Direct Unit Cost";
                            RegisterFieldSet(Item.FieldNo("Unit Cost"));
                        end;

                        RegisterFieldSet(FieldNo("Direct Unit Cost"));
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
                    Caption = 'discountAppliedBeforeTax';
                }
                field(amountExcludingTax; "Line Amount Excluding Tax")
                {
                    ApplicationArea = All;
                    Caption = 'amountExcludingTax', Locked = true;

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
                            RegisterFieldSet(FieldNo("Tax Code"));
                        end;
                    end;
                }
                field(taxPercent; "VAT %")
                {
                    ApplicationArea = All;
                    Caption = 'taxPercent', Locked = true;
                }
                field(totalTaxAmount; "Line Tax Amount")
                {
                    ApplicationArea = All;
                    Caption = 'totalTaxAmount', Locked = true;
                }
                field(amountIncludingTax; "Line Amount Including Tax")
                {
                    ApplicationArea = All;
                    Caption = 'amountIncludingTax', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Amount Including VAT"));
                    end;
                }
                field(invoiceDiscountAllocation; "Inv. Discount Amount Excl. VAT")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDiscountAllocation', Locked = true;
                }
                field(netAmount; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'netAmount', Locked = true;
                }
                field(netTaxAmount; "Tax Amount")
                {
                    ApplicationArea = All;
                    Caption = 'netTaxAmount', Locked = true;
                }
                field(netAmountIncludingTax; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'netAmountIncludingTax', Locked = true;
                }
                field(expectedReceiptDate; "Expected Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'expectedReceiptDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Expected Receipt Date"));
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
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        PurchInvAggregator.PropagateDeleteLine(Rec);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        DocumentIdFilter: Text;
        FilterView: Text;
    begin
        if not LinesLoaded then begin
            FilterView := GetView;
            DocumentIdFilter := GetFilter("Document Id");
            PurchInvAggregator.LoadLines(Rec, DocumentIdFilter);
            SetView(FilterView);
            if not FindFirst then
                exit(false);
            LinesLoaded := true;
        end;

        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        if InsertItem then
            InsertItemOnTheFly;
        PurchInvAggregator.PropagateInsertLine(Rec, TempFieldBuffer);
    end;

    trigger OnModifyRecord(): Boolean
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        if InsertItem then
            InsertItemOnTheFly;
        PurchInvAggregator.PropagateModifyLine(Rec, TempFieldBuffer);
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
        UnitOfMeasureJSON: Text;
        LineObjectDetailsJSON: Text;
        LinesLoaded: Boolean;
        InsertItem: Boolean;
        CannotChangeLineNoErr: Label 'The value for sequence cannot be modified. Delete and insert the line again.', Locked = true;
        ItemWasDeletedErr: Label 'The item was deleted.', Locked = true;
        IdIsAlreadyUsedErr: Label 'The id is already in use used.', Locked = true;
        BothItemIdAndAccountIdAreSpecifiedErr: Label 'Both itemId and accountId are specified. Specify only one of them.';

    local procedure RegisterFieldSet(FieldNo: Integer)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        if TempFieldBuffer.FindLast then
            LastOrderNo := TempFieldBuffer.Order + 1;

        Clear(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := DATABASE::"Purch. Inv. Line Aggregate";
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
    end;

    local procedure SetCalculatedFields()
    var
        GraphMgtPurchInvLines: Codeunit "Graph Mgt - Purch. Inv. Lines";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        LineObjectDetailsJSON := GraphMgtComplexTypes.GetPurchaseLineDescriptionComplexType(Rec);
        UnitOfMeasureJSON := GraphMgtPurchInvLines.GetUnitOfMeasureJSON(Rec);
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

