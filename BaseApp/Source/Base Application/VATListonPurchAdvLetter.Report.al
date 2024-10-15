#if not CLEAN19
report 31031 "VAT List on Purch. Adv. Letter"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VATListonPurchAdvLetter.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT List on Purch. Adv. Letter (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    dataset
    {
        dataitem(xHeader; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;
            PrintOnlyIfDetail = true;
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(gteToDate; ToDateTxt)
            {
            }
            column(Purch__Advance_Letter_Header__TABLECAPTION__________gteRegFilter; "Purch. Advance Letter Header".TableCaption + ': ' + ReportFilter)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(VAT_List_on_Purch__Adv__LetterCaption; VAT_List_on_Purch__Adv__LetterCaptionLbl)
            {
            }
            column(VATEntry_AmountCaption; VATEntry.FieldCaption(Amount))
            {
            }
            column(Purch__Advance_Letter_Header__No__Caption; "Purch. Advance Letter Header".FieldCaption("No."))
            {
            }
            column(VATEntry__Document_Type_Caption; VATEntry.FieldCaption("Document Type"))
            {
            }
            column(VATEntry__Advance_Base_Caption; VATEntry.FieldCaption("Advance Base"))
            {
            }
            column(Posting_DateCaption; VATEntry.FieldCaption("Posting Date"))
            {
            }
            column(VATEntry__Advance_Exch__Rate_Difference_Caption; VATEntry.FieldCaption("Advance Exch. Rate Difference"))
            {
            }
            column(xHeader_Number; Number)
            {
            }
            dataitem("Purch. Advance Letter Header"; "Purch. Advance Letter Header")
            {
                RequestFilterFields = "No.", "Pay-to Vendor No.", "Document Date";
                column(Purch__Advance_Letter_Header__Purch__Advance_Letter_Header___Pay_to_Name_; "Pay-to Name")
                {
                }
                column(Purch__Advance_Letter_Header__Purch__Advance_Letter_Header___Pay_to_Vendor_No__; "Pay-to Vendor No.")
                {
                }
                column(Purch__Advance_Letter_Header__No__; "No.")
                {
                }
                column(Purch__Advance_Letter_Header__Template_Code_; "Template Code")
                {
                }
                column(Purch__Advance_Letter_Header__Purch__Advance_Letter_Header___Pay_to_Vendor_No__Caption; FieldCaption("Pay-to Vendor No."))
                {
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    dataitem(VATEntry; "VAT Entry")
                    {
                        DataItemLink = "Advance Letter No." = FIELD("No.");
                        DataItemLinkReference = "Purch. Advance Letter Header";
                        DataItemTableView = SORTING(Type, "Advance Letter No.", "Advance Letter Line No.") WHERE(Type = CONST(Purchase));
                        column(VATEntry_Amount; Amount)
                        {
                        }
                        column(VATEntry__Document_No__; "Document No.")
                        {
                        }
                        column(VATEntry__Posting_Date_; "Posting Date")
                        {
                        }
                        column(VATEntry__Document_Type_; "Document Type")
                        {
                        }
                        column(VATEntry__Advance_Base_; "Advance Base")
                        {
                        }
                        column(VATEntry__Advance_Exch__Rate_Difference_; "Advance Exch. Rate Difference")
                        {
                        }
                        column(greTempVATAmountLine__VAT_Prod__Posting_Group_; TempVATAmountLineAdvPmt."VAT Prod. Posting Group")
                        {
                        }
                        column(greTempVATAmountLine__VAT_Amount__LCY__; TempVATAmountLineAdvPmt."VAT Amount (LCY)")
                        {
                        }
                        column(greTempVATAmountLine__VAT_Base__LCY__; TempVATAmountLineAdvPmt."VAT Base (LCY)")
                        {
                        }
                        column(greTempVATAmountLine__VAT_Identifier_; TempVATAmountLineAdvPmt."VAT Identifier")
                        {
                        }
                        column(VATEntry_Entry_No_; "Entry No.")
                        {
                        }
                        column(VATEntry_Advance_Letter_No_; "Advance Letter No.")
                        {
                        }
                        column(gboPrintDetail; PrintDetail)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            "Advance Base" := "Advance Base" + CalcVATBaseExchRateCorrect(VATEntry);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("VAT Prod. Posting Group", TempVATAmountLineAdvPmt."VAT Prod. Posting Group");
                            if ToDate <> 0D then
                                SetFilter("Posting Date", '..%1', ToDate);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not TempVATAmountLineAdvPmt.Find('-') then
                                CurrReport.Break();
                        end else
                            if TempVATAmountLineAdvPmt.Next() = 0 then
                                CurrReport.Break();

                        TempVATAmountLine.Init();
                        TempVATAmountLine."VAT Identifier" := TempVATAmountLineAdvPmt."VAT Identifier";
                        TempVATAmountLine."VAT Calculation Type" := TempVATAmountLineAdvPmt."VAT Calculation Type";
                        TempVATAmountLine."VAT %" := TempVATAmountLineAdvPmt."VAT %";
                        TempVATAmountLine."VAT Base" := TempVATAmountLineAdvPmt."VAT Base (LCY)";
                        TempVATAmountLine."Amount Including VAT" := TempVATAmountLineAdvPmt."Amount Including VAT (LCY)";
                        TempVATAmountLine."Line Amount" := TempVATAmountLineAdvPmt."Amount Including VAT (LCY)";
                        TempVATAmountLine.InsertLine;
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    lreVATEntry: Record "VAT Entry";
                    lreVATPostSetup: Record "VAT Posting Setup";
                begin
                    TempVATAmountLineAdvPmt.Reset();
                    TempVATAmountLineAdvPmt.DeleteAll();
                    Clear(TempVATAmountLineAdvPmt);

                    with lreVATEntry do begin
                        SetCurrentKey(Type, "Advance Letter No.");
                        SetRange(Type, Type::Purchase);
                        SetRange("Advance Letter No.", "Purch. Advance Letter Header"."No.");
                        if ToDate <> 0D then
                            SetFilter("Posting Date", '..%1', ToDate);

                        if FindSet(false, false) then begin
                            repeat
                                TempVATAmountLineAdvPmt."VAT Prod. Posting Group" := "VAT Prod. Posting Group";
                                if not lreVATPostSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                                    lreVATPostSetup.Init();
                                TempVATAmountLineAdvPmt."VAT Identifier" := lreVATPostSetup."VAT Identifier";
                                TempVATAmountLineAdvPmt."VAT %" := lreVATPostSetup."VAT %";
                                TempVATAmountLineAdvPmt."VAT Base (LCY)" := "Advance Base" + CalcVATBaseExchRateCorrect(lreVATEntry);
                                TempVATAmountLineAdvPmt."VAT Amount (LCY)" := Amount + "Advance Exch. Rate Difference";
                                TempVATAmountLineAdvPmt.InsertLine;
                            until Next() = 0;
                        end;
                    end;

                    if SkipZero then begin
                        TempVATAmountLineAdvPmt.SetRange("VAT Base (LCY)", 0);
                        TempVATAmountLineAdvPmt.SetRange("VAT Amount (LCY)", 0);
                        TempVATAmountLineAdvPmt.DeleteAll();
                        TempVATAmountLineAdvPmt.Reset();
                    end;
                    if TempVATAmountLineAdvPmt.IsEmpty() then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    TempVATAmountLine.Reset();
                    TempVATAmountLine.DeleteAll();
                    Clear(TempVATAmountLine);
                end;
            }
            dataitem(xTotal; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(greTVATAmountLine__VAT_Identifier_; TempVATAmountLine."VAT Identifier")
                {
                }
                column(greTVATAmountLine__VAT_Base_; TempVATAmountLine."VAT Base")
                {
                }
                column(greTVATAmountLine__VAT_Amount_; TempVATAmountLine."VAT Amount")
                {
                }
                column(greTVATAmountLine__VAT___; TempVATAmountLine."VAT %")
                {
                    DecimalPlaces = 0 : 2;
                }
                column(greTVATAmountLine__VAT_Amount__Control1104000041; TempVATAmountLine."VAT Amount")
                {
                }
                column(greTVATAmountLine__VAT_Base__Control1104000042; TempVATAmountLine."VAT Base")
                {
                }
                column(greTVATAmountLine__VAT_Identifier_Caption; greTVATAmountLine__VAT_Identifier_CaptionLbl)
                {
                }
                column(greTVATAmountLine__VAT_Base_Caption; greTVATAmountLine__VAT_Base_CaptionLbl)
                {
                }
                column(greTVATAmountLine__VAT_Amount_Caption; greTVATAmountLine__VAT_Amount_CaptionLbl)
                {
                }
                column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                {
                }
                column(greTVATAmountLine__VAT___Caption; greTVATAmountLine__VAT___CaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(xTotal_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempVATAmountLine.FindSet
                    else
                        TempVATAmountLine.Next;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, TempVATAmountLine.Count);
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ToDate; ToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Balance to date';
                        ToolTip = 'Specifies the last date in the period for VAT list purchase advance letter.';
                    }
                    field(PrintDetail; PrintDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Detail';
                        ToolTip = 'Specifies to indicate that detailed documents will print.';
                    }
                    field(SkipZero; SkipZero)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Zero';
                        ToolTip = 'Specifies when the zero is to be skip';
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
        ReportFilter := "Purch. Advance Letter Header".GetFilters;

        if ToDate <> 0D then
            ToDateTxt := StrSubstNo(TodateLbl, Format(ToDate));
    end;

    var
        TempVATAmountLineAdvPmt: Record "VAT Amount Line Adv. Payment" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PrintDetail: Boolean;
        SkipZero: Boolean;
        ToDate: Date;
        ReportFilter: Text;
        TodateLbl: Label 'To date: %1';
        ToDateTxt: Text[50];
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        VAT_List_on_Purch__Adv__LetterCaptionLbl: Label 'VAT List on Purch. Adv. Letter';
        greTVATAmountLine__VAT_Identifier_CaptionLbl: Label 'VAT Identifier';
        greTVATAmountLine__VAT_Base_CaptionLbl: Label 'VAT Base';
        greTVATAmountLine__VAT_Amount_CaptionLbl: Label 'VAT Amount';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        greTVATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        TotalCaptionLbl: Label 'Total';

    local procedure CalcVATBaseExchRateCorrect(VATEntry: Record "VAT Entry"): Decimal
    var
        PurchAdvanceLetterEntry: Record "Purch. Advance Letter Entry";
    begin
        with PurchAdvanceLetterEntry do begin
            SetRange("Entry Type", "Entry Type"::"VAT Rate");
            SetRange("VAT Entry No.", VATEntry."Entry No.");
            CalcSums("VAT Base Amount (LCY)");
            exit("VAT Base Amount (LCY)");
        end;
    end;
}
#endif
