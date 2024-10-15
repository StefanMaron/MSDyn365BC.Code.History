page 11780 "VAT Periods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Periods (Obsolete)';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "VAT Period";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Control1220008)
            {
                ShowCaption = false;
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting date for the VAT period.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies name of VAT periods.';
                }
                field("New VAT Year"; "New VAT Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the period marks the beginning of a new VAT year.';
                }
                field(Closed; Closed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the closed VAT period. After the period is closed, posting is no longer recommended and the statement is typically settled.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("VAT &Statement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT &Statement';
                Image = VATStatement;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "VAT Statement";
                ToolTip = 'Opens vat statement';
            }
            action("&Create Periods")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Create Periods';
                Ellipsis = true;
                Image = Period;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Create VAT Period";
                ToolTip = 'This batch job automatically creates VAT periods.';
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Calc. and Post VAT Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calc. and Post VAT Settlement';
                    Image = CalculateSalesTax;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Report "Calc. and Post VAT Settlement";
                    ToolTip = 'This batch closes open VAT entries and transfers purchase and sales VAT amounts to the VAT settlement account.';
                }
                action("Create VIES Declaration")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create VIES Declaration';
                    Image = NewDocument;
                    RunObject = Page "VIES Declarations";
                    ToolTip = 'This batch job automatically creates VIES declaration.';
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                action("Trial Balance by Period")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Trial Balance by Period';
                    Image = GLBalance;
                    RunObject = Report "Trial Balance by Period";
                    ToolTip = 'Specifies the opening balance by general ledger account, the movements in the selected period of month, quarter, or year, and the resulting closing balance.';
                }
                action("Fiscal Year Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fiscal Year Balance';
                    Image = GLAccountBalance;
                    RunObject = Report "Fiscal Year Balance";
                    ToolTip = 'Specifies balance sheet movements for selected periods.';
                }
                action("G/L VAT Reconciliation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L VAT Reconciliation';
                    Image = VATStatement;
                    RunObject = Report "G/L VAT Reconciliation CZ";
                    ToolTip = 'This report compares general ledger entries by filtering data either by the posting date or the VAT date.';
                }
            }
        }
        area(creation)
        {
            action(Action1220010)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create VIES Declaration';
                Image = NewDocument;
                Promoted = true;
                PromotedCategory = New;
                RunObject = Page "VIES Declarations";
                RunPageMode = Create;
                ToolTip = 'This batch job automatically creates VIES declaration.';
            }
        }
        area(reporting)
        {
        }
    }
}

