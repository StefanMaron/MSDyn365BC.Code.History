page 20038 "APIV1 - Sales Credit Memos"
{
    APIVersion = 'v1.0';
    Caption = 'salesCreditMemos', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'salesCreditMemo';
    EntitySetName = 'salesCreditMemos';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = 5507;
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
                field(externalDocumentNumber; "External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'externalDocumentNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("External Document No."))
                    end;
                }
                field(creditMemoDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'creditMemoDate', Locked = true;

                    trigger OnValidate()
                    begin
                        DocumentDateVar := "Document Date";
                        DocumentDateSet := TRUE;

                        RegisterFieldSet(FIELDNO("Document Date"));
                    end;
                }
                field(dueDate; "Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'dueDate', Locked = true;

                    trigger OnValidate()
                    begin
                        DueDateVar := "Due Date";
                        DueDateSet := TRUE;

                        RegisterFieldSet(FIELDNO("Due Date"));
                    end;
                }
                field(customerId; "Customer Id")
                {
                    ApplicationArea = All;
                    Caption = 'customerId', Locked = true;

                    trigger OnValidate()
                    var
                        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
                    begin
                        SellToCustomer.SETRANGE(Id, "Customer Id");
                        IF NOT SellToCustomer.FINDFIRST() THEN
                            ERROR(CouldNotFindSellToCustomerErr);

                        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(SellToCustomer);

                        "Sell-to Customer No." := SellToCustomer."No.";
                        RegisterFieldSet(FIELDNO("Customer Id"));
                        RegisterFieldSet(FIELDNO("Sell-to Customer No."));
                    end;
                }
                field(contactId; "Contact Graph Id")
                {
                    ApplicationArea = All;
                    Caption = 'contactId', Locked = true;

                    trigger OnValidate()
                    var
                        Contact: Record "Contact";
                        Customer: Record "Customer";
                        GraphIntContact: Codeunit "Graph Int. - Contact";
                    begin
                        RegisterFieldSet(FIELDNO("Contact Graph Id"));

                        IF "Contact Graph Id" = '' THEN
                            ERROR(SellToContactIdHasToHaveValueErr);

                        IF NOT GraphIntContact.FindOrCreateCustomerFromGraphContactSafe("Contact Graph Id", Customer, Contact) THEN
                            EXIT;

                        UpdateSellToCustomerFromSellToGraphContactId(Customer);

                        IF Contact."Company No." = Customer."No." THEN BEGIN
                            VALIDATE("Sell-to Contact No.", Contact."No.");
                            VALIDATE("Sell-to Contact", Contact.Name);

                            RegisterFieldSet(FIELDNO("Sell-to Contact No."));
                            RegisterFieldSet(FIELDNO("Sell-to Contact"));
                        END;
                    end;
                }
                field(customerNumber; "Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'customerNumber', Locked = true;

                    trigger OnValidate()
                    var
                        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
                    begin
                        IF SellToCustomer."No." <> '' THEN BEGIN
                            IF SellToCustomer."No." <> "Sell-to Customer No." THEN
                                ERROR(SellToCustomerValuesDontMatchErr);
                            EXIT;
                        END;

                        IF NOT SellToCustomer.GET("Sell-to Customer No.") THEN
                            ERROR(CouldNotFindSellToCustomerErr);

                        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(SellToCustomer);

                        "Customer Id" := SellToCustomer.Id;
                        RegisterFieldSet(FIELDNO("Customer Id"));
                        RegisterFieldSet(FIELDNO("Sell-to Customer No."));
                    end;
                }
                field(customerName; "Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Caption = 'customerName', Locked = true;
                    Editable = false;
                }
                field(billToName; "Bill-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'billToName', Locked = true;
                    Editable = false;
                }
                field(billToCustomerId; "Bill-to Customer Id")
                {
                    ApplicationArea = All;
                    Caption = 'billToCustomerId', Locked = true;

                    trigger OnValidate()
                    var
                        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
                    begin
                        BillToCustomer.SETRANGE(Id, "Bill-to Customer Id");
                        IF NOT BillToCustomer.FINDFIRST() THEN
                            ERROR(CouldNotFindBillToCustomerErr);

                        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(BillToCustomer);

                        "Bill-to Customer No." := BillToCustomer."No.";
                        RegisterFieldSet(FIELDNO("Bill-to Customer Id"));
                        RegisterFieldSet(FIELDNO("Bill-to Customer No."));
                    end;
                }
                field(billToCustomerNumber; "Bill-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'billToCustomerNumber', Locked = true;

                    trigger OnValidate()
                    var
                        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
                    begin
                        IF BillToCustomer."No." <> '' THEN BEGIN
                            IF BillToCustomer."No." <> "Bill-to Customer No." THEN
                                ERROR(BillToCustomerValuesDontMatchErr);
                            EXIT;
                        END;

                        IF NOT BillToCustomer.GET("Bill-to Customer No.") THEN
                            ERROR(CouldNotFindBillToCustomerErr);

                        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(BillToCustomer);

                        "Bill-to Customer Id" := BillToCustomer.Id;
                        RegisterFieldSet(FIELDNO("Bill-to Customer Id"));
                        RegisterFieldSet(FIELDNO("Bill-to Customer No."));
                    end;
                }
                field(sellingPostalAddress; SellingPostalAddressJSONText)
                {
                    ApplicationArea = All;
                    Caption = 'sellingPostalAddress', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the selling address of the Sales Invoice.';

                    trigger OnValidate()
                    begin
                        SellingPostalAddressSet := TRUE;
                    end;
                }
                field(billingPostalAddress; BillingPostalAddressJSONText)
                {
                    ApplicationArea = All;
                    Caption = 'billingPostalAddress', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the billing address of the Sales Credit Memo.';

                    trigger OnValidate()
                    begin
                        BillingPostalAddressSet := TRUE;
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
                field(paymentTermsId; "Payment Terms Id")
                {
                    ApplicationArea = All;
                    Caption = 'paymentTermsId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF "Payment Terms Id" = BlankGUID THEN
                            "Payment Terms Code" := ''
                        ELSE BEGIN
                            PaymentTerms.SETRANGE(Id, "Payment Terms Id");
                            IF NOT PaymentTerms.FINDFIRST() THEN
                                ERROR(PaymentTermsIdDoesNotMatchAPaymentTermsErr);

                            "Payment Terms Code" := PaymentTerms.Code;
                        END;

                        RegisterFieldSet(FIELDNO("Payment Terms Id"));
                        RegisterFieldSet(FIELDNO("Payment Terms Code"));
                    end;
                }
                field(shipmentMethodId; "Shipment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'shipmentMethodId', Locked = true;

                    trigger OnValidate()
                    begin
                        IF "Shipment Method Id" = BlankGUID THEN
                            "Shipment Method Code" := ''
                        ELSE BEGIN
                            ShipmentMethod.SETRANGE(Id, "Shipment Method Id");
                            IF NOT ShipmentMethod.FINDFIRST() THEN
                                ERROR(ShipmentMethodIdDoesNotMatchAShipmentMethodErr);

                            "Shipment Method Code" := ShipmentMethod.Code;
                        END;

                        RegisterFieldSet(FIELDNO("Shipment Method Id"));
                        RegisterFieldSet(FIELDNO("Shipment Method Code"));
                    end;
                }
                field(salesperson; "Salesperson Code")
                {
                    ApplicationArea = All;
                    Caption = 'salesperson', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Salesperson Code"));
                    end;
                }
                field(pricesIncludeTax; "Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'pricesIncludeTax', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Prices Including VAT"));
                    end;
                }
                part(salesCreditMemoLines; 20046)
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    EntityName = 'salesCreditMemoLine';
                    EntitySetName = 'salesCreditMemoLines';
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
                        DiscountAmountSet := TRUE;
                        InvoiceDiscountAmount := "Invoice Discount Amount";
                    end;
                }
                field(discountAppliedBeforeTax; "Discount Applied Before Tax")
                {
                    ApplicationArea = All;
                    Caption = 'discountAppliedBeforeTax', Locked = true;
                    Editable = false;
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
                    ToolTip = 'Specifies the total tax amount for the sales credit memo.';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Total Tax Amount"));
                    end;
                }
                field(totalAmountIncludingTax; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountIncludingTax', Locked = true;
                    Editable = false;

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
                    ToolTip = 'Specifies the status of the Sales Credit Memo (cancelled, paid, on hold, created).';
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                    Editable = false;
                }
                field(invoiceId; InvoiceId)
                {
                    ApplicationArea = All;
                    Caption = 'invoiceId', Locked = true;

                    trigger OnValidate()
                    var
                        SalesInvoiceHeader: Record "Sales Invoice Header";
                        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
                        EmptyGuid: Guid;
                    begin
                        IF InvoiceId = EmptyGuid THEN BEGIN
                            "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                            CLEAR("Applies-to Doc. No.");
                            CLEAR(InvoiceNo);
                            RegisterFieldSet(FIELDNO("Applies-to Doc. Type"));
                            RegisterFieldSet(FIELDNO("Applies-to Doc. No."));
                            EXIT;
                        END;

                        IF NOT SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(InvoiceId, SalesInvoiceHeader) THEN
                            ERROR(InvoiceIdDoesNotMatchAnInvoiceErr);

                        "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
                        "Applies-to Doc. No." := SalesInvoiceHeader."No.";
                        InvoiceNo := "Applies-to Doc. No.";
                        RegisterFieldSet(FIELDNO("Applies-to Doc. Type"));
                        RegisterFieldSet(FIELDNO("Applies-to Doc. No."));
                    end;
                }
                field(invoiceNumber; "Applies-to Doc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        IF InvoiceNo <> '' THEN BEGIN
                            IF "Applies-to Doc. No." <> InvoiceNo THEN
                                ERROR(InvoiceValuesDontMatchErr);
                            EXIT;
                        END;

                        "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;

                        RegisterFieldSet(FIELDNO("Applies-to Doc. Type"));
                        RegisterFieldSet(FIELDNO("Applies-to Doc. No."));
                    end;
                }
                field(phoneNumber; "Sell-to Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'phoneNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Sell-to Phone No."));
                    end;
                }
                field(email; "Sell-to E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FIELDNO("Sell-to E-Mail"));
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
        if not Posted then
            if HasWritePermissionForDraft then
                GraphMgtSalCrMemoBuf.RedistributeCreditMemoDiscounts(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        GraphMgtSalCrMemoBuf.PropagateOnDelete(Rec);

        EXIT(FALSE);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CheckSellToCustomerSpecified();
        ProcessSellingPostalAddressOnInsert();
        ProcessBillingPostalAddressOnInsert();

        GraphMgtSalCrMemoBuf.PropagateOnInsert(Rec, TempFieldBuffer);
        SetDates();

        UpdateDiscount();

        SetCalculatedFields();

        EXIT(FALSE);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        IF xRec.Id <> Id THEN
            ERROR(CannotChangeIDErr);

        ProcessSellingPostalAddressOnModify();
        ProcessBillingPostalAddressOnModify();

        GraphMgtSalCrMemoBuf.PropagateOnModify(Rec, TempFieldBuffer);
        UpdateDiscount();

        SetCalculatedFields();

        EXIT(FALSE);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
    end;

    trigger OnOpenPage()
    begin
        SetPemissionsFilters();
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        SellToCustomer: Record "Customer";
        BillToCustomer: Record "Customer";
        Currency: Record "Currency";
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        GraphMgtSalesCreditMemo: Codeunit "Graph Mgt - Sales Credit Memo";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        CurrencyCodeTxt: Text;
        SellingPostalAddressJSONText: Text;
        BillingPostalAddressJSONText: Text;
        SellingPostalAddressSet: Boolean;
        BillingPostalAddressSet: Boolean;
        CannotChangeIDErr: Label 'The id cannot be changed.', Locked = true;
        CouldNotFindSellToCustomerErr: Label 'The sell-to customer cannot be found.', Locked = true;
        CouldNotFindBillToCustomerErr: Label 'The bill-to customer cannot be found.', Locked = true;
        SellToCustomerNotProvidedErr: Label 'A customerNumber or a customerId must be provided.', Locked = true;
        SellToCustomerValuesDontMatchErr: Label 'The sell-to customer values do not match to a specific Customer.', Locked = true;
        BillToCustomerValuesDontMatchErr: Label 'The bill-to customer values do not match to a specific Customer.', Locked = true;
        DiscountAmountSet: Boolean;
        InvoiceDiscountAmount: Decimal;
        InvoiceId: Guid;
        InvoiceNo: Code[20];
        InvoiceValuesDontMatchErr: Label 'The invoiceId and invoiceNumber do not match to a specific Invoice.', Locked = true;
        InvoiceIdDoesNotMatchAnInvoiceErr: Label 'The invoiceId does not match to an Invoice.', Locked = true;
        SellToContactIdHasToHaveValueErr: Label 'Sell-to ontact Id must have a value set.', Locked = true;
        CurrencyValuesDontMatchErr: Label 'The currency values do not match to a specific Currency.', Locked = true;
        CurrencyIdDoesNotMatchACurrencyErr: Label 'The "currencyId" does not match to a Currency.', Locked = true;
        CurrencyCodeDoesNotMatchACurrencyErr: Label 'The "currencyCode" does not match to a Currency.', Locked = true;
        PaymentTermsIdDoesNotMatchAPaymentTermsErr: Label 'The "paymentTermsId" does not match to a Payment Terms.', Locked = true;
        ShipmentMethodIdDoesNotMatchAShipmentMethodErr: Label 'The "shipmentMethodId" does not match to a Shipment Method.', Locked = true;
        PostedCreditMemoActionErr: Label 'The action can be applied to a posted credit memo only.', Locked = true;
        DraftCreditMemoActionErr: Label 'The action can be applied to a draft credit memo only.', Locked = true;
        CannotFindCreditMemoErr: Label 'The credit memo cannot be found.', Locked = true;
        CancelingCreditMemoFailedInvoiceCreatedAndPostedErr: Label 'Canceling the credit memo failed because of the following error: \\%1\\An invoice is posted.', Locked = true;
        CancelingCreditMemoFailedInvoiceCreatedButNotPostedErr: Label 'Canceling the credit memo failed because of the following error: \\%1\\An invoice is created but not posted.', Locked = true;
        CancelingCreditMemoFailedNothingCreatedErr: Label 'Canceling the credit memo failed because of the following error: \\%1.', Locked = true;
        AlreadyCancelledErr: Label 'The credit memo cannot be cancelled because it has already been canceled.', Locked = true;
        NoLineErr: Label 'Please add at least one line item to the credit memo.', Locked = true;
        BlankGUID: Guid;
        DocumentDateSet: Boolean;
        DocumentDateVar: Date;
        DueDateSet: Boolean;
        DueDateVar: Date;
        HasWritePermissionForDraft: Boolean;

    local procedure SetCalculatedFields()
    var
        GraphMgtSalesCreditMemo: Codeunit "Graph Mgt - Sales Credit Memo";
    begin
        SetInvoiceId();
        SellingPostalAddressJSONText := GraphMgtSalesCreditMemo.SellToCustomerAddressToJSON(Rec);
        BillingPostalAddressJSONText := GraphMgtSalesCreditMemo.BillToCustomerAddressToJSON(Rec);
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");
    end;

    local procedure ClearCalculatedFields()
    begin
        CLEAR(InvoiceId);
        CLEAR(InvoiceNo);
        CLEAR(SellingPostalAddressJSONText);
        CLEAR(BillingPostalAddressJSONText);
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
        TempFieldBuffer."Table ID" := DATABASE::"Sales Cr. Memo Entity Buffer";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.INSERT();
    end;

    local procedure ProcessSellingPostalAddressOnInsert()
    begin
        IF NOT SellingPostalAddressSet THEN
            EXIT;

        GraphMgtSalesCreditMemo.ParseSellToCustomerAddressFromJSON(SellingPostalAddressJSONText, Rec);

        RegisterFieldSet(FIELDNO("Sell-to Address"));
        RegisterFieldSet(FIELDNO("Sell-to Address 2"));
        RegisterFieldSet(FIELDNO("Sell-to City"));
        RegisterFieldSet(FIELDNO("Sell-to Country/Region Code"));
        RegisterFieldSet(FIELDNO("Sell-to Post Code"));
        RegisterFieldSet(FIELDNO("Sell-to County"));
    end;

    local procedure ProcessSellingPostalAddressOnModify()
    begin
        IF NOT SellingPostalAddressSet THEN
            EXIT;

        GraphMgtSalesCreditMemo.ParseSellToCustomerAddressFromJSON(SellingPostalAddressJSONText, Rec);

        IF xRec."Sell-to Address" <> "Sell-to Address" THEN
            RegisterFieldSet(FIELDNO("Sell-to Address"));

        IF xRec."Sell-to Address 2" <> "Sell-to Address 2" THEN
            RegisterFieldSet(FIELDNO("Sell-to Address 2"));

        IF xRec."Sell-to City" <> "Sell-to City" THEN
            RegisterFieldSet(FIELDNO("Sell-to City"));

        IF xRec."Sell-to Country/Region Code" <> "Sell-to Country/Region Code" THEN
            RegisterFieldSet(FIELDNO("Sell-to Country/Region Code"));

        IF xRec."Sell-to Post Code" <> "Sell-to Post Code" THEN
            RegisterFieldSet(FIELDNO("Sell-to Post Code"));

        IF xRec."Sell-to County" <> "Sell-to County" THEN
            RegisterFieldSet(FIELDNO("Sell-to County"));
    end;

    local procedure ProcessBillingPostalAddressOnInsert()
    begin
        IF NOT BillingPostalAddressSet THEN
            EXIT;

        GraphMgtSalesCreditMemo.ParseBillToCustomerAddressFromJSON(BillingPostalAddressJSONText, Rec);

        RegisterFieldSet(FIELDNO("Bill-to Address"));
        RegisterFieldSet(FIELDNO("Bill-to Address 2"));
        RegisterFieldSet(FIELDNO("Bill-to City"));
        RegisterFieldSet(FIELDNO("Bill-to Country/Region Code"));
        RegisterFieldSet(FIELDNO("Bill-to Post Code"));
        RegisterFieldSet(FIELDNO("Bill-to County"));
    end;

    local procedure ProcessBillingPostalAddressOnModify()
    begin
        IF NOT BillingPostalAddressSet THEN
            EXIT;

        GraphMgtSalesCreditMemo.ParseBillToCustomerAddressFromJSON(BillingPostalAddressJSONText, Rec);

        IF xRec."Bill-to Address" <> "Bill-to Address" THEN
            RegisterFieldSet(FIELDNO("Bill-to Address"));

        IF xRec."Bill-to Address 2" <> "Bill-to Address 2" THEN
            RegisterFieldSet(FIELDNO("Bill-to Address 2"));

        IF xRec."Bill-to City" <> "Bill-to City" THEN
            RegisterFieldSet(FIELDNO("Bill-to City"));

        IF xRec."Bill-to Country/Region Code" <> "Bill-to Country/Region Code" THEN
            RegisterFieldSet(FIELDNO("Bill-to Country/Region Code"));

        IF xRec."Bill-to Post Code" <> "Bill-to Post Code" THEN
            RegisterFieldSet(FIELDNO("Bill-to Post Code"));

        IF xRec."Bill-to County" <> "Bill-to County" THEN
            RegisterFieldSet(FIELDNO("Bill-to County"));
    end;

    local procedure UpdateSellToCustomerFromSellToGraphContactId(var Customer: Record Customer)
    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        UpdateCustomer: Boolean;
    begin
        UpdateCustomer := "Sell-to Customer No." = '';
        IF NOT UpdateCustomer THEN BEGIN
            TempFieldBuffer.RESET();
            TempFieldBuffer.SETRANGE("Field ID", FIELDNO("Customer Id"));
            UpdateCustomer := NOT TempFieldBuffer.FINDFIRST();
            TempFieldBuffer.RESET();
        END;

        IF UpdateCustomer THEN BEGIN
            VALIDATE("Customer Id", Customer.Id);
            VALIDATE("Sell-to Customer No.", Customer."No.");
            RegisterFieldSet(FIELDNO("Customer Id"));
            RegisterFieldSet(FIELDNO("Sell-to Customer No."));
        END;

        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(Customer);
    end;

    local procedure CheckSellToCustomerSpecified()
    begin
        IF ("Sell-to Customer No." = '') AND
           ("Customer Id" = BlankGUID)
        THEN
            ERROR(SellToCustomerNotProvidedErr);
    end;

    local procedure SetInvoiceId()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        CLEAR(InvoiceId);

        IF "Applies-to Doc. No." = '' THEN
            EXIT;

        IF SalesInvoiceHeader.GET("Applies-to Doc. No.") THEN
            InvoiceId := SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader);
    end;

    local procedure SetPemissionsFilters()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FilterText: Text;
    begin
        SalesHeader.SETRANGE("Document Type", SalesHeader."Document Type"::"Credit Memo");
        IF NOT SalesHeader.READPERMISSION() THEN
            FilterText := STRSUBSTNO('<>%1&<>%2', Status::Draft, Status::"In Review");

        IF NOT SalesCrMemoHeader.READPERMISSION() THEN BEGIN
            IF FilterText <> '' THEN
                FilterText += '&';
            FilterText +=
              STRSUBSTNO(
                '<>%1&<>%2&<>%3&<>%4', Status::Canceled, Status::Corrective,
                Status::Open, Status::Paid);
        END;

        IF FilterText <> '' THEN BEGIN
            FILTERGROUP(2);
            SETFILTER(Status, FilterText);
            FILTERGROUP(0);
        END;

        HasWritePermissionForDraft := SalesHeader.WRITEPERMISSION();
    end;

    local procedure UpdateDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        IF NOT DiscountAmountSet THEN BEGIN
            GraphMgtSalCrMemoBuf.RedistributeCreditMemoDiscounts(Rec);
            EXIT;
        END;

        SalesHeader.GET(SalesHeader."Document Type"::"Credit Memo", "No.");
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
    end;

    local procedure SetDates()
    var
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
    begin
        IF NOT (DueDateSet OR DocumentDateSet) THEN
            EXIT;

        TempFieldBuffer.RESET();
        TempFieldBuffer.DELETEALL();

        IF DocumentDateSet THEN BEGIN
            "Document Date" := DocumentDateVar;
            RegisterFieldSet(FIELDNO("Document Date"));
        END;

        IF DueDateSet THEN BEGIN
            "Due Date" := DueDateVar;
            RegisterFieldSet(FIELDNO("Due Date"));
        END;

        GraphMgtSalCrMemoBuf.PropagateOnModify(Rec, TempFieldBuffer);
        FIND();
    end;

    local procedure GetPostedCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        if not Posted then
            Error(PostedCreditMemoActionErr);

        if not GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderFromId(Id, SalesCrMemoHeader) then
            Error(CannotFindCreditMemoErr);
    end;

    local procedure GetDraftCreditMemo(var SalesHeader: Record "Sales Header")
    begin
        if Posted then
            Error(DraftCreditMemoActionErr);

        SalesHeader.SetRange(Id, Id);
        if not SalesHeader.FindFirst() then
            Error(CannotFindCreditMemoErr);
    end;

    local procedure CheckCreditMemoCanBeCancelled(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        if IsCreditMemoCancelled() then
            Error(AlreadyCancelledErr);
        CancelPostedSalesCrMemo.TestCorrectCrMemoIsAllowed(SalesCrMemoHeader);
    end;

    local procedure IsCreditMemoCancelled(): Boolean
    begin
        exit(Status = Status::Canceled);
    end;

    local procedure PostCreditMemo(var SalesHeader: Record "Sales Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        PreAssignedNo: Code[20];
    begin
        IF NOT SalesHeader.SalesLinesExist() THEN
            ERROR(NoLineErr);
        LinesInstructionMgt.SalesCheckAllLinesHaveQuantityAssigned(SalesHeader);
        PreAssignedNo := SalesHeader."No.";
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");
        SalesCrMemoHeader.SETCURRENTKEY("Pre-Assigned No.");
        SalesCrMemoHeader.SETRANGE("Pre-Assigned No.", PreAssignedNo);
        SalesCrMemoHeader.FINDFIRST();
    end;

    local procedure CancelCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
    begin
        GetPostedCreditMemo(SalesCrMemoHeader);
        CheckCreditMemoCanBeCancelled(SalesCrMemoHeader);
        if not CODEUNIT.Run(CODEUNIT::"Cancel Posted Sales Cr. Memo", SalesCrMemoHeader) then begin
            SalesInvoiceHeader.SetRange("Applies-to Doc. No.", SalesCrMemoHeader."No.");
            if not SalesInvoiceHeader.IsEmpty() then
                Error(CancelingCreditMemoFailedInvoiceCreatedAndPostedErr, GetLastErrorText());
            SalesHeader.SetRange("Applies-to Doc. No.", SalesCrMemoHeader."No.");
            if not SalesHeader.IsEmpty() then
                Error(CancelingCreditMemoFailedInvoiceCreatedButNotPostedErr, GetLastErrorText());
            Error(CancelingCreditMemoFailedNothingCreatedErr, GetLastErrorText());
        end;
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext; InvoiceId: Guid)
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"APIV1 - Sales Credit Memos");
        ActionContext.AddEntityKey(FieldNo(Id), InvoiceId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Deleted);
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure Post(var ActionContext: WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        GetDraftCreditMemo(SalesHeader);
        PostCreditMemo(SalesHeader, SalesCrMemoHeader);
        SetActionResponse(ActionContext, GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderId(SalesCrMemoHeader));
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure PostAndSend(var ActionContext: WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        APIV1SendSalesDocument: Codeunit "APIV1 - Send Sales Document";
    begin
        GetDraftCreditMemo(SalesHeader);
        PostCreditMemo(SalesHeader, SalesCrMemoHeader);
        Commit();
        APIV1SendSalesDocument.SendCreditMemo(SalesCrMemoHeader);
        SetActionResponse(ActionContext, GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderId(SalesCrMemoHeader));
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure Send(var ActionContext: WebServiceActionContext)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        APIV1SendSalesDocument: Codeunit "APIV1 - Send Sales Document";
    begin
        GetPostedCreditMemo(SalesCrMemoHeader);
        APIV1SendSalesDocument.SendCreditMemo(SalesCrMemoHeader);
        SetActionResponse(ActionContext, GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderId(SalesCrMemoHeader));
        exit;
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure Cancel(var ActionContext: WebServiceActionContext)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        GetPostedCreditMemo(SalesCrMemoHeader);
        CancelCreditMemo(SalesCrMemoHeader);
        SetActionResponse(ActionContext, GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderId(SalesCrMemoHeader));
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure CancelAndSend(var ActionContext: WebServiceActionContext)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        APIV1SendSalesDocument: Codeunit "APIV1 - Send Sales Document";
    begin
        GetPostedCreditMemo(SalesCrMemoHeader);
        CancelCreditMemo(SalesCrMemoHeader);
        APIV1SendSalesDocument.SendCreditMemo(SalesCrMemoHeader);
        SetActionResponse(ActionContext, GraphMgtSalCrMemoBuf.GetSalesCrMemoHeaderId(SalesCrMemoHeader));
    end;
}

