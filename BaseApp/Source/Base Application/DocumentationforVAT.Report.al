#if not CLEAN17
report 11764 "Documentation for VAT"
{
    DefaultLayout = RDLC;
    RDLCLayout = './DocumentationforVAT.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Documentation for VAT (Obsolete)';
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
            column(PeriodVATDateFilter; StrSubstNo(PeriodLbl, VATDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
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
            column(Heading; Heading)
            {
            }
            column(VATBase; VATBaseTotal[1])
            {
            }
            column(VATAmount; VATAmountTotal[1])
            {
                AutoFormatExpression = GetCurrency;
                AutoFormatType = 1;
            }
            column(VATBaseSale; VATBaseSaleTotal[1])
            {
            }
            column(VATAmountSale; VATAmountSaleTotal[1])
            {
            }
            column(VATBasePurch; VATBasePurchTotal[1])
            {
            }
            column(VATAmountPurch; VATAmountPurchTotal[1])
            {
            }
            column(VATBaseReverseChargeVAT; VATBaseReverseChargeVATTotal[1])
            {
            }
            column(VATAmountReverseChargeVAT; VATAmountReverseChargeVATTotal[1])
            {
            }
            column(VATBase2; VATBaseTotal[2])
            {
            }
            column(VATAmount2; VATAmountTotal[2])
            {
                AutoFormatExpression = GetCurrency;
                AutoFormatType = 1;
            }
            column(VATBaseSale2; VATBaseSaleTotal[2])
            {
            }
            column(VATAmountSale2; VATAmountSaleTotal[2])
            {
            }
            column(VATBasePurch2; VATBasePurchTotal[2])
            {
            }
            column(VATAmountPurch2; VATAmountPurchTotal[2])
            {
            }
            column(VATBaseReverseChargeVAT2; VATBaseReverseChargeVATTotal[2])
            {
            }
            column(VATAmountReverseChargeVAT2; VATAmountReverseChargeVATTotal[2])
            {
            }
            column(PageCaption; PageCaptionLbl)
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
            column(TotalSaleCaption; TotalSaleCaptionLbl)
            {
            }
            column(TotalPurchCaption; TotalPurchCaptionLbl)
            {
            }
            column(TotalPurchReverseChargeVATCaption; TotalPurchReverseChargeVATCaptionLbl)
            {
            }
            column(ReportCaption; ReportCaptionLbl)
            {
            }
            column(Selection; Selection)
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
                    DataItemTableView = SORTING(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Country/Region Code") WHERE(Type = FILTER(Purchase | Sale));
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
                    }
                    column(Base_VATEntry; VATBase)
                    {
                    }
                    column(Amount_VATEntry; VATAmount)
                    {
                    }
                    column(CalculatedVATBase; CalculatedVATBase)
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(CalculatedVATAmount; CalculatedVATAmount)
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
                            if not PrintVATEntries then
                                CurrReport.Break();

                            if PrintCountrySubTotal = 1 then
                                Clear(CountrySubTotalAmt);

                            Clear(PrintCountrySubTotal);

                            if not UseAmtsInAddCurr then begin
                                CountrySubTotalAmt[1] += CalculatedVATBase;
                                CountrySubTotalAmt[2] += CalculatedVATAmount;
                                CountrySubTotalAmt[3] += VATBase;
                                CountrySubTotalAmt[4] += VATAmount;
                            end else begin
                                CountrySubTotalAmt[1] += "VAT Entry"."Additional-Currency Base";
                                CountrySubTotalAmt[2] += "VAT Entry"."Additional-Currency Amount";
                            end;

                            SetRange(Number, 0);
                            VATEntryLocal := "VAT Entry";
                            if "VAT Entry".Next <> 0 then begin
                                if VATEntryLocal."Country/Region Code" <> "VAT Entry"."Country/Region Code" then
                                    PrintCountrySubTotal := 1;
                                "VAT Entry".Next(-1);
                            end else
                                PrintCountrySubTotal := 1;

                            SetRange(Number, PrintCountrySubTotal);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        VATBase := 0;
                        VATAmount := 0;
                        CalculatedVATBase := CalcVATBase("VAT Entry");
                        CalculatedVATAmount := CalcVATAmount("VAT Entry");

                        if CalcVATBaseIncludingAdvance("VAT Entry") <> CalculatedVATBase then
                            VATBase := CalcVATBaseIncludingAdvance("VAT Entry");
                        if Amount <> CalculatedVATAmount then
                            VATAmount := Amount;

                        VATEntrySubtotalAmt[1] += CalculatedVATBase;
                        VATEntrySubtotalAmt[2] += CalculatedVATAmount;
                        VATEntrySubtotalAmt[3] += "Additional-Currency Base";
                        VATEntrySubtotalAmt[4] += "Additional-Currency Amount";
                        VATEntrySubtotalAmt[5] += VATBase;
                        VATEntrySubtotalAmt[6] += VATAmount;

                        VATEntry.SetFilter("VAT Calculation Type", '<>%1', VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
                        VATEntry.CalcSums(Base, Amount, "Additional-Currency Base", "Additional-Currency Amount", "Advance Base");

                        case "VAT Posting Setup"."VAT Calculation Type" of
                            "VAT Posting Setup"."VAT Calculation Type"::"Normal VAT",
                          "VAT Posting Setup"."VAT Calculation Type"::"Full VAT",
                          "VAT Posting Setup"."VAT Calculation Type"::"Reverse Charge VAT":
                                AddTotal("VAT Entry");
                            "VAT Posting Setup"."VAT Calculation Type"::"Sales Tax":
                                case Type of
                                    Type::Purchase:
                                        if not "Use Tax" then
                                            AddTotal("VAT Entry");
                                    Type::Sale:
                                        AddTotal("VAT Entry");
                                end;
                        end;

                        VATEntryDocumentNo := "Document No.";
                        VATEntryDocumentType := Format("Document Type");
                    end;

                    trigger OnPreDataItem()
                    begin
                        CopyFilters(VATEntry);
                        Clear(CountrySubTotalAmt);
                        Clear(VATEntrySubtotalAmt);
                    end;
                }
                dataitem("Close VAT Entries"; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    MaxIteration = 1;
                    column(VATEntryTotalCaption; StrSubstNo(TotalPerLbl, "VAT Posting Setup"."VAT Bus. Posting Group", "VAT Posting Setup"."VAT Prod. Posting Group", VATEntry.GetFilter(Type)))
                    {
                    }
                    column(VATEntryTotalWithRevChrgVATCaption; StrSubstNo(VATEntryTotalWithRevChrgVATLbl, "VAT Posting Setup"."VAT Bus. Posting Group", "VAT Posting Setup"."VAT Prod. Posting Group", VATEntry.GetFilter(Type)))
                    {
                    }
                    column(VATEntrySumCalculatedBase; VATEntrySubtotalAmt[1])
                    {
                    }
                    column(VATEntrySumCalculatedAmount; VATEntrySubtotalAmt[2])
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(VATEntrySumAddCurrBase; VATEntrySubtotalAmt[3])
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(VATEntrySumAddCurrAmount; VATEntrySubtotalAmt[4])
                    {
                    }
                    column(VATEntrySumBase; VATEntrySubtotalAmt[5])
                    {
                        AutoFormatExpression = GetCurrency;
                        AutoFormatType = 1;
                    }
                    column(VATEntrySumAmount; VATEntrySubtotalAmt[6])
                    {
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    VATEntry.Reset();
                    VATEntry.SetCurrentKey(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group",
                      "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "EU 3-Party Trade");

                    VATEntry.SetRange(Type, VATType);
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    VATEntry.SetFilter("VAT Date", VATDateFilter);
                    VATEntry.SetRange("VAT Bus. Posting Group", "VAT Posting Setup"."VAT Bus. Posting Group");
                    VATEntry.SetRange("VAT Prod. Posting Group", "VAT Posting Setup"."VAT Prod. Posting Group");
                    if SettlementNoFilter <> '' then
                        VATEntry.SetFilter("VAT Settlement No.", SettlementNoFilter);

                    case "VAT Posting Setup"."VAT Calculation Type" of
                        "VAT Posting Setup"."VAT Calculation Type"::"Normal VAT",
                        "VAT Posting Setup"."VAT Calculation Type"::"Reverse Charge VAT",
                        "VAT Posting Setup"."VAT Calculation Type"::"Full VAT":
                            begin
                                if FindFirstEntry then begin
                                    if not VATEntry.FindSet then
                                        repeat
                                            VATType := VATType + 1;
                                            VATEntry.SetRange(Type, VATType);
                                        until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                    FindFirstEntry := false;
                                end else begin
                                    if VATEntry.Next() = 0 then
                                        repeat
                                            VATType := VATType + 1;
                                            VATEntry.SetRange(Type, VATType);
                                        until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                end;
                                if VATType < VATEntry.Type::Settlement then
                                    VATEntry.FindLast;
                            end;
                        "VAT Posting Setup"."VAT Calculation Type"::"Sales Tax":
                            begin
                                if FindFirstEntry then begin
                                    if not VATEntry.FindSet then
                                        repeat
                                            VATType := VATType + 1;
                                            VATEntry.SetRange(Type, VATType);
                                        until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                    FindFirstEntry := false;
                                end else begin
                                    VATEntry.SetRange("Tax Jurisdiction Code");
                                    VATEntry.SetRange("Use Tax");
                                    if VATEntry.Next() = 0 then
                                        repeat
                                            VATType := VATType + 1;
                                            VATEntry.SetRange(Type, VATType);
                                        until (VATType = VATEntry.Type::Settlement) or VATEntry.Find('-');
                                end;
                                if VATType < VATEntry.Type::Settlement then begin
                                    VATEntry.SetRange("Tax Jurisdiction Code", VATEntry."Tax Jurisdiction Code");
                                    VATEntry.SetRange("Use Tax", VATEntry."Use Tax");
                                    VATEntry.FindLast;
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

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                Clear(VATBaseTotal);
                Clear(VATAmountTotal);
                Clear(VATBaseSaleTotal);
                Clear(VATAmountSaleTotal);
                Clear(VATBasePurchTotal);
                Clear(VATAmountPurchTotal);
                Clear(VATBaseReverseChargeVATTotal);
                Clear(VATAmountReverseChargeVATTotal);

                if UseAmtsInAddCurr then
                    HeaderText := StrSubstNo(CurrencyTxt, GLSetup."Additional Reporting Currency")
                else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo(CurrencyTxt, GLSetup."LCY Code");
                end;

                case Selection of
                    Selection::Open:
                        Heading := OpenVATEntriesTxt;
                    Selection::Closed:
                        Heading := ClosedVATEntriesTxt;
                    Selection::"Open and Closed":
                        Heading := AllVATEntriesTxt;
                end;
                if SettlementNoFilter <> '' then
                    Heading := Heading + ', ' + VATEntry.FieldCaption("VAT Settlement No.") + ': ' + SettlementNoFilter;
            end;
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
                    field(StartDateReq; StartDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        TableRelation = "VAT Period";
                        ToolTip = 'Specifies the first date in the period for posted VAT entries.';

                        trigger OnValidate()
                        begin
                            VATPeriod.Get(StartDateReq);
                            if VATPeriod.Next > 0 then
                                EndDateReq := CalcDate('<-1D>', VATPeriod."Starting Date");
                        end;
                    }
                    field(EndDateReq; EndDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date in the period for posted cash documents.';
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        ToolTip = 'Specifies the filtr of VAT entries (open, closed, open and closed).';
                    }
                    field(PrintVATEntries; PrintVATEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show VAT Entries';
                        ToolTip = 'Specifies when the vat entries are to be show';
                    }
                    field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies when the amounts in add. reporting currency is to be show';
                    }
                    field(SettlementNoFilter; SettlementNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Filter VAT Settlement No.';
                        ToolTip = 'Specifies the filter setup of document number which the VAT entries were closed.';
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
        ModifiedBaseCoefLbl = 'Modified Base (coef.)';
        ModifiedAmountCoefLbl = 'Modified Amount (coef.)';
    }

    trigger OnPreReport()
    begin
        VATPostingSetupFilter := "VAT Posting Setup".GetFilters;
        if EndDateReq = 0D then
            VATEntry.SetFilter("VAT Date", '%1..', StartDateReq)
        else
            VATEntry.SetRange("VAT Date", StartDateReq, EndDateReq);
        VATDateFilter := VATEntry.GetFilter("VAT Date");
    end;

    var
        VATEntry: Record "VAT Entry";
        GLSetup: Record "General Ledger Setup";
        VATPeriod: Record "VAT Period";
        StartDateReq: Date;
        EndDateReq: Date;
        Selection: Enum "VAT Statement Report Selection";
        PrintVATEntries: Boolean;
        VATType: Integer;
        VATBaseTotal: array[2] of Decimal;
        VATAmountTotal: array[2] of Decimal;
        VATBaseSaleTotal: array[2] of Decimal;
        VATAmountSaleTotal: array[2] of Decimal;
        VATBasePurchTotal: array[2] of Decimal;
        VATAmountPurchTotal: array[2] of Decimal;
        VATBaseReverseChargeVATTotal: array[2] of Decimal;
        VATAmountReverseChargeVATTotal: array[2] of Decimal;
        CalculatedVATBase: Decimal;
        CalculatedVATAmount: Decimal;
        VATBase: Decimal;
        VATAmount: Decimal;
        FindFirstEntry: Boolean;
        VATPostingSetupFilter: Text;
        VATDateFilter: Text;
        Heading: Text;
        UseAmtsInAddCurr: Boolean;
        HeaderText: Text[30];
        PrintCountrySubTotal: Integer;
        CountrySubTotalAmt: array[4] of Decimal;
        SettlementNoFilter: Text;
        VATEntrySubtotalAmt: array[10] of Decimal;
        PeriodLbl: Label 'Period: %1', Comment = '%1 = Period';
        CurrencyTxt: Label 'All amounts are in %1', Comment = '%1 = Currency Code';
        TotalPerLbl: Label 'Total for %1 %2 %3', Comment = '%1 = VAT Bus. Posting Group; %2 = VAT Prod. Posting Group; %3 = Type';
        ReportCaptionLbl: Label 'Documentation for VAT';
        PageCaptionLbl: Label 'Page';
        DocumentTypeCaptionLbl: Label 'Document Type';
        UserIDCaptionLbl: Label 'User ID';
        TotalCaptionLbl: Label 'Total';
        TotalSaleCaptionLbl: Label 'Total Sale';
        TotalPurchCaptionLbl: Label 'Total Purchase';
        TotalPurchReverseChargeVATCaptionLbl: Label 'Total Purchase (Reverse Charge VAT)';
        CountrySubtotalCaptionLbl: Label 'Total for Country/Region %1', Comment = '%1 = Country Code';
        OpenVATEntriesTxt: Label 'Open VAT Entries';
        ClosedVATEntriesTxt: Label 'Closed VAT Entries';
        AllVATEntriesTxt: Label 'Open and Closed VAT Entries';
        VATEntryTotalWithRevChrgVATLbl: Label 'Total for %1 %2 %3 with Reverse Charge VAT', Comment = '%1=VAT Bus. Posting Group, %2=VAT Prod. Posting Group, %3=VAT Entry Type';
        VATEntryDocumentNo: Code[20];
        VATEntryDocumentType: Text;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewPrintVATEntries: Boolean; NewUseAmtsInAddCurr: Boolean)
    begin
        StartDateReq := NewStartDate;
        EndDateReq := NewEndDate;
        PrintVATEntries := NewPrintVATEntries;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        if VATPeriod.Get(StartDateReq) then;
    end;

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;

    local procedure CalcVATBase(VATEntry: Record "VAT Entry"): Decimal
    begin
        if VATEntry."Advance Base" <> 0 then
            exit(CalcVATBaseIncludingAdvance(VATEntry));
        exit(VATEntry.Base);
    end;

    local procedure CalcVATBaseIncludingAdvance(VATEntry: Record "VAT Entry"): Decimal
    begin
        exit(VATEntry.Base + VATEntry."Advance Base");
    end;

    local procedure CalcVATAmount(VATEntry: Record "VAT Entry"): Decimal
    begin
        if VATEntry."Advance Base" <> 0 then
            exit(VATEntry.Amount);
        exit(VATEntry.Amount);
    end;

    local procedure AddTotal(VATEntry: Record "VAT Entry")
    var
        CalculatedVATBase: Decimal;
        CalculatedVATAmount: Decimal;
    begin
        if not UseAmtsInAddCurr then begin
            CalculatedVATBase := CalcVATBase(VATEntry);
            CalculatedVATAmount := CalcVATAmount(VATEntry);
        end else begin
            CalculatedVATBase := VATEntry."Additional-Currency Base";
            CalculatedVATAmount := VATEntry."Additional-Currency Amount";
        end;

        case VATEntry.Type of
            VATEntry.Type::Purchase:
                begin
                    VATBasePurchTotal[1] += CalculatedVATBase;
                    VATAmountPurchTotal[1] += CalculatedVATAmount;
                    VATBasePurchTotal[2] += CalcVATBaseIncludingAdvance(VATEntry);
                    VATAmountPurchTotal[2] += VATEntry.Amount;

                    if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Reverse Charge VAT" then begin
                        VATBaseReverseChargeVATTotal[1] -= CalculatedVATBase;
                        VATAmountReverseChargeVATTotal[1] -= CalculatedVATAmount;
                        VATBaseReverseChargeVATTotal[2] -= CalculatedVATBase;
                        VATAmountReverseChargeVATTotal[2] -= CalculatedVATAmount;
                    end;
                end;
            VATEntry.Type::Sale:
                begin
                    VATBaseSaleTotal[1] += CalculatedVATBase;
                    VATAmountSaleTotal[1] += CalculatedVATAmount;
                    VATBaseSaleTotal[2] += CalcVATBaseIncludingAdvance(VATEntry);
                    VATAmountSaleTotal[2] += VATEntry.Amount;
                end;
        end;

        VATBaseTotal[1] := VATBasePurchTotal[1] + VATBaseReverseChargeVATTotal[1] + VATBaseSaleTotal[1];
        VATAmountTotal[1] := VATAmountPurchTotal[1] + VATAmountReverseChargeVATTotal[1] + VATAmountSaleTotal[1];
        VATBaseTotal[2] := VATBasePurchTotal[2] + VATBaseReverseChargeVATTotal[2] + VATBaseSaleTotal[2];
        VATAmountTotal[2] := VATAmountPurchTotal[2] + VATAmountReverseChargeVATTotal[2] + VATAmountSaleTotal[2];
    end;
}
#endif