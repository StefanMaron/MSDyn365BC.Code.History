codeunit 12424 "VAT Invoice Journal Management"
{

    trigger OnRun()
    begin
    end;

    var
        LastEntryNo: Integer;

    [Scope('OnPrem')]
    procedure GetVendVATList(var TempVendorLedgerEntry: Record "Vendor Ledger Entry"; var Vendor: Record Vendor; ReportType: Option Received,Issued; DatePeriod: Record Date; ShowCorrection: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        TempVendorLedgerEntry.Reset();
        TempVendorLedgerEntry.DeleteAll();

        if Vendor.FindSet() then
            repeat
                with VendorLedgerEntry do begin
                    SetRange("Vendor No.", Vendor."No.");
                    if FindSet() then
                        repeat
                            if ("Document Type" = "Document Type"::Payment) and (ReportType = ReportType::Issued) then
                                if IsVATAgent("Entry No.") then
                                    InsertVATAgent(VendorLedgerEntry, TempVendorLedgerEntry, DatePeriod, ReportType, ShowCorrection);

                            if ("Vendor VAT Invoice Rcvd Date" >= DatePeriod."Period Start") and
                               ("Vendor VAT Invoice Rcvd Date" <= DatePeriod."Period End") and
                               IsVATinfoAvaliable(VendorLedgerEntry)
                            then
                                if ReportType = ReportType::Issued then begin
                                    if "Document Type" = "Document Type"::"Credit Memo" then
                                        if IsCrMemoIncludedInVatLedg("Document No.", ReportType) then
                                            InsertVendLE(VendorLedgerEntry, TempVendorLedgerEntry, DatePeriod, ReportType, ShowCorrection);
                                end else
                                    case "Document Type" of
                                        "Document Type"::Invoice:
                                            InsertVendLE(VendorLedgerEntry, TempVendorLedgerEntry, DatePeriod, ReportType, ShowCorrection);
                                        "Document Type"::Payment:
                                            if Prepayment then
                                                InsertVendLE(VendorLedgerEntry, TempVendorLedgerEntry, DatePeriod, ReportType, ShowCorrection);
                                        "Document Type"::"Credit Memo":
                                            if ShowCorrection and not IsCrMemoIncludedInVatLedg("Document No.", ReportType::Issued) then
                                                InsertVendLE(VendorLedgerEntry, TempVendorLedgerEntry, DatePeriod, ReportType, ShowCorrection);
                                    end;
                        until Next() = 0;
                end;
            until Vendor.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetCustVATList(var TempVendorLedgerEntry: Record "Vendor Ledger Entry"; var Customer: Record Customer; ReportType: Option Received,Issued; DatePeriod: Record Date; ShowCorrection: Boolean)
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        TempVendorLedgerEntry.Reset();
        TempVendorLedgerEntry.DeleteAll();

        if Customer.FindSet() then
            repeat
                with CustomerLedgerEntry do begin
                    SetRange("Posting Date", DatePeriod."Period Start", DatePeriod."Period End");
                    SetRange("Customer No.", Customer."No.");
                    if FindSet() then
                        repeat
                            if ReportType = ReportType::Received then begin
                                if "Document Type" = "Document Type"::"Credit Memo" then
                                    if IsCrMemoIncludedInVatLedg("Document No.", ReportType) then
                                        InsertCustLE(CustomerLedgerEntry, TempVendorLedgerEntry, DatePeriod, ReportType, ShowCorrection);
                            end else
                                case "Document Type" of
                                    "Document Type"::Invoice:
                                        InsertCustLE(CustomerLedgerEntry, TempVendorLedgerEntry, DatePeriod, ReportType, ShowCorrection);
                                    "Document Type"::Payment:
                                        if Prepayment then
                                            InsertCustLE(CustomerLedgerEntry, TempVendorLedgerEntry, DatePeriod, ReportType, ShowCorrection);
                                    "Document Type"::"Credit Memo":
                                        if not (ShowCorrection or IsCrMemoIncludedInVatLedg("Document No.", ReportType::Received)) then
                                            InsertCustLE(CustomerLedgerEntry, TempVendorLedgerEntry, DatePeriod, ReportType, ShowCorrection);
                                end;
                        until Next() = 0;
                end;
            until Customer.Next() = 0;
    end;

    local procedure IsVATinfoAvaliable(VendorLE: Record "Vendor Ledger Entry"): Boolean
    begin
        if (VendorLE."Vendor VAT Invoice No." = '') or
           (VendorLE."Vendor VAT Invoice Date" = 0D) or
           (VendorLE."Vendor VAT Invoice Rcvd Date" = 0D)
        then
            exit(false);

        exit(true);
    end;

    local procedure IsCrMemoIncludedInVatLedg(DocumentNo: Code[20]; ReportType: Option Received,Issued): Boolean
    begin
        case ReportType of
            ReportType::Issued:
                exit(IsPurchCrMemoIncludedInVatLedg(DocumentNo));
            ReportType::Received:
                exit(IsSalesCrMemoIncludedInVatLedg(DocumentNo));
        end;
    end;

    local procedure IsCrMemoCorrection(DocumentNo: Code[20]; ReportType: Option Received,Issued): Boolean
    begin
        case ReportType of
            ReportType::Issued:
                exit(IsPurchCrMemoCorrection(DocumentNo));
            ReportType::Received:
                exit(IsSalesCrMemoCorrection(DocumentNo));
        end;
    end;

    local procedure IsSalesCrMemoIncludedInVatLedg(DocumentNo: Code[20]): Boolean
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
    begin
        if SalesCrMemoHdr.Get(DocumentNo) then
            exit(SalesCrMemoHdr."Include In Purch. VAT Ledger");
        exit(false);
    end;

    local procedure IsPurchCrMemoIncludedInVatLedg(DocumentNo: Code[20]): Boolean
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        if PurchCrMemoHdr.Get(DocumentNo) then
            exit(PurchCrMemoHdr."Include In Sales VAT Ledger");
        exit(false);
    end;

    local procedure IsSalesCrMemoCorrection(DocumentNo: Code[20]): Boolean
    var
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
    begin
        if SalesCrMemoHdr.Get(DocumentNo) then
            exit(SalesCrMemoHdr.Correction);
        exit(false);
    end;

    local procedure IsPurchCrMemoCorrection(DocumentNo: Code[20]): Boolean
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        if PurchCrMemoHdr.Get(DocumentNo) then
            exit(PurchCrMemoHdr.Correction);
        exit(false);
    end;

    local procedure InsertVendLE(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry"; DatePeriod: Record Date; ReportType: Option Received,Issued; ShowCorrection: Boolean)
    var
        AmountLCY: Decimal;
        AmountFCY: Decimal;
        AppliedAmountLCY: Decimal;
        AppliedAmountFCY: Decimal;
    begin
        TempVendorLedgerEntry.Init();

        LastEntryNo += 1;
        TempVendorLedgerEntry."Entry No." := LastEntryNo;
        TempVendorLedgerEntry."CV Ledger Entry No." := VendorLedgerEntry."Entry No.";
        TempVendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type";
        TempVendorLedgerEntry."Vendor VAT Invoice Rcvd Date" := VendorLedgerEntry."Vendor VAT Invoice Rcvd Date";
        TempVendorLedgerEntry."Vendor VAT Invoice Date" := VendorLedgerEntry."Vendor VAT Invoice Date";

        if VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::Payment then
            TempVendorLedgerEntry."Document No." := VendorLedgerEntry."Document No."
        else
            if VendorLedgerEntry.Prepayment then begin
                TempVendorLedgerEntry."Document Type" := TempVendorLedgerEntry."Document Type"::Invoice;
                TempVendorLedgerEntry."Document No." :=
                  GetPurchPrepaymentSourceDocNo(VendorLedgerEntry."Vendor VAT Invoice No.", VendorLedgerEntry."Vendor No.");
            end else
                TempVendorLedgerEntry."Document No." := VendorLedgerEntry."Document No.";
        TempVendorLedgerEntry."Vendor VAT Invoice No." := VendorLedgerEntry."Vendor VAT Invoice No.";

        TempVendorLedgerEntry."Vendor No." := VendorLedgerEntry."Vendor No.";

        GetInitialVendAmounts(AmountLCY, AmountFCY, VendorLedgerEntry."Entry No.", VendorLedgerEntry."Vendor No.");

        if (TempVendorLedgerEntry."Document Type" <> TempVendorLedgerEntry."Document Type"::"Credit Memo") and ShowCorrection then begin
            CalcVendAppliedEntriesAmount(
              AppliedAmountLCY, AppliedAmountFCY,
              VendorLedgerEntry."Entry No.", VendorLedgerEntry."Vendor No.",
              DatePeriod."Period End", ReportType, ShowCorrection);

            AmountLCY := Abs(Round(AmountLCY + AppliedAmountLCY, 0.01));
            AmountFCY := Abs(Round(AmountFCY + AppliedAmountLCY, 0.01));
        end;

        TempVendorLedgerEntry."Purchase (LCY)" := Abs(Round(AmountLCY, 0.01));
        TempVendorLedgerEntry."Inv. Discount (LCY)" := Abs(Round(AmountFCY, 0.01));
        TempVendorLedgerEntry."Currency Code" := VendorLedgerEntry."Currency Code";
        TempVendorLedgerEntry."VAT Entry Type" := VendorLedgerEntry."VAT Entry Type";

        if TempVendorLedgerEntry."Purchase (LCY)" > 0 then
            TempVendorLedgerEntry.Insert();
    end;

    local procedure InsertCustLE(var CustLedgerEntry: Record "Cust. Ledger Entry"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry"; DatePeriod: Record Date; ReportType: Option Received,Issued; ShowCorrection: Boolean)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        AmountLCY: Decimal;
        AmountFCY: Decimal;
        AppliedAmountLCY: Decimal;
        AppliedAmountFCY: Decimal;
    begin
        TempVendorLedgerEntry.Init();

        LastEntryNo += 1;
        TempVendorLedgerEntry."Entry No." := LastEntryNo;
        TempVendorLedgerEntry."CV Ledger Entry No." := CustLedgerEntry."Entry No.";
        TempVendorLedgerEntry."Document Type" := CustLedgerEntry."Document Type";

        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Payment then
            TempVendorLedgerEntry."Document No." := CustLedgerEntry."Document No."
        else
            if CustLedgerEntry.Prepayment then begin
                TempVendorLedgerEntry."Document Type" := TempVendorLedgerEntry."Document Type"::Invoice;
                TempVendorLedgerEntry."Document No." := CustLedgerEntry."Prepayment Document No.";
            end else
                TempVendorLedgerEntry."Document No." := CustLedgerEntry."Document No.";
        TempVendorLedgerEntry."Vendor VAT Invoice Rcvd Date" := CustLedgerEntry."Posting Date";

        GetInitialCustAmounts(AmountLCY, AmountFCY, CustLedgerEntry."Entry No.", CustLedgerEntry."Customer No.");

        if (CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::"Credit Memo") and ShowCorrection then begin
            CalcCustAppliedEntriesAmount(
              AppliedAmountLCY, AppliedAmountFCY,
              CustLedgerEntry."Entry No.", CustLedgerEntry."Customer No.",
              DatePeriod."Period End", ReportType, ShowCorrection);

            AmountLCY := Abs(Round(AmountLCY + AppliedAmountLCY, 0.01));
            AmountFCY := Abs(Round(AmountFCY + AppliedAmountLCY, 0.01));
        end;

        TempVendorLedgerEntry."Purchase (LCY)" := Abs(Round(AmountLCY, 0.01));
        TempVendorLedgerEntry."Inv. Discount (LCY)" := Abs(Round(AmountFCY, 0.01));
        TempVendorLedgerEntry."Currency Code" := CustLedgerEntry."Currency Code";

        TempVendorLedgerEntry."Vendor No." := CustLedgerEntry."Customer No.";

        case CustLedgerEntry."Document Type" of
            CustLedgerEntry."Document Type"::Invoice:
                if SalesInvoiceHeader.Get(CustLedgerEntry."Document No.") then
                    TempVendorLedgerEntry."Vendor VAT Invoice Date" := SalesInvoiceHeader."Shipment Date";
            CustLedgerEntry."Document Type"::"Credit Memo":
                if SalesCrMemoHeader.Get(CustLedgerEntry."Document No.") then
                    TempVendorLedgerEntry."Vendor VAT Invoice Date" := SalesCrMemoHeader."Posting Date";
        end;

        TempVendorLedgerEntry."VAT Entry Type" := CustLedgerEntry."VAT Entry Type";
        if TempVendorLedgerEntry."Purchase (LCY)" > 0 then
            TempVendorLedgerEntry.Insert();
    end;

    local procedure GetInitialVendAmounts(var AmountLCY: Decimal; var AmountFCY: Decimal; EntryNo: Integer; VendorNo: Code[20]): Decimal
    var
        DetailedVendLedgerEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        with DetailedVendLedgerEntry do begin
            SetRange("Entry Type", "Entry Type"::"Initial Entry");
            SetRange("Vendor Ledger Entry No.", EntryNo);
            SetRange("Vendor No.", VendorNo);
            if FindFirst() then begin
                AmountLCY := "Amount (LCY)";
                if "Currency Code" <> '' then
                    AmountFCY := Amount;
            end;
        end;
    end;

    local procedure CalcVendAppliedEntriesAmount(var AmountLCY: Decimal; var AmountFCY: Decimal; EntryNo: Integer; VendorNo: Code[20]; PostingDate: Date; ReportType: Option Received,Issued; ShowCorrection: Boolean)
    var
        DetailedVendLedgerEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        with DetailedVendLedgerEntry do begin
            SetRange("Entry Type", "Entry Type"::Application);
            SetRange("Vendor Ledger Entry No.", EntryNo);
            SetRange("Vendor No.", VendorNo);
            SetRange("Posting Date", 0D, PostingDate);
            SetRange("Initial Document Type", "Initial Document Type"::Invoice);

            if FindSet() then
                repeat
                    if VendorLedgerEntry.Get("Applied Vend. Ledger Entry No.") then
                        case VendorLedgerEntry."Document Type" of
                            VendorLedgerEntry."Document Type"::"Credit Memo":
                                if not IsCrMemoIncludedInVatLedg(VendorLedgerEntry."Document No.", ReportType::Issued) then
                                    if IsCrMemoCorrection(VendorLedgerEntry."Document No.", ReportType::Issued) and ShowCorrection then begin
                                        AmountLCY += "Amount (LCY)";
                                        AmountFCY += Amount;
                                    end;
                            VendorLedgerEntry."Document Type"::Payment:
                                if "Prepmt. Diff." then begin
                                    AmountLCY += "Amount (LCY)";
                                    AmountFCY += Amount;
                                end
                        end;
                until Next() = 0;
        end;
    end;

    local procedure GetInitialCustAmounts(var AmountLCY: Decimal; var AmountFCY: Decimal; EntryNo: Integer; VendorNo: Code[20]): Decimal
    var
        DetailedCustLedgerEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with DetailedCustLedgerEntry do begin
            SetRange("Entry Type", "Entry Type"::"Initial Entry");
            SetRange("Cust. Ledger Entry No.", EntryNo);
            SetRange("Customer No.", VendorNo);

            if FindFirst() then begin
                AmountLCY := "Amount (LCY)";
                if "Currency Code" <> '' then
                    AmountFCY := Amount;
            end;
        end;
    end;

    local procedure CalcCustAppliedEntriesAmount(var AmountLCY: Decimal; var AmountFCY: Decimal; EntryNo: Integer; VendorNo: Code[20]; PostingDate: Date; ReportType: Option Received,Issued; ShowCorrection: Boolean)
    var
        DetailedCustLedgerEntry: Record "Detailed Cust. Ledg. Entry";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        with DetailedCustLedgerEntry do begin
            SetRange("Entry Type", "Entry Type"::Application);
            SetRange("Cust. Ledger Entry No.", EntryNo);
            SetRange("Customer No.", VendorNo);
            SetRange("Posting Date", 0D, PostingDate);
            SetRange("Initial Document Type", "Initial Document Type"::Invoice);

            if FindSet() then
                repeat
                    if CustomerLedgerEntry.Get("Applied Cust. Ledger Entry No.") then
                        case CustomerLedgerEntry."Document Type" of
                            CustomerLedgerEntry."Document Type"::"Credit Memo":
                                if not IsCrMemoIncludedInVatLedg(CustomerLedgerEntry."Document No.", ReportType::Received) then
                                    if IsCrMemoCorrection(CustomerLedgerEntry."Document No.", ReportType::Received) and ShowCorrection then begin
                                        AmountLCY += "Amount (LCY)";
                                        AmountFCY += Amount;
                                    end;
                            CustomerLedgerEntry."Document Type"::Payment:
                                if "Prepmt. Diff." then begin
                                    AmountLCY += "Amount (LCY)";
                                    AmountFCY += Amount;
                                end;
                        end;
                until Next() = 0;
        end;
    end;

    local procedure GetName(No: Code[20]; EntryType: Option Purchase,Sale): Text[250]
    var
        LocRepMgt: Codeunit "Local Report Management";
    begin
        if EntryType = EntryType::Sale then
            exit(LocRepMgt.GetCustName(No));

        exit(LocRepMgt.GetVendorName(No));
    end;

    local procedure GetCVType(EntryType: Option Purchase,Sale): Integer
    var
        CVType: Option Vendor,Customer;
    begin
        case EntryType of
            EntryType::Purchase:
                exit(CVType::Vendor);
            EntryType::Sale:
                exit(CVType::Customer);
        end;
    end;

    local procedure GetPurchPrepaymentSourceDocNo(VendorInvoiceNo: Code[20]; VendorNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Vendor Invoice No.", VendorInvoiceNo);
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);

        if PurchInvHeader.FindFirst() then
            exit(PurchInvHeader."No.");
    end;

    local procedure IsVATAgent(EntryNo: Integer): Boolean
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("CV Ledg. Entry No.", EntryNo);
        if VATEntry.FindFirst() then
            exit(VATEntry."VAT Agent");

        exit(false);
    end;

    local procedure InsertVATAgent(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry"; DatePeriod: Record Date; ReportType: Option Received,Issued; ShowCorrection: Boolean)
    var
        AmountLCY: Decimal;
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("CV Ledg. Entry No.", VendorLedgerEntry."Entry No.");
        VATEntry.SetRange("Posting Date", DatePeriod."Period Start", DatePeriod."Period End");
        if not VATEntry.FindFirst() then
            exit;
        if not VATEntry."VAT Agent" then
            exit;

        TempVendorLedgerEntry.Init();

        LastEntryNo += 1;
        TempVendorLedgerEntry."Entry No." := LastEntryNo;
        TempVendorLedgerEntry."CV Ledger Entry No." := VendorLedgerEntry."Entry No.";
        TempVendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        TempVendorLedgerEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        TempVendorLedgerEntry."Currency Code" := VendorLedgerEntry."Currency Code";

        TempVendorLedgerEntry."Vendor VAT Invoice Rcvd Date" := VendorLedgerEntry."Posting Date";
        TempVendorLedgerEntry."Document No." := VATEntry."Document No.";
        TempVendorLedgerEntry."Vendor VAT Invoice No." := VATEntry."Document No.";

        if (VATEntry.Amount <> 0) or (VATEntry.Base <> 0) then
            AmountLCY := VATEntry.Base + VATEntry.Amount
        else
            AmountLCY := VATEntry."Unrealized Base" + VATEntry."Unrealized Amount";

        TempVendorLedgerEntry."Purchase (LCY)" := Abs(Round(AmountLCY, 0.01));

        if TempVendorLedgerEntry."Purchase (LCY)" > 0 then
            TempVendorLedgerEntry.Insert();
    end;

    local procedure IsCorrectiveDocument(var CorrVATEntry: Record "VAT Entry"; CVNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; EntryType: Option Purchase,Sale): Boolean
    begin
        if EntryType = EntryType::Sale then
            CorrVATEntry.SetRange(Type, CorrVATEntry.Type::Sale)
        else
            CorrVATEntry.SetRange(Type, CorrVATEntry.Type::Purchase);
        CorrVATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        CorrVATEntry.SetRange("Document Type", DocType);
        CorrVATEntry.SetRange("Document No.", DocNo);
        if CorrVATEntry.FindFirst() then
            exit(CorrVATEntry."Corrective Doc. Type" <> CorrVATEntry."Corrective Doc. Type"::" ");

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetCVVATRegKPP(CVNo: Code[20]; CVType: Option Vendor,Customer; VATLedgerType: Option) VATRegNoKPP: Text
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATLedger: Record "VAT Ledger";
    begin
        VATRegNoKPP := '';
        if CVType = CVType::Customer then
            if VATLedgerType = VATLedger.Type::Purchase then begin
                CompanyInformation.Get();
                VATRegNoKPP := GetVATRegKPP(CompanyInformation."VAT Registration No.", CompanyInformation."KPP Code");
            end else begin
                Cust.Get(CVNo);
                VATRegNoKPP := GetVATRegKPP(Cust."VAT Registration No.", Cust."KPP Code");
            end
        else
            if VATLedgerType = VATLedger.Type::Sales then begin
                CompanyInformation.Get();
                VATRegNoKPP := GetVATRegKPP(CompanyInformation."VAT Registration No.", CompanyInformation."KPP Code");
            end else begin
                Vend.Get(CVNo);
                VATRegNoKPP := GetVATRegKPP(Vend."VAT Registration No.", Vend."KPP Code")
            end;
    end;

    [Scope('OnPrem')]
    procedure GetVATRegKPP(VATRegNo: Code[20]; KPPCode: Code[10]) VATRegNoKPP: Text
    begin
        VATRegNoKPP := VATRegNo;
        if KPPCode <> '' then begin
            if VATRegNoKPP <> '' then
                VATRegNoKPP := VATRegNoKPP + ' / ' + KPPCode
            else
                VATRegNoKPP := KPPCode;
        end;
    end;

    local procedure GetDocAmounts(var AmtInclVATText: Text[30]; var VATAmtText: Text[30]; var Column: Option " ",Decrease,Increase; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; EntryType: Option Purchase,Sale; VATExempt: Boolean)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VATEntry: Record "VAT Entry";
        LocRepMgt: Codeunit "Local Report Management";
        Sign: Integer;
        AmtInclVAT: Decimal;
        VATAmount: Decimal;
    begin
        AmtInclVATText := '';
        VATAmtText := '';
        Column := Column::" ";
        Sign := 1;
        if EntryType = EntryType::Sale then begin
            case DocType of
                VATEntry."Document Type"::Invoice:
                    if SalesInvHeader.Get(DocNo) then begin
                        CalcSalesInvAmount(AmtInclVAT, VATAmount, SalesInvHeader."No.");
                        if SalesInvHeader."Corrective Document" and
                           (SalesInvHeader."Corrective Doc. Type" = SalesInvHeader."Corrective Doc. Type"::Correction)
                        then
                            Column := Column::Increase;
                    end;
                VATEntry."Document Type"::"Credit Memo":
                    if SalesCrMemoHeader.Get(DocNo) then begin
                        if SalesCrMemoHeader."Corrective Document" and
                           (SalesCrMemoHeader."Corrective Doc. Type" = SalesCrMemoHeader."Corrective Doc. Type"::Correction)
                        then
                            Column := Column::Decrease
                        else
                            Sign := -1;
                        CalcSalesCrMemoAmount(AmtInclVAT, VATAmount, SalesCrMemoHeader."No.");
                    end;
            end;
        end else
            case DocType of
                VATEntry."Document Type"::Invoice:
                    if PurchInvHeader.Get(DocNo) then begin
                        CalcPurchInvAmount(AmtInclVAT, VATAmount, PurchInvHeader."No.");
                        if PurchInvHeader."Corrective Document" and
                           (PurchInvHeader."Corrective Doc. Type" = PurchInvHeader."Corrective Doc. Type"::Correction)
                        then
                            Column := Column::Increase;
                    end;
                VATEntry."Document Type"::"Credit Memo":
                    if PurchCrMemoHeader.Get(DocNo) then begin
                        if PurchCrMemoHeader."Corrective Document" and
                           (PurchCrMemoHeader."Corrective Doc. Type" = PurchCrMemoHeader."Corrective Doc. Type"::Correction)
                        then
                            Column := Column::Decrease
                        else
                            Sign := -1;
                        CalcPurchCrMemoAmount(AmtInclVAT, VATAmount, PurchCrMemoHeader."No.");
                    end;
            end;
        AmtInclVATText := Format(Sign * AmtInclVAT);
        if VATExempt then
            LocRepMgt.FormatVATExemptLine(VATAmtText, VATAmtText)
        else
            VATAmtText := Format(Sign * VATAmount);
    end;

    local procedure GetCurrencyInfo(CurrencyCode: Code[10]): Text[40]
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrencyDescription: Text[40];
    begin
        CurrencyDescription := '';
        if CurrencyCode = '' then begin
            GLSetup.Get();
            CurrencyCode := GLSetup."LCY Code";
        end;

        if Currency.Get(CurrencyCode) then begin
            CurrencyDescription :=
              LowerCase(CopyStr(Currency.Description, 1, 1)) + CopyStr(Currency.Description, 2);
            if Currency."RU Bank Digital Code" <> '' then begin
                if CurrencyDescription <> '' then
                    CurrencyDescription := CurrencyDescription + '; ' + Currency."RU Bank Digital Code"
                else
                    CurrencyDescription := Currency."RU Bank Digital Code";
            end;
        end;
        exit(CurrencyDescription);
    end;

    local procedure GetCorrVendVATInvNo(var OrigVATInvNo: Code[30]; var CorrVATInvNo: Code[30]; VendLedgEntryNo: Integer; EntryType: Option Purchase,Sale; PrintRevision: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        OrigPurchInvHeader: Record "Purch. Inv. Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if EntryType = EntryType::Purchase then
            if VendLedgEntry.Get(VendLedgEntryNo) then
                case VendLedgEntry."Document Type" of
                    VendLedgEntry."Document Type"::Invoice:
                        if PurchInvHeader.Get(VendLedgEntry."Document No.") then
                            if PurchInvHeader."Corrective Document" then begin
                                if (VendLedgEntry."Vendor VAT Invoice No." <> '') and
                                   (PurchInvHeader."Corrective Doc. Type" =
                                    PurchInvHeader."Corrective Doc. Type"::Correction)
                                then
                                    CorrVATInvNo := VendLedgEntry."Vendor VAT Invoice No.";
                                if (PurchInvHeader."Corrective Doc. Type" =
                                    PurchInvHeader."Corrective Doc. Type"::Correction) or
                                   ((PurchInvHeader."Corrective Doc. Type" =
                                     PurchInvHeader."Corrective Doc. Type"::Revision) and
                                    PrintRevision)
                                then
                                    if PurchInvHeader."Original Doc. Type" =
                                       PurchInvHeader."Original Doc. Type"::Invoice
                                    then begin
                                        OrigPurchInvHeader.Get(PurchInvHeader."Original Doc. No.");
                                        OrigPurchInvHeader.CalcFields("Vendor VAT Invoice No.");
                                        if OrigPurchInvHeader."Vendor VAT Invoice No." <> '' then
                                            OrigVATInvNo := OrigPurchInvHeader."Vendor VAT Invoice No."
                                        else
                                            OrigVATInvNo := OrigPurchInvHeader."No.";
                                    end else begin
                                        VendLedgEntry.SetCurrentKey("Document Type", "Document No.");
                                        VendLedgEntry.SetRange("Document Type", PurchInvHeader."Original Doc. Type");
                                        VendLedgEntry.SetRange("Document No.", PurchInvHeader."Original Doc. No.");
                                        if VendLedgEntry.FindFirst() then begin
                                            if VendLedgEntry."Vendor VAT Invoice No." <> '' then
                                                OrigVATInvNo := VendLedgEntry."Vendor VAT Invoice No."
                                            else
                                                OrigVATInvNo := VendLedgEntry."Document No.";
                                        end;
                                        VendLedgEntry.Reset();
                                    end;
                            end;
                    VendLedgEntry."Document Type"::"Credit Memo":
                        if PurchCrMemoHeader.Get(VendLedgEntry."Document No.") then
                            if PurchCrMemoHeader."Corrective Document" then begin
                                if (VendLedgEntry."Vendor VAT Invoice No." <> '') and
                                   (PurchCrMemoHeader."Corrective Doc. Type" =
                                    PurchCrMemoHeader."Corrective Doc. Type"::Correction)
                                then
                                    CorrVATInvNo := VendLedgEntry."Vendor VAT Invoice No.";
                                if (PurchCrMemoHeader."Corrective Doc. Type" =
                                    PurchCrMemoHeader."Corrective Doc. Type"::Correction) or
                                   ((PurchCrMemoHeader."Corrective Doc. Type" =
                                     PurchCrMemoHeader."Corrective Doc. Type"::Revision) and
                                    PrintRevision)
                                then
                                    if PurchCrMemoHeader."Original Doc. Type" =
                                       PurchCrMemoHeader."Original Doc. Type"::Invoice
                                    then begin
                                        OrigPurchInvHeader.Get(PurchCrMemoHeader."Original Doc. No.");
                                        OrigPurchInvHeader.CalcFields("Vendor VAT Invoice No.");
                                        if OrigPurchInvHeader."Vendor VAT Invoice No." <> '' then
                                            OrigVATInvNo := OrigPurchInvHeader."Vendor VAT Invoice No."
                                        else
                                            OrigVATInvNo := OrigPurchInvHeader."No.";
                                    end else begin
                                        VendLedgEntry.SetCurrentKey("Document Type", "Document No.");
                                        VendLedgEntry.SetRange("Document Type", PurchCrMemoHeader."Original Doc. Type");
                                        VendLedgEntry.SetRange("Document No.", PurchCrMemoHeader."Original Doc. No.");
                                        if VendLedgEntry.FindFirst() then begin
                                            if VendLedgEntry."Vendor VAT Invoice No." <> '' then
                                                OrigVATInvNo := VendLedgEntry."Vendor VAT Invoice No."
                                            else
                                                OrigVATInvNo := VendLedgEntry."Document No.";
                                        end;
                                        VendLedgEntry.Reset();
                                    end;
                            end;
                end;
    end;

    local procedure GetEntryType(var EntryType: Option Purchase,Sale; IsCrMemo: Boolean; DocNo: Code[20]; ReportType: Option Received,Issued)
    begin
        if ReportType = ReportType::Received then begin
            if IsCrMemo and IsCrMemoIncludedInVatLedg(DocNo, ReportType) then
                EntryType := EntryType::Sale
            else
                EntryType := EntryType::Purchase;
        end else begin
            if not (IsCrMemo and IsCrMemoIncludedInVatLedg(DocNo, ReportType)) then
                EntryType := EntryType::Sale
            else
                EntryType := EntryType::Purchase;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVATInvJnlLineValues(VendLedgEntry: Record "Vendor Ledger Entry"; var VATLedgerLine: Record "VAT Ledger Line"; LineNo: Integer; ReportType: Option Received,Issued; var AmtInclVATText: Text[30]; var VATAmtText: Text[30]; var Column: Option " ",Decrease,Increase; var VATInvRcvdDate: Date; var VATEntryType: Code[15]; var CurrDescr: Text[40]; var VATRegNoKPP: Text)
    var
        VATEntry: Record "VAT Entry";
        VATLedger: Record "VAT Ledger";
        VATLedgMgt: Codeunit "VAT Ledger Management";
        LocRepMgt: Codeunit "Local Report Management";
        EntryType: Option Purchase,Sale;
        Corrective: Boolean;
        VATExempt: Boolean;
        VATAgent: Boolean;
        DocumentNo: Code[30];
        DocumentDate: Date;
        CorrectionNo: Code[30];
        CorrectionDate: Date;
        RevisionNo: Code[20];
        RevisionDate: Date;
        RevisionOfCorrNo: Code[20];
        RevisionOfCorrDate: Date;
        PrintRevision: Boolean;
    begin
        with VendLedgEntry do begin
            VATAgent := IsVATAgent("CV Ledger Entry No.");
            GetEntryType(
              EntryType, "Document Type" = "Document Type"::"Credit Memo", "Document No.", ReportType);
            if VATAgent then
                EntryType := EntryType::Purchase;
            Corrective :=
              IsCorrectiveDocument(
                VATEntry, "Vendor No.", "Document Type", "Document No.", EntryType);
            VATExempt :=
              LocRepMgt.VATExemptLine(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
            GetDocAmounts(
              AmtInclVATText, VATAmtText, Column, "Document Type", "Document No.", EntryType, VATExempt);
            if Corrective then
                VATLedgMgt.GetCorrDocProperties(
                  VATEntry, DocumentNo, DocumentDate, CorrectionNo, CorrectionDate,
                  RevisionNo, RevisionDate, RevisionOfCorrNo, RevisionOfCorrDate, PrintRevision);
            if not Corrective or
               (((RevisionNo <> '') or (RevisionOfCorrNo <> '')) and not PrintRevision)
            then begin
                if ReportType = ReportType::Received then
                    DocumentNo := "Vendor VAT Invoice No."
                else
                    DocumentNo := "Document No.";
                DocumentDate := "Vendor VAT Invoice Date";
            end;

            GetCorrVendVATInvNo(DocumentNo, CorrectionNo, "CV Ledger Entry No.", EntryType, PrintRevision);

            VATLedgerLine.Init();
            VATLedgerLine."Line No." := LineNo;
            VATLedgerLine."Document No." := DocumentNo;
            VATLedgerLine."Document Date" := DocumentDate;
            VATLedgerLine."Correction No." := CorrectionNo;
            VATLedgerLine."Correction Date" := CorrectionDate;
            VATLedgerLine."Revision No." := RevisionNo;
            VATLedgerLine."Revision Date" := RevisionDate;
            VATLedgerLine."Revision of Corr. No." := RevisionOfCorrNo;
            VATLedgerLine."Revision of Corr. Date" := RevisionOfCorrDate;
            VATLedgerLine."Print Revision" := PrintRevision;
            if not VATAgent then
                VATLedgerLine."C/V Name" :=
                  CopyStr(GetName("Vendor No.", EntryType), 1, MaxStrLen(VATLedgerLine."C/V Name"))
            else
                VATLedgerLine."C/V Name" :=
                  CopyStr(LocRepMgt.GetCompanyName(), 1, MaxStrLen(VATLedgerLine."C/V Name"));
            VATInvRcvdDate := "Vendor VAT Invoice Rcvd Date";
            VATEntryType := "VAT Entry Type";
            CurrDescr := GetCurrencyInfo("Currency Code");
            VATRegNoKPP := GetCVVATRegKPP("Vendor No.", GetCVType(EntryType), VATLedger.Type::Purchase);
        end;
    end;

    local procedure CalcSalesInvAmount(var AmtInclVAT: Decimal; var VATAmount: Decimal; DocumentNo: Code[20])
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        with SalesInvLine do begin
            SetRange("Document No.", DocumentNo);
            if FindSet() then
                repeat
                    AmtInclVAT += "Amount Including VAT";
                    VATAmount += "Amount Including VAT" - Amount;
                until Next() = 0;
        end;
    end;

    local procedure CalcSalesCrMemoAmount(var AmtInclVAT: Decimal; var VATAmount: Decimal; DocumentNo: Code[20])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        with SalesCrMemoLine do begin
            SetRange("Document No.", DocumentNo);
            if FindSet() then
                repeat
                    AmtInclVAT += "Amount Including VAT";
                    VATAmount += "Amount Including VAT" - Amount;
                until Next() = 0;
        end;
    end;

    local procedure CalcPurchInvAmount(var AmtInclVAT: Decimal; var VATAmount: Decimal; DocumentNo: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        with PurchInvLine do begin
            SetRange("Document No.", DocumentNo);
            if FindSet() then
                repeat
                    AmtInclVAT += "Amount Including VAT";
                    VATAmount += "Amount Including VAT" - Amount;
                until Next() = 0;
        end;
    end;

    local procedure CalcPurchCrMemoAmount(var AmtInclVAT: Decimal; var VATAmount: Decimal; DocumentNo: Code[20])
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        with PurchCrMemoLine do begin
            SetRange("Document No.", DocumentNo);
            if FindSet() then
                repeat
                    AmtInclVAT += "Amount Including VAT";
                    VATAmount += "Amount Including VAT" - Amount;
                until Next() = 0;
        end;
    end;
}

