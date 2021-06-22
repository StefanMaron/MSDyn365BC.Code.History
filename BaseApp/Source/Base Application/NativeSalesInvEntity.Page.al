page 2810 "Native - Sales Inv. Entity"
{
    Caption = 'nativeInvoicingSalesInvoices', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = Id;
    PageType = List;
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

                    trigger OnValidate()
                    begin
                        CheckStatus;
                        RegisterFieldSet(FieldNo(Id));
                    end;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                    Editable = false;
                }
                field(customerId; "Customer Id")
                {
                    ApplicationArea = All;
                    Caption = 'customerId', Locked = true;

                    trigger OnValidate()
                    var
                        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
                    begin
                        CheckStatus;

                        Customer.SetRange(Id, "Customer Id");

                        if not Customer.FindFirst then
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
                    Caption = 'graphContactId', Locked = true;

                    trigger OnValidate()
                    var
                        Contact: Record Contact;
                        Customer: Record Customer;
                        GraphIntContact: Codeunit "Graph Int. - Contact";
                    begin
                        CheckStatus;

                        if ("Contact Graph Id" = '') and CustomerIdSet then
                            exit;

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
                        CheckStatus;

                        if Customer."No." <> '' then
                            exit;

                        if not Customer.Get("Sell-to Customer No.") then
                            Error(CannotFindCustomerErr);

                        O365SalesInvoiceMgmt.EnforceCustomerTemplateIntegrity(Customer);

                        "Customer Id" := Customer.Id;
                        RegisterFieldSet(FieldNo("Customer Id"));
                        RegisterFieldSet(FieldNo("Sell-to Customer No."));
                    end;
                }
                field(taxLiable; "Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'taxLiable';
                    Importance = Additional;
                    ToolTip = 'Specifies if the sales invoice contains sales tax.';

                    trigger OnValidate()
                    begin
                        CheckStatus;
                        RegisterFieldSet(FieldNo("Tax Liable"));
                    end;
                }
                field(taxAreaId; "Tax Area ID")
                {
                    ApplicationArea = All;
                    Caption = 'taxAreaId';

                    trigger OnValidate()
                    begin
                        CheckStatus;

                        RegisterFieldSet(FieldNo("Tax Area ID"));

                        if IsUsingVAT then
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
                        CheckStatus;
                        RegisterFieldSet(FieldNo("VAT Registration No."));
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
                    ToolTip = 'Specifies the email address of the customer.';
                }
                field(invoiceDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'invoiceDate', Locked = true;

                    trigger OnValidate()
                    begin
                        CheckStatus;

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
                        CheckStatus;

                        DueDateVar := "Due Date";
                        DueDateSet := true;

                        RegisterFieldSet(FieldNo("Due Date"));
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
                        CheckStatus;
                        BillingPostalAddressSet := true;
                    end;
                }
                field(pricesIncludeTax; "Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'pricesIncludeTax', Locked = true;
                    Editable = false;
                }
                field(currencyCode; CurrencyCodeTxt)
                {
                    ApplicationArea = All;
                    Caption = 'currencyCode', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies the currency code.';
                }
                field(lines; SalesInvoiceLinesJSON)
                {
                    ApplicationArea = All;
                    Caption = 'lines', Locked = true;
                    ODataEDMType = 'Collection(NATIVE-SALESINVOICE-LINE)';
                    ToolTip = 'Specifies Sales Invoice Lines';

                    trigger OnValidate()
                    begin
                        CheckStatus;
                        SalesLinesSet := PreviousSalesInvoiceLinesJSON <> SalesInvoiceLinesJSON;
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
                    Editable = false;
                }
                field(coupons; CouponsJSON)
                {
                    ApplicationArea = All;
                    Caption = 'coupons', Locked = true;
                    ODataEDMType = 'Collection(NATIVE-SALESDOCUMENT-COUPON)';
                    ToolTip = 'Specifies Sales Invoice Coupons.';

                    trigger OnValidate()
                    begin
                        CheckStatus;
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
                }
                field(totalAmountIncludingTax; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'totalAmountIncludingTax', Locked = true;
                    Editable = false;
                }
                field(noteForCustomer; WorkDescription)
                {
                    ApplicationArea = All;
                    Caption = 'noteForCustomer';
                    ToolTip = 'Specifies the note for the customer.';

                    trigger OnValidate()
                    begin
                        CheckStatus;
                        NoteForCustomerSet := true;
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
                        CheckStatus;
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
                        CheckStatus;
                        RegisterFieldSet(FieldNo("Invoice Discount Value"));
                        DiscountAmountSet := true;
                    end;
                }
                field(remainingAmount; RemainingAmountVar)
                {
                    ApplicationArea = All;
                    Caption = 'remainingAmount';
                    Editable = false;
                    ToolTip = 'Specifies the Status for the Invoice';
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
                field(isTest; IsTest)
                {
                    ApplicationArea = All;
                    Caption = 'isTest', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies if the sales invoice is a test invoice.';
                }
                field(isCustomerBlocked; IsCustomerBlocked)
                {
                    ApplicationArea = All;
                    Caption = 'isCustomerBlocked', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies if the customer is blocked.';
                }
                part(Payments; "Native - Payments")
                {
                    ApplicationArea = All;
                    Caption = 'Payments', Locked = true;
                    SubPageLink = "Applies-to Invoice Id" = FIELD(Id);
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
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if not GetParentRecordNativeInvoicing(SalesHeader, SalesInvoiceHeader) then begin
            GraphMgtGeneralTools.CleanAggregateWithoutParent(Rec);
            exit;
        end;

        SetCalculatedFields(SalesHeader, SalesInvoiceHeader);
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
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        CheckCustomer;
        ProcessBillingPostalAddress;

        SalesInvoiceAggregator.PropagateOnInsert(Rec, TempFieldBuffer);
        SetDates;

        UpdateAttachments;
        UpdateLines;
        UpdateDiscount;
        UpdateCoupons;
        SetNoteForCustomer;

        if not GetParentRecordNativeInvoicing(SalesHeader, SalesInvoiceHeader) then
            Error(AggregateParentIsMissingErr);

        SetCalculatedFields(SalesHeader, SalesInvoiceHeader);

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        if Posted then begin
            if not IsAttachmentsSet then
                exit(false);
            UpdateAttachments;
            SetAttachmentsJSON;
            exit(false);
        end;

        if xRec.Id <> Id then
            Error(CannotChangeIDErr);

        ProcessBillingPostalAddress;

        SalesInvoiceAggregator.PropagateOnModify(Rec, TempFieldBuffer);

        UpdateAttachments;
        UpdateLines;
        UpdateDiscount;
        UpdateCoupons;
        SetNoteForCustomer;

        if not GetParentRecordNativeInvoicing(SalesHeader, SalesInvoiceHeader) then
            Error(AggregateParentIsMissingErr);

        SetCalculatedFields(SalesHeader, SalesInvoiceHeader);

        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields;
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(NativeAPILanguageHandler);
        SelectLatestVersion;
    end;

    var
        CannotChangeIDErr: Label 'The id cannot be changed.', Locked = true;
        TempFieldBuffer: Record "Field Buffer" temporary;
        Customer: Record Customer;
        DummySalesLine: Record "Sales Line";
        NativeAPILanguageHandler: Codeunit "Native API - Language Handler";
        BillingPostalAddressJSONText: Text;
        CustomerEmail: Text;
        SalesInvoiceLinesJSON: Text;
        PreviousSalesInvoiceLinesJSON: Text;
        CouponsJSON: Text;
        PreviousCouponsJSON: Text;
        AttachmentsJSON: Text;
        PreviousAttachmentsJSON: Text;
        TaxAreaDisplayName: Text;
        BillingPostalAddressSet: Boolean;
        CannotFindCustomerErr: Label 'The customer cannot be found.', Locked = true;
        ContactIdHasToHaveValueErr: Label 'Contact Id must have a value set.';
        SalesLinesSet: Boolean;
        CouponsSet: Boolean;
        DiscountAmountSet: Boolean;
        IsAttachmentsSet: Boolean;
        InvoiceDiscountAmount: Decimal;
        CustomerNotProvidedErr: Label 'A customerNumber or a customerID must be provided.', Locked = true;
        InvoiceDiscountPct: Decimal;
        WorkDescription: Text;
        NoteForCustomerSet: Boolean;
        CannotChangeWorkDescriptionOnPostedInvoiceErr: Label 'The Note for customer cannot be changed on the sent invoice.';
        DocumentDateSet: Boolean;
        DocumentDateVar: Date;
        DueDateSet: Boolean;
        DueDateVar: Date;
        PostedInvoiceActionErr: Label 'The action can be applied to a posted invoice only.';
        DraftInvoiceActionErr: Label 'The action can be applied to a draft invoice only.';
        CannotFindInvoiceErr: Label 'The invoice cannot be found.';
        CancelingInvoiceFailedCreditMemoCreatedAndPostedErr: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is posted.', Comment = '%1 - Error Message';
        CancelingInvoiceFailedCreditMemoCreatedButNotPostedErr: Label 'Canceling the invoice failed because of the following error: \\%1\\A credit memo is created but not posted.', Comment = '%1 - Error Message';
        CancelingInvoiceFailedNothingCreatedErr: Label 'Canceling the invoice failed because of the following error: \\%1.', Comment = '%1 - Error Message';
        EmptyEmailErr: Label 'The send-to email is empty. Specify email either for the customer or for the invoice in email preview.';
        AlreadyCanceledErr: Label 'The invoice cannot be canceled because it has already been canceled.';
        InvoiceDiscountPctMustBePositiveErr: Label 'Invoice discount percentage must be positive.';
        InvoiceDiscountPctMustBeBelowHundredErr: Label 'Invoice discount percentage must be below 100.';
        InvoiceDiscountAmtMustBePositiveErr: Label 'Invoice discount must be positive.';
        RemainingAmountVar: Decimal;
        CustomerIdSet: Boolean;
        LastEmailSentTime: DateTime;
        CannotModifyPostedInvioceErr: Label 'The invoice has been posted and can no longer be modified. You are only allowed to change the attachments.';
        LastEmailSentStatus: Option "Not Sent","In Process",Finished,Error;
        AggregateParentIsMissingErr: Label 'Please try the operation again. If the error persists, please contact support.';
        CurrencyCodeTxt: Text;
        LCYCurrencyCode: Code[10];
        IsCustomerBlocked: Boolean;

    local procedure SetAttachmentsJSON()
    var
        NativeAttachments: Codeunit "Native - Attachments";
    begin
        AttachmentsJSON := NativeAttachments.GenerateAttachmentsJSON(Id);
        PreviousAttachmentsJSON := AttachmentsJSON;
    end;

    local procedure SetCalculatedFields(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        DummyNativeAPITaxSetup: Record "Native - API Tax Setup";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        GraphMgtSalesInvoice: Codeunit "Graph Mgt - Sales Invoice";
        NativeEDMTypes: Codeunit "Native - EDM Types";
        NativeCoupons: Codeunit "Native - Coupons";
    begin
        DocumentDateVar := "Document Date";
        DueDateVar := "Due Date";
        BillingPostalAddressJSONText := GraphMgtSalesInvoice.BillToCustomerAddressToJSON(Rec);
        CurrencyCodeTxt := GraphMgtGeneralTools.TranslateNAVCurrencyCodeToCurrencyCode(LCYCurrencyCode, "Currency Code");

        if "Sell-to Customer No." <> '' then
            if Customer.Get("Sell-to Customer No.") then begin
                CustomerEmail := Customer."E-Mail";
                IsCustomerBlocked := Customer.IsBlocked
            end else begin
                IsCustomerBlocked := false;
                CustomerEmail := '';
            end;

        LoadLines(TempSalesInvoiceLineAggregate, Rec);
        SalesInvoiceLinesJSON :=
          NativeEDMTypes.WriteSalesLinesJSON(TempSalesInvoiceLineAggregate);
        PreviousSalesInvoiceLinesJSON := SalesInvoiceLinesJSON;

        CouponsJSON := NativeCoupons.WriteCouponsJSON(DummySalesLine."Document Type"::Invoice, "No.", Posted);
        PreviousCouponsJSON := CouponsJSON;

        SetAttachmentsJSON;
        TaxAreaDisplayName := DummyNativeAPITaxSetup.GetTaxAreaDisplayName("Tax Area ID");
        GetNoteForCustomer(SalesHeader, SalesInvoiceHeader);
        GetRemainingAmount;
        GetLastEmailSentFields(SalesHeader, SalesInvoiceHeader);
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(BillingPostalAddressJSONText);
        Clear(SalesInvoiceLinesJSON);
        Clear(PreviousSalesInvoiceLinesJSON);
        Clear(SalesLinesSet);
        Clear(CouponsJSON);
        Clear(PreviousCouponsJSON);
        Clear(CouponsSet);
        Clear(AttachmentsJSON);
        Clear(PreviousAttachmentsJSON);
        Clear(IsAttachmentsSet);
        Clear(WorkDescription);
        Clear(DueDateSet);
        Clear(CurrencyCodeTxt);
        "Due Date" := 19990101D;
        Clear(DocumentDateSet);
        Clear(DocumentDateVar);
        Clear(RemainingAmountVar);
        Clear(TaxAreaDisplayName);
        Clear(LastEmailSentTime);
        Clear(LastEmailSentStatus);
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

    local procedure LoadLines(var TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary; var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate")
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        TempSalesInvoiceLineAggregate.SetRange("Document Id", SalesInvoiceEntityAggregate.Id);
        SalesInvoiceAggregator.LoadLines(TempSalesInvoiceLineAggregate, TempSalesInvoiceLineAggregate.GetFilter("Document Id"));
    end;

    local procedure UpdateLines()
    var
        TempSalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate" temporary;
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        NativeEDMTypes: Codeunit "Native - EDM Types";
    begin
        if not SalesLinesSet then
            exit;

        NativeEDMTypes.ParseSalesLinesJSON(
          DummySalesLine."Document Type"::Invoice, SalesInvoiceLinesJSON, TempSalesInvoiceLineAggregate, Id);
        TempSalesInvoiceLineAggregate.SetRange("Document Id", Id);
        SalesInvoiceAggregator.PropagateMultipleLinesUpdate(TempSalesInvoiceLineAggregate);
        Find;
    end;

    local procedure UpdateDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        CustInvDisc: Record "Cust. Invoice Disc.";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        O365Discounts: Codeunit "O365 Discounts";
        DocumentTotals: Codeunit "Document Totals";
        VatAmount: Decimal;
    begin
        if Posted then
            exit;

        if SalesLinesSet and (not DiscountAmountSet) then begin
            SalesInvoiceAggregator.RedistributeInvoiceDiscounts(Rec);
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

        SalesHeader.Get("Document Type"::Invoice, "No.");
        if InvoiceDiscountPct <> 0 then begin
            O365Discounts.ApplyInvoiceDiscountPercentage(SalesHeader, InvoiceDiscountPct);
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            if SalesLine.FindFirst then begin
                SalesInvoiceAggregator.RedistributeInvoiceDiscounts(Rec);
                DocumentTotals.CalculateSalesTotals(TotalSalesLine, VatAmount, SalesLine);
                "Invoice Discount Amount" := TotalSalesLine."Inv. Discount Amount";
                RegisterFieldSet(FieldNo("Invoice Discount Amount"));
            end;
        end else begin
            CustInvDisc.SetRange(Code, "No.");
            CustInvDisc.DeleteAll();
            SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
            SalesInvoiceAggregator.RedistributeInvoiceDiscounts(Rec);
        end;
    end;

    local procedure UpdateCoupons()
    var
        NativeEDMTypes: Codeunit "Native - EDM Types";
    begin
        if not CouponsSet then
            exit;

        NativeEDMTypes.ParseCouponsJSON("Contact Graph Id", DummySalesLine."Document Type"::Invoice, "No.", CouponsJSON);
    end;

    local procedure UpdateAttachments()
    var
        NativeAttachments: Codeunit "Native - Attachments";
    begin
        if not IsAttachmentsSet then
            exit;

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

    local procedure CheckStatus()
    begin
        if Posted then
            Error(CannotModifyPostedInvioceErr);
    end;

    local procedure GetNoteForCustomer(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if Posted then
            WorkDescription := SalesInvoiceHeader.GetWorkDescription
        else
            WorkDescription := SalesHeader.GetWorkDescription;
    end;

    local procedure GetLastEmailSentFields(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if Posted then begin
            LastEmailSentTime := SalesInvoiceHeader."Last Email Sent Time";
            LastEmailSentStatus := SalesInvoiceHeader."Last Email Sent Status";
        end else begin
            LastEmailSentTime := SalesHeader."Last Email Sent Time";
            LastEmailSentStatus := SalesHeader."Last Email Sent Status";
        end;
    end;

    local procedure GetRemainingAmount()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        RemainingAmountVar := "Amount Including VAT";
        if Posted then
            if SalesInvoiceHeader.Get("No.") then begin
                if IsInvoiceCanceled then begin
                    RemainingAmountVar := 0;
                    exit;
                end;

                RemainingAmountVar := SalesInvoiceHeader.GetRemainingAmount;
            end;
    end;

    local procedure SetNoteForCustomer()
    var
        SalesHeader: Record "Sales Header";
    begin
        if not NoteForCustomerSet then
            exit;

        if Posted then
            Error(CannotChangeWorkDescriptionOnPostedInvoiceErr);

        SalesHeader.Get(SalesHeader."Document Type"::Invoice, "No.");
        SalesHeader.SetWorkDescription(WorkDescription);
        SalesHeader.Modify(true);
        Find;
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
            "Posting Date" := DocumentDateVar;
            RegisterFieldSet(FieldNo("Document Date"));
            RegisterFieldSet(FieldNo("Posting Date"));
        end;

        if DueDateSet then begin
            "Due Date" := DueDateVar;
            RegisterFieldSet(FieldNo("Due Date"));
        end;

        SalesInvoiceAggregator.PropagateOnModify(Rec, TempFieldBuffer);
        Find;
    end;

    local procedure GetPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if not Posted then
            Error(PostedInvoiceActionErr);

        SalesInvoiceHeader.SetRange(Id, Id);
        if not SalesInvoiceHeader.FindFirst then
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
        O365SetupEmail: Codeunit "O365 Setup Email";
        O365SalesEmailManagement: Codeunit "O365 Sales Email Management";
    begin
        O365SetupEmail.SilentSetup;
        CheckSendToEmailAddress(SalesInvoiceHeader."No.");
        O365SalesEmailManagement.NativeAPISaveEmailBodyText(Id);

        CheckAttachmentsSize(SalesInvoiceHeader);

        SalesInvoiceHeader.SetRecFilter;
        SalesInvoiceHeader.EmailRecords(false);
    end;

    local procedure SendDraftInvoice(var SalesHeader: Record "Sales Header")
    var
        DummyO365SalesDocument: Record "O365 Sales Document";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        O365SendResendInvoice: Codeunit "O365 Send + Resend Invoice";
        O365SetupEmail: Codeunit "O365 Setup Email";
        O365SalesEmailManagement: Codeunit "O365 Sales Email Management";
    begin
        O365SendResendInvoice.CheckDocumentIfNoItemsExists(SalesHeader, false, DummyO365SalesDocument);
        LinesInstructionMgt.SalesCheckAllLinesHaveQuantityAssigned(SalesHeader);
        O365SetupEmail.SilentSetup;
        CheckSendToEmailAddress(SalesHeader."No.");

        CheckAttachmentsSize(SalesHeader);

        O365SalesEmailManagement.NativeAPISaveEmailBodyText(Id);
        SalesHeader.SetRecFilter;
        SalesHeader.EmailRecords(false);
    end;

    local procedure SendCanceledInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
        O365SetupEmail: Codeunit "O365 Setup Email";
        O365SalesEmailManagement: Codeunit "O365 Sales Email Management";
        O365SalesCancelInvoice: Codeunit "O365 Sales Cancel Invoice";
        GraphMail: Codeunit "Graph Mail";
    begin
        O365SetupEmail.SilentSetup;
        CheckSendToEmailAddress(SalesInvoiceHeader."No.");
        O365SalesEmailManagement.NativeAPISaveEmailBodyText(Id);

        CheckAttachmentsSize(SalesInvoiceHeader);

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"O365 Sales Cancel Invoice";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Record ID to Process" := SalesInvoiceHeader.RecordId;

        if GraphMail.IsEnabled and GraphMail.HasConfiguration then
            O365SalesCancelInvoice.SendInvoiceCancelationEmail(SalesInvoiceHeader)
        else
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
        ODataActionManagement.SetDeleteResponseLocation(ActionContext, PAGE::"Native - Sales Inv. Entity");
    end;

    [ServiceEnabled]
    procedure Post(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        GetDraftInvoice(SalesHeader);
        PostInvoice(SalesHeader, SalesInvoiceHeader);
        SetActionResponse(ActionContext, SalesInvoiceHeader.Id);
    end;

    [ServiceEnabled]
    procedure PostAndSend(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        GetDraftInvoice(SalesHeader);
        PostInvoice(SalesHeader, SalesInvoiceHeader);
        Commit();
        SendPostedInvoice(SalesInvoiceHeader);
        SetActionResponse(ActionContext, SalesInvoiceHeader.Id);
    end;

    [ServiceEnabled]
    procedure Send(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if Posted then begin
            GetPostedInvoice(SalesInvoiceHeader);
            if IsInvoiceCanceled then
                SendCanceledInvoice(SalesInvoiceHeader)
            else
                SendPostedInvoice(SalesInvoiceHeader);
            SetActionResponse(ActionContext, SalesInvoiceHeader.Id);
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
    begin
        GetPostedInvoice(SalesInvoiceHeader);
        CancelInvoice(SalesInvoiceHeader);
        SetActionResponse(ActionContext, SalesInvoiceHeader.Id);
    end;

    [ServiceEnabled]
    procedure CancelAndSend(var ActionContext: DotNet WebServiceActionContext)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        GetPostedInvoice(SalesInvoiceHeader);
        CancelInvoice(SalesInvoiceHeader);
        SendCanceledInvoice(SalesInvoiceHeader);
        SetActionResponse(ActionContext, SalesInvoiceHeader.Id);
    end;

    local procedure CheckAttachmentsSize(RecordVariant: Variant)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
    begin
        O365SalesAttachmentMgt.GetAttachments(RecordVariant, IncomingDocumentAttachment);
        O365SalesAttachmentMgt.AssertIncomingDocumentSizeBelowMax(IncomingDocumentAttachment);
    end;
}

