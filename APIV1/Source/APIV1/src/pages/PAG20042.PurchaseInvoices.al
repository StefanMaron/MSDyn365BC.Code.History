page 20042 "APIV1 - Purchase Invoices"
{
    APIVersion = 'v1.0';
    Caption = 'purchaseInvoices', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'purchaseInvoice';
    EntitySetName = 'purchaseInvoices';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = 5477;
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
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO(Id));
                    end;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'number', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("No."));
                    end;
                }
                field(invoiceDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Document Date"));
                        WORKDATE("Document Date"); // TODO: replicate page logic and set other dates appropriately
                    end;
                }
                field(dueDate; "Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'dueDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Due Date"));
                    end;
                }
                field(vendorInvoiceNumber; "Vendor Invoice No.")
                {
                    ApplicationArea = All;
                    Caption = 'vendorInvoiceNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Vendor Invoice No."));
                    end;
                }
                field(vendorId; "Vendor Id")
                {
                    ApplicationArea = All;
                    Caption = 'vendorId', Locked = true;

                    trigger OnValidate()
                    begin
                        BuyFromVendor.SETRANGE(Id, "Vendor Id");
                        IF NOT BuyFromVendor.FINDFIRST() THEN
                            ERROR(CouldNotFindBuyFromVendorErr);

                        "Buy-from Vendor No." := BuyFromVendor."No.";
                        RegisterFieldSet(FIELDNO("Vendor Id"));
                        RegisterFieldSet(FIELDNO("Buy-from Vendor No."));
                    end;
                }
                field(vendorNumber; "Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'vendorNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        IF BuyFromVendor."No." <> '' THEN
                            EXIT;

                        IF NOT BuyFromVendor.GET("Buy-from Vendor No.") THEN
                            ERROR(CouldNotFindBuyFromVendorErr);

                        "Vendor Id" := BuyFromVendor.Id;
                        RegisterFieldSet(FIELDNO("Vendor Id"));
                        RegisterFieldSet(FIELDNO("Buy-from Vendor No."));
                    end;
                }
                field(vendorName; "Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    Caption = 'vendorName', Locked = true;
                    Editable = false;
                }
                field(payToName; "Pay-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'payToName', Locked = true;
                    Editable = false;
                }
                field(payToContact; "Pay-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'payToContact', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        if xRec."Pay-to Contact" <> "Pay-to Contact" then
                            RegisterFieldSet(FIELDNO("Pay-to Contact"));
                    end;
                }
                field(payToVendorId; "Pay-to Vendor Id")
                {
                    ApplicationArea = All;
                    Caption = 'payToVendorId', Locked = true;

                    trigger OnValidate()
                    begin
                        PayToVendor.SETRANGE(Id, "Pay-to Vendor Id");
                        IF NOT PayToVendor.FINDFIRST() THEN
                            ERROR(CouldNotFindPayToVendorErr);

                        "Pay-to Vendor No." := PayToVendor."No.";
                        RegisterFieldSet(FIELDNO("Pay-to Vendor Id"));
                        RegisterFieldSet(FIELDNO("Pay-to Vendor No."));
                    end;
                }
                field(payToVendorNumber; "Pay-to Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'payToVendorNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        IF PayToVendor."No." <> '' THEN
                            EXIT;

                        IF NOT PayToVendor.GET("Pay-to Vendor No.") THEN
                            ERROR(CouldNotFindPayToVendorErr);

                        "Pay-to Vendor Id" := PayToVendor.Id;
                        RegisterFieldSet(FIELDNO("Pay-to Vendor Id"));
                        RegisterFieldSet(FIELDNO("Pay-to Vendor No."));
                    end;
                }
                field(shipToName; "Ship-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'shipToName', Locked = true;

                    trigger OnValidate()
                    begin
                        if xRec."Ship-to Name" <> "Ship-to Name" then begin
                            "Ship-to Code" := '';
                            RegisterFieldSet(FIELDNO("Ship-to Code"));
                            RegisterFieldSet(FIELDNO("Ship-to Name"));
                        end;
                    end;
                }
                field(shipToContact; "Ship-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'shipToContact', Locked = true;

                    trigger OnValidate()
                    begin
                        if xRec."Ship-to Contact" <> "Ship-to Contact" then begin
                            "Ship-to Code" := '';
                            RegisterFieldSet(FIELDNO("Ship-to Code"));
                            RegisterFieldSet(FIELDNO("Ship-to Contact"));
                        end;
                    end;
                }
                field(buyFromAddress; BuyFromPostalAddressJSONText)
                {
                    ApplicationArea = All;
                    Caption = 'buyFromAddress', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the buy-from address of the Purchase Invoice.';

                    trigger OnValidate()
                    begin
                        BuyFromPostalAddressSet := TRUE;
                    end;
                }
                field(payToAddress; PayToPostalAddressJSONText)
                {
                    ApplicationArea = All;
                    Caption = 'payToAddress', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the pay-to address of the Purchase Invoice.';
                    Editable = false;

                    trigger OnValidate()
                    begin
                        Error(PayToAddressIsReadOnlyErr);
                    end;
                }
                field(shipToAddress; ShipToPostalAddressJSONText)
                {
                    ApplicationArea = All;
                    Caption = 'shipToAddress', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the ship-to address of the Purchase Invoice.';

                    trigger OnValidate()
                    begin
                        ShipToPostalAddressSet := TRUE;
                    end;
                }
                field(currencyId; "Currency Id")
                {
                    ApplicationArea = All;
                    Caption = 'currencyId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF "Currency Id" = BlankGUID THEN
                            "Currency Code" := ''
                        ELSE BEGIN
                            Currency.SETRANGE(Id, "Currency Id");
                            IF NOT Currency.FINDFIRST() THEN
                                ERROR(CurrencyIdDoesNotMatchACurrencyErr);

                            "Currency Code" := Currency.Code;
                        END;

                        RegisterFieldSet(FIELDNO("Currency Id"));
                        RegisterFieldSet(FIELDNO("Currency Code"));
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
                            LCYCurrencyCode, COPYSTR(CurrencyCodeTxt, 1, MAXSTRLEN(LCYCurrencyCode)));

                        IF Currency.Code <> '' THEN BEGIN
                            IF Currency.Code <> "Currency Code" THEN
                                ERROR(CurrencyValuesDontMatchErr);
                            EXIT;
                        END;

                        IF "Currency Code" = '' THEN
                            "Currency Id" := BlankGUID
                        ELSE BEGIN
                            IF NOT Currency.GET("Currency Code") THEN
                                ERROR(CurrencyCodeDoesNotMatchACurrencyErr);

                            "Currency Id" := Currency.Id;
                        END;

                        RegisterFieldSet(FIELDNO("Currency Id"));
                        RegisterFieldSet(FIELDNO("Currency Code"));
                    end;
                }
                field(pricesIncludeTax; "Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'pricesIncludeTax', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Prices Including VAT"));
                    end;
                }
                part(purchaseInvoiceLines; 20047)
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    EntityName = 'purchaseInvoiceLine';
                    EntitySetName = 'purchaseInvoiceLines';
                    SubPageLink = "Document Id" = FIELD(Id);
                }
                part(pdfDocument; 5529)
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
                        RegisterFieldSet(FIELDNO("Invoice Discount Amount"));
                        InvoiceDiscountAmount := "Invoice Discount Amount";
                        DiscountAmountSet := TRUE;
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
                        RegisterFieldSet(FIELDNO("Total Tax Amount"));
                    end;
                }
                field(totalAmountIncludingTax; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountIncludingTax', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Amount Including VAT"));
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
        SetCalculatedFields();
        if HasWritePermission then
            PurchInvAggregator.RedistributeInvoiceDiscounts(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        PurchInvAggregator.PropagateOnDelete(Rec);

        EXIT(FALSE);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        CheckBuyFromVendor();
        ProcessBuyFromPostalAddressOnInsert();
        ProcessShipToPostalAddressOnInsert();

        PurchInvAggregator.PropagateOnInsert(Rec, TempFieldBuffer);
        UpdateDiscount();

        SetCalculatedFields();

        PurchInvAggregator.RedistributeInvoiceDiscounts(Rec);

        EXIT(FALSE);
    end;

    trigger OnModifyRecord(): Boolean
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        IF xRec.Id <> Id THEN
            ERROR(CannotChangeIDErr);

        ProcessBuyFromPostalAddressOnModify();
        ProcessShipToPostalAddressOnModify();

        PurchInvAggregator.PropagateOnModify(Rec, TempFieldBuffer);
        UpdateDiscount();

        SetCalculatedFields();

        PurchInvAggregator.RedistributeInvoiceDiscounts(Rec);

        EXIT(FALSE);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
    end;

    trigger OnOpenPage()
    begin
        CheckPermissions();
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        BuyFromVendor: Record "Vendor";
        PayToVendor: Record "Vendor";
        Currency: Record "Currency";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        CurrencyCodeTxt: Text;
        BuyFromPostalAddressJSONText: Text;
        PayToPostalAddressJSONText: Text;
        ShipToPostalAddressJSONText: Text;
        BuyFromPostalAddressSet: Boolean;
        ShipToPostalAddressSet: Boolean;
        CannotChangeIDErr: Label 'The id cannot be changed.', Locked = true;
        BuyFromVendorNotProvidedErr: Label 'A vendorNumber or a vendorID must be provided.', Locked = true;
        CouldNotFindBuyFromVendorErr: Label 'The vendor cannot be found.', Locked = true;
        CouldNotFindPayToVendorErr: Label 'The pay-to vendor cannot be found.', Locked = true;
        CurrencyValuesDontMatchErr: Label 'The currency values do not match to a specific Currency.', Locked = true;
        CurrencyIdDoesNotMatchACurrencyErr: Label 'The "currencyId" does not match to a Currency.', Locked = true;
        CurrencyCodeDoesNotMatchACurrencyErr: Label 'The "currencyCode" does not match to a Currency.', Locked = true;
        BlankGUID: Guid;
        DraftInvoiceActionErr: Label 'The action can be applied to a draft invoice only.', Locked = true;
        CannotFindInvoiceErr: Label 'The invoice cannot be found.', Locked = true;
        DiscountAmountSet: Boolean;
        InvoiceDiscountAmount: Decimal;
        HasWritePermission: Boolean;
        PurchaseInvoicePermissionsErr: Label 'You do not have permissions to read Purchase Invoices.', Locked = true;
        PayToAddressIsReadOnlyErr: Label 'The "payToAddress" is read-only.', Locked = true;

    local procedure SetCalculatedFields()
    var
        GraphMgtPurchaseInvoice: Codeunit "Graph Mgt - Purchase Invoice";
    begin
        BuyFromPostalAddressJSONText := GraphMgtPurchaseInvoice.BuyFromVendorAddressToJSON(Rec);
        PayToPostalAddressJSONText := GraphMgtPurchaseInvoice.PayToVendorAddressToJSON(Rec);
        ShipToPostalAddressJSONText := GraphMgtPurchaseInvoice.ShipToVendorAddressToJSON(Rec);
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");
    end;

    local procedure UpdateDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        IF Posted THEN
            EXIT;

        IF NOT DiscountAmountSet THEN BEGIN
            PurchInvAggregator.RedistributeInvoiceDiscounts(Rec);
            EXIT;
        END;

        PurchaseHeader.GET("Document Type"::Invoice, "No.");
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
    end;

    local procedure ClearCalculatedFields()
    begin
        CLEAR(BuyFromPostalAddressJSONText);
        CLEAR(PayToPostalAddressJSONText);
        CLEAR(ShipToPostalAddressJSONText);
        CLEAR(InvoiceDiscountAmount);
        CLEAR(DiscountAmountSet);
        TempFieldBuffer.DELETEALL();
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        IF TempFieldBuffer.FINDLAST() THEN
            LastOrderNo := TempFieldBuffer.Order + 1;

        CLEAR(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := DATABASE::"Purch. Inv. Entity Aggregate";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.INSERT();
    end;

    local procedure CheckBuyFromVendor()
    begin
        IF ("Buy-from Vendor No." = '') AND
           ("Vendor Id" = BlankGUID)
        THEN
            ERROR(BuyFromVendorNotProvidedErr);
    end;

    local procedure CheckPermissions()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SETRANGE("Document Type", PurchaseHeader."Document Type"::Invoice);
        if not PurchaseHeader.READPERMISSION() then
            ERROR(PurchaseInvoicePermissionsErr);

        HasWritePermission := PurchaseHeader.WRITEPERMISSION();
    end;

    local procedure ProcessBuyFromPostalAddressOnInsert()
    var
        GraphMgtPurchaseInvoice: Codeunit "Graph Mgt - Purchase Invoice";
    begin
        IF NOT BuyFromPostalAddressSet THEN
            EXIT;

        GraphMgtPurchaseInvoice.ParseBuyFromVendorAddressFromJSON(BuyFromPostalAddressJSONText, Rec);

        RegisterFieldSet(FIELDNO("Buy-from Address"));
        RegisterFieldSet(FIELDNO("Buy-from Address 2"));
        RegisterFieldSet(FIELDNO("Buy-from City"));
        RegisterFieldSet(FIELDNO("Buy-from Country/Region Code"));
        RegisterFieldSet(FIELDNO("Buy-from Post Code"));
        RegisterFieldSet(FIELDNO("Buy-from County"));
    end;

    local procedure ProcessBuyFromPostalAddressOnModify()
    var
        GraphMgtPurchaseInvoice: Codeunit "Graph Mgt - Purchase Invoice";
    begin
        IF NOT BuyFromPostalAddressSet THEN
            EXIT;

        GraphMgtPurchaseInvoice.ParseBuyFromVendorAddressFromJSON(BuyFromPostalAddressJSONText, Rec);

        IF xRec."Buy-from Address" <> "Buy-from Address" THEN
            RegisterFieldSet(FIELDNO("Buy-from Address"));

        IF xRec."Buy-from Address 2" <> "Buy-from Address 2" THEN
            RegisterFieldSet(FIELDNO("Buy-from Address 2"));

        IF xRec."Buy-from City" <> "Buy-from City" THEN
            RegisterFieldSet(FIELDNO("Buy-from City"));

        IF xRec."Buy-from Country/Region Code" <> "Buy-from Country/Region Code" THEN
            RegisterFieldSet(FIELDNO("Buy-from Country/Region Code"));

        IF xRec."Buy-from Post Code" <> "Buy-from Post Code" THEN
            RegisterFieldSet(FIELDNO("Buy-from Post Code"));

        IF xRec."Buy-from County" <> "Buy-from County" THEN
            RegisterFieldSet(FIELDNO("Buy-from County"));
    end;

    local procedure ProcessShipToPostalAddressOnInsert()
    var
        GraphMgtPurchaseInvoice: Codeunit "Graph Mgt - Purchase Invoice";
    begin
        if not ShipToPostalAddressSet then
            exit;

        GraphMgtPurchaseInvoice.ParseShipToVendorAddressFromJSON(ShipToPostalAddressJSONText, Rec);

        "Ship-to Code" := '';
        RegisterFieldSet(FIELDNO("Ship-to Address"));
        RegisterFieldSet(FIELDNO("Ship-to Address 2"));
        RegisterFieldSet(FIELDNO("Ship-to City"));
        RegisterFieldSet(FIELDNO("Ship-to Country/Region Code"));
        RegisterFieldSet(FIELDNO("Ship-to Post Code"));
        RegisterFieldSet(FIELDNO("Ship-to County"));
        RegisterFieldSet(FIELDNO("Ship-to Code"));
    end;

    local procedure ProcessShipToPostalAddressOnModify()
    var
        GraphMgtPurchaseInvoice: Codeunit "Graph Mgt - Purchase Invoice";
        Changed: Boolean;
    begin
        if not ShipToPostalAddressSet then
            exit;

        GraphMgtPurchaseInvoice.ParseShipToVendorAddressFromJSON(ShipToPostalAddressJSONText, Rec);

        if xRec."Ship-to Address" <> "Ship-to Address" then begin
            RegisterFieldSet(FIELDNO("Ship-to Address"));
            Changed := true;
        end;

        if xRec."Ship-to Address 2" <> "Ship-to Address 2" then begin
            RegisterFieldSet(FIELDNO("Ship-to Address 2"));
            Changed := true;
        end;

        if xRec."Ship-to City" <> "Ship-to City" then begin
            RegisterFieldSet(FIELDNO("Ship-to City"));
            Changed := true;
        end;

        if xRec."Ship-to Country/Region Code" <> "Ship-to Country/Region Code" then begin
            RegisterFieldSet(FIELDNO("Ship-to Country/Region Code"));
            Changed := true;
        end;

        if xRec."Ship-to Post Code" <> "Ship-to Post Code" then begin
            RegisterFieldSet(FIELDNO("Ship-to Post Code"));
            Changed := true;
        end;

        if xRec."Ship-to County" <> "Ship-to County" then begin
            RegisterFieldSet(FIELDNO("Ship-to County"));
            Changed := true;
        end;

        if Changed then begin
            "Ship-to Code" := '';
            RegisterFieldSet(FIELDNO("Ship-to Code"));
        end;
    end;

    local procedure GetDraftInvoice(var PurchaseHeader: Record "Purchase Header")
    begin
        IF Posted THEN
            ERROR(DraftInvoiceActionErr);

        PurchaseHeader.SETRANGE(Id, Id);
        IF NOT PurchaseHeader.FINDFIRST() THEN
            ERROR(CannotFindInvoiceErr);
    end;

    local procedure PostInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        PreAssignedNo: Code[20];
    begin
        LinesInstructionMgt.PurchaseCheckAllLinesHaveQuantityAssigned(PurchaseHeader);
        PreAssignedNo := PurchaseHeader."No.";
        PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post");
        PurchInvHeader.SETCURRENTKEY("Pre-Assigned No.");
        PurchInvHeader.SETRANGE("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FINDFIRST();
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext; InvoiceId: Guid)
    var
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"APIV1 - Purchase Invoices");
        ActionContext.AddEntityKey(FieldNo(Id), InvoiceId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Deleted);
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure Post(var ActionContext: WebServiceActionContext)
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