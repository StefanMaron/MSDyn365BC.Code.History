page 475 "VAT Statement Preview Line"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
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
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field("VAT Statement Cipher"; "VAT Statement Cipher")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a row number in the VAT statement report.';
                }
                field(Description; Description)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a description of the VAT statement line.';
                }
                field(Type; Type)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies what the VAT statement line will include.';
                }
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT statement line shows the VAT amounts, or the base amounts on which the VAT is calculated.';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Tax Jurisdiction Code"; "Tax Jurisdiction Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a tax jurisdiction code for the statement.';
                    Visible = false;
                }
                field("Use Tax"; "Use Tax")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies whether to use only entries from the VAT Entry table that are marked as Use Tax to be totaled on this line.';
                    Visible = false;
                }
                field(TotalEmpty; TotalEmpty)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the amount of the entry on the line.';

                    trigger OnDrillDown()
                    begin
                        if Type <> Type::"Row Totaling" then
                            if Type <> Type::"Account Totaling" then
                                FieldError(Type);
                        DrillDownOnEntries;
                    end;
                }
                field(TotalBase; TotalBase)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Base Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the amount that does no represent VAT.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOnEntries;
                    end;
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'VAT Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the total VAT amount that has been calculated.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOnEntries;
                    end;
                }
                field(TotalUnrealizedBase; TotalUnrealizedBase)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Unrealized Base Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the unrealized amount if you use unrealized VAT.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOnEntries;
                    end;
                }
                field(UnrealizedVATAmount; TotalUnrealizedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Unrealized VAT Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the unrealized amount if you use unrealized VAT.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOnEntries;
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
        VATStatementGermany.CalcLineTotal(Rec, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, 0);
        if "Print with" = "Print with"::"Opposite Sign" then begin
            TotalEmpty := -TotalEmpty;
            TotalBase := -TotalBase;
            TotalAmount := -TotalAmount;
            TotalUnrealizedAmount := -TotalUnrealizedAmount;
            TotalUnrealizedBase := -TotalUnrealizedBase;
        end;
    end;

    var
        Text000: Label 'Drilldown is not possible when %1 is %2.';
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        Selection: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";
        UseAmtsInAddCurr: Boolean;
        VATStatementGermany: Report "VAT Statement Germany";
        TotalAmount: Decimal;
        TotalEmpty: Decimal;
        TotalBase: Decimal;
        TotalUnrealizedAmount: Decimal;
        TotalUnrealizedBase: Decimal;

    procedure UpdateForm(var VATStmtName: Record "VAT Statement Name"; NewSelection: Option Open,Closed,"Open and Closed"; NewPeriodSelection: Option "Before and Within Period","Within Period"; NewUseAmtsInAddCurr: Boolean)
    begin
        SetRange("Statement Template Name", VATStmtName."Statement Template Name");
        SetRange("Statement Name", VATStmtName.Name);
        VATStmtName.CopyFilter("Date Filter", "Date Filter");
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        VATStatementGermany.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        CurrPage.Update;
    end;

    [Scope('OnPrem')]
    procedure DrillDownOnEntries()
    begin
        case Type of
            Type::"Account Totaling":
                begin
                    GLEntry.SetFilter("G/L Account No.", "Account Totaling");
                    if PeriodSelection = PeriodSelection::"Before and Within Period" then
                        GLEntry.SetRange("Posting Date", 0D, GetRangeMax("Date Filter"))
                    else
                        CopyFilter("Date Filter", GLEntry."Posting Date");
                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                end;
            Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset;
                    if not
                       VATEntry.SetCurrentKey(
                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                    then
                        VATEntry.SetCurrentKey(
                          Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                    VATEntry.SetRange(Type, "Gen. Posting Type");
                    VATEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                    VATEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                    VATEntry.SetRange("Tax Jurisdiction Code", "Tax Jurisdiction Code");
                    VATEntry.SetRange("Use Tax", "Use Tax");
                    if GetFilter("Date Filter") <> '' then
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            VATEntry.SetRange("Posting Date", 0D, GetRangeMax("Date Filter"))
                        else
                            CopyFilter("Date Filter", VATEntry."Posting Date");
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                        Selection::"Open and Closed":
                            VATEntry.SetRange(Closed);
                    end;
                    OnBeforeOpenPageVATEntryTotaling(VATEntry, Rec);
                    PAGE.Run(PAGE::"VAT Entries", VATEntry);
                end;
            Type::"Row Totaling",
          Type::Description:
                Error(Text000, FieldCaption(Type), Type);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOpenPageVATEntryTotaling(var VATEntry: Record "VAT Entry"; var VATStatementLine: Record "VAT Statement Line")
    begin
    end;
}

