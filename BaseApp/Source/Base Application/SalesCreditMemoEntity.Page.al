page 5507 "Sales Credit Memo Entity"
{
    Caption = 'salesCreditMemos', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'salesCreditMemo';
    EntitySetName = 'salesCreditMemos';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Sales Cr. Memo Entity Buffer";

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
                    Caption = 'number', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("No."));
                    end;
                }
                field(externalDocumentNumber; "External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'externalDocumentNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("External Document No."))
                    end;
                }
                field(creditMemoDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'creditMemoDate', Locked = true;

                    trigger OnValidate()
                    begin
                        DocumentDateVar := "Document Date";
                        DocumentDateSet := true;

                        RegisterFieldSet(FieldNo("Document Date"));
                    end;
                }
                field(dueDate; "Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'dueDate', Locked = true;

                    trigger OnValidate()
                    begin
                        DueDateVar := "Due Date";
                        DueDateSet := true;

                        RegisterFieldSet(FieldNo("Due Date"));
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
                        Customer.SetRange(Id, "Customer Id");
                        if not Customer.FindFirst then
                            Error(CouldNotFindCustomerErr);

                        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(Customer);

                        "Sell-to Customer No." := Customer."No.";
                        RegisterFieldSet(FieldNo("Customer Id"));
                        RegisterFieldSet(FieldNo("Sell-to Customer No."));
                    end;
                }
                field(contactId; "Contact Graph Id")
                {
                    ApplicationArea = All;
                    Caption = 'contactId', Locked = true;

                    trigger OnValidate()
                    var
                        Contact: Record Contact;
                        Customer: Record Customer;
                        GraphIntContact: Codeunit "Graph Int. - Contact";
                    begin
                        RegisterFieldSet(FieldNo("Contact Graph Id"));

                        if "Contact Graph Id" = '' then
                            Error(ContactIdHasToHaveValueErr);

                        if not GraphIntContact.FindOrCreateCustomerFromGraphContactSafe("Contact Graph Id", Customer, Contact) then
                            exit;

                        UpdateCustomerFromGraphContactId(Customer);

                        if Contact."Company No." = Customer."No." then begin
                            Validate("Sell-to Contact No.", Contact."No.");
                            Validate("Sell-to Contact", Contact.Name);

                            RegisterFieldSet(FieldNo("Sell-to Contact No."));
                            RegisterFieldSet(FieldNo("Sell-to Contact"));
                        end;
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
                        if Customer."No." <> '' then begin
                            if Customer."No." <> "Sell-to Customer No." then
                                Error(CustomerValuesDontMatchErr);
                            exit;
                        end;

                        if not Customer.Get("Sell-to Customer No.") then
                            Error(CouldNotFindCustomerErr);

                        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(Customer);

                        "Customer Id" := Customer.Id;
                        RegisterFieldSet(FieldNo("Customer Id"));
                        RegisterFieldSet(FieldNo("Sell-to Customer No."));
                    end;
                }
                field(customerName; "Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Caption = 'customerName', Locked = true;
                    Editable = false;
                }
                field(billingPostalAddress; BillingPostalAddressJSONText)
                {
                    ApplicationArea = All;
                    Caption = 'billingPostalAddress', Locked = true;
                    ODataEDMType = 'POSTALADDRESS';
                    ToolTip = 'Specifies the billing address of the Sales Credit Memo.';

                    trigger OnValidate()
                    begin
                        BillingPostalAddressSet := true;
                    end;
                }
                field(currencyId; "Currency Id")
                {
                    ApplicationArea = All;
                    Caption = 'CurrencyId', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Currency Id" = BlankGUID then
                            "Currency Code" := ''
                        else begin
                            Currency.SetRange(Id, "Currency Id");
                            if not Currency.FindFirst then
                                Error(CurrencyIdDoesNotMatchACurrencyErr);

                            "Currency Code" := Currency.Code;
                        end;

                        RegisterFieldSet(FieldNo("Currency Id"));
                        RegisterFieldSet(FieldNo("Currency Code"));
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

                        if Currency.Code <> '' then begin
                            if Currency.Code <> "Currency Code" then
                                Error(CurrencyValuesDontMatchErr);
                            exit;
                        end;

                        if "Currency Code" = '' then
                            "Currency Id" := BlankGUID
                        else begin
                            if not Currency.Get("Currency Code") then
                                Error(CurrencyCodeDoesNotMatchACurrencyErr);

                            "Currency Id" := Currency.Id;
                        end;

                        RegisterFieldSet(FieldNo("Currency Id"));
                        RegisterFieldSet(FieldNo("Currency Code"));
                    end;
                }
                field(paymentTermsId; "Payment Terms Id")
                {
                    ApplicationArea = All;
                    Caption = 'PaymentTermsId', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Payment Terms Id" = BlankGUID then
                            "Payment Terms Code" := ''
                        else begin
                            PaymentTerms.SetRange(Id, "Payment Terms Id");
                            if not PaymentTerms.FindFirst then
                                Error(PaymentTermsIdDoesNotMatchAPaymentTermsErr);

                            "Payment Terms Code" := PaymentTerms.Code;
                        end;

                        RegisterFieldSet(FieldNo("Payment Terms Id"));
                        RegisterFieldSet(FieldNo("Payment Terms Code"));
                    end;
                }
                field(shipmentMethodId; "Shipment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'ShipmentMethodId', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Shipment Method Id" = BlankGUID then
                            "Shipment Method Code" := ''
                        else begin
                            ShipmentMethod.SetRange(Id, "Shipment Method Id");
                            if not ShipmentMethod.FindFirst then
                                Error(ShipmentMethodIdDoesNotMatchAShipmentMethodErr);

                            "Shipment Method Code" := ShipmentMethod.Code;
                        end;

                        RegisterFieldSet(FieldNo("Shipment Method Id"));
                        RegisterFieldSet(FieldNo("Shipment Method Code"));
                    end;
                }
                field(salesperson; "Salesperson Code")
                {
                    ApplicationArea = All;
                    Caption = 'salesperson', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Salesperson Code"));
                    end;
                }
                field(pricesIncludeTax; "Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'pricesIncludeTax', Locked = true;
                    Editable = false;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Prices Including VAT"));
                    end;
                }
                part(salesCreditMemoLines; "Sales Credit Memo Line Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    EntityName = 'salesCreditMemoLine';
                    EntitySetName = 'salesCreditMemoLines';
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
                        DiscountAmountSet := true;
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
                        RegisterFieldSet(FieldNo("Total Tax Amount"));
                    end;
                }
                field(totalAmountIncludingTax; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountIncludingTax', Locked = true;
                    Editable = false;

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
                        EmptyGuid: Guid;
                    begin
                        if InvoiceId = EmptyGuid then begin
                            "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                            Clear("Applies-to Doc. No.");
                            Clear(InvoiceNo);
                            RegisterFieldSet(FieldNo("Applies-to Doc. Type"));
                            RegisterFieldSet(FieldNo("Applies-to Doc. No."));
                            exit;
                        end;

                        SalesInvoiceHeader.SetRange(Id, InvoiceId);
                        if not SalesInvoiceHeader.FindFirst then
                            Error(InvoiceIdDoesNotMatchAnInvoiceErr);

                        "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
                        "Applies-to Doc. No." := SalesInvoiceHeader."No.";
                        InvoiceNo := "Applies-to Doc. No.";
                        RegisterFieldSet(FieldNo("Applies-to Doc. Type"));
                        RegisterFieldSet(FieldNo("Applies-to Doc. No."));
                    end;
                }
                field(invoiceNumber; "Applies-to Doc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        if InvoiceNo <> '' then begin
                            if "Applies-to Doc. No." <> InvoiceNo then
                                Error(InvoiceValuesDontMatchErr);
                            exit;
                        end;

                        "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;

                        RegisterFieldSet(FieldNo("Applies-to Doc. Type"));
                        RegisterFieldSet(FieldNo("Applies-to Doc. No."));
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
        if not Posted then
            if HasWritePermissionForDraft then
                GraphMgtSalCrMemoBuf.RedistributeCreditMemoDiscounts(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        GraphMgtSalCrMemoBuf.PropagateOnDelete(Rec);

        exit(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CheckCustomerSpecified;
        ProcessBillingPostalAddress;

        GraphMgtSalCrMemoBuf.PropagateOnInsert(Rec, TempFieldBuffer);
        SetDates;

        UpdateDiscount;

        SetCalculatedFields;

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if xRec.Id <> Id then
            Error(CannotChangeIDErr);

        ProcessBillingPostalAddress;

        GraphMgtSalCrMemoBuf.PropagateOnModify(Rec, TempFieldBuffer);
        UpdateDiscount;

        SetCalculatedFields;

        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields;
    end;

    trigger OnOpenPage()
    begin
        SetPemissionsFilters;
    end;

    var
        CannotChangeIDErr: Label 'The id cannot be changed.', Locked = true;
        TempFieldBuffer: Record "Field Buffer" temporary;
        Customer: Record Customer;
        Currency: Record Currency;
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        GraphMgtSalesCreditMemo: Codeunit "Graph Mgt - Sales Credit Memo";
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        CurrencyCodeTxt: Text;
        BillingPostalAddressJSONText: Text;
        BillingPostalAddressSet: Boolean;
        CouldNotFindCustomerErr: Label 'The customer cannot be found.', Locked = true;
        CustomerNotProvidedErr: Label 'A customerNumber or a customerId must be provided.', Locked = true;
        CustomerValuesDontMatchErr: Label 'The customer values do not match to a specific Customer.', Locked = true;
        DiscountAmountSet: Boolean;
        InvoiceDiscountAmount: Decimal;
        InvoiceId: Guid;
        InvoiceNo: Code[20];
        InvoiceValuesDontMatchErr: Label 'The invoiceId and invoiceNumber do not match to a specific Invoice.', Locked = true;
        InvoiceIdDoesNotMatchAnInvoiceErr: Label 'The invoiceId does not match to an Invoice.', Locked = true;
        ContactIdHasToHaveValueErr: Label 'Contact Id must have a value set.';
        CurrencyValuesDontMatchErr: Label 'The currency values do not match to a specific Currency.', Locked = true;
        CurrencyIdDoesNotMatchACurrencyErr: Label 'The "currencyId" does not match to a Currency.', Locked = true;
        CurrencyCodeDoesNotMatchACurrencyErr: Label 'The "currencyCode" does not match to a Currency.', Locked = true;
        PaymentTermsIdDoesNotMatchAPaymentTermsErr: Label 'The "paymentTermsId" does not match to a Payment Terms.', Locked = true;
        ShipmentMethodIdDoesNotMatchAShipmentMethodErr: Label 'The "shipmentMethodId" does not match to a Shipment Method.', Locked = true;
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
        SetInvoiceId;
        BillingPostalAddressJSONText := GraphMgtSalesCreditMemo.BillToCustomerAddressToJSON(Rec);
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(InvoiceId);
        Clear(InvoiceNo);
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
        TempFieldBuffer."Table ID" := DATABASE::"Sales Cr. Memo Entity Buffer";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure ProcessBillingPostalAddress()
    begin
        if not BillingPostalAddressSet then
            exit;

        GraphMgtSalesCreditMemo.ProcessComplexTypes(Rec, BillingPostalAddressJSONText);

        if xRec."Sell-to Address" <> "Sell-to Address" then
            RegisterFieldSet(FieldNo("Sell-to Address"));

        if xRec."Sell-to Address 2" <> "Sell-to Address 2" then
            RegisterFieldSet(FieldNo("Sell-to Address 2"));

        if xRec."Sell-to City" <> "Sell-to City" then
            RegisterFieldSet(FieldNo("Sell-to City"));

        if xRec."Sell-to Country/Region Code" <> "Sell-to Country/Region Code" then
            RegisterFieldSet(FieldNo("Sell-to Country/Region Code"));

        if xRec."Sell-to Post Code" <> "Sell-to Post Code" then
            RegisterFieldSet(FieldNo("Sell-to Post Code"));

        if xRec."Sell-to County" <> "Sell-to County" then
            RegisterFieldSet(FieldNo("Sell-to County"));
    end;

    local procedure UpdateCustomerFromGraphContactId(var Customer: Record Customer)
    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        UpdateCustomer: Boolean;
    begin
        UpdateCustomer := "Sell-to Customer No." = '';
        if not UpdateCustomer then begin
            TempFieldBuffer.Reset();
            TempFieldBuffer.SetRange("Field ID", FieldNo("Customer Id"));
            UpdateCustomer := not TempFieldBuffer.FindFirst;
            TempFieldBuffer.Reset();
        end;

        if UpdateCustomer then begin
            Validate("Customer Id", Customer.Id);
            Validate("Sell-to Customer No.", Customer."No.");
            RegisterFieldSet(FieldNo("Customer Id"));
            RegisterFieldSet(FieldNo("Sell-to Customer No."));
        end;

        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(Customer);
    end;

    local procedure CheckCustomerSpecified()
    begin
        if ("Sell-to Customer No." = '') and
           ("Customer Id" = BlankGUID)
        then
            Error(CustomerNotProvidedErr);
    end;

    local procedure SetInvoiceId()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        Clear(InvoiceId);

        if "Applies-to Doc. No." = '' then
            exit;

        if SalesInvoiceHeader.Get("Applies-to Doc. No.") then
            InvoiceId := SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader);
    end;

    local procedure SetPemissionsFilters()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FilterText: Text;
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        if not SalesHeader.ReadPermission then
            FilterText := StrSubstNo('<>%1&<>%2', Status::Draft, Status::"In Review");

        if not SalesCrMemoHeader.ReadPermission then begin
            if FilterText <> '' then
                FilterText += '&';
            FilterText +=
              StrSubstNo(
                '<>%1&<>%2&<>%3&<>%4', Status::Canceled, Status::Corrective,
                Status::Open, Status::Paid);
        end;

        if FilterText <> '' then begin
            FilterGroup(2);
            SetFilter(Status, FilterText);
            FilterGroup(0);
        end;

        HasWritePermissionForDraft := SalesHeader.WritePermission;
    end;

    local procedure UpdateDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        if not DiscountAmountSet then begin
            GraphMgtSalCrMemoBuf.RedistributeCreditMemoDiscounts(Rec);
            exit;
        end;

        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", "No.");
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
    end;

    local procedure SetDates()
    var
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
    begin
        if not (DueDateSet or DocumentDateSet) then
            exit;

        TempFieldBuffer.Reset();
        TempFieldBuffer.DeleteAll();

        if DocumentDateSet then begin
            "Document Date" := DocumentDateVar;
            RegisterFieldSet(FieldNo("Document Date"));
        end;

        if DueDateSet then begin
            "Due Date" := DueDateVar;
            RegisterFieldSet(FieldNo("Due Date"));
        end;

        GraphMgtSalCrMemoBuf.PropagateOnModify(Rec, TempFieldBuffer);
        Find;
    end;
}

