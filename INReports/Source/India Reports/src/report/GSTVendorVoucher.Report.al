report 18035 "GST Vendor Voucher"
{
    DefaultLayout = RDLC;
    RDLCLayout = './rdlc/GSTVendorVoucher.rdl';
    Caption = 'GST Vendor Voucher';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = Basic, Suite;

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Document No.")
                                order(ascending)
                                where("Document Type" = filter(Payment | Refund),
                                      "GST Group Code" = filter(<> ''));
            RequestFilterFields = "Document No.";

            column(DocumentNo_VendLedgerEntry; "Document No.")
            {
            }
            column(DocumentDate_VendLedgerEntry; "Document Date")
            {
            }
            column(VendorInfo_Address; Vendor.Address)
            {
            }
            column(VendorInfo_Address2; Vendor."Address 2")
            {
            }
            column(Vend_Gst_Reg_No; Vendor."GST Registration No.")
            {
            }
            column(Vend_State; Vendor."State Code")
            {
            }
            column(VendorInfo_Name; Vendor.Name)
            {
            }
            column(CompanyName; CompanyInformation.Name)
            {
            }
            column(ComapanyAddress; CompanyInformation.Address)
            {
            }
            column(ComapanyAddress2; CompanyInformation."Address 2")
            {
            }
            column(companyGstRegNo; CompanyInformation."GST Registration No.")
            {
            }
            column(companyStateCode; CompanyInformation."State Code")
            {
            }
            column(ReceiptVoucherNo; ReceiptVoucherNo)
            {
            }
            column(ReceiptVoucherDate; ReceiptVoucherDate)
            {
            }
            column(Amount_VendLedgerEntry; Amount)
            {
            }
            column(ReceiptVoucherLbl; ReciptVoucherlbl)
            {
            }
            column(SupplierLbl; SupplierLbl)
            {
            }
            column(NameLbl; NameLbl)
            {
            }
            column(GSTRegNoLbl; GSTRegNoLbl)
            {
            }
            column(AddressLbl; AddressLbl)
            {
            }
            column(GSTStateCodeLbl; GSTStateCodeLbl)
            {
            }
            column(VoucherNoLbl; VoucherNoLbl)
            {
            }
            column(ReceiptVoucherNoLbl; ReceiptVoucherNoLbl)
            {
            }
            column(PayerBilltoLbl; PayerBilltoLbl)
            {
            }
            column(PayerDateLbl; PayerDateLbl)
            {
            }
            column(PayerReceiptVoucherDateLbl; PayerReceiptVoucherDateLbl)
            {
            }
            column(HSNSACLbl; HSNSACLbl)
            {
            }
            column(HSNSACDEscLbl; HSNSACDEscLbl)
            {
            }
            column(AdvAmtlbl; AdvAmtLbl)
            {
            }
            column(CGSTLbl; CGSTLbl)
            {
            }
            column(CGSTAmtlbl; CGSTAmtLbl)
            {
            }
            column(SGSTlbl; SGSTLbl)
            {
            }
            column(SGSTAmtlbl; SGSTAmtLbl)
            {
            }
            column(IGSTAmtlbl; IGSTAmtLbl)
            {
            }
            column(IGSTlbl; IGSTLbl)
            {
            }
            column(CESSlbl; CESSLbl)
            {
            }
            column(CessAmtlbl; CessAmtLbl)
            {
            }
            column(TCSTDS; TCSTDSLbl)
            {
            }
            column(TCSTDSAmtlbl; TCSTDSAmtLbl)
            {
            }
            column(TotalAdvncAmtlbl; TotalAdvncAmtLbl)
            {
            }
            column(Reversechargelbl; ReversechargeLbl)
            {
            }
            column(AmountinWordslbl; AmountinWordsLbl)
            {
            }
            column(TaxamtinWordslbl; TaxamtinWordsLbl)
            {
            }
            column(TDSTCsAmntinWordslbl; TDSTCsAmntinWordsLbl)
            {
            }
            column(TotalGSTAmtlbl; TotalGSTAmtLbl)
            {
            }
            column(TotalTCSTDSAmtlbl; TotalTCSTDSAmtLbl)
            {
            }
            column(SignatureLbl; SignatureLbl)
            {
            }
            dataitem("Detailed GST Ledger Entry"; "Detailed GST Ledger Entry")
            {
                DataItemLink = "Document No." = field("Document No.");
                DataItemTableView = sorting("Transaction Type", "Document Type", "Document No.", "Document Line No.")
                                    order(ascending)
                                    where("Entry Type" = filter("Initial Entry"),
                                          "Transaction Type" = filter(Purchase),
                                          "Document Type" = filter(Payment | Refund));

                column(DocumentNo_VendLedgerEntry1; "Vendor Ledger Entry"."Document No.")
                {
                }
                column(DocumentNo; "Document No.")
                {
                }
                column(DocumentLineNo; "Document Line No.")
                {
                }
                column(HSNSACCode; "HSN/SAC Code")
                {
                }
                column(GSTGroupCode_DetailedGSTLedgerEntry; "GST Group Code")
                {
                }
                column(GSTAmount_DetailedGSTLedgerEntry; "GST Amount")
                {
                }
                column(GSTComponentCode; "GST Component Code")
                {
                }
                column(GSTBaseAmount; "GST Base Amount")
                {
                }
                column(GSTPercentage; "GST %")
                {
                }
                column(ReverseCharge; "Reverse Charge")
                {
                }
                column(CGSTAmount; CGSTAmount)
                {
                }
                column(SGSTAmount; SGSTAmount)
                {
                }
                column(CessAmount; CessAmount)
                {
                }
                column(IGSTAmount; IGSTAmount)
                {
                }
                column(CGSTPercentage; CGSTPercentage)
                {
                }
                column(SGSTPercentage; SGSTPercentage)
                {
                }
                column(CESSPercentage; CESSPercentage)
                {
                }
                column(IGSTPercentage; IGSTPercentage)
                {
                }
                column(TotalTaxAmount_DetGST; TotalTaxAmount)
                {
                }
                column(Description_HSNSAC; HSNDesc)
                {
                }
                column(TdSPercentage; TDSPercentage)
                {
                }
                column(TdSAmount; TDSAmount)
                {
                }
                column(TotalTaxAmount; TotalTaxAmount)
                {
                }
                column(AmountinTax; AmountInText[1] + AmountInText[2])
                {
                }
                column(AmountInTextTCS; AmountInTextTCS[1] + AmountInTextTCS[2])
                {
                }
                column(AmountInTextTAx; AmountInTextTAx[1] + AmountInTextTAx[2])
                {
                }
                column(TotalTdSamount; TotalTDSAmount)
                {
                }
                column(TotalAmount; TotalAmountLine)
                {
                }

                trigger OnAfterGetRecord()
                var
                    TDSEntry: Record "TDS Entry";
                    VendorLedgerEntry: Record "Vendor Ledger Entry";
                    DetailedGSTLedger: Record "Detailed GST Ledger Entry";
                begin
                    ClearData();
                    DetailedGstLedger.Reset();
                    DetailedGstLedger.SetRange("Document No.", "Detailed GST Ledger Entry"."Document No.");
                    repeat
                        if DetailedGSTLedger."GST Component Code" = 'CGST' then
                            CGSTAmount += Abs(DetailedGSTLedger."GST Amount");
                        CGSTPercentage := DetailedGstLedger."GST %";
                        if DetailedGSTLedger."GST Component Code" = 'SGST' then
                            SGSTAmount += Abs(DetailedGSTLedger."GST Amount");
                        SGSTPercentage := DetailedGstLedger."GST %";
                        if DetailedGSTLedger."GST Component Code" = 'IGST' then
                            IGSTAmount += Abs(DetailedGSTLedger."GST Amount");
                        IGSTPercentage := DetailedGstLedger."GST %";
                        if DetailedGSTLedger."GST Component Code" = 'UGST' then
                            CessAmount += Abs(DetailedGSTLedger."GST Amount");
                        CessAmount := DetailedGstLedger."GST %";
                    until DetailedGSTLedger.Next() = 0;

                    TotalTaxAmount += IGSTAmount + CGSTAmount + SGSTAmount + CessAmount;
                    HsnSac.Get("GST Group Code", "HSN/SAC Code");
                    HSNDesc := HsnSac.Description;
                    if (DGLEDocumentNo <> "Document No.") or (DocumentLineno <> "Document Line No.") then begin
                        TDSEntry.Reset();
                        //VendorLedgerEntry.Get("CLE/VLE Entry No.");
                        TDSEntry.SetRange("Document No.", "Detailed GST Ledger Entry"."Document No.");
                        //VendorLedgerEntry.CALCFIELDS(Amount);
                        //TDSEntry.SetRange("TDS Base Amount", VendorLedgerEntry.Amount);
                        if TDSEntry.FindFirst() then begin
                            TDSAmount := TDSEntry."TDS Amount Including Surcharge";
                            TDSPercentage := TDSEntry."TDS %";
                            TotalTDSAmount += TDSEntry."TDS Amount Including Surcharge";
                        end;
                        TotalAmount += TotalTDSAmount;
                        TotalAmountLine := TotalTDSAmount;
                    end;
                    Check.InitTextVariable();
                    Check.FormatNoText(AmountInText, Round(Abs(TotalAmount), 0.01, '='), '');
                    Check.FormatNoText(AmountInTextTAx, Round(Abs(TotalTaxAmount), 0.01, '='), '');
                    Check.FormatNoText(AmountInTextTCS, Round(Abs(TotalTDSAmount), 0.01, '='), '');
                    DGLEDocumentNo := "Document No.";
                    DocumentLineno := "Document Line No.";
                end;
            }

            trigger OnAfterGetRecord()
            var
                DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
            begin
                if DocumentNo = "Document No." then
                    CurrReport.SKIP();
                Vendor.Get("Vendor No.");
                if "Document Type" = "Document Type"::Payment then
                    ReciptVoucherlbl := 'Payment Voucher'
                else begin
                    ReciptVoucherlbl := 'Refund Voucher';
                    DetailedGSTLedgerEntry.SetCurrentKey("Transaction Type", "Document Type", "Document No.", "Document Line No.");
                    DetailedGSTLedgerEntry.SetRange("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Sales);
                    DetailedGSTLedgerEntry.SetRange("Document Type", DetailedGSTLedgerEntry."Document Type"::Refund);
                    DetailedGSTLedgerEntry.SetRange("Document No.", "Document No.");
                    if DetailedGSTLedgerEntry.FindFirst() then begin
                        ReceiptVoucherNo := DetailedGSTLedgerEntry."Original Adv. Pmt Doc. No.";
                        ReceiptVoucherDate := DetailedGSTLedgerEntry."Original Adv. Pmt Doc. Date";
                    end;
                end;
                DocumentNo := "Document No.";
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }


    trigger OnInitReport()
    begin
        CompanyInformation.Get();
    end;

    trigger OnPreReport()
    begin
        if "Vendor Ledger Entry".GetFilter("Document No.") = '' then
            Error(DocNoNotBlankErr);
    end;

    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        HsnSac: Record "HSN/SAC";
        Check: Report Check;
        AmountInText: array[2] of Text[80];
        AmountInTextTCS: array[2] of Text[80];
        AmountInTextTAx: array[2] of Text[80];
        HSNDesc: Text[50];
        CGSTAmount: Decimal;
        SGSTAmount: Decimal;
        CessAmount: Decimal;
        IGSTAmount: Decimal;
        CGSTPercentage: Decimal;
        SGSTPercentage: Decimal;
        CESSPercentage: Decimal;
        IGSTPercentage: Decimal;
        CompReportView: Option " ",CGST,"SGST / UTGST",IGST,CESS;
        ReciptVoucherlbl: Text[50];
        ReceiptVoucherNo: Code[20];
        ReceiptVoucherDate: Date;
        TDSAmount: Decimal;
        TDSPercentage: Decimal;
        TotalTaxAmount: Decimal;
        DocumentNo: Code[20];
        TotalTDSAmount: Decimal;
        TotalAmount: Decimal;
        DGLEDocumentNo: Code[20];
        DocumentLineno: Integer;
        TotalAmountLine: Decimal;
        SupplierLbl: Label 'Supplier';
        NameLbl: Label 'Name';
        GSTRegNoLbl: Label 'GST Reg. No.';
        AddressLbl: Label 'Address';
        GSTStateCodeLbl: Label 'GST State Code';
        VoucherNoLbl: Label 'Voucher No.';
        ReceiptVoucherNoLbl: Label 'Receipt Voucher No.';
        PayerBilltoLbl: Label 'Payer (Bill to)';
        PayerDateLbl: Label 'Date';
        PayerReceiptVoucherDateLbl: Label 'Receipt voucher Date';
        HSNSACLbl: Label 'HSN/SAC Code';
        HSNSACDEscLbl: Label 'HSN/SAC Description ';
        AdvAmtLbl: Label 'Advance Amount ';
        CGSTLbl: Label 'CGST %';
        CGSTAmtLbl: Label 'CGST Amount';
        SGSTLbl: Label 'SGST %';
        SGSTAmtLbl: Label 'SGST Amount';
        IGSTAmtLbl: Label 'IGST Amount';
        IGSTLbl: Label 'IGST %';
        CESSLbl: Label 'CESS %';
        CessAmtLbl: Label 'CESS Amount';
        TCSTDSLbl: Label 'TDS %';
        TCSTDSAmtLbl: Label 'TDS Amount';
        TotalAdvncAmtLbl: Label 'Total Advance amount ';
        ReversechargeLbl: Label 'Reverse Charge ';
        AmountinWordsLbl: Label 'Total Amount in words ';
        TaxamtinWordsLbl: Label 'Total Tax Amount in words';
        TDSTCsAmntinWordsLbl: Label 'Total TDS amount in words';
        TotalGSTAmtLbl: Label 'Total IGST / CGST / SGST / CESS Tax Amount';
        TotalTCSTDSAmtLbl: Label 'Total TCS / TDS Amount';
        SignatureLbl: Label 'Signature';
        DocNoNotBlankErr: Label 'Document No. cannot be blank.';

    local procedure GetGSTAmountLine(DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry"; ReportView: Option): Decimal
    var
        GSTComponent: Record "GST Component";
    begin
        if GSTComponent.Get(DetailedGSTLedgerEntry."GST Component Code") then
            if GSTComponent."Report View" = ReportView then
                exit(DetailedGSTLedgerEntry."GST Amount");
    end;

    local procedure ClearData()
    begin
        Clear(CGSTAmount);
        Clear(SGSTAmount);
        Clear(CessAmount);
        Clear(IGSTAmount);
        Clear(CGSTPercentage);
        Clear(SGSTPercentage);
        Clear(IGSTPercentage);
        Clear(CESSPercentage);
        Clear(HSNDesc);
        Clear(TDSAmount);
        Clear(TDSPercentage);
        Clear(TotalAmountLine);
    end;

    local procedure CheckComponentReportView(ComponentCode: Code[10])
    var
        GSTComponent: Record "GST Component";
    begin
        GSTComponent.Get(ComponentCode);
        GSTComponent.TestField("Report View");
    end;

    local procedure GetGSTPercentageLine(DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry"; ReportView: Option): Decimal
    var
        GSTComponent: Record "GST Component";
    begin
        if GSTComponent.Get(DetailedGSTLedgerEntry."GST Component Code") then
            if GSTComponent."Report View" = ReportView then
                exit(DetailedGSTLedgerEntry."GST %");
    end;
}