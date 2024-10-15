table 11511 "Swiss QR-Bill Billing Info"
{
    DataClassification = CustomerContent;
    DrillDownPageId = "Swiss QR-Bill Billing Info";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Document No."; Boolean)
        {
            Caption = 'Document No.';
        }
        field(3; "Document Date"; Boolean)
        {
            Caption = 'Document Date';
        }
        field(5; "VAT Number"; Boolean)
        {
            Caption = 'VAT Number';
        }
        field(6; "VAT Date"; Boolean)
        {
            Caption = 'VAT Date';
        }
        field(7; "VAT Details"; Boolean)
        {
            Caption = 'VAT Details';
        }
        field(9; "Payment Terms"; Boolean)
        {
            Caption = 'Payment Terms';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    var
        QRBillMgt: Codeunit "Swiss QR-Bill Mgt.";
        BillingInfo: Codeunit "Swiss QR-Bill Billing Info";
        DefaultCodeLbl: Label 'DEFAULT';

    internal procedure InitDefault()
    begin
        Init();
        Code := DefaultCodeLbl;
        "Document No." := true;
        "Document Date" := true;
        "VAT Date" := true;
        "VAT Number" := true;
        "VAT Details" := true;
        "Payment Terms" := true;
    end;

    internal procedure GetBillingInformation(CustomerLedgerEntryNo: Integer): Text[140]
    var
        CompanyInfo: Record "Company Information";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PaymentTermsCode: Code[10];
    begin
        CompanyInfo.Get();
        with CustLedgerEntry do begin
            Get(CustomerLedgerEntryNo);
            if "Document Type" = "Document Type"::Invoice then
                case true of
                    SalesInvoiceHeader.Get(CustLedgerEntry."Document No."):
                        begin
                            PaymentTermsCode := SalesInvoiceHeader."Payment Terms Code";
                            SalesInvoiceLine.CalcVATAmountLines(SalesInvoiceHeader, TempVATAmountLine);
                        end;
                    QRBillMgt.FindServiceInvoiceFromLedgerEntry(ServiceInvoiceHeader, CustLedgerEntry):
                        begin
                            PaymentTermsCode := ServiceInvoiceHeader."Payment Terms Code";
                            ServiceInvoiceLine.CalcVATAmountLines(ServiceInvoiceHeader, TempVATAmountLine);
                        end;
                end;
            exit(GetDocumentBillingInfo("Document No.", "Document Date", CompanyInfo."VAT Registration No.", "Posting Date", TempVATAmountLine, PaymentTermsCode));
        end;
    end;

    local procedure GetDocumentBillingInfo(DoumentNo: Code[20]; DocumentDate: Date; VATRegNo: Text; VATDate: Date; var TempVATAmountLine: Record "VAT Amount Line"; PaymentTermsCode: Code[10]): Text[140]
    var
        BillingDetail: Record "Swiss QR-Bill Billing Detail" temporary;
    begin
        if "Document No." then
            AddDetailsIfNotBlanked(BillingDetail, BillingDetail."Tag Type"::"Document No.", DoumentNo);
        if "Document Date" then
            AddDetailsIfNotBlanked(BillingDetail, BillingDetail."Tag Type"::"Document Date", BillingInfo.FormatDate(DocumentDate));
        if "VAT Number" then
            AddDetailsIfNotBlanked(BillingDetail, BillingDetail."Tag Type"::"VAT Registration No.", BillingInfo.FormatVATRegNo(VATRegNo));
        if "VAT Date" then
            AddDetailsIfNotBlanked(BillingDetail, BillingDetail."Tag Type"::"VAT Date", BillingInfo.FormatDate(VATDate));
        if "VAT Details" then
            AddDetailsIfNotBlanked(BillingDetail, BillingDetail."Tag Type"::"VAT Details", BillingInfo.GetDocumentVATDetails(TempVATAmountLine));
        if "Payment Terms" then
            AddDetailsIfNotBlanked(BillingDetail, BillingDetail."Tag Type"::"Payment Terms", BillingInfo.GetDocumentPaymentTerms(PaymentTermsCode));
        exit(BillingInfo.CreateBillingInfoString(BillingDetail, 'S1'));
    end;

    local procedure AddDetailsIfNotBlanked(var BillingDetail: Record "Swiss QR-Bill Billing Detail"; TagType: Enum "Swiss QR-Bill Billing Detail"; DetailsValue: Text)
    begin
        if DetailsValue <> '' then
            BillingDetail.AddBufferRecord('S1', TagType, DetailsValue, '');
    end;
}
