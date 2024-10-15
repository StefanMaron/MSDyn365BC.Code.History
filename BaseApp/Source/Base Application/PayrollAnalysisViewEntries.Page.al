page 14969 "Payroll Analysis View Entries"
{
    Caption = 'Payroll Analysis View Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Payroll Analysis View Entry";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Analysis View Code"; "Analysis View Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field("Payroll Element Type"; "Payroll Element Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Use PF Accum. System"; "Use PF Accum. System")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Dimension 1 Value Code"; "Dimension 1 Value Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 1 on the analysis view card.';
                }
                field("Dimension 2 Value Code"; "Dimension 2 Value Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 2 on the analysis view card.';
                }
                field("Dimension 3 Value Code"; "Dimension 3 Value Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 3 on the analysis view card.';
                }
                field("Dimension 4 Value Code"; "Dimension 4 Value Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 4 on the analysis view card.';
                }
                field("Payroll Amount"; "Payroll Amount")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field("Taxable Amount"; "Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    var
        TempPayrollLedgerEntry: Record "Payroll Ledger Entry" temporary;

    local procedure DrillDown()
    begin
        SetAnalysisViewEntry(Rec);
        TempPayrollLedgerEntry.FilterGroup(DATABASE::"Payroll Analysis View Entry");
        PAGE.RunModal(PAGE::"Payroll Ledger Entries", TempPayrollLedgerEntry);
    end;

    [Scope('OnPrem')]
    procedure SetAnalysisViewEntry(PayrollAnalysisViewEntry: Record "Payroll Analysis View Entry")
    var
        PayrlAViewEntryToPayrlEntries: Codeunit PayrlAViewEntryToPayrlEntries;
    begin
        TempPayrollLedgerEntry.Reset();
        TempPayrollLedgerEntry.DeleteAll();
        PayrlAViewEntryToPayrlEntries.GetPayrollEntries(PayrollAnalysisViewEntry, TempPayrollLedgerEntry);
    end;
}

