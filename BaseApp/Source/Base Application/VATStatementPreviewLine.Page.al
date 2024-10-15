page 475 "VAT Statement Preview Line"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Statement Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Row No."; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT statement line.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what the VAT statement line will include.';
                }
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT statement line shows the VAT amounts, or the base amounts on which the VAT is calculated.';
                }
                field("G/L Amount Type"; "G/L Amount Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the general ledger amount type for the VAT statement line.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Gen. Posting Type"; "Gen. Posting Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a general posting type that will be used with the VAT statement.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.4';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the code for the Gen. Bus. Posting Group that applies to the entry.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the code for the Gen. Prod. Posting Group that applies to the entry.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("EU-3 Party Trade"; "EU-3 Party Trade")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether the document is part of a three-party trade.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("EU 3-Party Intermediate Role"; "EU 3-Party Intermediate Role")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies when the VAT entry will use European Union third-party intermediate trade rules. This option complies with VAT accounting standards for EU third-party trade.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Prepayment Type"; "Prepayment Type")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the VAT statement prepayment type.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.4';
                    Visible = false;
                }
                field("Tax Jurisdiction Code"; "Tax Jurisdiction Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a tax jurisdiction code for the statement.';
                    Visible = false;
                }
                field("Use Tax"; "Use Tax")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether to use only entries from the VAT Entry table that are marked as Use Tax to be totaled on this line.';
                    Visible = false;
                }
                field("Use Row Date Filter"; "Use Row Date Filter")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if you need to use a filter date other than the date on the VAT statement.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Unsupported functionality';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field(ColumnValue; ColumnValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Column Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the type of entries that will be included in the amounts in columns.';

                    trigger OnDrillDown()
                    begin
                        case Type of
                            Type::"Account Totaling":
                                begin
                                    GLEntry.SetFilter("G/L Account No.", "Account Totaling");
                                    // NAVCZ
                                    // COPYFILTER("Date Filter",GLEntry."Posting Date");
                                    GLEntry.SetRange("VAT Bus. Posting Group");
                                    GLEntry.SetRange("VAT Prod. Posting Group");
                                    if "VAT Bus. Posting Group" <> '' then
                                        GLEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                                    if "VAT Prod. Posting Group" <> '' then
                                        GLEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                                    if "Use Row Date Filter" and (GetFilter("Date Row Filter") <> '') then
                                        CopyFilter("Date Row Filter", GLEntry."VAT Date")
                                    else
                                        CopyFilter("Date Filter", GLEntry."VAT Date");
                                    // NAVCZ
                                    OnColumnValueDrillDownOnBeforeRunGeneralLedgerEntries(VATEntry, GLEntry, Rec);
                                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                                end;
                            Type::"VAT Entry Totaling":
                                begin
                                    VATEntry.Reset();
                                    if not
                                       VATEntry.SetCurrentKey(
                                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group",
                                         "Gen. Bus. Posting Group", "Gen. Prod. Posting Group",
                                         "EU 3-Party Trade", "EU 3-Party Intermediate Role", "VAT Date") // NAVCZ
                                    then
                                        VATEntry.SetCurrentKey(
                                          Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                                    VATEntry.SetRange(Type, "Gen. Posting Type");
                                    VATEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                                    VATEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                                    VATEntry.SetRange("Tax Jurisdiction Code", "Tax Jurisdiction Code");
                                    VATEntry.SetRange("Use Tax", "Use Tax");
                                    // NAVCZ
                                    /*
                               IF GETFILTER("Date Filter") <> '' THEN
                               IF PeriodSelection = PeriodSelection::"Before and Within Period" THEN
                               VATEntry.SETRANGE("Posting Date",0D,GETRANGEMAX("Date Filter"))
                               ELSE
                               COPYFILTER("Date Filter",VATEntry."Posting Date");
                              */
                                    if "Gen. Bus. Posting Group" <> '' then
                                        VATEntry.SetRange("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
                                    if "Gen. Prod. Posting Group" <> '' then
                                        VATEntry.SetRange("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
                                    case "EU-3 Party Trade" of
                                        "EU-3 Party Trade"::Yes:
                                            VATEntry.SetRange("EU 3-Party Trade", true);
                                        "EU-3 Party Trade"::No:
                                            VATEntry.SetRange("EU 3-Party Trade", false);
                                    end;
                                    case "EU 3-Party Intermediate Role" of
                                        "EU 3-Party Intermediate Role"::Yes:
                                            VATEntry.SetRange("EU 3-Party Intermediate Role", true);
                                        "EU 3-Party Intermediate Role"::No:
                                            VATEntry.SetRange("EU 3-Party Intermediate Role", false);
                                    end;
                                    if "Use Row Date Filter" and (GetFilter("Date Row Filter") <> '') then begin
                                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                                            VATEntry.SetRange("VAT Date", 0D, GetRangeMax("Date Row Filter"))
                                        else
                                            CopyFilter("Date Row Filter", VATEntry."VAT Date");
                                    end else begin
                                        if GetFilter("Date Filter") <> '' then
                                            if PeriodSelection = PeriodSelection::"Before and Within Period" then
                                                VATEntry.SetRange("VAT Date", 0D, GetRangeMax("Date Filter"))
                                            else
                                                CopyFilter("Date Filter", VATEntry."VAT Date");
                                    end;
                                    if SettlementNoFilter <> '' then
                                        VATEntry.SetRange("VAT Settlement No.", SettlementNoFilter);
                                    VATEntry.SetRange("Perform. Country/Region Code", CountryCodeFillFilter);
                                    // NAVCZ
                                    case Selection of
                                        Selection::Open:
                                            VATEntry.SetRange(Closed, false);
                                        Selection::Closed:
                                            VATEntry.SetRange(Closed, true);
                                        Selection::"Open and Closed":
                                            VATEntry.SetRange(Closed);
                                    end;
                                    OnBeforeOpenPageVATEntryTotaling(VATEntry, Rec, GLEntry);
                                    PAGE.Run(PAGE::"VAT Entries", VATEntry);
                                end;
                            Type::"Row Totaling",
                            Type::Description, Type::Formula: // NAVCZ
                                Error(Text000, FieldCaption(Type), Type);
                        end;

                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcColumnValue(Rec, ColumnValue, 0);
        if "Print with" = "Print with"::"Opposite Sign" then
            ColumnValue := -ColumnValue;
        // NAVCZ
        if not (Type = Type::Formula) then
            ColumnValue := Round(ColumnValue, 0.01);
        // NAVCZ
    end;

    var
        Text000: Label 'Drilldown is not possible when %1 is %2.';

    protected var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VATStatement: Report "VAT Statement";
        ColumnValue: Decimal;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        UseAmtsInAddCurr: Boolean;
        [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
        SettlementNoFilter: Text[50];
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)', '15.3')]
        CountryCodeFillFilter: Code[10];

    local procedure CalcColumnValue(VATStatementLine: Record "VAT Statement Line"; var ColumnValue: Decimal; Level: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcColumnValue(VATStatementLine, ColumnValue, Level, IsHandled, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        if IsHandled then
            exit;

        // NAVCZ
        if Type = Type::"VAT Entry Totaling" then
            TestField("Amount Type");
        // NAVCZ
        VATStatement.CalcLineTotal(VATStatementLine, ColumnValue, Level);
        // NAVCZ
        case Show of
            Show::"Zero If Negative":
                if ColumnValue < 0 then
                    ColumnValue := 0;
            Show::"Zero If Positive":
                if ColumnValue > 0 then
                    ColumnValue := 0;
        end;
        // NAVCZ
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure UpdateForm(var VATStmtName: Record "VAT Statement Name"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewUseAmtsInAddCurr: Boolean; SettlementNoFilter2: Text[50]; CountryCodeFillFilter2: Code[10])
    begin
        SetRange("Statement Template Name", VATStmtName."Statement Template Name");
        SetRange("Statement Name", VATStmtName.Name);
        VATStmtName.CopyFilter("Date Filter", "Date Filter");
        VATStmtName.CopyFilter("Date Row Filter", "Date Row Filter"); // NAVCZ
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        VATStatement.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr,
          SettlementNoFilter2, CountryCodeFillFilter2); // NAVCZ
        SettlementNoFilter := SettlementNoFilter2;
        CountryCodeFillFilter := CountryCodeFillFilter2;
        OnUpdateFormOnBeforePageUpdate(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr, SettlementNoFilter2, CountryCodeFillFilter2);
        CurrPage.Update;

        OnAfterUpdateForm();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcColumnValue(VATStatementLine: Record "VAT Statement Line"; var TotalAmount: Decimal; Level: Integer; var IsHandled: Boolean; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; PrintInIntegers: Boolean; UseAmtsInAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOpenPageVATEntryTotaling(var VATEntry: Record "VAT Entry"; var VATStatementLine: Record "VAT Statement Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnColumnValueDrillDownOnBeforeRunGeneralLedgerEntries(var VATEntry: Record "VAT Entry"; var GLEntry: Record "G/L Entry"; var VATStatementLine: Record "VAT Statement Line")
    begin
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [IntegrationEvent(false, false)]
    local procedure OnUpdateFormOnBeforePageUpdate(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; SettlementNoFilter2: Text[50]; CountryCodeFillFilter2: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateForm()
    begin
    end;
}

