page 5475 "Sales Invoice Entity"
{
    Caption = 'salesInvoices', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'salesInvoice';
    EntitySetName = 'salesInvoices';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Sales Invoice Entity Aggregate";

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
                        RegisterFieldSet(FieldNo("External Document No."));
                    end;
                }
                field(invoiceDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDate', Locked = true;

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
                field(customerPurchaseOrderReference; "Your Reference")
                {
                    ApplicationArea = All;
                    Caption = 'customerPurchaseOrderReference', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Your Reference"));
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
                field(orderId; "Order Id")
                {
                    ApplicationArea = All;
                    Caption = 'orderId', Locked = true;
                    Editable = false;
                }
                field(orderNumber; "Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'orderNumber', Locked = true;
                    Editable = false;
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
                part(salesInvoiceLines; "Sales Invoice Line Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    EntityName = 'salesInvoiceLine';
                    EntitySetName = 'salesInvoiceLines';
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
                    ToolTip = 'Specifies the status of the Sales Invoice (cancelled, paid, on hold, created).';
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                    Editable = false;
                }
                field(phoneNumber; "Sell-to Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'PhoneNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Sell-to Phone No."));
                    end;
                }
                field(email; "Sell-to E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'Email', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Sell-to E-Mail"));
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        SetCalculatedFields;
        if not Posted then
            if HasWritePermissionForDraft then
                SalesInvoiceAggregator.RedistributeInvoiceDiscounts(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        SalesInvoiceAggregator.PropagateOnDelete(Rec);

        exit(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        CheckCustomerSpecified;
        ProcessBillingPostalAddress;

        SalesInvoiceAggregator.PropagateOnInsert(Rec, TempFieldBuffer);
        SetDates;

        UpdateDiscount;

        SetCalculatedFields;

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        if xRec.Id <> Id then
            Error(CannotChangeIDErr);

        ProcessBillingPostalAddress;

        SalesInvoiceAggregator.PropagateOnModify(Rec, TempFieldBuffer);
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
        SetPermissionFilters;
    end;

    var
        CannotChangeIDErr: Label 'The id cannot be changed.', Locked = true;
        TempFieldBuffer: Record "Field Buffer" temporary;
        Customer: Record Customer;
        Currency: Record Currency;
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        LCYCurrencyCode: Code[10];
        CurrencyCodeTxt: Text;
        BillingPostalAddressJSONText: Text;
        BillingPostalAddressSet: Boolean;
        CustomerNotProvidedErr: Label 'A customerNumber or a customerId must be provided.', Locked = true;
        CustomerValuesDontMatchErr: Label 'The customer values do not match to a specific Customer.', Locked = true;
        CouldNotFindCustomerErr: Label 'The customer cannot be found.', Locked = true;
        ContactIdHasToHaveValueErr: Label 'Contact Id must have a value set.', Locked = true;
        CurrencyValuesDontMatchErr: Label 'The currency values do not match to a specific Currency.', Locked = true;
        CurrencyIdDoesNotMatchACurrencyErr: Label 'The "currencyId" does not match to a Currency.', Locked = true;
        CurrencyCodeDoesNotMatchACurrencyErr: Label 'The "currencyCode" does not match to a Currency.', Locked = true;
        BlankGUID: Guid;
        PaymentTermsIdDoesNotMatchAPaymentTermsErr: Label 'The "paymentTermsId" does not match to a Payment Terms.', Locked = true;
        ShipmentMethodIdDoesNotMatchAShipmentMethodErr: Label 'The "shipmentMethodId" does not match to a Shipment Method.', Locked = true;
        DiscountAmountSet: Boolean;
        InvoiceDiscountAmount: Decimal;
        DocumentDateSet: Boolean;
        DocumentDateVar: Date;
        DueDateSet: Boolean;
        DueDateVar: Date;
        PostedInvoiceActionErr: Label 'The action can be applied to a posted invoice only.', Locked = true;
        DraftInvoiceActionErr: Label 'The action can be applied to a draft invoice only.', Locked = true;
        CannotFindInvoiceErr: Label 'The invoice cannot be found.', Locked = true;
        CancelingInvoiceFailedCreditMemoCreatedAndPostedErr: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is posted.', Locked = true;
        CancelingInvoiceFailedCreditMemoCreatedButNotPostedErr: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is created but not posted.', Locked = true;
        CancelingInvoiceFailedNothingCreatedErr: Label 'Canceling the invoice failed because of the following error: \\%1.', Locked = true;
        EmptyEmailErr: Label 'The send-to email is empty. Specify email either for the customer or for the invoice in email preview.', Locked = true;
        AlreadyCanceledErr: Label 'The invoice cannot be canceled because it has already been canceled.', Locked = true;
        MailNotConfiguredErr: Label 'An email account must be configured to send emails.', Locked = true;
        HasWritePermissionForDraft: Boolean;

    local procedure SetCalculatedFields()
    var
        GraphMgtSalesInvoice: Codeunit "Graph Mgt - Sales Invoice";
    begin
        BillingPostalAddressJSONText := GraphMgtSalesInvoice.BillToCustomerAddressToJSON(Rec);
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
        TempFieldBuffer."Table ID" := DATABASE::"Sales Invoice Entity Aggregate";
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
        GraphMgtSalesInvoice: Codeunit "Graph Mgt - Sales Invoice";
    begin
        if not BillingPostalAddressSet then
            exit;

        GraphMgtSalesInvoice.ProcessComplexTypes(Rec, BillingPostalAddressJSONText);

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

    local procedure SetPermissionFilters()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilterText: Text;
    begin
        // Filtering out test documents
        SalesHeader.SetRange(IsTest, false);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        if not SalesHeader.ReadPermission then
            FilterText :=
              StrSubstNo('<>%1&<>%2', Status::Draft, Status::"In Review");

        if not SalesInvoiceHeader.ReadPermission then begin
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
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        if Posted then
            exit;

        if not DiscountAmountSet then begin
            SalesInvoiceAggregator.RedistributeInvoiceDiscounts(Rec);
            exit;
        end;

        SalesHeader.Get("Document Type"::Invoice, "No.");
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
    end;

    local procedure SetDates()
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
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

        SalesInvoiceAggregator.PropagateOnModify(Rec, TempFieldBuffer);
        Find;
    end;

    local procedure GetPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        if not Posted then
            Error(PostedInvoiceActionErr);

        if not SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(Id, SalesInvoiceHeader) then
            Error(CannotFindInvoiceErr);
    end;

    local procedure GetDraftInvoice(var SalesHeader: Record "Sales Header")
    begin
        if Posted then
            Error(DraftInvoiceActionErr);

        SalesHeader.SetRange(Id, Id);
        if not SalesHeader.FindFirst then
            Error(CannotFindInvoiceErr);
    end;

    local procedure CheckSmtpMailSetup()
    var
        O365SetupEmail: Codeunit "O365 Setup Email";
    begin
        if not O365SetupEmail.SMTPEmailIsSetUp then
            Error(MailNotConfiguredErr);
    end;

    local procedure CheckSendToEmailAddress(DocumentNo: Code[20])
    begin
        if GetSendToEmailAddress(DocumentNo) = '' then
            Error(EmptyEmailErr);
    end;

    local procedure GetSendToEmailAddress(DocumentNo: Code[20]): Text[250]
    var
        EmailAddress: Text[250];
    begin
        EmailAddress := GetDocumentEmailAddress(DocumentNo);
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

    local procedure GetDocumentEmailAddress(DocumentNo: Code[20]): Text[250]
    var
        EmailParameter: Record "Email Parameter";
    begin
        if not EmailParameter.Get(DocumentNo, "Document Type", EmailParameter."Parameter Type"::Address) then
            exit('');
        exit(EmailParameter."Parameter Value");
    end;

    local procedure CheckInvoiceCanBeCanceled(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        if IsInvoiceCanceled then
            Error(AlreadyCanceledErr);
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
    end;

    local procedure IsInvoiceCanceled(): Boolean
    begin
        exit(Status = Status::Canceled);
    end;

    local procedure PostInvoice(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        DummyO365SalesDocument: Record "O365 Sales Document";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
        PreAssignedNo: Code[20];
    begin
        O365SendResendInvoice.CheckDocumentIfNoItemsExists(SalesHeader, false, DummyO365SalesDocument);
        LinesInstructionMgt.SalesCheckAllLinesHaveQuantityAssigned(SalesHeader);
        PreAssignedNo := SalesHeader."No.";
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");
        SalesInvoiceHeader.SetCurrentKey("Pre-Assigned No.");
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        SalesInvoiceHeader.FindFirst;
    end;

    local procedure SendPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        GraphIntBusinessProfile: Codeunit "Graph Int - Business Profile";
    begin
        CheckSmtpMailSetup;
        CheckSendToEmailAddress(SalesInvoiceHeader."No.");
        GraphIntBusinessProfile.SyncFromGraphSynchronously;

        SalesInvoiceHeader.SetRecFilter;
        SalesInvoiceHeader.EmailRecords(false);
    end;

    local procedure SendDraftInvoice(var SalesHeader: Record "Sales Header")
    var
        DummyO365SalesDocument: Record "O365 Sales Document";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
        GraphIntBusinessProfile: Codeunit "Graph Int - Business Profile";
    begin
        O365SendResendInvoice.CheckDocumentIfNoItemsExists(SalesHeader, false, DummyO365SalesDocument);
        LinesInstructionMgt.SalesCheckAllLinesHaveQuantityAssigned(SalesHeader);
        CheckSmtpMailSetup;
        CheckSendToEmailAddress(SalesHeader."No.");

        GraphIntBusinessProfile.SyncFromGraphSynchronously;
        SalesHeader.SetRecFilter;
        SalesHeader.EmailRecords(false);
    end;

    local procedure SendCanceledInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
        GraphIntBusinessProfile: Codeunit "Graph Int - Business Profile";
    begin
        CheckSmtpMailSetup;
        CheckSendToEmailAddress(SalesInvoiceHeader."No.");
        GraphIntBusinessProfile.SyncFromGraphSynchronously;

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"O365 Sales Cancel Invoice";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Record ID to Process" := SalesInvoiceHeader.RecordId;
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    local procedure CancelInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
    begin
        GetPostedInvoice(SalesInvoiceHeader);
        CheckInvoiceCanBeCanceled(SalesInvoiceHeader);
        if not CODEUNIT.Run(CODEUNIT::"Correct Posted Sales Invoice", SalesInvoiceHeader) then begin
            SalesCrMemoHeader.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
            if SalesCrMemoHeader.FindFirst then
                Error(CancelingInvoiceFailedCreditMemoCreatedAndPostedErr, GetLastErrorText);
            SalesHeader.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
            if SalesHeader.FindFirst then
                Error(CancelingInvoiceFailedCreditMemoCreatedButNotPostedErr, GetLastErrorText);
            Error(CancelingInvoiceFailedNothingCreatedErr, GetLastErrorText);
        end;
    end;

    local procedure SetActionResponse(var ActionContext: DotNet WebServiceActionContext; InvoiceId: Guid)
    var
        ODataActionManagement: Codeunit "OData Action Management";
    begin
        ODataActionManagement.AddKey(FieldNo(Id), InvoiceId);
        ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Sales Invoice Entity");
    end;

    [ServiceEnabled]
    procedure Post(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        GetDraftInvoice(SalesHeader);
        PostInvoice(SalesHeader, SalesInvoiceHeader);
        SetActionResponse(ActionContext, SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader));
    end;

    [ServiceEnabled]
    procedure PostAndSend(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        GetDraftInvoice(SalesHeader);
        PostInvoice(SalesHeader, SalesInvoiceHeader);
        Commit();
        SendPostedInvoice(SalesInvoiceHeader);
        SetActionResponse(ActionContext, SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader));
    end;

    [ServiceEnabled]
    procedure Send(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        if Posted then begin
            GetPostedInvoice(SalesInvoiceHeader);
            if IsInvoiceCanceled then
                SendCanceledInvoice(SalesInvoiceHeader)
            else
                SendPostedInvoice(SalesInvoiceHeader);
            SetActionResponse(ActionContext, SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader));
            exit;
        end;
        GetDraftInvoice(SalesHeader);
        SendDraftInvoice(SalesHeader);
        SetActionResponse(ActionContext, SalesHeader.Id);
    end;

    [ServiceEnabled]
    procedure Cancel(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        GetPostedInvoice(SalesInvoiceHeader);
        CancelInvoice(SalesInvoiceHeader);
        SetActionResponse(ActionContext, SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader));
    end;

    [ServiceEnabled]
    procedure CancelAndSend(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        GetPostedInvoice(SalesInvoiceHeader);
        CancelInvoice(SalesInvoiceHeader);
        SendCanceledInvoice(SalesInvoiceHeader);
        SetActionResponse(ActionContext, SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader));
    end;
}

