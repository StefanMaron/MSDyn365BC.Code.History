page 5505 "Sales Quote Entity"
{
    Caption = 'salesQuotes', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'salesQuote';
    EntitySetName = 'salesQuotes';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Sales Quote Entity Buffer";

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
                field(externalDocumentNumber; "External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'externalDocumentNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("External Document No."))
                    end;
                }
                field(documentDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'documentDate', Locked = true;

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
                    ToolTip = 'Specifies the billing address of the Sales Invoice.';

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
                part(salesQuoteLines; "Sales Quote Line Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    EntityName = 'salesQuoteLine';
                    EntitySetName = 'salesQuoteLines';
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
                    ToolTip = 'Specifies the total tax amount for the sales invoice.';

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
                    ToolTip = 'Specifies the status of the Sales Quote (Draft,Sent,Accepted).';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo(Status));
                    end;
                }
                field(sentDate; "Quote Sent to Customer")
                {
                    ApplicationArea = All;
                    Caption = 'sentDate', Locked = true;
                }
                field(validUntilDate; "Quote Valid Until Date")
                {
                    ApplicationArea = All;
                    Caption = 'validUntilDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Quote Valid Until Date"));
                    end;
                }
                field(acceptedDate; "Quote Accepted Date")
                {
                    ApplicationArea = All;
                    Caption = 'acceptedDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Quote Accepted Date"));
                    end;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        SetCalculatedFields;
        if HasWritePermission then
            GraphMgtSalesQuoteBuffer.RedistributeInvoiceDiscounts(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        GraphMgtSalesQuoteBuffer.PropagateOnDelete(Rec);

        exit(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        CheckCustomerSpecified;
        ProcessBillingPostalAddress;

        GraphMgtSalesQuoteBuffer.PropagateOnInsert(Rec, TempFieldBuffer);
        SetDates;

        UpdateDiscount;

        SetCalculatedFields;

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        if xRec.Id <> Id then
            Error(CannotChangeIDErr);

        ProcessBillingPostalAddress;

        GraphMgtSalesQuoteBuffer.PropagateOnModify(Rec, TempFieldBuffer);
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
        CheckPermissions;
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        Customer: Record Customer;
        Currency: Record Currency;
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        BillingPostalAddressJSONText: Text;
        CurrencyCodeTxt: Text;
        BillingPostalAddressSet: Boolean;
        CouldNotFindCustomerErr: Label 'The customer cannot be found.', Locked = true;
        ContactIdHasToHaveValueErr: Label 'Contact Id must have a value set.', Locked = true;
        CannotChangeIDErr: Label 'The id cannot be changed.', Locked = true;
        CustomerNotProvidedErr: Label 'A customerNumber or a customerId must be provided.', Locked = true;
        CustomerValuesDontMatchErr: Label 'The customer values do not match to a specific Customer.', Locked = true;
        SalesQuotePermissionsErr: Label 'You do not have permissions to read Sales Quotes.';
        CurrencyValuesDontMatchErr: Label 'The currency values do not match to a specific Currency.', Locked = true;
        CurrencyIdDoesNotMatchACurrencyErr: Label 'The "currencyId" does not match to a Currency.', Locked = true;
        CurrencyCodeDoesNotMatchACurrencyErr: Label 'The "currencyCode" does not match to a Currency.', Locked = true;
        PaymentTermsIdDoesNotMatchAPaymentTermsErr: Label 'The "paymentTermsId" does not match to a Payment Terms.', Locked = true;
        ShipmentMethodIdDoesNotMatchAShipmentMethodErr: Label 'The "shipmentMethodId" does not match to a Shipment Method.', Locked = true;
        DiscountAmountSet: Boolean;
        InvoiceDiscountAmount: Decimal;
        BlankGUID: Guid;
        DocumentDateSet: Boolean;
        DocumentDateVar: Date;
        DueDateSet: Boolean;
        DueDateVar: Date;
        CannotFindQuoteErr: Label 'The quote cannot be found.', Locked = true;
        EmptyEmailErr: Label 'The send-to email is empty. Specify email either for the customer or for the quote in email preview.', Locked = true;
        MailNotConfiguredErr: Label 'An email account must be configured to send emails.', Locked = true;
        HasWritePermission: Boolean;

    local procedure SetCalculatedFields()
    var
        GraphMgtSalesQuote: Codeunit "Graph Mgt - Sales Quote";
    begin
        BillingPostalAddressJSONText := GraphMgtSalesQuote.BillToCustomerAddressToJSON(Rec);
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(BillingPostalAddressJSONText);
        Clear(DiscountAmountSet);
        Clear(InvoiceDiscountAmount);

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
        TempFieldBuffer."Table ID" := DATABASE::"Sales Quote Entity Buffer";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
    end;

    local procedure CheckCustomerSpecified()
    begin
        if ("Sell-to Customer No." = '') and
           ("Customer Id" = BlankGUID)
        then
            Error(CustomerNotProvidedErr);
    end;

    local procedure ProcessBillingPostalAddress()
    var
        GraphMgtSalesQuote: Codeunit "Graph Mgt - Sales Quote";
    begin
        if not BillingPostalAddressSet then
            exit;

        GraphMgtSalesQuote.ProcessComplexTypes(Rec, BillingPostalAddressJSONText);

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

    local procedure CheckPermissions()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        if not SalesHeader.ReadPermission then
            Error(SalesQuotePermissionsErr);

        HasWritePermission := SalesHeader.WritePermission;
    end;

    local procedure UpdateDiscount()
    var
        SalesHeader: Record "Sales Header";
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        if not DiscountAmountSet then begin
            GraphMgtSalesQuoteBuffer.RedistributeInvoiceDiscounts(Rec);
            exit;
        end;

        SalesHeader.Get(SalesHeader."Document Type"::Quote, "No.");
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
    end;

    local procedure SetDates()
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
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

        GraphMgtSalesQuoteBuffer.PropagateOnModify(Rec, TempFieldBuffer);
        Find;
    end;

    local procedure GetQuote(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRange(Id, Id);
        if not SalesHeader.FindFirst then
            Error(CannotFindQuoteErr);
    end;

    local procedure CheckSmtpMailSetup()
    var
        O365SetupEmail: Codeunit "O365 Setup Email";
    begin
        if not O365SetupEmail.SMTPEmailIsSetUp then
            Error(MailNotConfiguredErr);
    end;

    local procedure CheckSendToEmailAddress()
    begin
        if GetSendToEmailAddress = '' then
            Error(EmptyEmailErr);
    end;

    local procedure GetSendToEmailAddress(): Text[250]
    var
        EmailAddress: Text[250];
    begin
        EmailAddress := GetDocumentEmailAddress;
        if EmailAddress <> '' then
            exit(EmailAddress);
        EmailAddress := GetCustomerEmailAddress;
        exit(EmailAddress);
    end;

    local procedure GetCustomerEmailAddress(): Text[250]
    begin
        if not Customer.Get("Sell-to Customer No.") then
            exit('');
        exit(Customer."E-Mail");
    end;

    local procedure GetDocumentEmailAddress(): Text[250]
    var
        EmailParameter: Record "Email Parameter";
    begin
        if not EmailParameter.Get("No.", "Document Type", EmailParameter."Parameter Type"::Address) then
            exit('');
        exit(EmailParameter."Parameter Value");
    end;

    local procedure SendQuote(var SalesHeader: Record "Sales Header")
    var
        DummyO365SalesDocument: Record "O365 Sales Document";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
        GraphIntBusinessProfile: Codeunit "Graph Int - Business Profile";
    begin
        O365SendResendInvoice.CheckDocumentIfNoItemsExists(SalesHeader, false, DummyO365SalesDocument);
        LinesInstructionMgt.SalesCheckAllLinesHaveQuantityAssigned(SalesHeader);
        CheckSmtpMailSetup;
        CheckSendToEmailAddress;
        GraphIntBusinessProfile.SyncFromGraphSynchronously;

        SalesHeader.SetRecFilter;
        SalesHeader.EmailRecords(false);
    end;

    local procedure SetActionResponse(var ActionContext: DotNet WebServiceActionContext; var SalesHeader: Record "Sales Header")
    var
        ODataActionManagement: Codeunit "OData Action Management";
    begin
        ODataActionManagement.AddKey(FieldNo(Id), SalesHeader.Id);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Sales Invoice Entity")
        else
            ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Sales Quote Entity");
    end;

    [ServiceEnabled]
    procedure MakeInvoice(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
        SalesQuoteToInvoice: Codeunit "Sales-Quote to Invoice";
    begin
        GetQuote(SalesHeader);
        SalesHeader.SetRecFilter;
        SalesQuoteToInvoice.Run(SalesHeader);
        SalesQuoteToInvoice.GetSalesInvoiceHeader(SalesHeader);
        SetActionResponse(ActionContext, SalesHeader);
    end;

    [ServiceEnabled]
    procedure Send(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
    begin
        GetQuote(SalesHeader);
        SendQuote(SalesHeader);
        SetActionResponse(ActionContext, SalesHeader);
    end;
}

