#if not CLEAN17
report 20 "Calc. and Post VAT Settlement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CalcandPostVATSettlement.rdlc';
    AdditionalSearchTerms = 'settle vat value added tax,report vat value added tax';
    ApplicationArea = Basic, Suite;
    Caption = 'Calculate and Post VAT Settlement (Obsolete)';
    Permissions = TableData "VAT Entry" = imd;
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("VAT Posting Setup"; "VAT Posting Setup")
        {
            DataItemTableView = SORTING("VAT Bus. Posting Group", "VAT Prod. Posting Group");
            RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PeriodVATDateFilter; StrSubstNo(Text005, VATDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(PostSettlement; PostSettlement)
            {
            }
            column(PostingDate; Format(PostingDate))
            {
            }
            column(DocNo; DocNo)
            {
            }
            column(GLAccSettleNo; GLAccSettle."No.")
            {
            }
            column(UseAmtsInAddCurr; UseAmtsInAddCurr)
            {
            }
            column(PrintVATEntries; PrintVATEntries)
            {
            }
            column(VATPostingSetupCaption; TableCaption + ': ' + VATPostingSetupFilter)
            {
            }
            column(VATPostingSetupFilter; VATPostingSetupFilter)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(VATAmount; VATAmount)
            {
                AutoFormatExpression = GetCurrency;
                AutoFormatType = 1;
            }
            column(VATAmountAddCurr; VATAmountAddCurr)
            {
                AutoFormatExpression = GetCurrency;
                AutoFormatType = 1;
            }
            column(CalcandPostVATSettlementCaption; CalcandPostVATSettlementCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(TestReportnotpostedCaption; TestReportnotpostedCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(SettlementAccCaption; SettlementAccCaptionLbl)
            {
            }
            column(DocumentTypeCaption; DocumentTypeCaptionLbl)
            {
            }
            column(UserIDCaption; UserIDCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(DocumentNoCaption; "VAT Entry".FieldCaption("Document No."))
            {
            }
            column(TypeCaption; "VAT Entry".FieldCaption(Type))
            {
            }
            column(BaseCaption; "VAT Entry".FieldCaption(Base))
            {
            }
            column(AmountCaption; "VAT Entry".FieldCaption(Amount))
            {
            }
            column(UnrealizedBaseCaption; "VAT Entry".FieldCaption("Unrealized Base"))
            {
            }
            column(UnrealizedAmountCaption; "VAT Entry".FieldCaption("Unrealized Amount"))
            {
            }
            column(VATCalculationCaption; "VAT Entry".FieldCaption("VAT Calculation Type"))
            {
            }
            column(BilltoPaytoNoCaption; "VAT Entry".FieldCaption("Bill-to/Pay-to No."))
            {
            }
            column(EntryNoCaption; "VAT Entry".FieldCaption("Entry No."))
            {
            }
            column(PostingDateCaption; "VAT Entry".FieldCaption("VAT Date"))
            {
            }
            dataitem(Advance; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 .. 2));
                dataitem("Closing G/L and VAT Entry"; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(VATBusPstGr_VATPostSetup; "VAT Posting Setup"."VAT Bus. Posting Group")
                    {
                    }
                    column(VATPrdPstGr_VATPostSetup; "VAT Posting Setup"."VAT Prod. Posting Group")
                    {
                    }
                    column(VATEntryGetFilterType; VATEntry.GetFilter(Type))
                    {
                    }
                    column(VATEntryGetFiltTaxJurisCd; VATEntry.GetFilter("Tax Jurisdiction Code"))
                    {
                    }
                    column(VATEntryGetFilterUseTax; VATEntry.GetFilter("Use Tax"))
                    {
                    }
                    dataitem("VAT Entry"; "VAT Entry")
                    {
                        DataItemTableView = SORTING(Type, Closed) WHERE(Closed = CONST(false), Type = FILTER(Purchase | Sale));
                        column(PostingDate_VATEntry; Format("VAT Date"))
                        {
                        }
                        column(DocumentNo_VATEntry; VATEntryDocumentNo)
                        {
                        }
                        column(DocumentType_VATEntry; VATEntryDocumentType)
                        {
                        }
                        column(Type_VATEntry; Type)
                        {
                            IncludeCaption = false;
                        }
                        column(Base_VATEntry; Base)
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(Amount_VATEntry; Amount)
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(VATCalcType_VATEntry; "VAT Calculation Type")
                        {
                        }
                        column(BilltoPaytoNo_VATEntry; "Bill-to/Pay-to No.")
                        {
                        }
                        column(EntryNo_VATEntry; "Entry No.")
                        {
                        }
                        column(UserID_VATEntry; "User ID")
                        {
                        }
                        column(UnrealizedAmount_VATEntry; "Unrealized Amount")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(UnrealizedBase_VATEntry; "Unrealized Base")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(AddCurrUnrlzdAmt_VATEntry; "Add.-Currency Unrealized Amt.")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(AddCurrUnrlzdBas_VATEntry; "Add.-Currency Unrealized Base")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(AdditionlCurrAmt_VATEntry; "Additional-Currency Amount")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(AdditinlCurrBase_VATEntry; "Additional-Currency Base")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(VATRegistrationNo_VATEntry; "VAT Registration No.")
                        {
                            IncludeCaption = true;
                        }
                        column(CountryRegionCode_VATEntry; "Country/Region Code")
                        {
                            IncludeCaption = true;
                        }
                        dataitem(CountrySubTotal; "Integer")
                        {
                            DataItemTableView = SORTING(Number);
                            column(CountrySubtotalCaption; StrSubstNo(CountrySubtotalCaptionLbl, "VAT Entry"."Country/Region Code"))
                            {
                            }
                            column(CountrySubBase; CountrySubTotalAmt[1])
                            {
                            }
                            column(CountrySubAmount; CountrySubTotalAmt[2])
                            {
                            }
                            column(CountrySubUnrealBase; CountrySubTotalAmt[3])
                            {
                            }
                            column(CountrySubUnrealAmount; CountrySubTotalAmt[4])
                            {
                            }
                            column(CountrySubTotalPrint; PrintCountrySubTotal)
                            {
                            }

                            trigger OnPreDataItem()
                            var
                                VATEntryLocal: Record "VAT Entry";
                            begin
                                // NAVCZ
                                if not PrintVATEntries then
                                    CurrReport.Break();

                                if PrintCountrySubTotal = 1 then
                                    Clear(CountrySubTotalAmt);
                                Clear(PrintCountrySubTotal);
                                if not UseAmtsInAddCurr then begin
                                    CountrySubTotalAmt[1] += "VAT Entry".Base;
                                    CountrySubTotalAmt[2] += "VAT Entry".Amount;
                                    CountrySubTotalAmt[3] += "VAT Entry"."Unrealized Base";
                                    CountrySubTotalAmt[4] += "VAT Entry"."Unrealized Amount";
                                end else begin
                                    CountrySubTotalAmt[1] += "VAT Entry"."Additional-Currency Base";
                                    CountrySubTotalAmt[2] += "VAT Entry"."Additional-Currency Amount";
                                    CountrySubTotalAmt[3] += "VAT Entry"."Add.-Currency Unrealized Base";
                                    CountrySubTotalAmt[4] += "VAT Entry"."Add.-Currency Unrealized Amt.";
                                end;

                                SetRange(Number, 0);
                                VATEntryLocal := "VAT Entry";
                                if "VAT Entry".Next <> 0 then begin
                                    if VATEntryLocal."Country/Region Code" <> "VAT Entry"."Country/Region Code" then
                                        PrintCountrySubTotal := 1;
                                    "VAT Entry".Next(-1);
                                    if ("VAT Entry".Base = 0) and ("VAT Entry"."Advance Base" <> 0) then
                                        "VAT Entry".Base := "VAT Entry"."Advance Base";
                                end else
                                    PrintCountrySubTotal := 1;
                                SetRange(Number, PrintCountrySubTotal);
                                // NAVCZ
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnBeforeCheckPrintVATEntries("VAT Entry");
                            if not PrintVATEntries then
                                CurrReport.Skip();
                            // NAVCZ
                            if (Base = 0) and ("Advance Base" <> 0) then
                                Base := "Advance Base";
                            VATEntryDocumentNo := "Document No.";
                            VATEntryDocumentType := Format("Document Type");
                            // NAVCZ
                        end;

                        trigger OnPreDataItem()
                        begin
                            CopyFilters(VATEntry);
                            Clear(CountrySubTotalAmt); // NAVCZ
                        end;
                    }
                    dataitem("Close VAT Entries"; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        MaxIteration = 1;
                        column(PostingDate1; Format(PostingDate))
                        {
                        }
                        column(GenJnlLineDocumentNo; GenJnlLine."Document No.")
                        {
                        }
                        column(GenJnlLineVATBaseAmount; GenJnlLine."VAT Base Amount")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(GenJnlLineVATAmount; GenJnlLine."VAT Amount")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(GenJnlLnVATCalcType; Format(GenJnlLine."VAT Calculation Type"))
                        {
                        }
                        column(NextVATEntryNo; NextVATEntryNo)
                        {
                        }
                        column(GenJnlLnSrcCurrVATAmount; GenJnlLine."Source Curr. VAT Amount")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(GenJnlLnSrcCurrVATBaseAmt; GenJnlLine."Source Curr. VAT Base Amount")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(GenJnlLine2Amount; GenJnlLine2.Amount)
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(GenJnlLine2DocumentNo; GenJnlLine2."Document No.")
                        {
                        }
                        column(ReversingEntry; ReversingEntry)
                        {
                        }
                        column(GenJnlLn2SrcCurrencyAmt; GenJnlLine2."Source Currency Amount")
                        {
                            AutoFormatExpression = GetCurrency;
                            AutoFormatType = 1;
                        }
                        column(SettlementCaption; SettlementCaptionLbl)
                        {
                        }
                        column(GenJnlLineVATRegistrationNo; GenJnlLine."VAT Registration No.")
                        {
                        }
                        column(GenJnlLineCountryRegionCode; GenJnlLine."Country/Region Code")
                        {
                        }
                        column(GenJnlLine2VATRegistrationNo; GenJnlLine2."VAT Registration No.")
                        {
                        }
                        column(GenJnlLine2CountryRegionCode; GenJnlLine2."Country/Region Code")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            // Calculate amount and base
                            VATEntry.CalcSums(
                              Base, Amount,
                              "Additional-Currency Base", "Additional-Currency Amount");
                            // NAVCZ
                            VATEntry.CalcSums("Advance Base");
                            // NAVCZ

                            ReversingEntry := false;
                            // Balancing entries to VAT accounts
                            Clear(GenJnlLine);
                            GenJnlLine."System-Created Entry" := true;
                            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                            case VATType of
                                VATEntry.Type::Purchase:
                                    GenJnlLine.Description :=
                                      DelChr(
                                        StrSubstNo(
                                          Text007,
                                          "VAT Posting Setup"."VAT Bus. Posting Group",
                                          "VAT Posting Setup"."VAT Prod. Posting Group"),
                                        '>');
                                VATEntry.Type::Sale:
                                    GenJnlLine.Description :=
                                      DelChr(
                                        StrSubstNo(
                                          Text008,
                                          "VAT Posting Setup"."VAT Bus. Posting Group",
                                          "VAT Posting Setup"."VAT Prod. Posting Group"),
                                        '>');
                            end;
                            SetVatPostingSetupToGenJnlLine(GenJnlLine, "VAT Posting Setup");
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine.Validate("VAT Date", PostingDate); // NAVCZ
                            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                            GenJnlLine."Document No." := DocNo;
                            GenJnlLine."Source Code" := SourceCodeSetup."VAT Settlement";
                            GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                            case "VAT Posting Setup"."VAT Calculation Type" of
                                "VAT Posting Setup"."VAT Calculation Type"::"Normal VAT",
                              "VAT Posting Setup"."VAT Calculation Type"::"Full VAT":
                                    CalculateNormalVAT; // NAVCZ
                                "VAT Posting Setup"."VAT Calculation Type"::"Reverse Charge VAT":
                                    CalculateReverseChargeVAT; // NAVCZ
                                "VAT Posting Setup"."VAT Calculation Type"::"Sales Tax":
                                    CalculateSalesTax; // NAVCZ
                            end;
                            NextVATEntryNo := GetSettlementVATEntryNo(PostSettlement);

                            // Close current VAT entries
                            if PostSettlement and (NextVATEntryNo <> 0) then
                                CloseVATEntriesOnPostSettlement(VATEntry, NextVATEntryNo);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        VATEntry.Reset();
                        VATEntry.SetRange(Type, VATType);
                        VATEntry.SetRange(Closed, false);
                        VATEntry.SetFilter("VAT Date", VATDateFilter); // NAVCZ
                        VATEntry.SetRange("VAT Bus. Posting Group", "VAT Posting Setup"."VAT Bus. Posting Group");
                        VATEntry.SetRange("VAT Prod. Posting Group", "VAT Posting Setup"."VAT Prod. Posting Group");
                        // NAVCZ
                        if Advance.Number = 1 then
                            VATEntry.SetRange("Advance Letter No.", '')
                        else
                            VATEntry.SetFilter("Advance Letter No.", '<>%1', '');
                        // NAVCZ

                        OnClosingGLAndVATEntryOnAfterGetRecordOnAfterSetVATEntryFilters("VAT Posting Setup", VATEntry, "VAT Entry");

                        case "VAT Posting Setup"."VAT Calculation Type" of
                            "VAT Posting Setup"."VAT Calculation Type"::"Normal VAT",
                            "VAT Posting Setup"."VAT Calculation Type"::"Reverse Charge VAT",
                            "VAT Posting Setup"."VAT Calculation Type"::"Full VAT":
                                begin
                                    VATEntry.SetCurrentKey(
                                      Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group",
                                      "Gen. Bus. Posting Group", "Gen. Prod. Posting Group",
                                      "EU 3-Party Trade", "EU 3-Party Intermediate Role", "VAT Date");
                                    if FindFirstEntry then begin
                                        if not VATEntry.Find('-') then
                                            repeat
                                                VATType := IncrementGenPostingType(VATType);
                                                VATEntry.SetRange(Type, VATType);
                                            until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                        FindFirstEntry := false;
                                    end else begin
                                        if VATEntry.Next() = 0 then
                                            repeat
                                                VATType := IncrementGenPostingType(VATType);
                                                VATEntry.SetRange(Type, VATType);
                                            until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                    end;
                                    if IsNotSettlement(VATType) then
                                        VATEntry.Find('+');
                                end;
                            "VAT Posting Setup"."VAT Calculation Type"::"Sales Tax":
                                begin
                                    VATEntry.SetCurrentKey(Type, Closed, "Tax Jurisdiction Code", "Use Tax", "VAT Date");
                                    if FindFirstEntry then begin
                                        if not VATEntry.Find('-') then
                                            repeat
                                                VATType := IncrementGenPostingType(VATType);
                                                VATEntry.SetRange(Type, VATType);
                                            until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                        FindFirstEntry := false;
                                    end else begin
                                        VATEntry.SetRange("Tax Jurisdiction Code");
                                        VATEntry.SetRange("Use Tax");
                                        if VATEntry.Next() = 0 then
                                            repeat
                                                VATType := IncrementGenPostingType(VATType);
                                                VATEntry.SetRange(Type, VATType);
                                            until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                    end;
                                    if IsNotSettlement(VATType) then begin
                                        VATEntry.SetRange("Tax Jurisdiction Code", VATEntry."Tax Jurisdiction Code");
                                        VATEntry.SetRange("Use Tax", VATEntry."Use Tax");
                                        VATEntry.Find('+');
                                    end;
                                end;
                        end;

                        if not IsNotSettlement(VATType) then
                            CurrReport.Break();
                    end;

                    trigger OnPreDataItem()
                    begin
                        VATType := VATEntry.Type::Purchase;
                        FindFirstEntry := true;
                    end;
                }
            }

            trigger OnPostDataItem()
            begin
                // Post to settlement account
                if VATAmount <> 0 then begin
                    GenJnlLine.Init();
                    GenJnlLine."System-Created Entry" := true;
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";

                    GLAccSettle.TestField("Gen. Posting Type", GenJnlLine."Gen. Posting Type"::" ");
                    GLAccSettle.TestField("VAT Bus. Posting Group", '');
                    GLAccSettle.TestField("VAT Prod. Posting Group", '');
                    if VATPostingSetup.Get(GLAccSettle."VAT Bus. Posting Group", GLAccSettle."VAT Prod. Posting Group") then
                        VATPostingSetup.TestField("VAT %", 0);
                    GLAccSettle.TestField("Gen. Bus. Posting Group", '');
                    GLAccSettle.TestField("Gen. Prod. Posting Group", '');

                    GenJnlLine.Validate("Account No.", GLAccSettle."No.");
                    GenJnlLine."Posting Date" := PostingDate;
                    GenJnlLine.Validate("VAT Date", PostingDate); // NAVCZ
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                    GenJnlLine."Document No." := DocNo;
                    GenJnlLine.Description := Text004;
                    GenJnlLine.Amount := VATAmount;
                    GenJnlLine."Source Currency Code" := GLSetup."Additional Reporting Currency";
                    GenJnlLine."Source Currency Amount" := VATAmountAddCurr;
                    GenJnlLine."Source Code" := SourceCodeSetup."VAT Settlement";
                    GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                    if PostSettlement then
                        PostGenJnlLine(GenJnlLine);
                end;
            end;

            trigger OnPreDataItem()
            begin
                GLEntry.LockTable(); // Avoid deadlock with function 12
                if GLEntry.FindLast then;
                VATEntry.LockTable();
                VATEntry.Reset();
                NextVATEntryNo := VATEntry.GetLastEntryNo();

                SourceCodeSetup.Get();
                GLSetup.Get();
                VATAmount := 0;
                VATAmountAddCurr := 0;

                if UseAmtsInAddCurr then
                    HeaderText := StrSubstNo(AllAmountsAreInTxt, GLSetup."Additional Reporting Currency")
                else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo(AllAmountsAreInTxt, GLSetup."LCY Code");
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        ShowFilter = false;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; EntrdStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        TableRelation = "VAT Period";
                        ToolTip = 'Specifies the first date in the period from which VAT entries are processed in the batch job.';

                        trigger OnValidate()
                        begin
                            // NAVCZ
                            VATPeriod.Get(EntrdStartDate);
                            if VATPeriod.Next > 0 then
                                EndDateReq := CalcDate('<-1D>', VATPeriod."Starting Date");
                            // NAVCZ
                        end;
                    }
                    field(EndDateReq; EndDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date in the period from which VAT entries are processed in the batch job.';
                    }
                    field(PostingDt; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date on which the transfer to the VAT account is posted. This field must be filled in.';
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies a document number. This field must be filled in.';
                    }
                    field(SettlementAcc; GLAccSettle."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Settlement Account';
                        TableRelation = "G/L Account";
                        ToolTip = 'Specifies the number of the VAT settlement account. Select the field to see the chart of account. This field must be filled in.';

                        trigger OnValidate()
                        begin
                            if GLAccSettle."No." <> '' then begin
                                GLAccSettle.Find();
                                GLAccSettle.CheckGLAcc();
                            end;
                        end;
                    }
                    field(ShowVATEntries; PrintVATEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show VAT Entries';
                        ToolTip = 'Specifies if you want the report that is printed during the batch job to contain the individual VAT entries. If you do not choose to print the VAT entries, the settlement amount is shown only for each VAT posting group.';
                    }
                    field(Post; PostSettlement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                        ToolTip = 'Specifies if you want the program to post the transfer to the VAT settlement account automatically. If you do not choose to post the transfer, the batch job only prints a test report, and Test Report (not Posted) appears on the report.';
                    }
                    field(AmtsinAddReportingCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
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

    trigger OnPostReport()
    begin
        // NAVCZ
        if PostSettlement and VATPeriod.Get(EntrdStartDate) then begin
            VATPeriod.Closed := true;
            VATPeriod.Modify();
        end;
        // NAVCZ

        OnAfterPostReport();
    end;

    trigger OnPreReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        OnBeforePreReport("VAT Posting Setup");

        if PostingDate = 0D then
            Error(Text000);
        if DocNo = '' then
            Error(Text001);
        // NAVCZ
        if MaxStrLen(VATEntry."VAT Settlement No.") < StrLen(DocNo) then
            Error(DocNoErr, Format(MaxStrLen(VATEntry."VAT Settlement No.")));
        // NAVCZ
        if GLAccSettle."No." = '' then
            Error(Text002);
        GLAccSettle.Find();

        if PostSettlement and not Initialized then
            if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
                CurrReport.Quit;

        VATPostingSetupFilter := "VAT Posting Setup".GetFilters;
        // NAVCZ
        if EndDateReq = 0D then
            VATEntry.SetFilter("VAT Date", '%1..', EntrdStartDate)
        else
            VATEntry.SetRange("VAT Date", EntrdStartDate, EndDateReq);
        VATDateFilter := CopyStr(VATEntry.GetFilter("VAT Date"), 1, 30);
        Clear(GenJnlPostLine);
        // NAVCZ

        OnAfterPreReport("VAT Entry");
    end;

    var
        Text000: Label 'Enter the posting date.';
        Text001: Label 'Enter the document no.';
        Text002: Label 'Enter the settlement account.';
        Text003: Label 'Do you want to calculate and post the VAT Settlement?';
        Text004: Label 'VAT Settlement';
        Text005: Label 'Period: %1';
        AllAmountsAreInTxt: Label 'All amounts are in %1.', Comment = '%1 = Currency Code';
        Text007: Label 'Purchase VAT settlement: #1######## #2########';
        Text008: Label 'Sales VAT settlement  : #1######## #2########';
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        TaxJurisdiction: Record "Tax Jurisdiction";
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPeriod: Record "VAT Period";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        EntrdStartDate: Date;
        EndDateReq: Date;
        PrintVATEntries: Boolean;
        NextVATEntryNo: Integer;
        PostingDate: Date;
        DocNo: Code[20];
        VATType: Enum "General Posting Type";
        VATAmount: Decimal;
        VATAmountAddCurr: Decimal;
        PostSettlement: Boolean;
        FindFirstEntry: Boolean;
        ReversingEntry: Boolean;
        Initialized: Boolean;
        VATPostingSetupFilter: Text;
        VATDateFilter: Text;
        UseAmtsInAddCurr: Boolean;
        HeaderText: Text[30];
        CalcandPostVATSettlementCaptionLbl: Label 'Calc. and Post VAT Settlement';
        PageCaptionLbl: Label 'Page';
        TestReportnotpostedCaptionLbl: Label 'Test Report (Not Posted)';
        DocNoCaptionLbl: Label 'Document No.';
        SettlementAccCaptionLbl: Label 'Settlement Account';
        DocumentTypeCaptionLbl: Label 'Document Type';
        UserIDCaptionLbl: Label 'User ID';
        TotalCaptionLbl: Label 'Total';
        SettlementCaptionLbl: Label 'Settlement';
        PrintCountrySubTotal: Integer;
        CountrySubTotalAmt: array[4] of Decimal;
        DocNoErr: Label 'Document No. is too long (max. %1 characters).', Comment = '%1=Max length of VAT Settlement No.';
        CountrySubtotalCaptionLbl: Label 'Total for Country/Region %1', Comment = '%1="Country/Region Code"';
        VATEntryDocumentNo: Code[20];
        VATEntryDocumentType: Text;

    protected var
        GLAccSettle: Record "G/L Account";

    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewPostingDate: Date; NewDocNo: Code[20]; NewSettlementAcc: Code[20]; ShowVATEntries: Boolean; Post: Boolean)
    begin
        EntrdStartDate := NewStartDate;
        EndDateReq := NewEndDate;
        PostingDate := NewPostingDate;
        DocNo := NewDocNo;
        GLAccSettle."No." := NewSettlementAcc;
        PrintVATEntries := ShowVATEntries;
        PostSettlement := Post;
        Initialized := true;
        if VATPeriod.Get(EntrdStartDate) then; // NAVCZ
    end;

    procedure InitializeRequest2(NewUseAmtsInAddCurr: Boolean)
    begin
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
    end;

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;

    local procedure PostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := DATABASE::"G/L Account";
        TableID[2] := DATABASE::"G/L Account";
        No[1] := GenJnlLine."Account No.";
        No[2] := GenJnlLine."Bal. Account No.";
        GenJnlLine."Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            GenJnlLine, 0, TableID, No, GenJnlLine."Source Code",
            GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code", 0, 0);
        GenJnlPostLine.Run(GenJnlLine);
    end;

    procedure SetInitialized(Initialize: Boolean)
    begin
        Initialized := Initialize;
    end;

    local procedure CopyAmounts(var GenJournalLine: Record "Gen. Journal Line"; VATEntry: Record "VAT Entry")
    begin
        with GenJournalLine do begin
            Amount := -VATEntry.Amount;
            "VAT Amount" := -VATEntry.Amount;
            "VAT Base Amount" := -VATEntry.Base;
            "VAT Base Amount" := "VAT Base Amount" - VATEntry."Advance Base"; // NAVCZ
            "Source Currency Code" := GLSetup."Additional Reporting Currency";
            "Source Currency Amount" := -VATEntry."Additional-Currency Amount";
            "Source Curr. VAT Amount" := -VATEntry."Additional-Currency Amount";
            "Source Curr. VAT Base Amount" := -VATEntry."Additional-Currency Base";
        end;
    end;

    local procedure CreateGenJnlLine(var GenJnlLine2: Record "Gen. Journal Line"; AccountNo: Code[20])
    begin
        Clear(GenJnlLine2);
        GenJnlLine2."System-Created Entry" := true;
        GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::"G/L Account";
        GenJnlLine2.Description := GenJnlLine.Description;
        GenJnlLine2."Posting Date" := PostingDate;
        GenJnlLine2."Document Type" := GenJnlLine2."Document Type"::" ";
        GenJnlLine2."Document No." := DocNo;
        GenJnlLine2."Source Code" := SourceCodeSetup."VAT Settlement";
        GenJnlLine2."VAT Posting" := GenJnlLine2."VAT Posting"::"Manual VAT Entry";
        GenJnlLine2."Account No." := AccountNo;
        GenJnlLine2.Amount := VATEntry.Amount;
        GenJnlLine2."Source Currency Code" := GLSetup."Additional Reporting Currency";
        GenJnlLine2."Source Currency Amount" := VATEntry."Additional-Currency Amount";
        GenJnlLine2.Validate("VAT Date", PostingDate); // NAVCZ
    end;

    local procedure CalculateNormalVAT()
    begin
        // NAVCZ
        GenJnlLine."Account No." :=
          "VAT Posting Setup".GetVATAccountNo(VATEntry.Type, VATEntry."Advance Letter No." <> '');
        // NAVCZ
        CopyAmounts(GenJnlLine, VATEntry);
        if PostSettlement then
            PostGenJnlLine(GenJnlLine);
        VATAmount := VATAmount + VATEntry.Amount;
        VATAmountAddCurr := VATAmountAddCurr + VATEntry."Additional-Currency Amount";
    end;

    local procedure CalculateReverseChargeVAT()
    begin
        case VATType of
            VATEntry.Type::Purchase:
                begin
                    // NAVCZ
                    GenJnlLine."Account No." :=
                      "VAT Posting Setup".GetVATAccountNo(VATEntry.Type, VATEntry."Advance Letter No." <> '');
                    // NAVCZ
                    CopyAmounts(GenJnlLine, VATEntry);
                    if PostSettlement then
                        PostGenJnlLine(GenJnlLine);

                    CreateGenJnlLine(GenJnlLine2, "VAT Posting Setup".GetRevChargeAccount(false));
                    if PostSettlement then
                        PostGenJnlLine(GenJnlLine2);
                    ReversingEntry := true;
                end;
            VATEntry.Type::Sale:
                begin
                    // NAVCZ
                    GenJnlLine."Account No." :=
                      "VAT Posting Setup".GetVATAccountNo(VATEntry.Type, VATEntry."Advance Letter No." <> '');
                    // NAVCZ
                    CopyAmounts(GenJnlLine, VATEntry);
                    if PostSettlement then
                        PostGenJnlLine(GenJnlLine);
                end;
        end;
    end;

    local procedure CalculateSalesTax()
    begin
        TaxJurisdiction.Get(VATEntry."Tax Jurisdiction Code");
        GenJnlLine."Tax Area Code" := TaxJurisdiction.Code;
        GenJnlLine."Use Tax" := VATEntry."Use Tax";
        case VATType of
            VATEntry.Type::Purchase:
                if VATEntry."Use Tax" then begin
                    TaxJurisdiction.TestField("Tax Account (Purchases)");
                    GenJnlLine."Account No." := TaxJurisdiction."Tax Account (Purchases)";
                    CopyAmounts(GenJnlLine, VATEntry);
                    if PostSettlement then
                        PostGenJnlLine(GenJnlLine);

                    TaxJurisdiction.TestField("Reverse Charge (Purchases)");
                    CreateGenJnlLine(GenJnlLine2, TaxJurisdiction."Reverse Charge (Purchases)");
                    GenJnlLine2."Tax Area Code" := TaxJurisdiction.Code;
                    GenJnlLine2."Use Tax" := VATEntry."Use Tax";
                    if PostSettlement then
                        PostGenJnlLine(GenJnlLine2);
                    ReversingEntry := true;
                end else begin
                    TaxJurisdiction.TestField("Tax Account (Purchases)");
                    GenJnlLine."Account No." := TaxJurisdiction."Tax Account (Purchases)";
                    CopyAmounts(GenJnlLine, VATEntry);
                    if PostSettlement then
                        PostGenJnlLine(GenJnlLine);
                    VATAmount := VATAmount + VATEntry.Amount;
                    VATAmountAddCurr := VATAmountAddCurr + VATEntry."Additional-Currency Amount";
                end;
            VATEntry.Type::Sale:
                begin
                    TaxJurisdiction.TestField("Tax Account (Sales)");
                    GenJnlLine."Account No." := TaxJurisdiction."Tax Account (Sales)";
                    CopyAmounts(GenJnlLine, VATEntry);
                    if PostSettlement then
                        PostGenJnlLine(GenJnlLine);
                    VATAmount := VATAmount + VATEntry.Amount;
                    VATAmountAddCurr := VATAmountAddCurr + VATEntry."Additional-Currency Amount";
                end;
        end;
    end;

    local procedure SetVatPostingSetupToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Settlement;
        GenJnlLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        GenJnlLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GenJnlLine."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
    end;

    local procedure IncrementGenPostingType(var OldGenPostingType: Enum "General Posting Type") NewGenPostingType: Enum "General Posting Type"
    begin
        case OldGenPostingType of
            OldGenPostingType::" ":
                exit(NewGenPostingType::Purchase);
            OldGenPostingType::Purchase:
                exit(NewGenPostingType::Sale);
            OldGenPostingType::Sale:
                exit(NewGenPostingType::Settlement);
        end;

        OnAfterIncrementGenPostingType(OldGenPostingType, NewGenPostingType);
    end;

    local procedure CloseVATEntriesOnPostSettlement(var VATEntry: Record "VAT Entry"; NextVATEntryNo: Integer)
    var
        VATEntryNext: Record "VAT Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCloseVATEntriesOnPostSettlement(VATEntry, NextVATEntryNo, IsHandled);
        if IsHandled then
            exit;

        VATEntry.ModifyAll("Closed by Entry No.", NextVATEntryNo);
        VATEntry.ModifyAll("VAT Settlement No.", CopyStr(DocNo, 1, MaxStrLen(VATEntry."VAT Settlement No."))); // NAVCZ
        VATEntry.ModifyAll(Closed, true);

        // NAVCZ
        VATEntryNext.Get(NextVATEntryNo);
        VATEntryNext."VAT Settlement No." := CopyStr(DocNo, 1, MaxStrLen(VATEntryNext."VAT Settlement No."));
        VATEntryNext.Modify();
        // NAVCZ
    end;

    local procedure IsNotSettlement(GenPostingType: Enum "General Posting Type"): Boolean
    begin
        exit(
            (GenPostingType = GenPostingType::" ") or
            (GenPostingType = GenPostingType::Purchase) or
            (GenPostingType = GenPostingType::Sale));
    end;

    local procedure GetSettlementVATEntryNo(PostVATSettlement: Boolean): Integer
    var
        NextAvailableVATEntryNo: Integer;
        LastPostedVATEntryNo: Integer;
    begin
        if PostVATSettlement then begin
            NextAvailableVATEntryNo := GenJnlPostLine.GetNextVATEntryNo();
            if NextAvailableVATEntryNo <> 0 then
                LastPostedVATEntryNo := NextAvailableVATEntryNo - 1;
            exit(LastPostedVATEntryNo);
        end;

        NextVATEntryNo += 1;
        exit(NextVATEntryNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPreReport(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrintVATEntries(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCloseVATEntriesOnPostSettlement(var VATEntry: Record "VAT Entry"; NextVATEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncrementGenPostingType(OldGenPostingType: Enum "General Posting Type"; var NewGenPostingType: Enum "General Posting Type")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnClosingGLAndVATEntryOnAfterGetRecordOnAfterSetVATEntryFilters(VATPostingSetup: Record "VAT Posting Setup"; var VATEntry: Record "VAT Entry"; var VATEntry2: Record "VAT Entry")
    begin
    end;
}
#endif