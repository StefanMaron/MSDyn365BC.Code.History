#if not CLEAN20
page 2812 "Native - Sales Quotes"
{
    Caption = 'nativeInvoicingSalesQuotes', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    PageType = List;
    SourceTable = "Sales Quote Entity Buffer";
    ObsoleteState = Pending;
    ObsoleteReason = 'These objects will be removed';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("No."));
                    end;
                }
                field(quoteDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'quoteDate', Locked = true;

                    trigger OnValidate()
                    begin
                        DocumentDateVar := "Document Date";
                        DocumentDateSet := true;

                        RegisterFieldSet(FieldNo("Document Date"));
                        RegisterFieldSet(FieldNo("Posting Date"));
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
                field(validUntilDate; "Quote Valid Until Date")
                {
                    ApplicationArea = All;
                    Caption = 'validUntilDate', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Quote Valid Until Date"));
                    end;
                }
                field(status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the status of the Sales Quote (Draft,Sent,Accepted,Expired).';
                }
                field(accepted; "Quote Accepted")
                {
                    ApplicationArea = All;
                    Caption = 'accepted';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Quote Accepted"));
                    end;
                }
                field(acceptedDate; "Quote Accepted Date")
                {
                    ApplicationArea = All;
                    Caption = 'acceptedDate', Locked = true;
                }
                field(customerId; "Customer Id")
                {
                    ApplicationArea = All;
                    Caption = 'customerId', Locked = true;

                    trigger OnValidate()
                    var
                        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
                    begin
                        if not Customer.GetBySystemId("Customer Id") then
                            Error(CannotFindCustomerErr);

                        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(Customer);

                        "Sell-to Customer No." := Customer."No.";
                        RegisterFieldSet(FieldNo("Customer Id"));
                        RegisterFieldSet(FieldNo("Sell-to Customer No."));
                        CustomerIdSet := true;
                    end;
                }
                field(graphContactId; "Contact Graph Id")
                {
                    ApplicationArea = All;
                    Caption = 'contactId', Locked = true;

                    trigger OnValidate()
                    var
                        Contact: Record Contact;
                        Customer: Record Customer;
                    begin
                        if ("Contact Graph Id" = '') and CustomerIdSet then
                            exit;

                        RegisterFieldSet(FieldNo("Contact Graph Id"));

                        if "Contact Graph Id" = '' then
                            Error(ContactIdHasToHaveValueErr);

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
                        if Customer."No." <> '' then
                            exit;

                        if not Customer.Get("Sell-to Customer No.") then
                            Error(CannotFindCustomerErr);

                        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(Customer);

                        "Customer Id" := Customer.SystemId;
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
                field(customerEmail; CustomerEmail)
                {
                    ApplicationArea = All;
                    Caption = 'customerEmail', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the email address of the customer';
                }
                field(taxLiable; "Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'taxLiable';
                    Importance = Additional;
                    ToolTip = 'Specifies if the sales invoice contains sales tax.';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Tax Liable"));
                    end;
                }
                field(taxAreaId; "Tax Area ID")
                {
                    ApplicationArea = All;
                    Caption = 'taxAreaId';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Tax Area ID"));

                        if IsUsingVAT() then
                            RegisterFieldSet(FieldNo("VAT Bus. Posting Group"))
                        else
                            RegisterFieldSet(FieldNo("Tax Area Code"));
                    end;
                }
                field(taxAreaDisplayName; TaxAreaDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'taxAreaDisplayName';
                    Editable = false;
                    ToolTip = 'Specifies the tax area display name.';
                }
                field(taxRegistrationNumber; "VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'taxRegistrationNumber';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("VAT Registration No."));
                    end;
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
                field(shipmentMethod; "Shipment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'shipmentMethod', Locked = true;

                    trigger OnValidate()
                    begin
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
                field(currencyCode; CurrencyCodeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'currencyCode', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the currency code.';
                }
                field(lines; SalesQuoteLinesJSON)
                {
                    ApplicationArea = All;
                    Caption = 'lines', Locked = true;
                    ODataEDMType = 'Collection(NATIVE-SALESQUOTE-LINE)';
                    ToolTip = 'Specifies Sales Invoice Lines';

                    trigger OnValidate()
                    begin
                        SalesLinesSet := PreviousSalesQuoteLinesJSON <> SalesQuoteLinesJSON;
                    end;
                }
                field(subtotalAmount; "Subtotal Amount")
                {
                    ApplicationArea = All;
                    Caption = 'subtotalAmount';
                    Editable = false;
                }
                field(discountAmount; "Invoice Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'discountAmount', Locked = true;
                    Editable = false;
                }
                field(discountAppliedBeforeTax; "Discount Applied Before Tax")
                {
                    ApplicationArea = All;
                    Caption = 'discountAppliedBeforeTax', Locked = true;
                }
                field(coupons; CouponsJSON)
                {
                    ApplicationArea = All;
                    Caption = 'coupons', Locked = true;
                    ODataEDMType = 'Collection(NATIVE-SALESDOCUMENT-COUPON)';
                    ToolTip = 'Specifies Sales Invoice Coupons.';

                    trigger OnValidate()
                    begin
                        CouponsSet := PreviousCouponsJSON <> CouponsJSON;
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
                field(noteForCustomer; WorkDescription)
                {
                    ApplicationArea = All;
                    Caption = 'noteForCustomer';
                    ToolTip = 'Specifies the note for the customer.';

                    trigger OnValidate()
                    begin
                        NoteForCustomerSet := true;
                    end;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                    Editable = false;
                }
                field(attachments; AttachmentsJSON)
                {
                    ApplicationArea = All;
                    Caption = 'attachments', Locked = true;
                    ODataEDMType = 'Collection(NATIVE-ATTACHMENT)';
                    ToolTip = 'Specifies Attachments';

                    trigger OnValidate()
                    begin
                        IsAttachmentsSet := AttachmentsJSON <> PreviousAttachmentsJSON;
                    end;
                }
                field(invoiceDiscountCalculation; "Invoice Discount Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDiscountCalculation';
                    OptionCaption = ',%,Amount', Locked = true;

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Invoice Discount Calculation"));
                        DiscountAmountSet := true;
                    end;
                }
                field(invoiceDiscountValue; "Invoice Discount Value")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDiscountValue';

                    trigger OnValidate()
                    begin
                        RegisterFieldSet(FieldNo("Invoice Discount Value"));
                        DiscountAmountSet := true;
                    end;
                }
                field(lastEmailSentStatus; LastEmailSentStatus)
                {
                    ApplicationArea = All;
                    Caption = 'lastEmailSentStatus', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the status of the last sent email, Not Sent, In Process, Finished, or Error.';
                }
                field(lastEmailSentTime; LastEmailSentTime)
                {
                    ApplicationArea = All;
                    Caption = 'lastEmailSentTime', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the time that the last email was sent.';
                }
                field(isCustomerBlocked; IsCustomerBlocked)
                {
                    ApplicationArea = All;
                    Caption = 'isCustomerBlocked', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies if the customer is blocked.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        SalesHeader: Record "Sales Header";
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if not GetParentRecordNativeInvoicing(SalesHeader) then begin
            GraphMgtGeneralTools.CleanAggregateWithoutParent(Rec);
            exit;
        end;

        SetCalculatedFields(SalesHeader);
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
        SalesHeader: Record "Sales Header";
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        CheckCustomer();
        ProcessBillingPostalAddress();

        GraphMgtSalesQuoteBuffer.PropagateOnInsert(Rec, TempFieldBuffer);
        SetDates();

        UpdateAttachments();
        UpdateLines();
        UpdateDiscount();
        UpdateCoupons();
        SetNoteForCustomer();

        if not GetParentRecordNativeInvoicing(SalesHeader) then
            Error(AggregateParentIsMissingErr);

        SetCalculatedFields(SalesHeader);

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        SalesHeader: Record "Sales Header";
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        if xRec.Id <> Id then
            Error(CannotChangeIDErr);

        ProcessBillingPostalAddress();

        GraphMgtSalesQuoteBuffer.PropagateOnModify(Rec, TempFieldBuffer);

        UpdateAttachments();
        UpdateLines();
        UpdateDiscount();
        UpdateCoupons();
        SetNoteForCustomer();

        if not GetParentRecordNativeInvoicing(SalesHeader) then
            Error(AggregateParentIsMissingErr);

        SetCalculatedFields(SalesHeader);

        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields();
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(NativeAPILanguageHandler);
        SelectLatestVersion();
    end;

    var
        TempFieldBuffer: Record "Field Buffer" temporary;
        Customer: Record Customer;
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        BillingPostalAddressJSONText: Text;
        CustomerEmail: Text;
        SalesQuoteLinesJSON: Text;
        PreviousSalesQuoteLinesJSON: Text;
        CouponsJSON: Text;
        PreviousCouponsJSON: Text;
        AttachmentsJSON: Text;
        TaxAreaDisplayName: Text;
        PreviousAttachmentsJSON: Text;
        BillingPostalAddressSet: Boolean;
        CannotFindCustomerErr: Label 'The customer cannot be found.';
        ContactIdHasToHaveValueErr: Label 'Contact Id must have a value set.';
        CannotChangeIDErr: Label 'The id cannot be changed.';
        SalesLinesSet: Boolean;
        CouponsSet: Boolean;
        DiscountAmountSet: Boolean;
        IsAttachmentsSet: Boolean;
        InvoiceDiscountAmount: Decimal;
        WorkDescription: Text;
        CustomerNotProvidedErr: Label 'A customerNumber or a customerID must be provided.';
        NoteForCustomerSet: Boolean;
        DocumentDateSet: Boolean;
        DocumentDateVar: Date;
        DueDateSet: Boolean;
        DueDateVar: Date;
        CannotFindQuoteErr: Label 'The quote cannot be found.';
        EmptyEmailErr: Label 'The send-to email is empty. Specify email either for the customer or for the quote in email preview.';
        InvoiceDiscountPctMustBePositiveErr: Label 'Invoice discount percentage must be positive.';
        InvoiceDiscountPctMustBeBelowHundredErr: Label 'Invoice discount percentage must be below 100.';
        InvoiceDiscountAmtMustBePositiveErr: Label 'Invoice discount must be positive.';
        CustomerIdSet: Boolean;
        LastEmailSentTime: DateTime;
        LastEmailSentStatus: Option "Not Sent","In Process",Finished,Error;
        AggregateParentIsMissingErr: Label 'Please try the operation again. If the error persists, please contact support.';
        CurrencyCodeTxt: Text;
        LCYCurrencyCode: Code[10];
        IsCustomerBlocked: Boolean;

    local procedure SetCalculatedFields(var SalesHeader: Record "Sales Header")
    var
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        DummyNativeAPITaxSetup: Record "Native - API Tax Setup";
        GraphMgtSalesQuote: Codeunit "Graph Mgt - Sales Quote";
        NativeEDMTypes: Codeunit "Native - EDM Types";
        NativeCoupons: Codeunit "Native - Coupons";
        NativeAttachments: Codeunit "Native - Attachments";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        BillingPostalAddressJSONText := GraphMgtSalesQuote.BillToCustomerAddressToJSON(Rec);
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");

        if "Sell-to Customer No." <> '' then
            if Customer.Get("Sell-to Customer No.") then begin
                CustomerEmail := Customer."E-Mail";
                IsCustomerBlocked := Customer.IsBlocked()
            end else begin
                IsCustomerBlocked := false;
                CustomerEmail := '';
            end;

        LoadLines(TempSalesInvoiceLineAggregate, Rec);
        SalesQuoteLinesJSON := NativeEDMTypes.WriteSalesLinesJSON(TempSalesInvoiceLineAggregate);
        PreviousSalesQuoteLinesJSON := SalesQuoteLinesJSON;

        CouponsJSON := NativeCoupons.WriteCouponsJSON("Sales Document Type"::Quote.AsInteger(), "No.", false);
        PreviousCouponsJSON := CouponsJSON;

        AttachmentsJSON := NativeAttachments.GenerateAttachmentsJSON(Id);
        PreviousAttachmentsJSON := AttachmentsJSON;
        TaxAreaDisplayName := DummyNativeAPITaxSetup.GetTaxAreaDisplayName("Tax Area ID");

        GetNoteForCustomer(SalesHeader);
        GetLastEmailSentFields(SalesHeader);
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(BillingPostalAddressJSONText);
        Clear(SalesQuoteLinesJSON);
        Clear(PreviousSalesQuoteLinesJSON);
        Clear(SalesLinesSet);
        Clear(AttachmentsJSON);
        Clear(PreviousAttachmentsJSON);
        Clear(IsAttachmentsSet);
        Clear(WorkDescription);
        Clear(TaxAreaDisplayName);
        Clear(LastEmailSentTime);
        Clear(LastEmailSentStatus);
        Clear(CurrencyCodeTxt);
        TempFieldBuffer.DeleteAll();
    end;

    local procedure RegisterFieldSet(FieldNo: Integer)
    var
        LastOrderNo: Integer;
    begin
        LastOrderNo := 1;
        if TempFieldBuffer.FindLast() then
            LastOrderNo := TempFieldBuffer.Order + 1;

        Clear(TempFieldBuffer);
        TempFieldBuffer.Order := LastOrderNo;
        TempFieldBuffer."Table ID" := DATABASE::"Sales Quote Entity Buffer";
        TempFieldBuffer."Field ID" := FieldNo;
        TempFieldBuffer.Insert();
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
            UpdateCustomer := not TempFieldBuffer.FindFirst();
            TempFieldBuffer.Reset();
        end;

        if UpdateCustomer then begin
            Validate("Customer Id", Customer.SystemId);
            Validate("Sell-to Customer No.", Customer."No.");
            RegisterFieldSet(FieldNo("Customer Id"));
            RegisterFieldSet(FieldNo("Sell-to Customer No."));
        end;

        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(Customer);
    end;

    local procedure LoadLines(var TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        TempSalesInvoiceLineAggregate.SetRange("Document Id", SalesQuoteEntityBuffer.Id);
        GraphMgtSalesQuoteBuffer.LoadLines(TempSalesInvoiceLineAggregate, TempSalesInvoiceLineAggregate.GetFilter("Document Id"));
    end;

    local procedure UpdateLines()
    var
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
        NativeEDMTypes: Codeunit "Native - EDM Types";
    begin
        if not SalesLinesSet then
            exit;

        NativeEDMTypes.ParseSalesLinesJSON(
          "Sales Document Type"::Quote.AsInteger(), SalesQuoteLinesJSON, TempSalesInvoiceLineAggregate, Id);
        TempSalesInvoiceLineAggregate.SetRange("Document Id", Id);
        GraphMgtSalesQuoteBuffer.PropagateMultipleLinesUpdate(TempSalesInvoiceLineAggregate);
        Find();
    end;

    local procedure UpdateDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        CustInvDisc: Record "Cust. Invoice Disc.";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        O365Discounts: Codeunit "O365 Discounts";
        DocumentTotals: Codeunit "Document Totals";
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
        VatAmount: Decimal;
        InvoiceDiscountPct: Decimal;
    begin
        if SalesLinesSet and (not DiscountAmountSet) then begin
            GraphMgtSalesQuoteBuffer.RedistributeInvoiceDiscounts(Rec);
            exit;
        end;

        if not DiscountAmountSet then
            exit;

        case "Invoice Discount Calculation" of
            "Invoice Discount Calculation"::"%":
                begin
                    if "Invoice Discount Value" < 0 then
                        Error(InvoiceDiscountPctMustBePositiveErr);
                    if "Invoice Discount Value" > 100 then
                        Error(InvoiceDiscountPctMustBeBelowHundredErr);
                    InvoiceDiscountPct := "Invoice Discount Value";
                end;
            "Invoice Discount Calculation"::Amount:
                begin
                    InvoiceDiscountAmount := "Invoice Discount Value";
                    if "Invoice Discount Value" < 0 then
                        Error(InvoiceDiscountAmtMustBePositiveErr);
                end;
        end;

        SalesHeader.Get("Document Type"::Quote, "No.");
        if InvoiceDiscountPct <> 0 then begin
            O365Discounts.ApplyInvoiceDiscountPercentage(SalesHeader, InvoiceDiscountPct);
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            if SalesLine.FindFirst() then begin
                GraphMgtSalesQuoteBuffer.RedistributeInvoiceDiscounts(Rec);
                DocumentTotals.CalculateSalesTotals(TotalSalesLine, VatAmount, SalesLine);
                "Invoice Discount Amount" := TotalSalesLine."Inv. Discount Amount";
            end;
        end else begin
            CustInvDisc.SetRange(Code, "No.");
            CustInvDisc.DeleteAll();
            SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
            GraphMgtSalesQuoteBuffer.RedistributeInvoiceDiscounts(Rec);
        end;
    end;

    local procedure UpdateCoupons()
    var
        NativeEDMTypes: Codeunit "Native - EDM Types";
    begin
        if not CouponsSet then
            exit;

        NativeEDMTypes.ParseCouponsJSON("Contact Graph Id", "Sales Document Type"::Quote.AsInteger(), "No.", CouponsJSON);
    end;

    local procedure UpdateAttachments()
    var
        NativeAttachments: Codeunit "Native - Attachments";
    begin
        if not IsAttachmentsSet then
            exit;

        // Here we now know that user has specified different attachments than before.
        // We should patch the attachments. This means:
        // Delete the ones not in use anymore.
        // Add new ones.
        // Keep old ones.

        NativeAttachments.UpdateAttachments(Id, AttachmentsJSON, PreviousAttachmentsJSON);
    end;

    local procedure CheckCustomer()
    var
        BlankGUID: Guid;
    begin
        if ("Sell-to Customer No." = '') and
           ("Customer Id" = BlankGUID)
        then
            Error(CustomerNotProvidedErr);
    end;

    local procedure GetLastEmailSentFields(var SalesHeader: Record "Sales Header")
    begin
        LastEmailSentTime := SalesHeader."Last Email Sent Time";
        LastEmailSentStatus := SalesHeader."Last Email Sent Status";
    end;

    local procedure GetNoteForCustomer(var SalesHeader: Record "Sales Header")
    begin
        Clear(WorkDescription);
        WorkDescription := SalesHeader.GetWorkDescription();
    end;

    local procedure SetNoteForCustomer()
    var
        SalesHeader: Record "Sales Header";
    begin
        if not NoteForCustomerSet then
            exit;

        SalesHeader.Get(SalesHeader."Document Type"::Quote, "No.");
        SalesHeader.SetWorkDescription(WorkDescription);
        SalesHeader.Modify(true);
        Find();
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
            "Posting Date" := DocumentDateVar;
            RegisterFieldSet(FieldNo("Document Date"));
            RegisterFieldSet(FieldNo("Posting Date"));
        end;

        if DueDateSet then begin
            "Due Date" := DueDateVar;
            RegisterFieldSet(FieldNo("Due Date"));
        end;

        GraphMgtSalesQuoteBuffer.PropagateOnModify(Rec, TempFieldBuffer);
        Find();
    end;

    local procedure GetQuote(var SalesHeader: Record "Sales Header")
    begin
        if not SalesHeader.GetBySystemId(SystemId) then
            Error(CannotFindQuoteErr);
    end;

    local procedure CheckAttachmentsSize(RecordVariant: Variant)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
    begin
        O365SalesAttachmentMgt.GetAttachments(RecordVariant, IncomingDocumentAttachment);
        O365SalesAttachmentMgt.AssertIncomingDocumentSizeBelowMax(IncomingDocumentAttachment);
    end;

    local procedure CheckSendToEmailAddress()
    begin
        if GetSendToEmailAddress() = '' then
            Error(EmptyEmailErr);
    end;

    local procedure GetSendToEmailAddress(): Text[250]
    var
        EmailAddress: Text[250];
    begin
        EmailAddress := GetDocumentEmailAddress();
        if EmailAddress <> '' then
            exit(EmailAddress);
        EmailAddress := GetCustomerEmailAddress();
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
        O365SalesEmailManagement: Codeunit "O365 Sales Email Management";
    begin
        O365SendResendInvoice.CheckDocumentIfNoItemsExists(SalesHeader, false, DummyO365SalesDocument);
        LinesInstructionMgt.SalesCheckAllLinesHaveQuantityAssigned(SalesHeader);
        CheckSendToEmailAddress();

        O365SalesEmailManagement.NativeAPISaveEmailBodyText(Id);
        SalesHeader.SetRecFilter();
        SalesHeader.EmailRecords(false);
    end;

    local procedure SetActionResponse(var ActionContext: DotNet WebServiceActionContext; var SalesHeader: Record "Sales Header")
    var
        ODataActionManagement: Codeunit "OData Action Management";
    begin
        ODataActionManagement.AddKey(FieldNo(SystemId), SalesHeader.SystemId);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Native - Sales Inv. Entity")
        else
            ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Native - Sales Quotes");
    end;

    [ServiceEnabled]
    procedure MakeInvoice(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
        SalesQuoteToInvoice: Codeunit "Sales-Quote to Invoice";
    begin
        GetQuote(SalesHeader);
        SalesHeader.SetRecFilter();
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
        CheckAttachmentsSize(SalesHeader);
        SendQuote(SalesHeader);
        SetActionResponse(ActionContext, SalesHeader);
    end;
}
#endif
