page 11512 "Swiss QR-Bill Print Select Doc"
{
    Caption = 'Select Document';

    layout
    {
        area(Content)
        {
            group(Selected)
            {
                Caption = 'Selected Document Information';

                field(CustomerLedgerEntryDescription; CustLedgerEntry.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the selected document description.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(PaymentReference; CustLedgerEntry."Payment Reference")
                {
                    Caption = 'Payment Reference';
                    ToolTip = 'Specifies the payment reference value for the selected document.';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(FromDocuments)
            {
                Caption = 'From Posted Document';

                group(SalesService)
                {
                    ShowCaption = false;

                    field(SalesInvoiceHeaderNo; SalesInvoiceHeader."No.")
                    {
                        Caption = 'Posted Sales Invoice';
                        ToolTip = 'Specifies the document number of the selected posted sales invoice.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            ValidateSalesInvoiceHeader(SalesInvoiceHeader."No.");
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            DocumentNo := QRBillMgt.LookupFilteredSalesInvoices();
                            if DocumentNo <> '' then
                                ValidateSalesInvoiceHeader(DocumentNo);
                        end;
                    }

                    field(ServiceInvoiceHeaderNo; ServiceInvoiceHeader."No.")
                    {
                        Caption = 'Posted Service Invoice';
                        ToolTip = 'Specifies the document number of the selected posted service invoice.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            ValidateServiceInvoiceHeader(ServiceInvoiceHeader."No.");
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            DocumentNo := QRBillMgt.LookupFilteredServiceInvoices();
                            if DocumentNo <> '' then
                                ValidateServiceInvoiceHeader(DocumentNo);
                        end;
                    }
                }

                group(ReminderFinChargeMemo)
                {
                    ShowCaption = false;

                    field(IssuedReminderHeaderNo; IssuedReminderHeader."No.")
                    {
                        Caption = 'Issued Reminder';
                        ToolTip = 'Specifies the document number of the selected issued reminder.';
                        ApplicationArea = All;
                        Visible = false;

                        trigger OnValidate()
                        begin
                            ValidateReminderHeader(IssuedReminderHeader."No.");
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            DocumentNo := QRBillMgt.LookupFilteredReminders();
                            if DocumentNo <> '' then
                                ValidateReminderHeader(DocumentNo);
                        end;
                    }
                    field(IssuedFinChargeMemoHeaderNo; IssuedFinChargeMemoHeader."No.")
                    {
                        Caption = 'Issued Finance Charge Memo';
                        ToolTip = 'Specifies the document number of the selected issued finance charge memo.';
                        ApplicationArea = All;
                        Visible = false;

                        trigger OnValidate()
                        begin
                            ValidateFinChargeMemoHeader(IssuedFinChargeMemoHeader."No.");
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            DocumentNo := QRBillMgt.LookupFilteredFinChargeMemos();
                            if DocumentNo <> '' then
                                ValidateFinChargeMemoHeader(DocumentNo);
                        end;
                    }
                }
            }
            group(FromLedgerEntries)
            {
                Caption = 'From Ledger Entry';

                field(CustomerLedgerEntry; CustLedgerEntry."Entry No.")
                {
                    Caption = 'Customer Ledger Entry';
                    ToolTip = 'Specifies the selected customer ledger entry.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ValidateCustomerLedgerEntry(CustLedgerEntry."Entry No.");
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        EntryNo := QRBillMgt.LookupFilteredCustLedgerEntries();
                        if EntryNo <> 0 then
                            ValidateCustomerLedgerEntry(EntryNo);
                    end;
                }
            }
        }
    }

    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        QRBillMgt: Codeunit "Swiss QR-Bill Mgt.";
        DocumentNo: Code[20];
        EntryNo: Integer;

    local procedure ResetSelection()
    begin
        SalesInvoiceHeader."No." := '';
        ServiceInvoiceHeader."No." := '';
        IssuedReminderHeader."No." := '';
        IssuedFinChargeMemoHeader."No." := '';
        Clear(CustLedgerEntry);
    end;

    local procedure GetDocumentFromLedgerEntry()
    begin
        if CustLedgerEntry."Entry No." <> 0 then
            case true of
                SalesInvoiceHeader.Get(CustLedgerEntry."Document No."):
                    ;
                QRBillMgt.FindServiceInvoiceFromLedgerEntry(ServiceInvoiceHeader, CustLedgerEntry):
                    ;
                QRBillMgt.FindIssuedReminderFromLedgerEntry(IssuedReminderHeader, CustLedgerEntry):
                    ;
                QRBillMgt.FindIssuedFinChargeMemoFromLedgerEntry(IssuedFinChargeMemoHeader, CustLedgerEntry):
                    ;
            end;
    end;

    local procedure ValidateLedgerEntry()
    begin
        CustLedgerEntry.Get(EntryNo);
        GetDocumentFromLedgerEntry();
    end;

    local procedure ValidateSalesInvoiceHeader(DocumentNo: Code[20])
    begin
        ResetSelection();
        if DocumentNo <> '' then
            with SalesInvoiceHeader do begin
                Get(DocumentNo);
                EntryNo := "Cust. Ledger Entry No.";
                ValidateLedgerEntry();
            end;
    end;

    local procedure ValidateServiceInvoiceHeader(DocumentNo: Code[20])
    begin
        ResetSelection();
        if DocumentNo <> '' then
            with ServiceInvoiceHeader do begin
                Get(DocumentNo);
                if QRBillMgt.FindCustLedgerEntry(EntryNo, "Bill-to Customer No.", CustLedgerEntry."Document Type"::Invoice, "No.", "Posting Date") then
                    ValidateLedgerEntry();
            end;
    end;

    local procedure ValidateReminderHeader(DocumentNo: Code[20])
    begin
        ResetSelection();
        if DocumentNo <> '' then
            with IssuedReminderHeader do begin
                Get(DocumentNo);
                if QRBillMgt.FindCustLedgerEntry(EntryNo, "Customer No.", CustLedgerEntry."Document Type"::Reminder, "No.", "Posting Date") then
                    ValidateLedgerEntry();
            end;
    end;

    local procedure ValidateFinChargeMemoHeader(DocumentNo: Code[20])
    begin
        ResetSelection();
        if DocumentNo <> '' then
            with IssuedFinChargeMemoHeader do begin
                Get(DocumentNo);
                if QRBillMgt.FindCustLedgerEntry(EntryNo, "Customer No.", CustLedgerEntry."Document Type"::"Finance Charge Memo", "No.", "Posting Date") then
                    ValidateLedgerEntry();
            end;
    end;

    local procedure ValidateCustomerLedgerEntry(EntryNo: Integer)
    begin
        ResetSelection();
        if EntryNo <> 0 then
            ValidateLedgerEntry();
    end;

    internal procedure GetSelectedLedgerEntry(): Integer
    begin
        exit(CustLedgerEntry."Entry No.");
    end;
}
