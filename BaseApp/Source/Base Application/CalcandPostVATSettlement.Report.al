report 20 "Calc. and Post VAT Settlement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CalcandPostVATSettlement.rdlc';
    AdditionalSearchTerms = 'settle vat value added tax,report vat value added tax';
    ApplicationArea = Basic, Suite;
    Caption = 'Calculate and Post VAT Settlement';
    Permissions = TableData "VAT Entry" = imd;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Posting Setup"; "VAT Posting Setup")
        {
            DataItemTableView = SORTING("VAT Bus. Posting Group", "VAT Prod. Posting Group");
            RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PeriodVATDateFltr; StrSubstNo(Text005, VATDateFilter))
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
            column(GlAccSettleNo; GLAccSettle."No.")
            {
            }
            column(UseAmtsInAddCurr; UseAmtsInAddCurr)
            {
            }
            column(PrintVATEntries; PrintVATEntries)
            {
            }
            column(Fltr_VATPostingSetup; "VAT Posting Setup".TableCaption + ': ' + VATPostingSetupFilter)
            {
            }
            column(VATPostingSetupFltr; VATPostingSetupFilter)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(VatAmt; VATAmount)
            {
                AutoFormatExpression = GetCurrency;
                AutoFormatType = 1;
            }
            column(VatAmtAddCurr; VATAmountAddCurr)
            {
                AutoFormatExpression = GetCurrency;
                AutoFormatType = 1;
            }
            column(VATProdPostGrp_VATPostingSetup; "VAT Prod. Posting Group")
            {
            }
            column(CalcandPostVATSettleCaption; CalcandPostVATSettleCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(TestRepnotpostedCaption; TestRepnotpostedCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(GLAccSettleNoCaption; GLAccSettleNoCaptionLbl)
            {
            }
            column(VATEntryDocTypeCaption; VATEntryDocTypeCaptionLbl)
            {
            }
            column(VATEntryUserIDCaption; VATEntryUserIDCaptionLbl)
            {
            }
            column(VatCalTypeCaption; "VAT Entry".FieldCaption("VAT Calculation Type"))
            {
            }
            column(UnrealizedAmtCaption; "VAT Entry".FieldCaption("Unrealized Amount"))
            {
            }
            column(UnrealizedBaseCaption; "VAT Entry".FieldCaption("Unrealized Base"))
            {
            }
            column(BilltoPaytoNoCaption; "VAT Entry".FieldCaption("Bill-to/Pay-to No."))
            {
            }
            column(EntryNoCaption; "VAT Entry".FieldCaption("Entry No."))
            {
            }
            column(VATAmtCaption; VATAmtCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            dataitem("Closing G/L and VAT Entry"; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(ProdGroup1_VATPostingSetup; "VAT Posting Setup"."VAT Bus. Posting Group")
                {
                }
                column(ProdGroup2_VATPostingSetup; "VAT Posting Setup"."VAT Prod. Posting Group")
                {
                }
                column(VatEntryFltrType; VATEntry.GetFilter(Type))
                {
                }
                column(VatEntryFltrTypeTaxJurCode; VATEntry.GetFilter("Tax Jurisdiction Code"))
                {
                }
                column(VatEntryFltrUseTax; VATEntry.GetFilter("Use Tax"))
                {
                }
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemTableView = SORTING(Type, Closed) WHERE(Closed = CONST(false), Type = FILTER(Purchase | Sale));
                    column(PostingDate_VatEntry; Format("Posting Date"))
                    {
                    }
                    column(DocumentNo_VatEntry; "Document No.")
                    {
                        IncludeCaption = true;
                    }
                    column(DocumentType_VatEntry; "Document Type")
                    {
                    }
                    column(Type_VatEntry; Type)
                    {
                        IncludeCaption = true;
                    }
                    column(Base_VatEntry; Base)
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                        IncludeCaption = true;
                    }
                    column(Amt_VatEntry; Amount)
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                        IncludeCaption = true;
                    }
                    column(CalType_VatEntry; "VAT Calculation Type")
                    {
                        IncludeCaption = true;
                    }
                    column(BilltoPaytoNo_VatEntry; "Bill-to/Pay-to No.")
                    {
                        IncludeCaption = true;
                    }
                    column(EntryNo_VatEntry; "Entry No.")
                    {
                        IncludeCaption = true;
                    }
                    column(UserID_VatEntry; "User ID")
                    {
                    }
                    column(UnrealizedAmt_VatEntry; "Unrealized Amount")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                        IncludeCaption = true;
                    }
                    column(UnrealizedBase_VatEntry; "Unrealized Base")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                        IncludeCaption = true;
                    }
                    column(CurrUnrealizedAmt_VatEntry; "Add.-Currency Unrealized Amt.")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(CurrUnrealizedBase_VatEntry; "Add.-Currency Unrealized Base")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(CurrencyAmt_VatEntry; "Additional-Currency Amount")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(CurrencyBase_VatEntry; "Additional-Currency Base")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        OnBeforeCheckPrintVATEntries("VAT Entry");
                        if not PrintVATEntries then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        CopyFilters(VATEntry);
                    end;
                }
                dataitem("Close VAT Entries"; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    MaxIteration = 1;
                    column(PostingDate1; Format(PostingDate))
                    {
                    }
                    column(GenJnlLineDocNo; GenJnlLine."Document No.")
                    {
                    }
                    column(GenJnlLineVATBaseAmt; GenJnlLine."VAT Base Amount")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(GenJnlLineVATAmt; GenJnlLine."VAT Amount")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(GenJnlLineVATCalType; Format(GenJnlLine."VAT Calculation Type"))
                    {
                    }
                    column(NextVatEntryNo; NextVATEntryNo)
                    {
                    }
                    column(GenJnlLineSrcCurrVatAmt; GenJnlLine."Source Curr. VAT Amount")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(GenJnlLineSrcCurrVatBaseAmt; GenJnlLine."Source Curr. VAT Base Amount")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(GenJnlLine2Amt; GenJnlLine2.Amount)
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(GenJnlLine2DocNo; GenJnlLine2."Document No.")
                    {
                    }
                    column(ReversingEntry; ReversingEntry)
                    {
                    }
                    column(GenJnlLine2SrcCurrAmt; GenJnlLine2."Source Currency Amount")
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(GenJnlLineVATBaseAmtCaption; GenJnlLineVATBaseAmtCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        // Calculate amount and base
                        VATEntry.CalcSums(
                          Base, Amount,
                          "Additional-Currency Base", "Additional-Currency Amount");

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
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                        GenJnlLine."Document No." := DocNo;
                        GenJnlLine."Source Code" := SourceCodeSetup."VAT Settlement";
                        GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                        case "VAT Posting Setup"."VAT Calculation Type" of
                            "VAT Posting Setup"."VAT Calculation Type"::"Normal VAT",
                            "VAT Posting Setup"."VAT Calculation Type"::"Full VAT",
                            "VAT Posting Setup"."VAT Calculation Type"::"No Taxable VAT":
                                begin
                                    case VATType of
                                        VATEntry.Type::Purchase:
                                            GenJnlLine."Account No." := "VAT Posting Setup".GetPurchAccount(false);
                                        VATEntry.Type::Sale:
                                            GenJnlLine."Account No." := "VAT Posting Setup".GetSalesAccount(false);
                                    end;
                                    CopyAmounts(GenJnlLine, VATEntry);
                                    if PostSettlement then
                                        PostGenJnlLine(GenJnlLine);
                                    VATAmount := VATAmount + VATEntry.Amount;
                                    VATAmountAddCurr := VATAmountAddCurr + VATEntry."Additional-Currency Amount";
                                end;
                            "VAT Posting Setup"."VAT Calculation Type"::"Reverse Charge VAT":
                                case VATType of
                                    VATEntry.Type::Purchase:
                                        begin
                                            GenJnlLine."Account No." := "VAT Posting Setup".GetPurchAccount(false);
                                            CopyAmounts(GenJnlLine, VATEntry);
                                            if PostSettlement then
                                                PostGenJnlLine(GenJnlLine);

                                            CreateGenJnlLine(GenJnlLine2, "VAT Posting Setup".GetRevChargeAccount(false));
                                            OnBeforePostGenJnlLineReverseChargeVAT(GenJnlLine2, VATEntry, VATAmount, VATAmountAddCurr);
                                            if PostSettlement then
                                                PostGenJnlLine(GenJnlLine2);
                                            ReversingEntry := true;
                                        end;
                                    VATEntry.Type::Sale:
                                        begin
                                            GenJnlLine."Account No." := "VAT Posting Setup".GetSalesAccount(false);
                                            CopyAmounts(GenJnlLine, VATEntry);
                                            if PostSettlement then
                                                PostGenJnlLine(GenJnlLine);

                                            OnCloseVATEntriesOnAfterPostGenJnlLineReverseChargeVATSales(
                                                VATEntry, GenJnlLine, GenJnlPostLine, "VAT Posting Setup", PostSettlement, ReversingEntry, DocNo, PostingDate);
                                        end;
                                end;
                            "VAT Posting Setup"."VAT Calculation Type"::"Sales Tax":
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
                    VATEntry.SetFilter("Posting Date", VATDateFilter);
                    VATEntry.SetRange("VAT Bus. Posting Group", "VAT Posting Setup"."VAT Bus. Posting Group");
                    VATEntry.SetRange("VAT Prod. Posting Group", "VAT Posting Setup"."VAT Prod. Posting Group");

                    case "VAT Posting Setup"."VAT Calculation Type" of
                        "VAT Posting Setup"."VAT Calculation Type"::"Normal VAT",
                        "VAT Posting Setup"."VAT Calculation Type"::"Reverse Charge VAT",
                        "VAT Posting Setup"."VAT Calculation Type"::"Full VAT",
                        "VAT Posting Setup"."VAT Calculation Type"::"No Taxable VAT":
                            begin
                                VATEntry.SetCurrentKey(
                                    Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date");
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
                                VATEntry.SetCurrentKey(Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
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

                    if VATType = VATEntry.Type::Settlement then
                        CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    VATType := VATEntry.Type::Purchase;
                    FindFirstEntry := true;
                end;
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
                        VATPostingSetup.TestField("VAT+EC %", 0);
                    GLAccSettle.TestField("Gen. Bus. Posting Group", '');
                    GLAccSettle.TestField("Gen. Prod. Posting Group", '');

                    GenJnlLine.Validate("Account No.", GLAccSettle."No.");
                    GenJnlLine."Posting Date" := PostingDate;
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
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EndDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date in the period from which VAT entries are processed in the batch job. ';
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
        TypeCaption = 'Type';
        BaseCaption = 'Base';
        AmountCaption = 'Amount';
    }

    trigger OnPostReport()
    begin
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
        if GLAccSettle."No." = '' then
            Error(Text002);
        GLAccSettle.Find();

        if PostSettlement and not Initialized then
            if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
                CurrReport.Quit;

        VATPostingSetupFilter := "VAT Posting Setup".GetFilters;
        if EndDateReq = 0D then
            VATEntry.SetFilter("Posting Date", '%1..', EntrdStartDate)
        else
            VATEntry.SetRange("Posting Date", EntrdStartDate, EndDateReq);
        VATDateFilter := VATEntry.GetFilter("Posting Date");
        Clear(GenJnlPostLine);

        OnAfterPreReport;
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
        GLAccSettle: Record "G/L Account";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        TaxJurisdiction: Record "Tax Jurisdiction";
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
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
        CalcandPostVATSettleCaptionLbl: Label 'Calc. and Post VAT Settlement';
        PageNoCaptionLbl: Label 'Page';
        TestRepnotpostedCaptionLbl: Label 'Test Report (Not Posted)';
        PostingDateCaptionLbl: Label 'Posting Date';
        DocNoCaptionLbl: Label 'Document No.';
        GLAccSettleNoCaptionLbl: Label 'Settlement Account';
        VATEntryDocTypeCaptionLbl: Label 'Document Type';
        VATEntryUserIDCaptionLbl: Label 'User ID';
        VATAmtCaptionLbl: Label 'Total';
        PageCaptionLbl: Label 'Page';
        GenJnlLineVATBaseAmtCaptionLbl: Label 'Settlement';

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
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCloseVATEntriesOnPostSettlement(VATEntry, NextVATEntryNo, IsHandled);
        if IsHandled then
            exit;

        VATEntry.ModifyAll("Closed by Entry No.", NextVATEntryNo);
        VATEntry.ModifyAll(Closed, true);
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
    local procedure OnAfterPreReport()
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
    local procedure OnBeforePostGenJnlLineReverseChargeVAT(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var VATAmount: Decimal; var VATAmountAddCurr: Decimal)
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

    [IntegrationEvent(false, false)]
    local procedure OnCloseVATEntriesOnAfterPostGenJnlLineReverseChargeVATSales(var VATEntry: Record "VAT Entry"; GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; VATPostingSetup: Record "VAT Posting Setup"; PostSettlement: Boolean; var ReversingEntry: Boolean; DocNo: Code[20]; PostingDate: Date)
    begin
    end;
}

