report 12 "VAT Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VATStatement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Statement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = SORTING("Statement Template Name", Name);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Statement Template Name", Name;
            column(Name_VATStatementName; Name)
            {
            }
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = FIELD("Statement Template Name"), "Statement Name" = FIELD(Name);
                DataItemTableView = SORTING("Statement Template Name", "Statement Name") WHERE(Print = CONST(true));
                RequestFilterFields = "Date Filter";
                column(CompanyName; COMPANYPROPERTY.DisplayName)
                {
                }
                column(Header; Header)
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(TypeReport; TypeReport)
                {
                }
                column(StmntTemName_VATStmntName; "VAT Statement Name"."Statement Template Name")
                {
                }
                column(AllAmtAreIn; AllAmtAreInLbl)
                {
                }
                column(AmtrInGLSetupAddtnalRprtCurr; StrSubstNo(Text003, GLSetup."Additional Reporting Currency"))
                {
                }
                column(VATEntriesBeforeAndWithinThePeriod; "VAT Statement Line".TableCaption + ': ' + VATStmtLineFilter)
                {
                }
                column(VATStmtLineFilter; VATStmtLineFilter)
                {
                }
                column(TotalAmt; TotalAmount)
                {
                    AutoFormatExpression = GetCurrency;
                    AutoFormatType = 1;
                }
                column(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                }
                column(Selection; Selection)
                {
                }
                column(PrintInIntegers; PrintInIntegers)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(Desc_VATStatementLine; Description)
                {
                    IncludeCaption = true;
                }
                column(RowNo_VATStatementLine; "Row No.")
                {
                    IncludeCaption = true;
                }
                column(TotalBase; TotalBase)
                {
                    AutoFormatExpression = GetCurrency;
                    AutoFormatType = 1;
                }
                column(TotalECAmt; TotalECAmount)
                {
                    AutoFormatExpression = GetCurrency;
                    AutoFormatType = 1;
                }
                column(TotalVATAmt; TotalVATAmount)
                {
                    AutoFormatExpression = GetCurrency;
                    AutoFormatType = 1;
                }
                column(VATProdPostGr; VATProdPostGr)
                {
                }
                column(VATBusPostGr; VATBusPostGr)
                {
                }
                column(VATPercentage; VATPercentage)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ECPercentage; ECPercentage)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(StmntName_VATStatementLine; "Statement Name")
                {
                }
                column(VATDeclarationCaption; VATDeclarationCaptionLbl)
                {
                }
                column(PageNoCaption; PageNoCaptionLbl)
                {
                }
                column(VATStmntTempCaption; VATStmntTempCaptionLbl)
                {
                }
                column(VATStatementNameCaption; VATStatementNameCaptionLbl)
                {
                }
                column(VATStatementCaption; VATStatementCaptionLbl)
                {
                }
                column(AmountsareinwholeLCYsCaption; AmountsareinwholeLCYsCaptionLbl)
                {
                }
                column(ThereportincludesallVATentriesCaption; ThereportincludesallVATentriesCaptionLbl)
                {
                }
                column(ThereportincludesonlyclosedVATentriesCaption; ThereportincludesonlyclosedVATentriesCaptionLbl)
                {
                }
                column(ColumnAmtCaption; ColumnAmtCaptionLbl)
                {
                }
                column(VATAmtCaption; VATAmtCaptionLbl)
                {
                }
                column(ECAmtCaption; ECAmtCaptionLbl)
                {
                }
                column(BaseCaption; BaseCaptionLbl)
                {
                }
                column(TypesCaption; TypesCaptionLbl)
                {
                }
                column(VATPercentCaption; VATPercentCaptionLbl)
                {
                }
                column(ECPercentCaption; ECPercentCaptionLbl)
                {
                }
                column(VATStmtLineDescCaption; FieldCaption(Description))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    VATStmtName.SetRange(VATStmtName.Name, "VAT Statement Line"."Statement Name");
                    if not VATStmtName.Find('-') then
                        Error(Text1100102);

                    if (VATStmtName."Template Type" = VATStmtName."Template Type"::"Two Columns Report") then begin
                        TypeReport := true;
                        TotalAmount := 0;
                        TotalBase := 0;
                        TotalECAmount := 0;
                        TotalVATAmount := 0;
                        CalcLineTotal2C("VAT Statement Line", 0);
                        if "Print with" = "Print with"::"Opposite Sign" then begin
                            TotalAmount := -TotalAmount;
                            TotalBase := -TotalBase;
                            TotalVATAmount := -TotalVATAmount;
                            TotalECAmount := -TotalECAmount;
                        end
                    end else begin
                        CalcLineTotal("VAT Statement Line", TotalAmount, 0);
                        if PrintInIntegers then
                            TotalAmount := Round(TotalAmount, 1, '<');
                        if "Print with" = "Print with"::"Opposite Sign" then
                            TotalAmount := -TotalAmount;
                    end;
                    PageGroupNo := NextPageGroupNo;
                    if "New Page" then
                        NextPageGroupNo := PageGroupNo + 1;
                end;

                trigger OnPreDataItem()
                begin
                    PageGroupNo := 1;
                    NextPageGroupNo := 1;
                end;
            }

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                SetRange("VAT Statement Name".Name, "VAT Statement Line".GetFilter("VAT Statement Line"."Statement Name"));
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
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        ToolTip = 'Specifies if you want to include open VAT entries in the report.';
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        ToolTip = 'Specifies if you want to include VAT entries from before the specified time period in the report.';
                    }
                    field(ShowAmtInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amounts in add. Curr.';
                        ToolTip = 'Specifies if you want report amounts to be shown in the additional reporting currency.';
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
        VATStmtLineFilter := "VAT Statement Line".GetFilters;

        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            Header := Text000
        else
            Header := StrSubstNo(Text1100101, "VAT Statement Line".GetFilter("Date Filter"));

        if not UseAmtsInAddCurr then
            GLSetup.Get
        else begin
            GLSetup.Get();
            Currency.Get(GLSetup."Additional Reporting Currency");
        end;
    end;

    var
        Text000: Label 'VAT entries before and within the period';
        Text002: Label 'All amounts are in %1';
        Text003: Label 'Amounts are in %1, rounded without decimals.';
        Text004: Label 'VAT entries within the period';
        Text005: Label 'Period: %1..%2';
        GLAcc: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        GLSetup: Record "General Ledger Setup";
        VATStmtLine: Record "VAT Statement Line";
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        PrintInIntegers: Boolean;
        VATStmtLineFilter: Text;
        Heading: Text[50];
        Amount: Decimal;
        TotalAmount: Decimal;
        RowNo: array[6] of Code[10];
        ErrorText: Text[80];
        i: Integer;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        UseAmtsInAddCurr: Boolean;
        HeaderText: Text[50];
        EndDate: Date;
        StartDate: Date;
        EndDateReq: Date;
        Heading2: Text[50];
        Text1100101: Label 'Period: %1';
        Text1100102: Label 'The Statement name does not exist';
        VATPostSetup: Record "VAT Posting Setup";
        VATStmtName: Record "VAT Statement Name";
        Header: Text[50];
        Base: Decimal;
        VATAmount: Decimal;
        VATAmountAC: Decimal;
        TotalBase: Decimal;
        TotalECAmount: Decimal;
        TotalVATAmount: Decimal;
        VATPercentage: Decimal;
        ECPercentage: Decimal;
        VATBusPostGr: Code[20];
        VATProdPostGr: Code[20];
        TypeReport: Boolean;
        Currency: Record Currency;
        AllAmtAreInLbl: Label 'All amounts are in';
        VATDeclarationCaptionLbl: Label 'VAT Declaration';
        PageNoCaptionLbl: Label 'Page';
        VATStmntTempCaptionLbl: Label 'VAT Statement Template';
        VATStatementNameCaptionLbl: Label 'VAT Statement Name';
        VATStatementCaptionLbl: Label 'VAT Statement';
        AmountsareinwholeLCYsCaptionLbl: Label 'Amounts are in whole LCYs.';
        ThereportincludesallVATentriesCaptionLbl: Label 'The report includes all VAT entries.';
        ThereportincludesonlyclosedVATentriesCaptionLbl: Label 'The report includes only closed VAT entries.';
        ColumnAmtCaptionLbl: Label 'Column Amount';
        VATAmtCaptionLbl: Label 'VAT Amount';
        ECAmtCaptionLbl: Label 'EC Amount';
        BaseCaptionLbl: Label 'Base';
        TypesCaptionLbl: Label 'Types';
        VATPercentCaptionLbl: Label 'VAT %';
        ECPercentCaptionLbl: Label 'EC %';

    [Scope('OnPrem')]
    procedure CalcLineTotal2C(VATStmtLine2: Record "VAT Statement Line"; Level: Integer): Boolean
    begin
        case VATStmtLine2.Type of
            VATStmtLine2.Type::"Account Totaling":
                ;
            VATStmtLine2.Type::"EC Entry Totaling",
            VATStmtLine2.Type::"VAT Entry Totaling":
                begin
                    if VATEntry.SetCurrentKey(
                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                    then begin
                        VATEntry.SetRange("VAT Bus. Posting Group", VATStmtLine2."VAT Bus. Posting Group");
                        VATEntry.SetRange("VAT Prod. Posting Group", VATStmtLine2."VAT Prod. Posting Group");
                    end else begin
                        VATEntry.SetCurrentKey(
                          Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                        VATEntry.SetRange("Tax Jurisdiction Code", VATStmtLine2."Tax Jurisdiction Code");
                        VATEntry.SetRange("Use Tax", VATStmtLine2."Use Tax");
                    end;
                    VATEntry.SetRange(Type, VATStmtLine2."Gen. Posting Type");
                    if "VAT Statement Line".GetFilter("Date Filter") <> '' then
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            VATEntry.SetRange("Posting Date", 0D, "VAT Statement Line".GetRangeMax("Date Filter"))
                        else
                            "VAT Statement Line".CopyFilter("Date Filter", VATEntry."Posting Date");
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                    end;
                    if VATEntry.Find('-') then;
                    case VATStmtLine2."Amount Type" of
                        VATStmtLine2."Amount Type"::Amount:
                            if VATPostSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then begin
                                CalcVatLineTotal(VATEntry, VATAmount, VATAmountAC, false);
                                Amount := ConditionalAdd(0, VATAmount, VATAmountAC);
                            end;
                        VATStmtLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base");
                                Base := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                            end;
                        VATStmtLine2."Amount Type"::"Amount+Base":
                            begin
                                VATEntry.CalcSums(Amount, Base, VATEntry."Additional-Currency Amount", VATEntry."Additional-Currency Base");
                                Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                                if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then
                                    Base := ConditionalAdd(0, CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry.Amount, UseAmtsInAddCurr),
                                      CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry."Additional-Currency Amount", UseAmtsInAddCurr))
                                else
                                    Base := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                            end;
                    end;
                    CalculateTotalAmount(VATStmtLine2);
                end;
            VATStmtLine2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := VATStmtLine2."Row No.";

                    if VATStmtLine2."Row Totaling" = '' then
                        exit(true);
                    VATStmtLine2.SetRange("Statement Name", VATStmtLine2."Statement Name");
                    VATStmtLine2.SetFilter("Row No.", VATStmtLine2."Row Totaling");
                    if VATStmtLine2.Find('-') then
                        repeat
                            if not CalcLineTotal2C(VATStmtLine2, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                VATStmtLine2.FieldError("Row No.", ErrorText);
                            end;
                        until VATStmtLine2.Next() = 0;
                    VATPercentage := 0;
                    ECPercentage := 0;
                    VATBusPostGr := '';
                    VATProdPostGr := '';
                end;
            VATStmtLine2.Type::Description:
                begin
                    VATPercentage := 0;
                    ECPercentage := 0;
                    VATBusPostGr := '';
                    VATProdPostGr := '';
                end;
        end;

        exit(true);
    end;

    local procedure CalculateTotalAmount(VATStmtLine2: Record "VAT Statement Line")
    begin
        if VATStmtLine2."Calculate with" = 1 then begin
            Amount := -Amount;
            Base := -Base;
        end;
        TotalAmount := TotalAmount + Amount;
        TotalBase := TotalBase + Base;

        VATPostSetup.Get(VATStmtLine2."VAT Bus. Posting Group", VATStmtLine2."VAT Prod. Posting Group");
        VATPercentage := VATPostSetup."VAT %";
        ECPercentage := VATPostSetup."EC %";
        VATBusPostGr := VATPostSetup."VAT Bus. Posting Group";
        VATProdPostGr := VATPostSetup."VAT Prod. Posting Group";
        VATAmount := Amount;
        if VATPostSetup."VAT+EC %" <> 0 then
            VATAmount := VATAmount / VATPostSetup."VAT+EC %" * VATPercentage;
        TotalVATAmount := TotalVATAmount + VATAmount;
        TotalECAmount := TotalAmount - TotalVATAmount;
    end;

    procedure CalcLineTotal(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; Level: Integer): Boolean
    begin
        if Level = 0 then begin
            TotalAmount := 0;
            VATAmount := 0;
            VATAmountAC := 0;
        end;
        case VATStmtLine2.Type of
            VATStmtLine2.Type::"Account Totaling":
                begin
                    GLAcc.SetFilter("No.", VATStmtLine2."Account Totaling");
                    "VAT Statement Line".CopyFilter("Date Filter", GLAcc."Date Filter");
                    Amount := 0;
                    if GLAcc.Find('-') and (VATStmtLine2."Account Totaling" <> '') then
                        repeat
                            GLAcc.CalcFields("Net Change", "Additional-Currency Net Change");
                            Amount := ConditionalAdd(Amount, GLAcc."Net Change", GLAcc."Additional-Currency Net Change");
                        until GLAcc.Next() = 0;
                    OnCalcLineTotalOnBeforeCalcTotalAmountAccountTotaling(VATStmtLine2, VATEntry, Amount, UseAmtsInAddCurr);
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;
            VATStmtLine2.Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset();
                    if VATEntry.SetCurrentKey(
                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                    then begin
                        VATEntry.SetRange("VAT Bus. Posting Group", VATStmtLine2."VAT Bus. Posting Group");
                        VATEntry.SetRange("VAT Prod. Posting Group", VATStmtLine2."VAT Prod. Posting Group");
                    end else begin
                        VATEntry.SetCurrentKey(
                          Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                        VATEntry.SetRange("Tax Jurisdiction Code", VATStmtLine2."Tax Jurisdiction Code");
                        VATEntry.SetRange("Use Tax", VATStmtLine2."Use Tax");
                    end;
                    VATEntry.SetRange(Type, VATStmtLine2."Gen. Posting Type");
                    if "VAT Statement Line".GetFilter("Date Filter") <> '' then
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            VATEntry.SetRange("Posting Date", 0D, "VAT Statement Line".GetRangeMax("Date Filter"))
                        else
                            "VAT Statement Line".CopyFilter("Date Filter", VATEntry."Posting Date");
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    if VATEntry.Find('-') then;
                    case VATStmtLine2."Amount Type" of
                        VATStmtLine2."Amount Type"::Amount:
                            begin
                                if VATPostSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then begin
                                    CalcVatLineTotal(VATEntry, VATAmount, VATAmountAC, false);
                                    Amount := ConditionalAdd(0, VATAmount, VATAmountAC);
                                end;
                            end;
                        VATStmtLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base");
                                Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Amount", "Add.-Curr. Rem. Unreal. Amount");
                                Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Base", "Add.-Curr. Rem. Unreal. Base");
                                Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Base", VATEntry."Add.-Curr. Rem. Unreal. Base");
                            end;
                        VATStmtLine2."Amount Type"::"Amount+Base":
                            begin
                                VATEntry.CalcSums(Amount, Base, VATEntry."Additional-Currency Amount", VATEntry."Additional-Currency Base");
                                Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                                if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then
                                    Base := ConditionalAdd(0, CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry.Amount, UseAmtsInAddCurr),
                                      CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry."Additional-Currency Amount", UseAmtsInAddCurr))
                                else
                                    Base := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                                Amount := Amount + Base;
                            end;

                    end;
                    OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine2, VATEntry, Amount, UseAmtsInAddCurr);
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;
            VATStmtLine2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := VATStmtLine2."Row No.";

                    if VATStmtLine2."Row Totaling" = '' then
                        exit(true);
                    VATStmtLine2.SetRange("Statement Template Name", VATStmtLine2."Statement Template Name");
                    VATStmtLine2.SetRange("Statement Name", VATStmtLine2."Statement Name");
                    VATStmtLine2.SetFilter("Row No.", VATStmtLine2."Row Totaling");
                    if VATStmtLine2.Find('-') then
                        repeat
                            if not CalcLineTotal(VATStmtLine2, TotalAmount, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                VATStmtLine2.FieldError("Row No.", ErrorText);
                            end;
                        until VATStmtLine2.Next() = 0;
                end;
            VATStmtLine2.Type::Description:
                ;
            VATStmtLine2.Type::"EC Entry Totaling":
                begin
                    VATEntry.Reset();
                    if VATEntry.SetCurrentKey(
                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                    then begin
                        VATEntry.SetRange("VAT Bus. Posting Group", VATStmtLine2."VAT Bus. Posting Group");
                        VATEntry.SetRange("VAT Prod. Posting Group", VATStmtLine2."VAT Prod. Posting Group");
                    end else begin
                        VATEntry.SetCurrentKey(
                          Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                        VATEntry.SetRange("Tax Jurisdiction Code", VATStmtLine2."Tax Jurisdiction Code");
                        VATEntry.SetRange("Use Tax", VATStmtLine2."Use Tax");
                    end;
                    VATEntry.SetRange(Type, VATStmtLine2."Gen. Posting Type");
                    if "VAT Statement Line".GetFilter("Date Filter") <> '' then
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            VATEntry.SetRange("Posting Date", 0D, "VAT Statement Line".GetRangeMax("Date Filter"))
                        else
                            "VAT Statement Line".CopyFilter("Date Filter", VATEntry."Posting Date");
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    if VATEntry.Find('-') then;
                    case VATStmtLine2."Amount Type" of
                        VATStmtLine2."Amount Type"::Amount:
                            begin
                                if VATPostSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then begin
                                    CalcVatLineTotal(VATEntry, VATAmount, VATAmountAC, true);
                                    Amount := ConditionalAdd(0, VATAmount, VATAmountAC);
                                end;
                            end;
                        VATStmtLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base");
                                Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                                if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then begin
                                    Base := ConditionalAdd(0, CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry.Amount, UseAmtsInAddCurr),
                                      CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry."Additional-Currency Amount", UseAmtsInAddCurr));
                                    Amount := Amount + Base;
                                end;
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Unrealized Amount", "Add.-Currency Unrealized Amt.");
                                Amount := ConditionalAdd(0, VATEntry."Unrealized Amount", VATEntry."Add.-Currency Unrealized Amt.");
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Unrealized Base", "Add.-Currency Unrealized Base");
                                Amount := ConditionalAdd(0, VATEntry."Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                            end;
                        VATStmtLine2."Amount Type"::"Amount+Base":
                            begin
                                VATEntry.CalcSums(Amount, Base, VATEntry."Additional-Currency Amount", VATEntry."Additional-Currency Base");
                                Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                                if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT" then
                                    Base := ConditionalAdd(0, CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry.Amount, false),
                                      CalcTotalVATBase(VATEntry."VAT %", VATEntry."EC %", VATEntry."Additional-Currency Amount", false))
                                else
                                    Base := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                                Amount := Amount + Base;
                            end;

                    end;

                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;

        end;

        exit(true);
    end;

    local procedure CalcTotalAmount(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal)
    begin
        if VATStmtLine2."Calculate with" = 1 then
            Amount := -Amount;
        if PrintInIntegers and VATStmtLine2.Print then
            Amount := Round(Amount, 1, '<');
        TotalAmount := TotalAmount + Amount;
    end;

    procedure InitializeRequest(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean)
    begin
        "VAT Statement Name".Copy(NewVATStmtName);
        "VAT Statement Line".Copy(NewVATStatementLine);
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        PrintInIntegers := NewPrintInIntegers;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
    end;

    local procedure ConditionalAdd(Amount: Decimal; AmountToAdd: Decimal; AddCurrAmountToAdd: Decimal): Decimal
    begin
        if UseAmtsInAddCurr then
            exit(Amount + AddCurrAmountToAdd)
        else
            exit(Amount + AmountToAdd);
    end;

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency")
        else
            exit('');
    end;

    [Scope('OnPrem')]
    procedure CalcTotalVATBase(VAT: Decimal; EC: Decimal; VATAmount: Decimal; UseAddCurr: Boolean) VATBase: Decimal
    begin
        if ((VAT + EC) = 0) then
            exit;
        if UseAddCurr then
            exit(Round(100 * VATAmount / (VAT + EC), Currency."Amount Rounding Precision"))
        else
            exit(Round(100 * VATAmount / (VAT + EC), GLSetup."Amount Rounding Precision"));
    end;

    [Scope('OnPrem')]
    procedure CalcVatLineTotal(var VATEntry1: Record "VAT Entry"; var VATAmount1: Decimal; var VATAmountAC1: Decimal; ECAmount: Boolean)
    var
        Percent: Decimal;
    begin
        VATAmount1 := 0;
        VATAmountAC1 := 0;
        with VATEntry1 do begin
            if FindSet then
                repeat
                    if "VAT %" + "EC %" <> 0 then begin
                        if ECAmount then
                            Percent := "EC %"
                        else
                            Percent := "VAT %";
                        VATAmount1 := VATAmount1 + (Amount / ("VAT %" + "EC %")) * Percent;
                        VATAmountAC1 := VATAmountAC1 + ("Additional-Currency Amount" / ("VAT %" + "EC %")) * Percent;
                    end else
                        if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then begin
                            VATAmount1 := VATAmount1 + Amount;
                            VATAmountAC1 := VATAmountAC1 + "Additional-Currency Amount";
                        end;
                until Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; var Amount: Decimal; UseAmtsInAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnBeforeCalcTotalAmountAccountTotaling(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; var Amount: Decimal; UseAmtsInAddCurr: Boolean)
    begin
    end;
}

