page 30055 "APIV2 - Customer Payments"
{
    APIVersion = 'v2.0';
    EntityCaption = 'Customer Payment';
    EntitySetCaption = 'Customer Payments';
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    PageType = API;
    EntityName = 'customerPayment';
    EntitySetName = 'customerPayments';
    SourceTable = "Gen. Journal Line";
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
                field(journalId; "Journal Batch Id")
                {
                    Caption = 'Journal Id';
                    Editable = false;
                }
                field(journalDisplayName; GlobalJournalDisplayNameTxt)
                {
                    Caption = 'Journal Display Name';

                    trigger OnValidate()
                    begin
                        Error(CannotEditBatchNameErr);
                    end;
                }
                field(lineNumber; "Line No.")
                {
                    Caption = 'Line Number';
                }
                field(customerId; "Customer Id")
                {
                    Caption = 'Customer Id';

                    trigger OnValidate()
                    begin
                        if "Customer Id" = BlankGUID then begin
                            "Account No." := '';
                            exit;
                        end;

                        if not Customer.GetBySystemId("Customer Id") then
                            Error(CustomerIdDoesNotMatchACustomerErr);

                        "Account No." := Customer."No.";
                    end;
                }
                field(customerNumber; "Account No.")
                {
                    Caption = 'Customer Number';
                    TableRelation = Customer;

                    trigger OnValidate()
                    begin
                        if Customer."No." <> '' then begin
                            if Customer."No." <> "Account No." then
                                Error(CustomerValuesDontMatchErr);
                            exit;
                        end;

                        if "Account No." = '' then begin
                            "Customer Id" := BlankGUID;
                            exit;
                        end;

                        if not Customer.Get("Account No.") then
                            Error(CustomerNumberDoesNotMatchACustomerErr);

                        "Customer Id" := Customer.SystemId;
                    end;
                }
                field(postingDate; "Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(documentNumber; "Document No.")
                {
                    Caption = 'Document Number';
                }
                field(externalDocumentNumber; "External Document No.")
                {
                    Caption = 'External Document Number';
                }
                field(amount; Amount)
                {
                    Caption = 'Amount';
                }
                field(appliesToInvoiceId; AppliesToInvoiceIdText)
                {
                    Caption = 'Applies To Invoice Id';

                    trigger OnValidate()
                    var
                        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
                    begin
                        "Applies-to Invoice Id" := AppliesToInvoiceIdText;
                        if "Applies-to Invoice Id" = BlankGUID then begin
                            AppliesToInvoiceNumberText := '';
                            exit;
                        end;

                        SalesInvoiceHeader.Reset();
                        if not SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(Format(AppliesToInvoiceIdText), SalesInvoiceHeader) then
                            Error(AppliesToInvoiceIdDoesNotMatchAnInvoiceErr);

                        AppliesToInvoiceNumberText := SalesInvoiceHeader."No.";

                        if "Account No." = '' then
                            if SalesInvoiceHeader."Bill-to Customer No." <> '' then
                                "Account No." := SalesInvoiceHeader."Bill-to Customer No."
                            else
                                "Account No." := SalesInvoiceHeader."Sell-to Customer No.";
                    end;
                }
                field(appliesToInvoiceNumber; AppliesToInvoiceNumberText)
                {
                    Caption = 'Applies To Invoice Number';

                    trigger OnValidate()
                    var
                        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
                        BlankGUID: Guid;
                    begin
                        "Applies-to Doc. No." := AppliesToInvoiceNumberText;

                        if SalesInvoiceHeader."No." <> '' then begin
                            if SalesInvoiceHeader."No." <> AppliesToInvoiceNumberText then
                                Error(AppliesToDocValuesDontMatchErr);
                            exit;
                        end;

                        if SalesInvoiceHeader.Get(AppliesToInvoiceNumberText) then begin
                            AppliesToInvoiceIdText := SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader);
                            if "Account No." = '' then
                                if SalesInvoiceHeader."Bill-to Customer No." <> '' then
                                    "Account No." := SalesInvoiceHeader."Bill-to Customer No."
                                else
                                    "Account No." := SalesInvoiceHeader."Sell-to Customer No.";
                        end else
                            AppliesToInvoiceIdText := BlankGUID;
                    end;
                }
                field(description; Description)
                {
                    Caption = 'Description';
                }
                field(comment; Comment)
                {
                    Caption = 'Comment';
                }
                field(lastModifiedDateTime; SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                }
                part(dimensionSetLines; "APIV2 - Dimension Set Lines")
                {
                    Caption = 'Dimension Set Lines';
                    EntityName = 'dimensionSetLine';
                    EntitySetName = 'dimensionSetLines';
                    SubPageLink = "Parent Id" = Field(SystemId), "Parent Type" = const(1);
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        if not FiltersChecked then begin
            CheckFilters();
            FiltersChecked := true;
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
    begin
        ProcessAppliesToInvoiceNumberAndId();

        TempGenJournalLine.Reset();
        TempGenJournalLine.Copy(Rec);

        Clear(Rec);
        GraphMgtCustomerPayments.SetCustomerPaymentsTemplateAndBatch(
          Rec, LibraryAPIGeneralJournal.GetBatchNameFromId(TempGenJournalLine.GetFilter("Journal Batch Id")));
        LibraryAPIGeneralJournal.InitializeLine(
          Rec, TempGenJournalLine."Line No.", TempGenJournalLine."Document No.", TempGenJournalLine."External Document No.");
        TransferGeneratedFieldsFromInitializeLine(TempGenJournalLine);

        GraphMgtCustomerPayments.SetCustomerPaymentsValues(Rec, TempGenJournalLine);

        SetCalculatedFields();
    end;

    trigger OnModifyRecord(): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ProcessAppliesToInvoiceNumberAndId();

        GenJournalLine.GetBySystemId(SystemId);

        if "Line No." = GenJournalLine."Line No." then
            Modify(true)
        else begin
            GenJournalLine.TransferFields(Rec, false);
            GenJournalLine.Rename("Journal Template Name", "Journal Batch Name", "Line No.");
            TransferFields(GenJournalLine, true);
        end;

        SetCalculatedFields();

        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CheckFilters();

        ClearCalculatedFields();

        "Document Type" := "Document Type"::Payment;
        "Account Type" := "Account Type"::Customer;
        "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
    end;

    trigger OnOpenPage()
    begin
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(Rec);
    end;

    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GraphMgtCustomerPayments: Codeunit "Graph Mgt - Customer Payments";
        LibraryAPIGeneralJournal: Codeunit "Library API - General Journal";
        GlobalJournalDisplayNameTxt: Text;
        AppliesToInvoiceNumberText: Code[20];
        AppliesToInvoiceIdText: Guid;
        FiltersNotSpecifiedErr: Label 'You must specify a journal batch ID or a journal ID to get a journal line.';
        CannotEditBatchNameErr: Label 'The Journal Batch Display Name isn''t editable.';
        CustomerValuesDontMatchErr: Label 'The customer values do not match to a specific Customer.';
        CustomerIdDoesNotMatchACustomerErr: Label 'The "customerId" does not match to a Customer.';
        CustomerNumberDoesNotMatchACustomerErr: Label 'The "customerNumber" does not match to a Customer.';
        AppliesToDocValuesDontMatchErr: Label 'The AppliesToInvoice values do not match to the same Invoice.';
        AppliesToInvoiceIdDoesNotMatchAnInvoiceErr: Label 'The "appliesToInvoiceId" should be the ID of an Open, Paid, Corrective, or Canceled Invoice.';
        FiltersChecked: Boolean;
        BlankGUID: Guid;

    local procedure TransferGeneratedFieldsFromInitializeLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Document No." = '' then
            GenJournalLine."Document No." := "Document No.";
    end;

    local procedure SetCalculatedFields()
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GlobalJournalDisplayNameTxt := "Journal Batch Name";
        AppliesToInvoiceNumberText := "Applies-to Doc. No.";
        AppliesToInvoiceIdText := "Applies-to Invoice Id";
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(GlobalJournalDisplayNameTxt);
        Clear(AppliesToInvoiceIdText);
        Clear(AppliesToInvoiceNumberText);
    end;

    local procedure ProcessAppliesToInvoiceNumberAndId()
    begin
        if AppliesToInvoiceNumberText <> '' then
            "Applies-to Doc. No." := AppliesToInvoiceNumberText;
        "Applies-to Invoice Id" := AppliesToInvoiceIdText;
    end;

    local procedure CheckFilters()
    begin
        if (GetFilter("Journal Batch Id") = '') and
           (GetFilter(SystemId) = '')
        then
            Error(FiltersNotSpecifiedErr);
    end;
}

