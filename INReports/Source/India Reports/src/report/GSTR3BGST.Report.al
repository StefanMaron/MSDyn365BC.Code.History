report 18007 "GSTR-3B GST"
{
    DefaultLayout = RDLC;
    RDLCLayout = './rdlc/GSTR3B.rdl';
    Caption = 'GSTR-3B';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = Basic, Suite;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number)
                                order(ascending)
                                where(Number = filter(1));

            column(GSTRLbl; GSTRLbl)
            {
            }
            column(RuleLbl; RuleLbl)
            {
            }
            column(YearLbl; YearLbl)
            {
            }
            column(MonthLbl; MonthLbl)
            {
            }
            column(GSTINLbl; GSTINLbl)
            {
            }
            column(LegalNameLbl; LegalNameLbl)
            {
            }
            column(OutwardSpplyLbl; OutwardSpplyLbl)
            {
            }
            column(NatureofSpplyLbl; NatureofSpplyLbl)
            {
            }
            column(TotTaxableLbl; TotTaxableLbl)
            {
            }
            column(IntegratedLbl; IntegratedLbl)
            {
            }
            column(CentralLbl; CentralLbl)
            {
            }
            column(StateTaxLbl; StateTaxLbl)
            {
            }
            column(CessLbl; CessLbl)
            {
            }
            column(OutwardTaxableSpplyLbl; OutwardTaxableSpplyLbl)
            {
            }
            column(OutwardTaxableSpplyZeroLbl; OutwardTaxableSpplyZeroLbl)
            {
            }
            column(OutwardTaxableSpplyNilLbl; OutwardTaxableSpplyNilLbl)
            {
            }
            column(InwardSpplyLbl; InwardSpplyLbl)
            {
            }
            column(NonGSTOutwardSpplyLbl; NonGSTOutwardSpplyLbl)
            {
            }
            column(UnregCompoLbl; UnregCompoLbl)
            {
            }
            column(PlaceOfSupplyLbl; PlaceOfSupplyLbl)
            {
            }
            column(IntegratedTaxLbl; IntegratedTaxLbl)
            {
            }
            column(EligibleITCLbl; EligibleITCLbl)
            {
            }
            column(NatureOfSuppliesLbl; NatureOfSuppliesLbl)
            {
            }
            column(ITCAvlLbl; ITCAvlLbl)
            {
            }
            column(ImportGoodLbl; ImportGoodLbl)
            {
            }
            column(ImportServiceLbl; ImportServiceLbl)
            {
            }
            column(InwrdReverseLbl; InwrdReverseLbl)
            {
            }
            column(InwrdISDLbl; InwrdISDLbl)
            {
            }
            column(AllITCLbl; AllITCLbl)
            {
            }
            column(ITCReverseLbl; ITCReverseLbl)
            {
            }
            column(RulesLbl; RulesLbl)
            {
            }
            column(OthersLbl; OthersLbl)
            {
            }
            column(NetITCLbl; NetITCLbl)
            {
            }
            column(IneligibleITCLbl; IneligibleITCLbl)
            {
            }
            column(SectionLbl; SectionLbl)
            {
            }
            column(ValuesExemptLbl; ValuesExemptLbl)
            {
            }
            column(InterStateSpplyLbl; InterStateSpplyLbl)
            {
            }
            column(IntraStateLbl; IntraStateLbl)
            {
            }
            column(SupplierCompLbl; SupplierCompLbl)
            {
            }
            column(NonGSTSpply; NonGSTSpplyLbl)
            {
            }
            column(PaymentLbl; PaymentLbl)
            {
            }
            column(DescLbl; DescLbl)
            {
            }
            column(TaxLbl; TaxLbl)
            {
            }
            column(PayableLbl; PayableLbl)
            {
            }
            column(PaidITCLbl; PaidITCLbl)
            {
            }
            column(TaxPaidLbl; TaxPaidLbl)
            {
            }
            column(TDSTCSLbl; TDSTCSLbl)
            {
            }
            column(TaxCessLbl; TaxCessLbl)
            {
            }
            column(CashLbl; CashLbl)
            {
            }
            column(InterestLbl; InterestLbl)
            {
            }
            column(LateFeeLbl; LateFeeLbl)
            {
            }
            column(TDSTCSCrLbl; TDSTCSCrLbl)
            {
            }
            column(DetailsLbl; DetailsLbl)
            {
            }
            column(TDSLbl; TDSLbl)
            {
            }
            column(TCSLbl; TCSLbl)
            {
            }
            column(VerificationLbl; VerificationLbl)
            {
            }
            column(VerifyTxtLbl; VerifyTxtLbl)
            {
            }
            column(PlaceLbl; PlaceLbl)
            {
            }
            column(DateLbl; DateLbl)
            {
            }
            column(Place; Place)
            {
            }
            column(PostingDate; PostingDate)
            {
            }
            column(ResponsibleLbl; AuthorisedPerson)
            {
            }
            column(SignatoryLbl; SignatoryLbl)
            {
            }
            column(GSTIN; GSTIN)
            {
            }
            column(Year; Year)
            {
            }
            column(Month; Month)
            {
            }
            column(LegalName; CompanyInformation.Name + CompanyInformation."Name 2")
            {
            }
            column(GSTINChar1; gstinchar[1])
            {
            }
            column(GSTINChar2; gstinchar[2])
            {
            }
            column(GSTINChar3; gstinchar[3])
            {
            }
            column(GSTINChar4; gstinchar[4])
            {
            }
            column(GSTINChar5; gstinchar[5])
            {
            }
            column(GSTINChar6; gstinchar[6])
            {
            }
            column(GSTINChar7; gstinchar[7])
            {
            }
            column(GSTINChar8; gstinchar[8])
            {
            }
            column(GSTINChar9; gstinchar[9])
            {
            }
            column(GSTINChar10; gstinchar[10])
            {
            }
            column(GSTINChar11; gstinchar[11])
            {
            }
            column(GSTINChar12; gstinchar[12])
            {
            }
            column(GSTINChar13; gstinchar[13])
            {
            }
            column(GSTINChar14; gstinchar[14])
            {
            }
            column(GSTINChar15; gstinchar[15])
            {
            }
            column(OwrdtaxableTotalAmount; -OwrdtaxableTotalAmount)
            {
            }
            column(OwrdtaxableIGSTAmount; -OwrdtaxableIGSTAmount)
            {
            }
            column(OwrdtaxableCGSTAmount; -OwrdtaxableCGSTAmount)
            {
            }
            column(OwrdtaxableSGSTUTGSTAmount; -OwrdtaxableSGSTUTGSTAmount)
            {
            }
            column(OwrdtaxableCESSAmount; -OwrdtaxableCESSAmount)
            {
            }
            column(OwrdZeroTotalAmount; -OwrdZeroTotalAmount)
            {
            }
            column(OwrdZeroIGSTAmount; -OwrdZeroIGSTAmount)
            {
            }
            column(OwrdZeroCGSTAmount; -OwrdZeroCGSTAmount)
            {
            }
            column(OwrdZeroSGSTUTGSTAmount; -OwrdZeroSGSTUTGSTAmount)
            {
            }
            column(OwrdZeroCESSAmount; -OwrdZeroCESSAmount)
            {
            }
            column(OwrdNilTotalAmount; -OwrdNilTotalAmount)
            {
            }
            column(OwrdNilIGSTAmount; -OwrdNilIGSTAmount)
            {
            }
            column(OwrdNilCGSTAmount; -OwrdNilCGSTAmount)
            {
            }
            column(OwrdNilSGSTUTGSTAmount; -OwrdNilSGSTUTGSTAmount)
            {
            }
            column(OwrdNilCESSAmount; -OwrdNilCESSAmount)
            {
            }
            column(InwrdtotalAmount; InwrdtotalAmount)
            {
            }
            column(InwrdIGSTAmount; InwrdIGSTAmount)
            {
            }
            column(InwrdCGSTAmount; InwrdCGSTAmount)
            {
            }
            column(InwrdSGSTUTGSTAmount; InwrdSGSTUTGSTAmount)
            {
            }
            column(InwrdCESSAmount; InwrdCESSAmount)
            {
            }
            column(OwrdNonGSTTotalAmount; OwrdNonGSTTotalAmount)
            {
            }
            column(ImportGoodsIGSTAmount; ImportGoodsIGSTAmount)
            {
            }
            column(ImportGoodsCGSTAmount; ImportGoodsCGSTAmount)
            {
            }
            column(ImportGoodsSGSTUTGSTAmount; ImportGoodsSGSTUTGSTAmount)
            {
            }
            column(ImportGoodsCESSAmount; ImportGoodsCESSAmount)
            {
            }
            column(ImportServiceIGSTAmount; ImportServiceIGSTAmount)
            {
            }
            column(ImportServiceCGSTAmount; ImportServiceCGSTAmount)
            {
            }
            column(ImportServiceSGSTUTGSTAmount; ImportServiceSGSTUTGSTAmount)
            {
            }
            column(ImportServiceCESSAmount; ImportServiceCESSAmount)
            {
            }
            column(InwrdReverseIGSTAmount; InwrdReverseIGSTAmount)
            {
            }
            column(InwrdReverseCGSTAmount; InwrdReverseCGSTAmount)
            {
            }
            column(InwrdReverseSGSTUTGSTAmount; InwrdReverseSGSTUTGSTAmount)
            {
            }
            column(InwrdReverseCESSAmount; InwrdReverseCESSAmount)
            {
            }
            column(AllOtherITCIGSTAmount; AllOtherITCIGSTAmount)
            {
            }
            column(AllOtherITCCGSTAmount; AllOtherITCCGSTAmount)
            {
            }
            column(AllOtherITCSGSTUTGSTAmount; AllOtherITCSGSTUTGSTAmount)
            {
            }
            column(AllOtherITCCESSAmount; AllOtherITCCESSAmount)
            {
            }
            column(IneligibleITCIGSTAmount; IneligibleITCIGSTAmount)
            {
            }
            column(IneligibleITCCGSTAmount; IneligibleITCCGSTAmount)
            {
            }
            column(IneligibleITCSGSTUTGSTAmount; IneligibleITCSGSTUTGSTAmount)
            {
            }
            column(IneligibleITCCESSAmount; IneligibleITCCESSAmount)
            {
            }
            column(InwrdISDIGSTAmount; InwrdISDIGSTAmount)
            {
            }
            column(InwrdISDCGSTAmount; InwrdISDCGSTAmount)
            {
            }
            column(InwrdISDSGSTUTGSTAmount; InwrdISDSGSTUTGSTAmount)
            {
            }
            column(InwrdISDCESSAmount; InwrdISDCESSAmount)
            {
            }
            column(InterStateCompSupplyAmount; InterStateCompSupplyAmount)
            {
            }
            column(IntraStateCompSupplyAmount; IntraStateCompSupplyAmount)
            {
            }
            column(PurchInterStateAmount; PurchInterStateAmount)
            {
            }
            column(PurchIntraStateAmount; PurchIntraStateAmount)
            {
            }
            column(SupplyUnregLbl; SupplyUnregLbl)
            {
            }
            column(SupplyCompLbl; SupplyCompLbl)
            {
            }
            column(SupplyUINLbl; SupplyUINLbl)
            {
            }
            column(OthersIGSTAmount; OthersIGSTAmount)
            {
            }
            column(OthersCGSTAmount; OthersCGSTAmount)
            {
            }
            column(OthersSGSTUTGSTAmount; OthersSGSTUTGSTAmount)
            {
            }
            column(OthersCESSAmount; OthersCESSAmount)
            {
            }
            column(InwrdtotalAmount1; InwrdtotalAmount1)
            {
            }
            column(InwrdIGSTAmount1; InwrdIGSTAmount1)
            {
            }
            column(InwrdCGSTAmount1; InwrdCGSTAmount1)
            {
            }
            column(InwrdSGSTUTGSTAmount1; InwrdSGSTUTGSTAmount1)
            {
            }
            column(InwrdCESSAmount1; InwrdCESSAmount1)
            {
            }
            column(InwrdReverseIGSTAmount1; InwrdReverseIGSTAmount1)
            {
            }
            column(InwrdReverseCGSTAmount1; InwrdReverseCGSTAmount1)
            {
            }
            column(InwrdReverseSGSTUTGSTAmount1; InwrdReverseSGSTUTGSTAmount1)
            {
            }
            column(InwrdReverseCESSAmount1; InwrdReverseCESSAmount1)
            {
            }
            column(ImportServiceIGSTAmount1; ImportServiceIGSTAmount1)
            {
            }
            column(ImportServiceCGSTAmount1; ImportServiceCGSTAmount1)
            {
            }
            column(ImportServiceSGSTUTGSTAmount1; ImportServiceSGSTUTGSTAmount1)
            {
            }
            column(ImportServiceCESSAmount1; ImportServiceCESSAmount1)
            {
            }

            trigger OnPreDataItem()
            begin
                for i := 1 TO 15 do
                    if GSTIN = '' then
                        gstinchar[i] := ''
                    else
                        gstinchar[i] := CopyStr(GSTIN, i, 1);
                if PeriodDate = 0D then
                    Error(PeriodDateErr);
                if AuthorisedPerson = '' then
                    Error(AuthErr);
                if Place = '' then
                    Error(PlaceErr);
                if PostingDate = 0D then
                    Error(PostingDateBlankErr);
                Month := Date2DMY(PeriodDate, 2) - 1;
                Year := Format(Date2DMY(PeriodDate, 3));
                StartingDate := CalcDate('<CM-1M+1D>', PeriodDate);
                EndingDate := CalcDate('<CM>', PeriodDate);
                CompanyInformation.Get();
                CalculateValues();
            end;
        }
        dataitem(SupplyUnreg; "Detailed GST Ledger Entry")
        {
            DataItemTableView = where("GST Jurisdiction Type" = filter(Interstate));

            column(PlaceOfSupplyUnreg; PlaceOfSupplyUnreg)
            {
            }
            column(SupplyBaseAmtUnreg; -SupplyBaseAmtUnreg)
            {
            }
            column(SupplyIGSTAmtUnreg; -SupplyIGSTAmtUnreg)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Clear(PlaceOfSupplyUnreg);
                Clear(SupplyBaseAmtUnreg);
                Clear(SupplyIGSTAmtUnreg);
                if not ("Component Calc. Type" in ["Component Calc. Type"::General,
                                                   "Component Calc. Type"::Threshold,
                                                   "Component Calc. Type"::"Cess %"])
                then
                    CurrReport.SKIP();
                CheckComponentReportView("GST Component Code");
                if (EntryType <> "Entry Type") or (DocumentType <> "Document Type") or
                   (DocumentNo <> "Document No.") or (TransactionNo <> "Transaction No.") or
                   (OriginalDocNo <> "Original Doc. No.") or (DocumentLineNo <> "Document Line No.") or
                   (OriginalInvNo <> "Original Invoice No.") or (ItemChargeAssgnLineNo <> "Item Charge Assgn. Line No.")
                then begin
                    SupplyBaseAmtUnreg := GetBaseAmount(SupplyUnreg);
                    if SupplyBaseAmtUnreg <> 0 then begin
                        if "Shipping Address State Code" <> '' then
                            PlaceOfSupplyUnreg := "Shipping Address State Code"
                        else
                            PlaceOfSupplyUnreg := "Buyer/Seller State Code";
                        SupplyIGSTAmtUnreg := GetSupplyGSTAmountRec(SupplyUnreg, CompReportView::IGST);
                    end;
                    EntryType := "Entry Type";
                    DocumentType := "Document Type";
                    DocumentNo := "Document No.";
                    DocumentLineNo := "Document Line No.";
                    OriginalDocNo := "Original Doc. No.";
                    TransactionNo := "Transaction No.";
                    OriginalInvNo := "Original Invoice No.";
                    ItemChargeAssgnLineNo := "Item Charge Assgn. Line No.";
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetCurrentKey("Location  Reg. No.", "Source Type", "GST Customer Type", "Posting Date");
                SetRange("Location  Reg. No.", GSTIN);
                SetRange("Source Type", "Source Type"::Customer);
                SetFilter("GST Customer Type", '%1', "GST Customer Type"::Unregistered);
                SetRange("Posting Date", StartingDate, EndingDate);
                SetCurrentKey("Transaction Type", "Entry Type", "Document Type", "Document No.",
                  "Transaction No.", "Original Doc. No.", "Document Line No.",
                  "Original Invoice No.", "Item Charge Assgn. Line No.");
                ClearDocInfo();
            end;
        }
        dataitem(SupplyUIN; "Detailed GST Ledger Entry")
        {
            DataItemTableView = where("GST Jurisdiction Type" = filter(Interstate));

            column(PlaceOfSupplyUIN; PlaceOfSupplyUIN)
            {
            }
            column(SupplyBaseAmtUIN; -SupplyBaseAmtUIN)
            {
            }
            column(SupplyIGSTAmtUIN; -SupplyIGSTAmtUIN)
            {
            }

            trigger OnAfterGetRecord()
            var
                Customer: Record Customer;
            begin
                Clear(PlaceOfSupplyUIN);
                Clear(SupplyBaseAmtUIN);
                Clear(SupplyIGSTAmtUIN);
                Customer.Get("Source No.");
                if Customer."GST Registration Type" <> Customer."GST Registration Type"::UID then
                    CurrReport.SKIP();
                if not ("Component Calc. Type" in ["Component Calc. Type"::General,
                                                   "Component Calc. Type"::Threshold,
                                                   "Component Calc. Type"::"Cess %"])
                then
                    CurrReport.SKIP();
                CheckComponentReportView("GST Component Code");
                if (EntryType <> "Entry Type") or (DocumentType <> "Document Type") or
                   (DocumentNo <> "Document No.") or (TransactionNo <> "Transaction No.") or
                   (OriginalDocNo <> "Original Doc. No.") or (DocumentLineNo <> "Document Line No.") or
                   (OriginalInvNo <> "Original Invoice No.") or (ItemChargeAssgnLineNo <> "Item Charge Assgn. Line No.")
                then begin
                    SupplyBaseAmtUIN := GetBaseAmount(SupplyUIN);
                    if SupplyBaseAmtUIN <> 0 then begin
                        if "Shipping Address State Code" <> '' then
                            PlaceOfSupplyUIN := "Shipping Address State Code"
                        else
                            PlaceOfSupplyUIN := "Buyer/Seller State Code";
                        SupplyIGSTAmtUIN := GetSupplyGSTAmountRec(SupplyUIN, CompReportView::IGST);
                    end;
                    EntryType := "Entry Type";
                    DocumentType := "Document Type";
                    DocumentNo := "Document No.";
                    DocumentLineNo := "Document Line No.";
                    OriginalDocNo := "Original Doc. No.";
                    TransactionNo := "Transaction No.";
                    OriginalInvNo := "Original Invoice No.";
                    ItemChargeAssgnLineNo := "Item Charge Assgn. Line No.";
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetCurrentKey("Location  Reg. No.", "Source Type", "GST Customer Type", "Posting Date");
                SetRange("Location  Reg. No.", GSTIN);
                SetRange("Source Type", "Source Type"::Customer);
                SetFilter("GST Customer Type", '%1', "GST Customer Type"::Registered);
                SetRange("Posting Date", StartingDate, EndingDate);
                SetCurrentKey("Transaction Type", "Entry Type", "Document Type",
                  "Document No.", "Transaction No.", "Original Doc. No.", "Document Line No.",
                  "Original Invoice No.", "Item Charge Assgn. Line No.");
                ClearDocInfo();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(GSTIN; GSTIN)
                {
                    Caption = 'GSTIN No.';
                    TableRelation = "GST Registration Nos.";
                    ApplicationArea = Basic, Suite;
                }
                field(PeriodDate; PeriodDate)
                {
                    Caption = 'Period Date';
                    ApplicationArea = Basic, Suite;
                }
                field(AuthorisedPerson; AuthorisedPerson)
                {
                    Caption = 'Name of the Authorized Person';
                    ApplicationArea = Basic, Suite;
                }
                field(Place; Place)
                {
                    Caption = 'Place';
                    ApplicationArea = Basic, Suite;
                }
                field(PostingDate; PostingDate)
                {
                    Caption = 'Posting Date';
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        if PeriodDate = 0D then
                            ERROR(PeriodDateErr);
                        if PostingDate <= CALCDATE('<CM>', PeriodDate) then
                            ERROR(PostingDateErr, CALCDATE('<CM>', PeriodDate));
                    end;
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        PostedGSTLiabilityAdj: Record "Posted GST Liability Adj.";
        CompanyInformation: Record "Company Information";
        DetailedCrAdjstmntEntry: Record "Detailed Cr. Adjstmnt. Entry";
        GSTIN: Code[15];
        PeriodDate: Date;
        AuthorisedPerson: Text[100];
        Place: Text[50];
        PostingDate: Date;
        Month: Option January,February,March,April,May,June,July,August,September,October,November,December;
        Year: Code[4];
        StartingDate: Date;
        EndingDate: Date;
        PlaceOfSupplyUnreg: Code[10];
        SupplyBaseAmtUnreg: Decimal;
        SupplyIGSTAmtUnreg: Decimal;
        PlaceOfSupplyUIN: Code[10];
        SupplyBaseAmtUIN: Decimal;
        SupplyIGSTAmtUIN: Decimal;
        OwrdtaxableTotalAmount: Decimal;
        OwrdtaxableIGSTAmount: Decimal;
        OwrdtaxableCGSTAmount: Decimal;
        OwrdtaxableSGSTUTGSTAmount: Decimal;
        OwrdtaxableCESSAmount: Decimal;
        OwrdZeroTotalAmount: Decimal;
        OwrdZeroIGSTAmount: Decimal;
        OwrdZeroCGSTAmount: Decimal;
        OwrdZeroSGSTUTGSTAmount: Decimal;
        OwrdZeroCESSAmount: Decimal;
        OwrdNilTotalAmount: Decimal;
        OwrdNilIGSTAmount: Decimal;
        OwrdNilCGSTAmount: Decimal;
        OwrdNilSGSTUTGSTAmount: Decimal;
        OwrdNilCESSAmount: Decimal;
        EntryType: Option "Initial Entry",Application;
        DocumentType: Option " ",Payment,Invoice,"Credit Memo",,,,Refund;
        DocumentNo: Code[20];
        InwrdtotalAmount: Decimal;
        InwrdIGSTAmount: Decimal;
        InwrdCGSTAmount: Decimal;
        InwrdSGSTUTGSTAmount: Decimal;
        InwrdCESSAmount: Decimal;
        InwrdtotalAmount1: Decimal;
        InwrdIGSTAmount1: Decimal;
        InwrdCGSTAmount1: Decimal;
        InwrdSGSTUTGSTAmount1: Decimal;
        InwrdCESSAmount1: Decimal;
        OwrdNonGSTTotalAmount: Decimal;
        CompReportView: Option " ",CGST,"SGST / UTGST",IGST,CESS;
        ImportGoodsIGSTAmount: Decimal;
        ImportGoodsCGSTAmount: Decimal;
        ImportGoodsSGSTUTGSTAmount: Decimal;
        ImportGoodsCESSAmount: Decimal;
        ImportServiceIGSTAmount: Decimal;
        ImportServiceCGSTAmount: Decimal;
        ImportServiceSGSTUTGSTAmount: Decimal;
        ImportServiceCESSAmount: Decimal;
        ImportServiceIGSTAmount1: Decimal;
        ImportServiceCGSTAmount1: Decimal;
        ImportServiceSGSTUTGSTAmount1: Decimal;
        ImportServiceCESSAmount1: Decimal;
        InwrdReverseIGSTAmount: Decimal;
        InwrdReverseCGSTAmount: Decimal;
        InwrdReverseSGSTUTGSTAmount: Decimal;
        InwrdReverseCESSAmount: Decimal;
        InwrdReverseIGSTAmount1: Decimal;
        InwrdReverseCGSTAmount1: Decimal;
        InwrdReverseSGSTUTGSTAmount1: Decimal;
        InwrdReverseCESSAmount1: Decimal;
        AllOtherITCIGSTAmount: Decimal;
        AllOtherITCCGSTAmount: Decimal;
        AllOtherITCSGSTUTGSTAmount: Decimal;
        AllOtherITCCESSAmount: Decimal;
        IneligibleITCIGSTAmount: Decimal;
        IneligibleITCCGSTAmount: Decimal;
        IneligibleITCSGSTUTGSTAmount: Decimal;
        IneligibleITCCESSAmount: Decimal;
        InwrdISDIGSTAmount: Decimal;
        InwrdISDCGSTAmount: Decimal;
        InwrdISDSGSTUTGSTAmount: Decimal;
        InwrdISDCESSAmount: Decimal;
        InterStateCompSupplyAmount: Decimal;
        IntraStateCompSupplyAmount: Decimal;
        PurchInterStateAmount: Decimal;
        PurchIntraStateAmount: Decimal;
        OthersIGSTAmount: Decimal;
        OthersCGSTAmount: Decimal;
        OthersSGSTUTGSTAmount: Decimal;
        OthersCESSAmount: Decimal;
        DocumentLineNo: Integer;
        OriginalDocNo: Code[20];
        TransactionNo: Integer;
        OriginalInvNo: Code[20];
        ItemChargeAssgnLineNo: Integer;
        Sign: Integer;
        i: Integer;
        gstinchar: array[15] of Text[1];
        PeriodDateErr: Label 'Period Date can not be Blank.';
        AuthErr: Label 'Provide a name for the Authorised Person.';
        PlaceErr: Label 'Provide the name of Place.';
        PostingDateBlankErr: Label 'Posting Date can not be Blank.';
        GSTRLbl: Label 'GSTR 3B';
        RuleLbl: Label '[See rule 61(5)]';
        YearLbl: Label 'Year';
        MonthLbl: Label 'Month';
        GSTINLbl: Label 'Gstin';
        LegalNameLbl: Label 'Legal Name of Registered Person';
        OutwardSpplyLbl: Label 'Details of Outward Supplies and inward supplies liable to reverse charge';
        NatureofSpplyLbl: Label 'Nature of Supplies';
        TotTaxableLbl: Label 'Total Taxable Value';
        IntegratedLbl: Label 'Integrated Tax';
        CentralLbl: Label 'Central Tax';
        StateTaxLbl: Label 'State/UT Tax';
        CessLbl: Label 'Cess';
        OutwardTaxableSpplyLbl: Label '(a) Outward taxable supplies (other than zero rated, nil rated and exempted)';
        OutwardTaxableSpplyZeroLbl: Label '(b) Outward taxable supplies (zero rated )';
        OutwardTaxableSpplyNilLbl: Label '(c) Other outward supplies (Nil rated, exempted)';
        InwardSpplyLbl: Label '(d) Inward supplies (liable to reverse charge)';
        NonGSTOutwardSpplyLbl: Label '(e) Non-GST outward supplies';
        UnregCompoLbl: Label 'Of the supplies shown in 3.1 (a) above, details of inter-State supplies made to unregistered persons,    composition taxable persons and UIN holders';
        PlaceOfSupplyLbl: Label 'Place of Supply     (State/UT)';
        IntegratedTaxLbl: Label 'Amount of Integrated Tax';
        EligibleITCLbl: Label 'Eligible ITC';
        NatureOfSuppliesLbl: Label 'Nature of Supplies';
        ITCAvlLbl: Label '(A) ITC Available (whether in full or part)';
        ImportGoodLbl: Label '(1) Import of goods';
        ImportServiceLbl: Label '(2) Import of services';
        InwrdReverseLbl: Label '(3) Inward supplies liable to reverse charge (other    than 1 & 2 above)';
        InwrdISDLbl: Label '(4) Inward supplies from ISD';
        AllITCLbl: Label '(5) All other ITC';
        ITCReverseLbl: Label '(B) ITC Reversed';
        RulesLbl: Label '(1) As per rules 42 & 43 of CGST Rules';
        OthersLbl: Label '(2) Others';
        NetITCLbl: Label '(C) Net ITC Available (A) – (B)';
        IneligibleITCLbl: Label '(D) Ineligible ITC';
        SectionLbl: Label '(1) As per section 17(5)';
        ValuesExemptLbl: Label 'Values of exempt, nil-rated and non-GST inward supplies';
        InterStateSpplyLbl: Label 'Inter-State supplies';
        IntraStateLbl: Label 'Intra-State supplies';
        SupplierCompLbl: Label 'From a supplier under composition scheme, Exempt and Nil    rated supply';
        NonGSTSpplyLbl: Label 'Non GST supply';
        PaymentLbl: Label 'Payment of tax';
        DescLbl: Label 'Description';
        TaxLbl: Label 'Tax';
        PayableLbl: Label 'payable';
        PaidITCLbl: Label 'Paid through ITC';
        TaxPaidLbl: Label 'Tax paid ';
        TDSTCSLbl: Label 'TDS / TCS';
        TaxCessLbl: Label 'Tax / Cess';
        CashLbl: Label 'paid in cash';
        InterestLbl: Label 'Interest';
        LateFeeLbl: Label 'Late Fee';
        TDSTCSCrLbl: Label 'TDS/TCS Credit';
        DetailsLbl: Label 'Details';
        TDSLbl: Label 'TDS';
        TCSLbl: Label 'TCS';
        VerificationLbl: Label 'Verification (by Authorised signatory)';
        VerifyTxtLbl: Label 'I hereby solemnly affirm and declare that the information given herein above is true and correct to the best of my knowledge and belief and nothing has been concealed there from.';
        PlaceLbl: Label 'Place :';
        DateLbl: Label 'Date :';
        SignatoryLbl: Label '(Authorised signatory)';
        SupplyUnregLbl: Label 'Supplies made to Unregistered Persons';
        SupplyCompLbl: Label 'Supplies made to Composition Persons';
        SupplyUINLbl: Label 'Supplies made to UIN holders';
        PostingDateErr: Label 'Posting Date must be after Period End Date %1.', Comment = '%1= period date';

    local procedure GetBaseAmount(DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry"): Decimal
    var
        BaseAmount: Decimal;
    begin
        with DetailedGSTLedgerEntry do begin
            if "Entry Type" = "Entry Type"::"Initial Entry" then
                if ("Document Type" = "Document Type"::Invoice) or
                   ("Document Type" = "Document Type"::"Credit Memo")
                then
                    BaseAmount := "GST Base Amount";
            if "Entry Type" = "Entry Type"::"Initial Entry" then
                if "Document Type" = "Document Type"::Payment then
                    BaseAmount := "GST Base Amount";
            if "Entry Type" = "Entry Type"::Application then
                BaseAmount := "GST Base Amount";
        end;
        exit(BaseAmount);
    end;

    local procedure ClearDocInfo()
    begin
        Clear(DocumentType);
        Clear(EntryType);
        Clear(DocumentNo);
        Clear(DocumentLineNo);
        Clear(OriginalDocNo);
        Clear(TransactionNo);
        Clear(OriginalInvNo);
        Clear(ItemChargeAssgnLineNo);
    end;

    local procedure CheckComponentReportView(ComponentCode: Code[10])
    var
        GSTComponent: Record "GST Component";
    begin
        GSTComponent.Get(ComponentCode);
        GSTComponent.TestField("Report View");
    end;

    local procedure GetSupplyGSTAmountLine(DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry"; ReportView: Option): Decimal
    var
        GSTComponent: Record "GST Component";
    begin
        if GSTComponent.Get(DetailedGSTLedgerEntry."GST Component Code") then
            if GSTComponent."Report View" = ReportView then
                exit(DetailedGSTLedgerEntry."GST Amount");
    end;

    local procedure GetSupplyGSTAmountISDLine(DetailedGSTDistEntry: Record "Detailed GST Dist. Entry"; ReportView: Option): Decimal
    var
        GSTComponent: Record "GST Component";
    begin
        if GSTComponent.Get(DetailedGSTDistEntry."Rcpt. Component Code") then
            if GSTComponent."Report View" = ReportView then
                exit(DetailedGSTDistEntry."Distribution Amount");
    end;

    local procedure SameStateCode(LocationCode: Code[10]; VendorCode: Code[20]): Boolean
    var
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        Location.Get(LocationCode);
        Vendor.Get(VendorCode);
        if Location."Post Code" = Vendor."Post Code" then
            exit(true);
    end;

    local procedure CalculateValues()
    begin
        OutwardTaxableSupplies();
        OutwardTaxableSuppliesZeroRated();
        OutwardSuppliesNilRated();
        InwardSuppliesReverseCharge();
        InwardSuppliesReverseChargeforGSTAdjustment();
        NonGSTOutwardSupplies();
        ImportGoodsServiceInwardReverse();
        AllAndIneligibleITC();
        InputFromComposition();
        InwardFromISD();
        NonGSTInwardSupply();
    end;

    local procedure GetSupplyGSTAmountRec(DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry"; ReportView: Option): Decimal
    var
        GSTComponent: Record "GST Component";
        DetailedGSTLedgerEntryDummy: Record "Detailed GST Ledger Entry";
        GSTAmount: Decimal;
    begin
        DetailedGSTLedgerEntryDummy.CopyFilters(DetailedGSTLedgerEntry);
        DetailedGSTLedgerEntryDummy.SetCurrentKey("Entry Type", "Document Type", "Document No.", "Transaction No.",
          "Original Doc. No.", "Document Line No.", "Original Invoice No.", "Item Charge Assgn. Line No.");
        DetailedGSTLedgerEntryDummy.SetRange("Entry Type", DetailedGSTLedgerEntry."Entry Type");
        DetailedGSTLedgerEntryDummy.SetRange("Document Type", DetailedGSTLedgerEntry."Document Type");
        DetailedGSTLedgerEntryDummy.SetRange("Document No.", DetailedGSTLedgerEntry."Document No.");
        DetailedGSTLedgerEntryDummy.SetRange("Transaction No.", DetailedGSTLedgerEntry."Transaction No.");
        DetailedGSTLedgerEntryDummy.SetRange("Original Doc. No.", DetailedGSTLedgerEntry."Original Doc. No.");
        DetailedGSTLedgerEntryDummy.SetRange("Document Line No.", DetailedGSTLedgerEntry."Document Line No.");
        DetailedGSTLedgerEntryDummy.SetRange("Original Invoice No.", DetailedGSTLedgerEntry."Original Invoice No.");
        DetailedGSTLedgerEntryDummy.SetRange("Item Charge Assgn. Line No.", DetailedGSTLedgerEntry."Item Charge Assgn. Line No.");
        DetailedGSTLedgerEntryDummy.SetFilter(
          "Component Calc. Type", '%1|%2|%3', DetailedGSTLedgerEntryDummy."Component Calc. Type"::General,
          DetailedGSTLedgerEntryDummy."Component Calc. Type"::Threshold,
          DetailedGSTLedgerEntryDummy."Component Calc. Type"::"Cess %");
        if DetailedGSTLedgerEntryDummy.FindSet() then
            repeat
                if GSTComponent.Get(DetailedGSTLedgerEntryDummy."GST Component Code") then
                    if GSTComponent."Report View" = ReportView then
                        GSTAmount += DetailedGSTLedgerEntryDummy."GST Amount";
            until DetailedGSTLedgerEntryDummy.Next() = 0;
        exit(GSTAmount);
    end;

    local procedure OutwardTaxableSupplies()
    var
        OtwrdTaxableAmt: Decimal;
    begin
        // Outward taxable supplies (other than zero rated, nil rated and exempted)
        with DetailedGSTLedgerEntry do begin
            ClearDocInfo();
            SetCurrentKey("Location  Reg. No.", "Posting Date", "Transaction Type", "Source Type", "GST Customer Type",
              "Entry Type", "Document Type", "Document No.", "Component Calc. Type", "GST %", "GST Exempted Goods");
            SetRange("Location  Reg. No.", GSTIN);
            SetRange("Posting Date", StartingDate, EndingDate);
            SetRange("Transaction Type", "Transaction Type"::Sales);
            SetRange("Source Type", "Source Type"::Customer);
            SetFilter("GST Customer Type", '%1|%2|%3', "GST Customer Type"::Unregistered,
              "GST Customer Type"::Registered, "GST Customer Type"::" ");
            SetFilter("Component Calc. Type", '%1|%2|%3', "Component Calc. Type"::General,
              "Component Calc. Type"::Threshold, "Component Calc. Type"::"Cess %");
            SetFilter("GST %", '<>%1', 0);
            SetRange("GST Exempted Goods", false);
            SetCurrentKey("Transaction Type", "Entry Type", "Document Type", "Document No.",
              "Transaction No.", "Original Doc. No.", "Document Line No.",
              "Original Invoice No.", "Item Charge Assgn. Line No.");
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    if (EntryType <> "Entry Type") or (DocumentType <> "Document Type") or
                       (DocumentNo <> "Document No.") or
                       (TransactionNo <> "Transaction No.") or (OriginalDocNo <> "Original Doc. No.") or
                       (DocumentLineNo <> "Document Line No.") or
                       (OriginalInvNo <> "Original Invoice No.") or (ItemChargeAssgnLineNo <> "Item Charge Assgn. Line No.")
                    then begin
                        Clear(OtwrdTaxableAmt);
                        OtwrdTaxableAmt := GetBaseAmount(DetailedGSTLedgerEntry);
                        if OtwrdTaxableAmt <> 0 then begin
                            OwrdtaxableTotalAmount += OtwrdTaxableAmt;
                            OwrdtaxableIGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::IGST);
                            OwrdtaxableCGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::CGST);
                            OwrdtaxableSGSTUTGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::"SGST / UTGST");
                            OwrdtaxableCESSAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::CESS);
                        end;
                        EntryType := "Entry Type";
                        DocumentType := "Document Type";
                        DocumentNo := "Document No.";
                        DocumentLineNo := "Document Line No.";
                        OriginalDocNo := "Original Doc. No.";
                        TransactionNo := "Transaction No.";
                        OriginalInvNo := "Original Invoice No.";
                        ItemChargeAssgnLineNo := "Item Charge Assgn. Line No.";
                    end;
                until Next() = 0;
        end;
    end;

    local procedure OutwardTaxableSuppliesZeroRated()
    var
        OwrdZeroAmt: Decimal;
    begin
        // Outward taxable supplies (zero rated )
        with DetailedGSTLedgerEntry do begin
            ClearDocInfo();
            SetFilter("GST Customer Type", '%1|%2|%3|%4', "GST Customer Type"::Export,
              "GST Customer Type"::"Deemed Export", "GST Customer Type"::"SEZ Development",
              "GST Customer Type"::"SEZ Unit");
            SetFilter("Component Calc. Type", '%1|%2|%3', "Component Calc. Type"::General,
              "Component Calc. Type"::Threshold, "Component Calc. Type"::"Cess %");
            SetRange("GST %");
            SetRange("GST Exempted Goods");
            SetCurrentKey("Transaction Type", "Entry Type", "Document Type",
              "Document No.", "Transaction No.", "Original Doc. No.", "Document Line No.",
              "Original Invoice No.", "Item Charge Assgn. Line No.");
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    if (EntryType <> "Entry Type") or (DocumentType <> "Document Type") or
                       (DocumentNo <> "Document No.") or (TransactionNo <> "Transaction No.") or
                       (OriginalDocNo <> "Original Doc. No.") or (DocumentLineNo <> "Document Line No.") or
                       (OriginalInvNo <> "Original Invoice No.") or (ItemChargeAssgnLineNo <> "Item Charge Assgn. Line No.")
                    then begin
                        Clear(OwrdZeroAmt);
                        OwrdZeroAmt := GetBaseAmount(DetailedGSTLedgerEntry);
                        if OwrdZeroAmt <> 0 then begin
                            OwrdZeroTotalAmount += OwrdZeroAmt;
                            OwrdZeroIGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::IGST);
                            OwrdZeroCGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::CGST);
                            OwrdZeroSGSTUTGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::"SGST / UTGST");
                            OwrdZeroCESSAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::CESS);
                        end;
                        EntryType := "Entry Type";
                        DocumentType := "Document Type";
                        DocumentNo := "Document No.";
                        DocumentLineNo := "Document Line No.";
                        OriginalDocNo := "Original Doc. No.";
                        TransactionNo := "Transaction No.";
                        OriginalInvNo := "Original Invoice No.";
                        ItemChargeAssgnLineNo := "Item Charge Assgn. Line No.";
                    end;
                until Next() = 0;
        end;
    end;

    local procedure OutwardSuppliesNilRated()
    var
        OwrdNilAmt: Decimal;
    begin
        // Other outward supplies (Nil rated, exempted)
        with DetailedGSTLedgerEntry do begin
            ClearDocInfo();
            SetFilter("GST Customer Type", '%1|%2|%3', "GST Customer Type"::Unregistered,
              "GST Customer Type"::Registered, "GST Customer Type"::" ");
            SetFilter("Component Calc. Type", '%1|%2|%3', "Component Calc. Type"::General,
              "Component Calc. Type"::Threshold, "Component Calc. Type"::"Cess %");
            SetFilter("GST %", '%1', 0);
            SetCurrentKey("Transaction Type", "Entry Type", "Document Type",
              "Document No.", "Transaction No.", "Original Doc. No.", "Document Line No.",
              "Original Invoice No.", "Item Charge Assgn. Line No.");
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    if (EntryType <> "Entry Type") or (DocumentType <> "Document Type") or
                       (DocumentNo <> "Document No.") or (TransactionNo <> "Transaction No.") or
                       (OriginalDocNo <> "Original Doc. No.") or (DocumentLineNo <> "Document Line No.") or
                       (OriginalInvNo <> "Original Invoice No.") or (ItemChargeAssgnLineNo <> "Item Charge Assgn. Line No.")
                    then begin
                        Clear(OwrdNilAmt);
                        OwrdNilAmt := GetBaseAmount(DetailedGSTLedgerEntry);
                        if OwrdNilAmt <> 0 then begin
                            OwrdNilTotalAmount += OwrdNilAmt;
                            OwrdNilIGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::IGST);
                            OwrdNilCGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::CGST);
                            OwrdNilSGSTUTGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::"SGST / UTGST");
                            OwrdNilCESSAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::CESS);
                        end;
                        EntryType := "Entry Type";
                        DocumentType := "Document Type";
                        DocumentNo := "Document No.";
                        DocumentLineNo := "Document Line No.";
                        OriginalDocNo := "Original Doc. No.";
                        TransactionNo := "Transaction No.";
                        OriginalInvNo := "Original Invoice No.";
                        ItemChargeAssgnLineNo := "Item Charge Assgn. Line No.";
                    end;
                until Next() = 0;
        end;
    end;

    local procedure InwardSuppliesReverseCharge()
    begin
        // Inward supplies (liable to reverse charge)
        with DetailedGSTLedgerEntry do begin
            ClearDocInfo();
            Reset();
            SetCurrentKey("Location  Reg. No.", "Posting Date", "Transaction Type", "Reverse Charge", "Liable to Pay",
              "Entry Type", "Document Type", "Document No.");
            SetRange("Location  Reg. No.", GSTIN);
            SetRange("Posting Date", StartingDate, EndingDate);
            SetRange("Transaction Type", "Transaction Type"::Purchase);
            SetRange("Reverse Charge", true);
            SetRange("Liable to Pay", true);
            SetCurrentKey("Transaction Type", "Entry Type", "Document Type", "Document No.",
              "Document Line No.", "Transaction No.", "Original Doc. No.",
              "Original Invoice No.", "Item Charge Assgn. Line No.");
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    Sign := 1;
                    if "Entry Type" = "Entry Type"::Application then
                        if "GST Group Type" = "GST Group Type"::Service then
                            if not "Associated Enterprises" then
                                Sign := -1;
                    if (EntryType <> "Entry Type") or (DocumentType <> "Document Type") or
                       (DocumentNo <> "Document No.") or (TransactionNo <> "Transaction No.") or
                       (OriginalDocNo <> "Original Doc. No.") or (DocumentLineNo <> "Document Line No.") or
                       (OriginalInvNo <> "Original Invoice No.") or (ItemChargeAssgnLineNo <> "Item Charge Assgn. Line No.")
                    then begin
                        InwrdtotalAmount += Sign * "GST Base Amount";
                        InwrdIGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::IGST) * Sign;
                        InwrdCGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::CGST) * Sign;
                        InwrdSGSTUTGSTAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::"SGST / UTGST") * Sign;
                        InwrdCESSAmount += GetSupplyGSTAmountRec(DetailedGSTLedgerEntry, CompReportView::CESS) * Sign;
                    end;
                    EntryType := "Entry Type";
                    DocumentType := "Document Type";
                    DocumentNo := "Document No.";
                    DocumentLineNo := "Document Line No.";
                    OriginalDocNo := "Original Doc. No.";
                    TransactionNo := "Transaction No.";
                    OriginalInvNo := "Original Invoice No.";
                    ItemChargeAssgnLineNo := "Item Charge Assgn. Line No.";
                until Next() = 0;
        end;
    end;

    local procedure NonGSTOutwardSupplies()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        Location: Record Location;
    begin
        // Non - GST Outward Supplies
        Sign := 1;
        Location.SetRange("GST Registration No.", GSTIN);
        if Location.FindSet() then
            repeat
                SalesInvoiceHeader.SetFilter("Location Code", Location.Code);
                SalesInvoiceHeader.SetRange("Posting Date", StartingDate, EndingDate);
                if SalesInvoiceHeader.FindSet() then
                    repeat
                        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
                        if SalesInvoiceLine.FindSet() then
                            repeat
                                OwrdNonGSTTotalAmount += SalesInvoiceLine."Amount Including VAT";
                            until SalesInvoiceLine.Next() = 0;
                    until SalesInvoiceHeader.Next() = 0;

                SalesCrMemoHeader.SetFilter("Location Code", Location.Code);
                SalesCrMemoHeader.SetRange("Posting Date", StartingDate, EndingDate);
                if SalesCrMemoHeader.FindSet() then
                    repeat
                        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
                        if SalesCrMemoLine.FindSet() then
                            repeat
                                OwrdNonGSTTotalAmount -= SalesCrMemoLine."Amount Including VAT";
                            until SalesCrMemoLine.Next() = 0;
                    until SalesCrMemoHeader.Next() = 0;
            until Location.Next() = 0;
    end;

    local procedure ImportGoodsServiceInwardReverse()
    begin
        // Eligible ITC
        // Import of Goods
        with DetailedGSTLedgerEntry do begin
            Reset();
            SetCurrentKey("Location  Reg. No.", "Posting Date", "Transaction Type", "Source Type", "GST Credit",
              "Credit Availed", "GST Vendor Type", "GST Group Type");
            SetRange("Location  Reg. No.", GSTIN);
            SetRange("Posting Date", StartingDate, EndingDate);
            SetRange("Transaction Type", "Transaction Type"::Purchase);
            SetRange("Source Type", "Source Type"::Vendor);
            SetRange("GST Credit", "GST Credit"::Availment);
            SetRange("Credit Availed", true);
            SetRange("GST Vendor Type", "GST Vendor Type"::Import, "GST Vendor Type"::SEZ);
            SetRange("GST Group Type", "GST Group Type"::Goods);
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    ImportGoodsIGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::IGST);
                    ImportGoodsCGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::CGST);
                    ImportGoodsSGSTUTGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::"SGST / UTGST");
                    ImportGoodsCESSAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::CESS);
                until Next() = 0;

            // Import of Services
            SetRange("GST Group Type", "GST Group Type"::Service);
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    if "Entry Type" = "Entry Type"::Application then
                        if "Reverse Charge" then
                            if not "Associated Enterprises" then
                                Sign := -1;
                    ImportServiceIGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::IGST) * Sign;
                    ImportServiceCGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::CGST) * Sign;
                    ImportServiceSGSTUTGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::"SGST / UTGST") * Sign;
                    ImportServiceCESSAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::CESS) * Sign;
                until Next() = 0;

            Sign := 1;

            // Inward supplies liable to reverse charge
            SetRange("GST Vendor Type", "GST Vendor Type"::Registered, "GST Vendor Type"::Unregistered);
            SetRange("GST Group Type");
            SetRange("Reverse Charge", true);
            if FindSet() then
                repeat
                    if "Entry Type" = "Entry Type"::Application then
                        if "GST Group Type" = "GST Group Type"::Service then
                            Sign := -1;
                    CheckComponentReportView("GST Component Code");
                    InwrdReverseIGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::IGST) * Sign;
                    InwrdReverseCGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::CGST) * Sign;
                    InwrdReverseSGSTUTGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::"SGST / UTGST") * Sign;
                    InwrdReverseCESSAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::CESS) * Sign;
                until Next() = 0;
        end;
        Sign := 1;
    end;

    local procedure AllAndIneligibleITC()
    begin
        with DetailedGSTLedgerEntry do begin
            // All other ITC
            Reset();
            SetCurrentKey("Location  Reg. No.", "Posting Date", "Transaction Type", "Source Type",
              "Input Service Distribution", "Reverse Charge", "GST Credit", "Credit Availed");
            SetRange("Location  Reg. No.", GSTIN);
            SetRange("Posting Date", StartingDate, EndingDate);
            SetRange("Transaction Type", "Transaction Type"::Purchase);
            SetRange("Source Type", "Source Type"::Vendor);
            SetRange("Input Service Distribution", false);
            SetRange("Reverse Charge", false);
            SetRange("GST Credit", "GST Credit"::Availment);
            SetRange("Credit Availed", true);
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    AllOtherITCIGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::IGST);
                    AllOtherITCCGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::CGST);
                    AllOtherITCSGSTUTGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::"SGST / UTGST");
                    AllOtherITCCESSAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::CESS);
                until Next() = 0;

            // Ineligible ITC  17(5) DGLE
            SetRange("Entry Type", "Entry Type"::"Initial Entry");
            SetRange("Reverse Charge");
            SetRange("GST Credit", "GST Credit"::"Non-Availment");
            SetRange("Credit Availed", false);
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    IneligibleITCIGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::IGST);
                    IneligibleITCCGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::CGST);
                    IneligibleITCSGSTUTGSTAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::"SGST / UTGST");
                    IneligibleITCCESSAmount += GetSupplyGSTAmountLine(DetailedGSTLedgerEntry, CompReportView::CESS);
                until Next() = 0;
        end;

        with DetailedCrAdjstmntEntry do begin
            SetCurrentKey("Location  Reg. No.", "Posting Date", "Reverse Charge");
            SetRange("Location  Reg. No.", GSTIN);
            SetRange("Posting Date", StartingDate, EndingDate);
            SetRange("Reverse Charge", true);
            SetFilter("Credit Adjustment Type", '%1|%2',
              "Credit Adjustment Type"::"Credit Reversal", "Credit Adjustment Type"::"Reversal of Availment");
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    AllOtherITCIGSTAmount += GetSupplyGSTAmountDCrAdjmntLine(DetailedCrAdjstmntEntry, CompReportView::IGST);
                    AllOtherITCCGSTAmount += GetSupplyGSTAmountDCrAdjmntLine(DetailedCrAdjstmntEntry, CompReportView::CGST);
                    AllOtherITCSGSTUTGSTAmount += GetSupplyGSTAmountDCrAdjmntLine(DetailedCrAdjstmntEntry, CompReportView::"SGST / UTGST");
                    AllOtherITCCESSAmount += GetSupplyGSTAmountDCrAdjmntLine(DetailedCrAdjstmntEntry, CompReportView::CESS);
                until Next() = 0;
        end;

        with DetailedCrAdjstmntEntry do begin
            Reset();
            SetCurrentKey("Location  Reg. No.", "Posting Date", "Reverse Charge");
            SetRange("Location  Reg. No.", GSTIN);
            SetRange("Posting Date", StartingDate, EndingDate);
            SetRange("Reverse Charge", true);
            SetFilter("Credit Adjustment Type", '%1|%2',
              "Credit Adjustment Type"::"Credit Availment", "Credit Adjustment Type"::"Credit Re-Availment");
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    OthersIGSTAmount += GetSupplyGSTAmountDCrAdjmntLine(DetailedCrAdjstmntEntry, CompReportView::IGST);
                    OthersCGSTAmount += GetSupplyGSTAmountDCrAdjmntLine(DetailedCrAdjstmntEntry, CompReportView::CGST);
                    OthersSGSTUTGSTAmount += GetSupplyGSTAmountDCrAdjmntLine(DetailedCrAdjstmntEntry, CompReportView::"SGST / UTGST");
                    OthersCESSAmount += GetSupplyGSTAmountDCrAdjmntLine(DetailedCrAdjstmntEntry, CompReportView::CESS);
                until Next() = 0;
        end;
    end;

    local procedure InputFromComposition()
    begin
        // Values of exempt, nil-rated and non-GST inward supplies
        // From a supplier under composition scheme, Exempt and Nil rated supply
        with DetailedGSTLedgerEntry do begin
            ClearDocInfo();
            Reset();
            SetCurrentKey("Location  Reg. No.", "Posting Date", "Transaction Type", "Source Type", "Entry Type",
              "Document Type", "Document No.", "Component Calc. Type", "GST %");
            SetRange("Location  Reg. No.", GSTIN);
            SetRange("Posting Date", StartingDate, EndingDate);
            SetRange("Transaction Type", "Transaction Type"::Purchase);
            SetRange("Source Type", "Source Type"::Vendor);
            SetFilter("Component Calc. Type", '%1|%2|%3', "Component Calc. Type"::General,
              "Component Calc. Type"::Threshold, "Component Calc. Type"::"Cess %");
            SetRange("GST %", 0);
            SetCurrentKey("Transaction Type", "Entry Type", "Document Type", "Document No.",
              "Transaction No.", "Original Doc. No.", "Document Line No.",
              "Original Invoice No.", "Item Charge Assgn. Line No.");
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    if (EntryType <> "Entry Type") or (DocumentType <> "Document Type") or
                       (DocumentNo <> "Document No.") or (TransactionNo <> "Transaction No.") or
                       (OriginalDocNo <> "Original Doc. No.") or (DocumentLineNo <> "Document Line No.") or
                       (OriginalInvNo <> "Original Invoice No.") or (ItemChargeAssgnLineNo <> "Item Charge Assgn. Line No.")
                    then
                        if "GST Jurisdiction Type" = "GST Jurisdiction Type"::Interstate then
                            InterStateCompSupplyAmount += "GST Base Amount"
                        else
                            if "GST Jurisdiction Type" = "GST Jurisdiction Type"::Intrastate then
                                IntraStateCompSupplyAmount += "GST Base Amount";

                    EntryType := "Entry Type";
                    DocumentType := "Document Type";
                    DocumentNo := "Document No.";
                    DocumentLineNo := "Document Line No.";
                    OriginalDocNo := "Original Doc. No.";
                    TransactionNo := "Transaction No.";
                    OriginalInvNo := "Original Invoice No.";
                    ItemChargeAssgnLineNo := "Item Charge Assgn. Line No.";
                until Next() = 0;
        end;
    end;

    local procedure InwardFromISD()
    var
        DetailedGSTDistEntry: Record "Detailed GST Dist. Entry";
    begin
        // Inward Supplies from ISD
        with DetailedGSTDistEntry do begin
            SetCurrentKey("Rcpt. GST Reg. No.", "Posting Date", "Rcpt. GST Credit", "Credit Availed");
            SetRange("Rcpt. GST Reg. No.", GSTIN);
            SetRange("Posting Date", StartingDate, EndingDate);
            SetRange("Rcpt. GST Credit", "Rcpt. GST Credit"::Availment);
            SetRange("Credit Availed", true);
            if FindSet() then
                repeat
                    CheckComponentReportView("Rcpt. Component Code");
                    InwrdISDIGSTAmount += GetSupplyGSTAmountISDLine(DetailedGSTDistEntry, CompReportView::IGST);
                    InwrdISDCGSTAmount += GetSupplyGSTAmountISDLine(DetailedGSTDistEntry, CompReportView::CGST);
                    InwrdISDSGSTUTGSTAmount += GetSupplyGSTAmountISDLine(DetailedGSTDistEntry, CompReportView::"SGST / UTGST");
                    InwrdISDCESSAmount += GetSupplyGSTAmountISDLine(DetailedGSTDistEntry, CompReportView::CESS);
                until Next() = 0;

            // Ineligible ITC  17(5) DGDE
            SetRange("Rcpt. GST Credit", "Rcpt. GST Credit"::"Non-Availment");
            SetRange("Credit Availed", false);
            if FindSet() then
                repeat
                    CheckComponentReportView("Rcpt. Component Code");
                    IneligibleITCIGSTAmount += GetSupplyGSTAmountISDLine(DetailedGSTDistEntry, CompReportView::IGST);
                    IneligibleITCCGSTAmount += GetSupplyGSTAmountISDLine(DetailedGSTDistEntry, CompReportView::CGST);
                    IneligibleITCSGSTUTGSTAmount += GetSupplyGSTAmountISDLine(DetailedGSTDistEntry, CompReportView::"SGST / UTGST");
                    IneligibleITCCESSAmount += GetSupplyGSTAmountISDLine(DetailedGSTDistEntry, CompReportView::CESS);
                until Next() = 0;
        end;
    end;

    local procedure NonGSTInwardSupply()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        Location: Record Location;
    begin
        // Non-GST supply Purchase
        Location.SetRange("GST Registration No.", GSTIN);
        if Location.FindSet() then
            repeat
                PurchInvHeader.SetFilter("Location Code", Location.Code);
                PurchInvHeader.SetRange("Posting Date", StartingDate, EndingDate);
                if PurchInvHeader.FindSet() then
                    repeat
                        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
                        if PurchInvLine.FindSet() then
                            repeat
                                if SameStateCode(PurchInvHeader."Location Code", PurchInvHeader."Buy-from Vendor No.") then
                                    PurchIntraStateAmount += PurchInvLine."Amount Including VAT"
                                else
                                    PurchInterStateAmount += PurchInvLine."Amount Including VAT";
                            until PurchInvLine.Next() = 0;
                    until PurchInvHeader.Next() = 0;

                PurchCrMemoHdr.SetFilter("Location Code", Location.Code);
                PurchCrMemoHdr.SetRange("Posting Date", StartingDate, EndingDate);
                if PurchCrMemoHdr.FindSet() then
                    repeat
                        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
                        if PurchCrMemoLine.FindSet() then
                            repeat
                                if SameStateCode(PurchCrMemoHdr."Location Code", PurchCrMemoHdr."Buy-from Vendor No.") then
                                    PurchIntraStateAmount -= PurchCrMemoLine."Amount Including VAT"
                                else
                                    PurchInterStateAmount -= PurchCrMemoLine."Amount Including VAT";
                            until PurchCrMemoLine.Next() = 0;
                    until PurchCrMemoHdr.Next() = 0;
            until Location.Next() = 0;
    end;

    local procedure GetSupplyGSTAmountDCrAdjmntLine(
        DetailedCrAdjstmntEntry: Record "Detailed Cr. Adjstmnt. Entry";
        ReportView: Option): Decimal
    var
        GSTComponent: Record "GST Component";
    begin
        if GSTComponent.Get(DetailedCrAdjstmntEntry."GST Component Code") then
            if GSTComponent."Report View" = ReportView then
                exit(DetailedCrAdjstmntEntry."GST Amount");
    end;

    local procedure InwardSuppliesReverseChargeforGSTAdjustment()
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        DocumentNo: Code[20];
        GSTBaseAmount: Decimal;
        GSTBaseAmount1: Decimal;
        LineNo: Integer;
        LineNo1: Integer;
    begin
        with PostedGSTLiabilityAdj do begin
            ClearDocInfo();
            Reset();
            SetRange("Location  Reg. No.", GSTIN);
            SetRange("Posting Date", StartingDate, EndingDate);
            SetRange("Liable to Pay", true);
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    DetailedGSTLedgerEntry.SetRange("Document No.", "Document No.");
                    DetailedGSTLedgerEntry.SetRange("Document Type", "Document Type");
                    DetailedGSTLedgerEntry.SetRange("Transaction Type", DetailedGSTLedgerEntry."Transaction Type"::Purchase);
                    if DetailedGSTLedgerEntry.FindSet() then
                        repeat
                            if "Credit Adjustment Type" = "Credit Adjustment Type"::Generate then begin
                                if (LineNo <> DetailedGSTLedgerEntry."Document Line No.") and
                                   (DocumentNo <> DetailedGSTLedgerEntry."Document No.")
                                then
                                    GSTBaseAmount := DetailedGSTLedgerEntry."GST Base Amount";
                                LineNo := DetailedGSTLedgerEntry."Document Line No.";
                            end else begin
                                if (LineNo1 <> DetailedGSTLedgerEntry."Document Line No.") and
                                   (DocumentNo <> DetailedGSTLedgerEntry."Document No.")
                                then
                                    GSTBaseAmount1 := DetailedGSTLedgerEntry."GST Base Amount";
                                LineNo1 := DetailedGSTLedgerEntry."Document Line No.";
                            end;
                            DocumentNo := DetailedGSTLedgerEntry."Document No.";
                        until DetailedGSTLedgerEntry.Next() = 0;
                    InwrdtotalAmount1 := GSTBaseAmount - GSTBaseAmount1;
                    InwrdIGSTAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::IGST);
                    InwrdCGSTAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::CGST);
                    InwrdSGSTUTGSTAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::"SGST / UTGST");
                    InwrdCESSAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::CESS);
                until Next() = 0;
        end;
        InwardSuppliesReverseChargeforGSTAdjCreditAvail();
    end;

    local procedure InwardSuppliesReverseChargeforGSTAdjCreditAvail()
    begin
        with PostedGSTLiabilityAdj do begin
            ClearDocInfo();
            Reset();
            SetRange("Location  Reg. No.", GSTIN);
            SetRange("Posting Date", StartingDate, EndingDate);
            SetRange("Credit Availed", true);
            if FindSet() then
                repeat
                    CheckComponentReportView("GST Component Code");
                    if not ("GST Vendor Type" in ["GST Vendor Type"::Import]) then begin
                        InwrdReverseIGSTAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::IGST);
                        InwrdReverseCGSTAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::CGST);
                        InwrdReverseSGSTUTGSTAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::"SGST / UTGST");
                        InwrdReverseCESSAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::CESS);
                    end else begin
                        ImportServiceIGSTAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::IGST);
                        ImportServiceCGSTAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::CGST);
                        ImportServiceSGSTUTGSTAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::"SGST / UTGST");
                        ImportServiceCESSAmount1 += GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj, CompReportView::CESS);
                    end;
                until Next() = 0;
        end;
    end;

    local procedure GetSupplyGSTAmountRecforGSTAdjust(PostedGSTLiabilityAdj: Record "Posted GST Liability Adj."; ReportView: Option): Decimal
    var
        GSTComponent: Record "GST Component";
        GSTAmount: Decimal;
    begin
        if GSTComponent.Get(PostedGSTLiabilityAdj."GST Component Code") then
            if GSTComponent."Report View" = ReportView then
                GSTAmount += PostedGSTLiabilityAdj."GST Amount";
        exit(GSTAmount);
    end;
}