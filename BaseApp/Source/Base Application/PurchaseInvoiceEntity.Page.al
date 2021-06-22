page 5527 "Purchase Invoice Entity"
{
    Caption = 'purchaseInvoices', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'purchaseInvoice';
    EntitySetName = 'purchaseInvoices';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Purch. Inv. Entity Aggregate";

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
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Id));
                    end;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("No."));
                    end;
                }
                field(invoiceDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Document Date"));
                        WorkDate("Document Date"); // TODO: replicate page logic and set other dates appropriately
                    end;
                }
                field(dueDate; "Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'dueDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Due Date"));
                    end;
                }
                field(vendorInvoiceNumber; "Vendor Invoice No.")
                {
                    ApplicationArea = All;
                    Caption = 'vendorInvoiceNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Vendor Invoice No."));
                    end;
                }
                field(vendorId; "Vendor Id")
                {
                    ApplicationArea = All;
                    Caption = 'vendorId', Locked = true;

                    trigger OnValidate()
                    begin
                        Vendor.SetRange(Id, "Vendor Id");
                        if not Vendor.FindFirst then
                            Error(CouldNotFindVendorErr);

                        "Buy-from Vendor No." := Vendor."No.";
                        RegisterFieldSet(FieldNo("Vendor Id"));
                        RegisterFieldSet(FieldNo("Buy-from Vendor No."));
                    end;
                }
                field(vendorNumber; "Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'vendorNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        if Vendor."No." <> '' then
                            exit;

                        if not Vendor.Get("Buy-from Vendor No.") then
                            Error(CouldNotFindVendorErr);

                        "Vendor Id" := Vendor.Id;
                        RegisterFieldSet(FieldNo("Vendor Id"));
                        RegisterFieldSet(FieldNo("Buy-from Vendor No."));
                    end;
                }
                field(vendorName; "Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    Caption = 'vendorName', Locked = true;
                }
                field(buyFromAddress; BillingPostalAddressJSONText)
                {
                    ApplicationArea = All;
                    Caption = 'buyFromAddress', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the billing address of the Purchase Invoice.';

                    trigger OnValidate()
                    begin
                        BillingPostalAddressSet := true;
                    end;
                }
                field(currencyCode; CurrencyCodeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'currencyCode', Locked = true;

                    trigger OnValidate()
                    begin
                        "Currency Code" :=
                          GraphMgtGeneralTools.TranslateCurrencyCodeToNAVCurrencyCode(
                            LCYCurrencyCode, CopyStr(CurrencyCodeTxt, 1, MaxStrLen(LCYCurrencyCode)));
                        RegisterFieldSet(FieldNo("Currency Code"));
                    end;
                }
                field(pricesIncludeTax; "Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'pricesIncludeTax', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Prices Including VAT"));
                    end;
                }
                part(purchaseInvoiceLines; "Purchase Invoice Line Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    EntityName = 'purchaseInvoiceLine';
                    EntitySetName = 'purchaseInvoiceLines';
                    SubPageLink = "Document Id" = FIELD(Id);
                }
                part(pdfDocument; "PDF Document Entity")
                {
                    ApplicationArea = All;
                    Caption = 'PDF Document', Locked = true;
                    EntityName = 'pdfDocument';
                    EntitySetName = 'pdfDocument';
                    SubPageLink = "Document Id" = FIELD(Id);
                }
                field(discountAmount; "Invoice Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'discountAmount', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Invoice Discount Amount"));
                        InvoiceDiscountAmount := "Invoice Discount Amount";
                        DiscountAmountSet := true;
                    end;
                }
                field(discountAppliedBeforeTax; "Discount Applied Before Tax")
                {
                    ApplicationArea = All;
                    Caption = 'discountAppliedBeforeTax', Locked = true;
                }
                field(totalAmountExcludingTax; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountExcludingTax', Locked = true;
                    Editable = false;
                }
                field(totalTaxAmount; "Total Tax Amount")
                {
                    ApplicationArea = All;
                    Caption = 'totalTaxAmount', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Total Tax Amount"));
                    end;
                }
                field(totalAmountIncludingTax; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountIncludingTax', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Amount Including VAT"));
                    end;
                }
                field(status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;
                    Editable = false;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        SetCalculatedFields;
        if HasWritePermission then
            PurchInvAggregator.RedistributeInvoiceDiscounts(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        PurchInvAggregator.PropagateOnDelete(Rec);

        exit(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        CheckVendor;
        ProcessBillingPostalAddress;

        PurchInvAggregator.PropagateOnInsert(Rec, TempFieldBuffer);
        UpdateDiscount;

        SetCalculatedFields;

        PurchInvAggregator.RedistributeInvoiceDiscounts(Rec);

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        if xRec.Id <> Id then
            Error(CannotChangeIDErr);

        ProcessBillingPostalAddress;

        PurchInvAggregator.PropagateOnModify(Rec, TempFieldBuffer);
        UpdateDiscount;

        SetCalculatedFields;

        PurchInvAggregator.RedistributeInvoiceDiscounts(Rec);

        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields;
    end;

    trigger OnOpenPage()
    begin
        CheckPermissions;
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        Vendor: Record Vendor;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        CurrencyCodeTxt: Text;
        BillingPostalAddressJSONText: Text;
        BillingPostalAddressSet: Boolean;
        CannotChangeIDErr: Label 'The id cannot be changed.', Locked = true;
        VendorNotProvidedErr: Label 'A vendorNumber or a vendorID must be provided.', Locked = true;
        CouldNotFindVendorErr: Label 'The vendor cannot be found.', Locked = true;
        DraftInvoiceActionErr: Label 'The action can be applied to a draft invoice only.', Locked = true;
        CannotFindInvoiceErr: Label 'The invoice cannot be found.', Locked = true;
        DiscountAmountSet: Boolean;
        InvoiceDiscountAmount: Decimal;
        HasWritePermission: Boolean;
        PurchaseInvoicePermissionsErr: Label 'You do not have permissions to read Purchase Invoices.', Locked = true;

    local procedure SetCalculatedFields()
    var
        GraphMgtPurchaseInvoice: Codeunit "Graph Mgt - Purchase Invoice";
    begin
        BillingPostalAddressJSONText := GraphMgtPurchaseInvoice.PayToVendorAddressToJSON(Rec);
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(BillingPostalAddressJSONText);
        Clear(InvoiceDiscountAmount);
        Clear(DiscountAmountSet);
        TempFieldBuffer.DeleteAll();
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        if TempFieldBuffer.FindLast then
            LastOrderNo := TempFieldBuffer.Order + 1;

        Clear(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := DATABASE::"Purch. Inv. Entity Aggregate";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure CheckVendor()
    var
        BlankGUID: Guid;
    begin
        if ("Buy-from Vendor No." = '') and
           ("Vendor Id" = BlankGUID)
        then
            Error(VendorNotProvidedErr);
    end;

    local procedure CheckPermissions()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        if not PurchaseHeader.ReadPermission then
            Error(PurchaseInvoicePermissionsErr);

        HasWritePermission := PurchaseHeader.WritePermission;
    end;

    local procedure ProcessBillingPostalAddress()
    var
        GraphMgtPurchaseInvoice: Codeunit "Graph Mgt - Purchase Invoice";
    begin
        if not BillingPostalAddressSet then
            exit;

        GraphMgtPurchaseInvoice.ProcessComplexTypes(Rec, BillingPostalAddressJSONText);

        if xRec."Buy-from Address" <> "Buy-from Address" then
            RegisterFieldSet(FieldNo("Buy-from Address"));

        if xRec."Buy-from Address 2" <> "Buy-from Address 2" then
            RegisterFieldSet(FieldNo("Buy-from Address 2"));

        if xRec."Buy-from City" <> "Buy-from City" then
            RegisterFieldSet(FieldNo("Buy-from City"));

        if xRec."Buy-from Country/Region Code" <> "Buy-from Country/Region Code" then
            RegisterFieldSet(FieldNo("Buy-from Country/Region Code"));

        if xRec."Buy-from Post Code" <> "Buy-from Post Code" then
            RegisterFieldSet(FieldNo("Buy-from Post Code"));

        if xRec."Buy-from County" <> "Buy-from County" then
            RegisterFieldSet(FieldNo("Buy-from County"));
    end;

    local procedure UpdateDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        if Posted then
            exit;

        if not DiscountAmountSet then begin
            PurchInvAggregator.RedistributeInvoiceDiscounts(Rec);
            exit;
        end;

        PurchaseHeader.Get("Document Type"::Invoice, "No.");
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
    end;

    local procedure GetDraftInvoice(var PurchaseHeader: Record "Purchase Header")
    begin
        if Posted then
            Error(DraftInvoiceActionErr);

        PurchaseHeader.SetRange(Id, Id);
        if not PurchaseHeader.FindFirst then
            Error(CannotFindInvoiceErr);
    end;

    local procedure PostInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        PreAssignedNo: Code[20];
    begin
        LinesInstructionMgt.PurchaseCheckAllLinesHaveQuantityAssigned(PurchaseHeader);
        PreAssignedNo := PurchaseHeader."No.";
        PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post");
        PurchInvHeader.SetCurrentKey("Pre-Assigned No.");
        PurchInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst;
    end;

    local procedure SetActionResponse(var ActionContext: DotNet WebServiceActionContext; InvoiceId: Guid)
    var
        ODataActionManagement: Codeunit "OData Action Management";
    begin
        ODataActionManagement.AddKey(FieldNo(Id), InvoiceId);
        ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Purchase Invoice Entity");
    end;

    [ServiceEnabled]
    procedure Post(var ActionContext: DotNet WebServiceActionContext)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        GetDraftInvoice(PurchaseHeader);
        PostInvoice(PurchaseHeader, PurchInvHeader);
        SetActionResponse(ActionContext, PurchInvAggregator.GetPurchaseInvoiceHeaderId(PurchInvHeader));
    end;
}

