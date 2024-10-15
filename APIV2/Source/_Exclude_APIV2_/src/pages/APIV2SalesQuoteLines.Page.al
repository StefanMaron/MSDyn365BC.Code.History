page 30045 "APIV2 - Sales Quote Lines"
{
    DelayedInsert = true;
    APIVersion = 'v2.0';
    EntityCaption = 'Sales Quote Line';
    EntitySetCaption = 'Sales Quote Lines';
    PageType = API;
    ODataKeyFields = SystemId;
    EntityName = 'salesQuoteLine';
    EntitySetName = 'salesQuoteLines';
    SourceTable = "Sales Invoice Line Aggregate";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(documentId; "Document Id")
                {
                    Caption = 'Document Id';

                    trigger OnValidate()
                    begin
                        if (not IsNullGuid(xRec."Document Id")) and (xRec."Document Id" <> "Document Id") then
                            Error(CannotChangeDocumentIdNoErr);
                    end;
                }
                field(sequence; "Line No.")
                {
                    Caption = 'Sequence';

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
                    Caption = 'Item Id';

                    trigger OnValidate()
                    begin
                        if not Item.GetBySystemId("Item Id") then
                            Error(ItemDoesNotExistErr);

                        RegisterFieldSet(FieldNo(Type));
                        RegisterFieldSet(FieldNo("No."));
                        RegisterFieldSet(FieldNo("Item Id"));

                        "No." := Item."No.";
                    end;
                }
                field(accountId; "Account Id")
                {
                    Caption = 'Account Id';

                    trigger OnValidate()
                    var
                        GLAccount: Record "G/L Account";
                        EmptyGuid: Guid;
                    begin
                        if "Account Id" <> EmptyGuid then
                            if Item."No." <> '' then
                                Error(BothItemIdAndAccountIdAreSpecifiedErr);

                        if not GLAccount.GetBySystemId("Account Id") then
                            Error(AccountDoesNotExistErr);

                        RegisterFieldSet(FieldNo(Type));
                        RegisterFieldSet(FieldNo("Account Id"));
                        RegisterFieldSet(FieldNo("No."));
                    end;
                }
                field(lineType; "API Type")
                {
                    Caption = 'Line Type';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Type));
                    end;
                }
                field(lineObjectNumber; "No.")
                {
                    Caption = 'Line Object Number';

                    trigger OnValidate()
                    var
                        GLAccount: Record "G/L Account";
                    begin
                        if (xRec."No." <> "No.") and (xRec."No." <> '') then
                            Error(CannotChangeLineObjectNoErr);

                        case Rec."API Type" of
                            Rec."API Type"::Item:
                                begin
                                    if not Item.Get("No.") then
                                        Error(ItemDoesNotExistErr);

                                    RegisterFieldSet(FieldNo("Item Id"));
                                    "Item Id" := Item.SystemId;
                                end;
                            Rec."API Type"::Account:
                                begin
                                    if not GLAccount.Get("No.") then
                                        Error(AccountDoesNotExistErr);

                                    RegisterFieldSet(FieldNo("Account Id"));
                                    "Account Id" := GLAccount.SystemId;
                                end;
                        end;
                        RegisterFieldSet(FieldNo("No."));
                    end;
                }
                field(description; Description)
                {
                    Caption = 'Description';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Description));
                    end;
                }
                field(unitOfMeasureId; "Unit of Measure Id")
                {
                    Caption = 'Unit Of Measure Id';

                    trigger OnValidate()
                    var
                        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
                    begin
                        SalesInvoiceAggregator.VerifyCanUpdateUOM(Rec);
                        RegisterFieldSet(FieldNo("Unit of Measure Code"));
                    end;
                }
                field(unitOfMeasureCode; "Unit of Measure Code")
                {
                    Caption = 'Unit Of Measure Code';
                    trigger OnValidate()
                    var
                        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
                    begin
                        SalesInvoiceAggregator.VerifyCanUpdateUOM(Rec);
                        RegisterFieldSet(FieldNo("Unit of Measure Code"));
                    end;
                }
                field(unitPrice; "Unit Price")
                {
                    Caption = 'Unit Price';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Unit Price"));
                    end;
                }
                field(quantity; Quantity)
                {
                    Caption = 'Quantity';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Quantity));
                    end;
                }
                field(discountAmount; "Line Discount Amount")
                {
                    Caption = 'DiscountAmount';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Line Discount Amount"));
                    end;
                }
                field(discountPercent; "Line Discount %")
                {
                    Caption = 'Discount Percent';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Line Discount %"));
                    end;
                }
                field(discountAppliedBeforeTax; "Discount Applied Before Tax")
                {
                    Caption = 'Discount Applied Before Tax';
                    Editable = false;
                }
                field(amountExcludingTax; "Line Amount Excluding Tax")
                {
                    Caption = 'Amount Excluding Tax';
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Amount));
                    end;
                }
                field(taxCode; "Tax Code")
                {
                    Caption = 'Tax Code';

                    trigger OnValidate()
                    var
                        GeneralLedgerSetup: Record "General Ledger Setup";
                    begin
                        if GeneralLedgerSetup.UseVat() then begin
                            Validate("VAT Prod. Posting Group", COPYSTR("Tax Code", 1, 20));
                            RegisterFieldSet(FieldNo("VAT Prod. Posting Group"));
                        end else begin
                            Validate("Tax Group Code", COPYSTR("Tax Code", 1, 20));
                            RegisterFieldSet(FieldNo("Tax Group Code"));
                        end;
                    end;
                }
                field(taxPercent; "VAT %")
                {
                    Caption = 'Tax Percent';
                    Editable = false;
                }
                field(totalTaxAmount; "Line Tax Amount")
                {
                    Caption = 'Total Tax Amount';
                    Editable = false;
                }
                field(amountIncludingTax; "Line Amount Including Tax")
                {
                    Caption = 'Amount Including Tax';
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Amount Including VAT"));
                    end;
                }
                field(netAmount; Amount)
                {
                    Caption = 'Net Amount';
                }
                field(netTaxAmount; "Tax Amount")
                {
                    Caption = 'Net Tax Amount';
                    Editable = false;
                }
                field(netAmountIncludingTax; "Amount Including VAT")
                {
                    Caption = 'Net Amount Including Tax';
                    Editable = false;
                }
                field(itemVariantId; "Variant Id")
                {
                    Caption = 'Item Variant Id';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Variant Code"));
                    end;
                }
                part(dimensionSetLines; "APIV2 - Dimension Set Lines")
                {
                    Caption = 'Dimension Set Lines';
                    EntityName = 'dimensionSetLine';
                    EntitySetName = 'dimensionSetLines';
                    SubPageLink = "Parent Id" = Field(SystemId), "Parent Type" = const(5);
                }
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        GraphMgtSalesQuoteBuffer.PropagateDeleteLine(Rec);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
        GraphMgtSalesInvLines: Codeunit "Graph Mgt - Sales Inv. Lines";
        SysId: Guid;
        DocumentIdFilter: Text;
        IdFilter: Text;
        FilterView: Text;
    begin
        if not LinesLoaded then begin
            FilterView := GetView();
            IdFilter := GetFilter(SystemId);
            DocumentIdFilter := GetFilter("Document Id");
            if (IdFilter = '') and (DocumentIdFilter = '') then
                Error(IDOrDocumentIdShouldBeSpecifiedForLinesErr);
            if IdFilter <> '' then begin
                Evaluate(SysId, IdFilter);
                DocumentIdFilter := GraphMgtSalesInvLines.GetSalesQuoteDocumentIdFilterFromSystemId(SysId);
            end else
                DocumentIdFilter := GetFilter("Document Id");
            GraphMgtSalesQuoteBuffer.LoadLines(Rec, DocumentIdFilter);
            SetView(FilterView);
            if not FindFirst() then
                exit(false);
            LinesLoaded := true;
        end;

        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        GraphMgtSalesQuoteBuffer.PropagateInsertLine(Rec, TempFieldBuffer);
    end;

    trigger OnModifyRecord(): Boolean
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        GraphMgtSalesQuoteBuffer.PropagateModifyLine(Rec, TempFieldBuffer);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
        RegisterFieldSet(FieldNo(Type));
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        Item: Record "Item";
        TempItemFieldSet: Record 2000000041 temporary;
        LinesLoaded: Boolean;
        IDOrDocumentIdShouldBeSpecifiedForLinesErr: Label 'You must specify an Id or a Document Id to get the lines.';
        CannotChangeDocumentIdNoErr: Label 'The value for "documentId" cannot be modified.';
        CannotChangeLineNoErr: Label 'The value for sequence cannot be modified. Delete and insert the line again.';
        BothItemIdAndAccountIdAreSpecifiedErr: Label 'Both "itemId" and "accountId" are specified. Specify only one of them.';
        ItemDoesNotExistErr: Label 'Item does not exist.';
        AccountDoesNotExistErr: Label 'Account does not exist.';
        CannotChangeLineObjectNoErr: Label 'The value for "lineObjectNumber" cannot be modified.';

    local procedure RegisterFieldSet(FieldNo: Integer)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        if TempFieldBuffer.FindLast() then
            LastOrderNo := TempFieldBuffer.Order + 1;

        Clear(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := Database::"Sales Invoice Line Aggregate";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure RegisterItemFieldSet(FieldNo: Integer)
    begin
        if TempItemFieldSet.Get(Database::Item, FieldNo) then
            exit;

        TempItemFieldSet.Init();
        TempItemFieldSet.TableNo := Database::Item;
        TempItemFieldSet.Validate("No.", FieldNo);
        TempItemFieldSet.Insert(true);
    end;

    local procedure ClearCalculatedFields()
    begin
        TempFieldBuffer.Reset();
        TempFieldBuffer.DeleteAll();
        TempItemFieldSet.Reset();
        TempItemFieldSet.DeleteAll();

        Clear(Item);
    end;
}