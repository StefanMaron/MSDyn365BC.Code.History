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
                field("Row No."; Rec."Row No.")
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
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT statement line shows the VAT amounts, or the base amounts on which the VAT is calculated.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a tax jurisdiction code for the statement.';
                    Visible = false;
                }
                field("Use Tax"; Rec."Use Tax")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies whether to use only entries from the VAT Entry table that are marked as Use Tax to be totaled on this line.';
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
                                    CopyFilter("Date Filter", GLEntry."Posting Date");
                                    OnColumnValueDrillDownOnBeforeRunGeneralLedgerEntries(VATEntry, GLEntry, Rec);
                                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                                end;
                            Type::"VAT Entry Totaling":
                                begin
                                    VATEntry.Reset();
                                    if not
                                       VATEntry.SetCurrentKey(
                                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                                    then
                                        VATEntry.SetCurrentKey(
                                          Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group",
                                          "Tax Jurisdiction Code", "Use Tax", "Tax Liable", "VAT Period", "Operation Occurred Date");
                                    VATEntry.SetRange(Type, "Gen. Posting Type");
                                    VATEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                                    VATEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                                    VATEntry.SetRange("Tax Jurisdiction Code", "Tax Jurisdiction Code");
                                    VATEntry.SetRange("VAT Period");
                                    VATEntry.SetRange("Use Tax", "Use Tax");
                                    VATEntry.SetRange("Operation Occurred Date");
                                    GeneralLedgerSetup.GetRecordOnce();
                                    if GeneralLedgerSetup."Use Activity Code" then
                                        VATEntry.SetFilter("Activity Code", GetFilter("Activity Code Filter"));
                                    if Selection = Selection::Closed then
                                        if VATPeriod <> '' then
                                            VATEntry.SetRange("VAT Period", VATPeriod);

                                    if GetFilter("Date Filter") <> '' then
                                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                                            VATEntry.SetRange("Operation Occurred Date", 0D, GetRangeMax("Date Filter"))
                                        else
                                            CopyFilter("Date Filter", VATEntry."Operation Occurred Date");
                                    if Selection = Selection::Open then
                                        VATEntry.SetRange(Closed, false)
                                    else
                                        if Selection = Selection::Closed then
                                            VATEntry.SetRange(Closed, true)
                                        else
                                            VATEntry.SetRange(Closed);
                                    OnBeforeOpenPageVATEntryTotaling(VATEntry, Rec, GLEntry);
                                    PAGE.Run(PAGE::"VAT Entries", VATEntry);
                                end;
                            Type::"Row Totaling",
                            Type::"Periodic VAT Settl.",
                            Type::Description:
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
        VATStatement.CalcLineTotal(Rec, ColumnValue, 0);

        CalcColumnValue(Rec, ColumnValue, 0);
        if "Print with" = "Print with"::"Opposite Sign" then
            ColumnValue := -ColumnValue;
        if "Round Factor" = "Round Factor"::"1" then
            ColumnValue := Round(ColumnValue, 1, '=');
    end;

    var
        Text000: Label 'Drilldown is not possible when %1 is %2.';

    protected var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATStatement: Report "VAT Statement";
        ColumnValue: Decimal;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        UseAmtsInAddCurr: Boolean;
        VATPeriod: Code[10];

    local procedure CalcColumnValue(VATStatementLine: Record "VAT Statement Line"; var ColumnValue: Decimal; Level: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcColumnValue(VATStatementLine, ColumnValue, Level, IsHandled, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        if IsHandled then
            exit;

        VATStatement.CalcLineTotal(VATStatementLine, ColumnValue, Level);
    end;

    procedure UpdateForm(var VATStmtName: Record "VAT Statement Name"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewUseAmtsInAddCurr: Boolean; NewVATPeriod: Code[10])
    begin
        SetRange("Statement Template Name", VATStmtName."Statement Template Name");
        SetRange("Statement Name", VATStmtName.Name);
        VATStmtName.CopyFilter("Date Filter", "Date Filter");
        GeneralLedgerSetup.GetRecordOnce();
        if GeneralLedgerSetup."Use Activity Code" then
            VATStmtName.CopyFilter("Activity Code Filter", "Activity Code Filter");
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        VATPeriod := NewVATPeriod;
        VATStatement.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr, VATPeriod);
        OnUpdateFormOnBeforePageUpdate(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr, VATPeriod);
        CurrPage.Update();

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

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFormOnBeforePageUpdate(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; VATPeriod: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateForm()
    begin
    end;
}

