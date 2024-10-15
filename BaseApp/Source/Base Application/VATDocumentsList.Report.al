report 11775 "VAT Documents List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VATDocumentsList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Documents';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(xRequest; "VAT Entry")
        {
            DataItemTableView = SORTING(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date");
            RequestFilterFields = "VAT Date", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Settlement No.", "Source Code";

            trigger OnPreDataItem()
            var
                lreVATEntry: Record "VAT Entry";
            begin
                lreVATEntry.Copy(VATFilter);

                TVATDoc.SetCurrentKey("Document No.", "Posting Date");
                if lreVATEntry.FindSet then
                    repeat
                        TVATDoc.SetRange("Pmt.Disc. Tax Corr.Doc. No.");
                        if lreVATEntry."Pmt.Disc. Tax Corr.Doc. No." <> '' then
                            TVATDoc.SetRange("Pmt.Disc. Tax Corr.Doc. No.", lreVATEntry."Pmt.Disc. Tax Corr.Doc. No.");

                        TVATDoc.SetRange("Document No.", lreVATEntry."Document No.");
                        TVATDoc.SetRange("VAT Date", lreVATEntry."VAT Date");
                        if not TVATDoc.Find('-') then begin
                            TVATDoc := lreVATEntry;
                            TVATDoc.Insert();
                        end;
                    until lreVATEntry.Next = 0;
                CurrReport.Break();
            end;
        }
        dataitem(Loop; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(gteFilters; Filters)
            {
            }
            column(gteEntryTypeText; EntryTypeText)
            {
            }
            column(gtePerfCountryFilter; PerfCountryFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                ObsoleteTag = '15.3';
            }
            column(gteTextVATUnreal; TextVATUnreal)
            {
            }
            column(gteTextBaseUnreal; TextBaseUnreal)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(VAT_Document_ListCaption; VAT_Document_ListCaptionLbl)
            {
            }
            column(VAT_Entry_TypeCaption; "VAT Entry".FieldCaption(Type))
            {
            }
            column(VAT_Entry_AmountCaption; "VAT Entry".FieldCaption(Amount))
            {
            }
            column(VAT_Entry_BaseCaption; "VAT Entry".FieldCaption(Base))
            {
            }
            column(VAT_Entry__VAT_Prod__Posting_Group_Caption; "VAT Entry".FieldCaption("VAT Prod. Posting Group"))
            {
            }
            column(VAT_Entry__VAT_Bus__Posting_Group_Caption; "VAT Entry".FieldCaption("VAT Bus. Posting Group"))
            {
            }
            column(VAT_Entry__External_Document_No__Caption; "VAT Entry".FieldCaption("External Document No."))
            {
            }
            column(VAT_Entry__Document_No__Caption; "VAT Entry".FieldCaption("Document No."))
            {
            }
            column(VAT_Entry__Document_Type_Caption; "VAT Entry".FieldCaption("Document Type"))
            {
            }
            column(VAT_Entry__VAT_Date_Caption; "VAT Entry".FieldCaption("VAT Date"))
            {
            }
            column(gboAdvanceCaption; AdvanceCaptionLbl)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(gboPrintDetail; PrintDetail)
            {
            }
            column(gboPrintSummary; PrintSummary)
            {
            }
            column(gboPrintTotal; PrintTotal)
            {
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(Loop_Number; Loop.Number)
                {
                }
                column(VAT_Entry_Type; Type)
                {
                }
                column(VAT_Entry_Amount; Amount)
                {
                }
                column(VAT_Entry_Base; Base)
                {
                }
                column(VAT_Entry__Unrealized_Amount_; "Unrealized Amount")
                {
                }
                column(text; "Unrealized Base")
                {
                }
                column(VAT_Entry__VAT_Prod__Posting_Group_; "VAT Prod. Posting Group")
                {
                }
                column(VAT_Entry__VAT_Bus__Posting_Group_; "VAT Bus. Posting Group")
                {
                }
                column(VAT_Entry__External_Document_No__; "External Document No.")
                {
                }
                column(VAT_Entry__Document_No__; VATEntryDocumentNo)
                {
                }
                column(VAT_Entry__Document_Type_; VATEntryDocumentType)
                {
                }
                column(VAT_Entry__VAT_Date_; "VAT Date")
                {
                }
                column(gboAdvance; Format(Advance))
                {
                }
                column(VAT_Entry_Type_Control1100162031; Type)
                {
                }
                column(VAT_Entry_Amount_Control1100162032; Amount)
                {
                }
                column(AmountWithReverseChargeVAT; AmountWithReverseChargeVAT)
                {
                }
                column(VAT_Entry_Base_Control1100162033; Base)
                {
                }
                column(Noreal__stkaSoucet; "Unrealized Amount")
                {
                }
                column(NorealZ_kladSoucet; "Unrealized Base")
                {
                }
                column(gtcDocTotals; DocTotalsLbl)
                {
                }
                column(DocTotalsWithReverseChargeVAT; DocTotalsWithReverseChargeVATLbl)
                {
                }
                column(VAT_Entry__External_Document_No___Control1100162037; "External Document No.")
                {
                }
                column(VAT_Entry__Document_No___Control1100162038; "Document No.")
                {
                }
                column(VAT_Entry__Document_Type__Control1100162039; "Document Type")
                {
                }
                column(VAT_Entry__VAT_Date__Control1100162040; "VAT Date")
                {
                }
                column(VAT_Entry_Entry_No_; "Entry No.")
                {
                }
                column(VAT_Entry_VATRegistrationNo; "VAT Registration No.")
                {
                    IncludeCaption = true;
                }
                column(VAT_Entry_CountryRegionCode; "Country/Region Code")
                {
                    IncludeCaption = true;
                }
                column(VATEntry_VATCalculationType; "VAT Calculation Type")
                {
                }
                column(HiddenTotalForReverseChargeVAT; HiddenTotalForReverseChargeVAT)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Perform. Country/Region Code" <> '' then begin
                        if "Advance Base" <> 0 then
                            "Advance Base" := ExchangeAmount("VAT Entry", "Advance Base")
                        else
                            Base := ExchangeAmount("VAT Entry", Base);
                        Amount := ExchangeAmount("VAT Entry", Amount);
                        if PrintUnreal then begin
                            "Unrealized Base" := ExchangeAmount("VAT Entry", "Unrealized Base");
                            "Unrealized Amount" := ExchangeAmount("VAT Entry", "Unrealized Amount");
                        end;
                    end;

                    if not PrintUnreal then begin
                        "Unrealized Base" := 0;
                        "Unrealized Amount" := 0;
                    end;

                    if not VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then begin
                        VATPostingSetup.Init();
                        VATPostingSetup."VAT Identifier" := NoneTxt;
                    end;

                    TDocVATAmtLine.Init();
                    TDocVATAmtLine."VAT Identifier" := VATPostingSetup."VAT Identifier";
                    TDocVATAmtLine."VAT Calculation Type" := "VAT Calculation Type";
                    TDocVATAmtLine."Tax Group Code" := "Tax Group Code";
                    TDocVATAmtLine."VAT %" := VATPostingSetup."VAT %";
                    if "VAT Entry"."Advance Base" <> 0 then begin
                        TDocVATAmtLine."VAT Base" := "Advance Base";
                        TDocVATAmtLine."Amount Including VAT" := Amount + "Advance Base";
                    end else begin
                        TDocVATAmtLine."VAT Base" := Base;
                        TDocVATAmtLine."Amount Including VAT" := Amount + Base;
                    end;

                    TDocVATAmtLine.InsertLine;

                    TTotVATAmtLine.Init();
                    TTotVATAmtLine."VAT Identifier" := VATPostingSetup."VAT Identifier";
                    TTotVATAmtLine."VAT Calculation Type" := "VAT Calculation Type";
                    TTotVATAmtLine."Tax Group Code" := "Tax Group Code";
                    TTotVATAmtLine."VAT %" := VATPostingSetup."VAT %";
                    if "VAT Entry"."Advance Base" <> 0 then begin
                        TTotVATAmtLine."VAT Base" := "Advance Base";
                        TTotVATAmtLine."Amount Including VAT" := Amount + "Advance Base";
                    end else begin
                        TTotVATAmtLine."VAT Base" := Base;
                        TTotVATAmtLine."Amount Including VAT" := Amount + Base;
                    end;
                    TTotVATAmtLine.InsertLine;

                    if PrintUnreal then begin
                        TUnrealDocVATAmtLine.Init();
                        TUnrealDocVATAmtLine."VAT Identifier" := VATPostingSetup."VAT Identifier";
                        TUnrealDocVATAmtLine."VAT Calculation Type" := "VAT Calculation Type";
                        TUnrealDocVATAmtLine."Tax Group Code" := "Tax Group Code";
                        TUnrealDocVATAmtLine."VAT %" := VATPostingSetup."VAT %";
                        TUnrealDocVATAmtLine."VAT Base" := "Unrealized Base";
                        TUnrealDocVATAmtLine."Amount Including VAT" := "Unrealized Amount" + "Unrealized Base";
                        TUnrealDocVATAmtLine.InsertLine;

                        TUnrealTotVATAmtLine.Init();
                        TUnrealTotVATAmtLine."VAT Identifier" := VATPostingSetup."VAT Identifier";
                        TUnrealTotVATAmtLine."VAT Calculation Type" := "VAT Calculation Type";
                        TUnrealTotVATAmtLine."Tax Group Code" := "Tax Group Code";
                        TUnrealTotVATAmtLine."VAT %" := VATPostingSetup."VAT %";
                        TUnrealTotVATAmtLine."VAT Base" := "Unrealized Base";
                        TUnrealTotVATAmtLine."Amount Including VAT" := "Unrealized Amount" + "Unrealized Base";
                        TUnrealTotVATAmtLine.InsertLine;
                    end;

                    Advance := "Advance Letter No." <> '';
                    if "Advance Base" <> 0 then
                        Base := "Advance Base";

                    AmountWithReverseChargeVAT := Amount;
                    if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                        AmountWithReverseChargeVAT := 0;

                    HiddenTotalForReverseChargeVAT :=
                      ("VAT Calculation Type" <> "VAT Calculation Type"::"Reverse Charge VAT") or
                      (Type <> Type::Purchase);

                    VATEntryDocumentNo := "Document No.";
                    VATEntryDocumentType := Format("Document Type");
                    if "Pmt.Disc. Tax Corr.Doc. No." <> '' then begin
                        VATEntryDocumentNo := "Pmt.Disc. Tax Corr.Doc. No.";
                        VATEntryDocumentType := Format("Document Type"::"Credit Memo");
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(TDocVATAmtLine);
                    TDocVATAmtLine.Reset();
                    TDocVATAmtLine.DeleteAll();

                    if PrintUnreal then begin
                        Clear(TUnrealDocVATAmtLine);
                        TUnrealDocVATAmtLine.Reset();
                        TUnrealDocVATAmtLine.DeleteAll();
                    end;

                    CopyFilters(VATFilter);
                    SetRange("Document No.", TVATDoc."Document No.");
                    if TVATDoc."Pmt.Disc. Tax Corr.Doc. No." <> '' then
                        SetRange("Pmt.Disc. Tax Corr.Doc. No.", TVATDoc."Pmt.Disc. Tax Corr.Doc. No.");
                    SetRange("VAT Date", TVATDoc."VAT Date");
                end;
            }
            dataitem(DocSummary; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(VAT_Entry__Type; Format("VAT Entry".Type))
                {
                }
                column(greTDocVATAmtLine__VAT_Amount_; TDocVATAmtLine."VAT Amount")
                {
                }
                column(greTDocVATAmtLine__VAT_Base_; TDocVATAmtLine."VAT Base")
                {
                }
                column(DokladDPHNereal_1_; TUnrealDocVATAmtLine."VAT Amount")
                {
                }
                column(DokladZ_kladNereal_1_; TUnrealDocVATAmtLine."VAT Base")
                {
                }
                column(gtcTaxRate_FORMAT_greTDocVATAmtLine__VAT_Identifier__; StrSubstNo(TaxRateLbl, Format(TDocVATAmtLine."VAT Identifier")))
                {
                }
                column(VAT_Entry___External_Document_No__; "VAT Entry"."External Document No.")
                {
                }
                column(VAT_Entry___Document_No__; "VAT Entry"."Document No.")
                {
                }
                column(VAT_Entry___Document_Type_; Format("VAT Entry"."Document Type"))
                {
                }
                column(VAT_Entry___Posting_Date_; "VAT Entry"."Posting Date")
                {
                }
                column(FORMAT_greTDocVATAmtLine__VAT_Calculation_Type__; Format(TDocVATAmtLine."VAT Calculation Type"))
                {
                }
                column(DocSummary_Number; Number)
                {
                }
                column(VAT_EntrySum_VATRegistrationNo; "VAT Entry"."VAT Registration No.")
                {
                }
                column(VAT_EntrySum_CountryRegionCode; "VAT Entry"."Country/Region Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TDocVATAmtLine.FindSet
                    else
                        TDocVATAmtLine.Next;

                    if PrintUnreal then begin
                        TUnrealDocVATAmtLine := TDocVATAmtLine;
                        if not TUnrealDocVATAmtLine.Find then
                            TUnrealDocVATAmtLine.Init();
                    end;
                end;

                trigger OnPreDataItem()
                var
                    lreTVATAmountLine: Record "VAT Amount Line" temporary;
                begin
                    TDocVATAmtLine.Reset();
                    TUnrealDocVATAmtLine.Reset();

                    if TDocVATAmtLine.FindSet then begin
                        repeat
                            lreTVATAmountLine.SetRange("VAT Identifier", TDocVATAmtLine."VAT Identifier");
                            lreTVATAmountLine.SetRange("VAT Calculation Type", TDocVATAmtLine."VAT Calculation Type");
                            lreTVATAmountLine.SetRange("Tax Group Code", TDocVATAmtLine."Tax Group Code");
                            lreTVATAmountLine.SetRange("Use Tax", TDocVATAmtLine."Use Tax");
                            if lreTVATAmountLine.Find('-') then begin
                                lreTVATAmountLine."VAT Base" := lreTVATAmountLine."VAT Base" + TDocVATAmtLine."VAT Base";
                                lreTVATAmountLine."VAT Amount" := lreTVATAmountLine."VAT Amount" + TDocVATAmtLine."VAT Amount";
                                lreTVATAmountLine.Modify();
                            end;
                            lreTVATAmountLine := TDocVATAmtLine;
                            lreTVATAmountLine.Insert();
                        until TDocVATAmtLine.Next = 0;

                        TDocVATAmtLine.Reset();
                        TDocVATAmtLine.DeleteAll();

                        lreTVATAmountLine.Reset();
                        if lreTVATAmountLine.FindSet then
                            repeat
                                TDocVATAmtLine := lreTVATAmountLine;
                                TDocVATAmtLine.Insert();
                            until lreTVATAmountLine.Next = 0;

                        lreTVATAmountLine.Reset();
                        lreTVATAmountLine.DeleteAll();
                    end;

                    if PrintUnreal then
                        if TUnrealDocVATAmtLine.FindSet then begin
                            repeat
                                lreTVATAmountLine.SetRange("VAT Identifier", TUnrealDocVATAmtLine."VAT Identifier");
                                lreTVATAmountLine.SetRange("VAT Calculation Type", TUnrealDocVATAmtLine."VAT Calculation Type");
                                lreTVATAmountLine.SetRange("Tax Group Code", TUnrealDocVATAmtLine."Tax Group Code");
                                lreTVATAmountLine.SetRange("Use Tax", TUnrealDocVATAmtLine."Use Tax");
                                if lreTVATAmountLine.Find('-') then begin
                                    lreTVATAmountLine."VAT Base" := lreTVATAmountLine."VAT Base" + TUnrealDocVATAmtLine."VAT Base";
                                    lreTVATAmountLine."VAT Amount" := lreTVATAmountLine."VAT Amount" + TUnrealDocVATAmtLine."VAT Amount";
                                    lreTVATAmountLine.Modify();
                                end;
                                lreTVATAmountLine := TUnrealDocVATAmtLine;
                                lreTVATAmountLine.Insert();

                            until TUnrealDocVATAmtLine.Next = 0;

                            TUnrealDocVATAmtLine.Reset();
                            TUnrealDocVATAmtLine.DeleteAll();

                            lreTVATAmountLine.Reset();
                            if lreTVATAmountLine.Find('-') then
                                repeat
                                    TUnrealDocVATAmtLine := lreTVATAmountLine;
                                    TUnrealDocVATAmtLine.Insert
                                until lreTVATAmountLine.Next = 0;

                            lreTVATAmountLine.Reset();
                            lreTVATAmountLine.DeleteAll();
                        end;

                    TDocVATAmtLine.Reset();
                    TUnrealDocVATAmtLine.Reset();
                    SetRange(Number, 1, TDocVATAmtLine.Count);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not TVATDoc.Find('-') then
                        CurrReport.Break();
                end else begin
                    if TVATDoc.Next = 0 then
                        CurrReport.Break();
                end;
            end;

            trigger OnPreDataItem()
            begin
                TVATDoc.Reset();
                TVATDoc.SetCurrentKey("Document No.", "Posting Date");
            end;
        }
        dataitem(xTotal; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(gteTextVATUnreal_Control1100162056; TextVATUnreal)
            {
            }
            column(gteTextBaseUnreal_Control1100162057; TextBaseUnreal)
            {
            }
            column(FORMAT_greTTotVATAmtLine__VAT_Calculation_Type__; Format(TTotVATAmtLine."VAT Calculation Type"))
            {
            }
            column(gtcTaxRate_FORMAT_greTTotVATAmtLine__VAT_Identifier__; StrSubstNo(TaxRateLbl, Format(TTotVATAmtLine."VAT Identifier")))
            {
            }
            column(greTTotVATAmtLine__VAT_Amount_; TTotVATAmtLine."VAT Amount")
            {
            }
            column(greTTotVATAmtLine__VAT_Base_; TTotVATAmtLine."VAT Base")
            {
            }
            column(greTUnrealTotVATAmtLine__VAT_Base_; TUnrealTotVATAmtLine."VAT Base")
            {
            }
            column(greTUnrealTotVATAmtLine__VAT_Amount_; TUnrealTotVATAmtLine."VAT Amount")
            {
            }
            column(gtcTotals; TotalsLbl)
            {
            }
            column(Total_VATsCaption; Total_VATsCaptionLbl)
            {
            }
            column(greTTotVATAmtLine__VAT_Amount_Caption; TTotVATAmtLine__VAT_Amount_CaptionLbl)
            {
            }
            column(greTTotVATAmtLine__VAT_Base_Caption; TTotVATAmtLine__VAT_Base_CaptionLbl)
            {
            }
            column(xTotal_Number; Number)
            {
            }
            column(gboHideHeader; PrintDetail or PrintSummary or PrintTotal)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TTotVATAmtLine.FindSet
                else
                    TTotVATAmtLine.Next;

                if PrintUnreal then begin
                    TUnrealTotVATAmtLine := TTotVATAmtLine;
                    if not TUnrealTotVATAmtLine.Find then
                        TUnrealTotVATAmtLine.Init();
                end;

                if TTotVATAmtLine."VAT Calculation Type" = TTotVATAmtLine."VAT Calculation Type"::"Reverse Charge VAT" then begin
                    TTotVATAmtLine."VAT Amount" := 0;
                    TUnrealDocVATAmtLine."VAT Amount" := 0;
                end;
            end;

            trigger OnPreDataItem()
            var
                lretVATAmountLine: Record "VAT Amount Line" temporary;
            begin
                TTotVATAmtLine.Reset();
                TUnrealTotVATAmtLine.Reset();

                if TTotVATAmtLine.FindSet then begin
                    repeat
                        lretVATAmountLine.SetRange("VAT Identifier", TTotVATAmtLine."VAT Identifier");
                        lretVATAmountLine.SetRange("VAT Calculation Type", TTotVATAmtLine."VAT Calculation Type");
                        lretVATAmountLine.SetRange("Tax Group Code", TTotVATAmtLine."Tax Group Code");
                        lretVATAmountLine.SetRange("Use Tax", TTotVATAmtLine."Use Tax");
                        if lretVATAmountLine.Find('-') then begin
                            lretVATAmountLine."VAT Base" := lretVATAmountLine."VAT Base" + TTotVATAmtLine."VAT Base";
                            lretVATAmountLine."VAT Amount" := lretVATAmountLine."VAT Amount" + TTotVATAmtLine."VAT Amount";
                            lretVATAmountLine.Modify();
                        end;
                        lretVATAmountLine := TTotVATAmtLine;
                        lretVATAmountLine.Insert();
                    until TTotVATAmtLine.Next = 0;

                    TTotVATAmtLine.Reset();
                    TTotVATAmtLine.DeleteAll();

                    lretVATAmountLine.Reset();
                    if lretVATAmountLine.FindSet then
                        repeat
                            TTotVATAmtLine := lretVATAmountLine;
                            TTotVATAmtLine.Insert();
                        until lretVATAmountLine.Next = 0;

                    lretVATAmountLine.Reset();
                    lretVATAmountLine.DeleteAll();
                end;

                if PrintUnreal then
                    if TUnrealTotVATAmtLine.FindSet then begin
                        repeat
                            lretVATAmountLine.SetRange("VAT Identifier", TUnrealTotVATAmtLine."VAT Identifier");
                            lretVATAmountLine.SetRange("VAT Calculation Type", TUnrealTotVATAmtLine."VAT Calculation Type");
                            lretVATAmountLine.SetRange("Tax Group Code", TUnrealTotVATAmtLine."Tax Group Code");
                            lretVATAmountLine.SetRange("Use Tax", TUnrealTotVATAmtLine."Use Tax");
                            if lretVATAmountLine.Find('-') then begin
                                lretVATAmountLine."VAT Base" := lretVATAmountLine."VAT Base" + TUnrealTotVATAmtLine."VAT Base";
                                lretVATAmountLine."VAT Amount" := lretVATAmountLine."VAT Amount" + TUnrealTotVATAmtLine."VAT Amount";
                                lretVATAmountLine.Modify();
                            end;
                            lretVATAmountLine := TUnrealTotVATAmtLine;
                            lretVATAmountLine.Insert();

                        until TUnrealTotVATAmtLine.Next = 0;

                        TUnrealTotVATAmtLine.Reset();
                        TUnrealTotVATAmtLine.DeleteAll();

                        lretVATAmountLine.Reset();
                        if lretVATAmountLine.Find('-') then
                            repeat
                                TUnrealTotVATAmtLine := lretVATAmountLine;
                                TUnrealTotVATAmtLine.Insert
                            until lretVATAmountLine.Next = 0;

                        lretVATAmountLine.Reset();
                        lretVATAmountLine.DeleteAll();
                    end;

                TTotVATAmtLine.Reset();
                TUnrealTotVATAmtLine.Reset();

                SetRange(Number, 1, TTotVATAmtLine.Count);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(EntryTypeFilter; EntryTypeFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Type';
                        OptionCaption = 'Purchase,Sale,All';
                        ToolTip = 'Specifies vat type';
                    }
                    field(PrintDetail; PrintDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Document VAT Entries';
                        ToolTip = 'Specifies if document VAT entries have to be printed.';
                    }
                    field(PrintSummary; PrintSummary)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Document Summary';
                        ToolTip = 'Specifies if document summary has to be printed.';
                    }
                    field(PrintTotal; PrintTotal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Document Totals';
                        ToolTip = 'Specifies if document totals has to be printed.';
                    }
                    field(PrintUnreal; PrintUnreal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Unrealized VAT';
                        ToolTip = 'Specifies if unrealized VAT entries have to be printed.';
                    }
                    field(PerfCountryCodeFiter; PerfCountryCodeFiter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Performance Country';
                        TableRelation = "Country/Region";
                        ToolTip = 'Specifies performance country code for VAT entries filtr.';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                        ObsoleteTag = '15.3';
                    }
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

    trigger OnPreReport()
    begin
        xRequest.SetRange("Perform. Country/Region Code");
        xRequest.SetRange(Type);

        Filters := CopyStr(xRequest.GetFilters, 1, 250);

        if PerfCountryCodeFiter <> '' then begin
            xRequest.SetRange("Perform. Country/Region Code", PerfCountryCodeFiter);
            PerfCountryFilter := "VAT Entry".FieldCaption("Perform. Country/Region Code") + ':' + PerfCountryCodeFiter;
        end else
            xRequest.SetRange("Perform. Country/Region Code", '');

        case EntryTypeFilter of
            EntryTypeFilter::Purchase:
                xRequest.SetRange(Type, xRequest.Type::Purchase);
            EntryTypeFilter::Sale:
                xRequest.SetRange(Type, xRequest.Type::Sale);
            EntryTypeFilter::All:
                xRequest.SetRange(Type, xRequest.Type::Purchase, xRequest.Type::Sale);
        end;

        case EntryTypeFilter of
            EntryTypeFilter::Purchase:
                EntryTypeText := PurchEntriesTxt;
            EntryTypeFilter::Sale:
                EntryTypeText := SoldEntriesTxt;
            EntryTypeFilter::All:
                EntryTypeText := AllEntriesTxt;
        end;

        VATFilter.Copy(xRequest);

        if PrintUnreal then begin
            TextBaseUnreal := UnrealVATBaseLbl;
            TextVATUnreal := UnrealVATAmountLbl;
        end;
    end;

    var
        TVATDoc: Record "VAT Entry" temporary;
        VATFilter: Record "VAT Entry";
        TDocVATAmtLine: Record "VAT Amount Line" temporary;
        TTotVATAmtLine: Record "VAT Amount Line" temporary;
        TUnrealDocVATAmtLine: Record "VAT Amount Line" temporary;
        TUnrealTotVATAmtLine: Record "VAT Amount Line" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
        PerfCountryCurrExchRate: Record "Perf. Country Curr. Exch. Rate";
        EntryTypeFilter: Option Purchase,Sale,All;
        PrintDetail: Boolean;
        PrintSummary: Boolean;
        PrintTotal: Boolean;
        PrintUnreal: Boolean;
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
        PerfCountryCodeFiter: Code[10];
        Filters: Text[250];
        EntryTypeText: Text[60];
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
        PerfCountryFilter: Text[50];
        TextBaseUnreal: Text[30];
        TextVATUnreal: Text[30];
        Advance: Boolean;
        DocTotalsLbl: Label 'Document Totals';
        DocTotalsWithReverseChargeVATLbl: Label 'Document Totals with Reverse Charge VAT';
        TaxRateLbl: Label 'Tax rate %1', Comment = '%1=VAT Identifier';
        SoldEntriesTxt: Label 'Sale VAT Entries';
        PurchEntriesTxt: Label 'Purchase VAT Entries';
        AllEntriesTxt: Label 'Both Purchase And Sale Entries';
        TotalsLbl: Label 'Totals';
        PageCaptionLbl: Label 'Page';
        VAT_Document_ListCaptionLbl: Label 'VAT Document List';
        AdvanceCaptionLbl: Label 'Adv.';
        Total_VATsCaptionLbl: Label 'Total VATs';
        TTotVATAmtLine__VAT_Amount_CaptionLbl: Label 'Amount';
        TTotVATAmtLine__VAT_Base_CaptionLbl: Label 'Base';
        UnrealVATBaseLbl: Label 'Unrealized VAT Base';
        UnrealVATAmountLbl: Label 'Unrealized VAT Amount';
        AmountWithReverseChargeVAT: Decimal;
        HiddenTotalForReverseChargeVAT: Boolean;
        NoneTxt: Label '<NONE>';
        VATEntryDocumentNo: Code[20];
        VATEntryDocumentType: Text;

    [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    local procedure ExchangeAmount(VATEntry: Record "VAT Entry"; Amount2: Decimal): Decimal
    begin
        with VATEntry do
            exit(PerfCountryCurrExchRate.ExchangeAmount(
                "Posting Date", "Perform. Country/Region Code", "Currency Code", Amount2 * "Currency Factor"));
    end;
}

