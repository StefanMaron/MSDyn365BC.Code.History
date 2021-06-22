page 859 "Cash Flow Manual Expenses"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Flow Manual Expenses';
    PageType = List;
    SourceTable = "Cash Flow Manual Expense";
    SourceTableView = SORTING("Starting Date")
                      ORDER(Ascending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the record.';
                    Visible = false;
                }
                field("Cash Flow Account No."; "Cash Flow Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the cash flow account that the entry on the manual revenue line is registered to.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the cash flow forecast entry.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date';
                    ShowMandatory = true;
                    ToolTip = 'Specifies the date of the cash flow entry.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount in LCY that the manual expense consists of. The entered amount is the amount that is registered in the given time period per recurring frequency.';
                }
                field(Recurrence; Recurrence)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recurrence';
                    OptionCaption = ' ,Daily,Weekly,Monthly,Quarterly,Yearly';
                    ToolTip = 'Specifies a date formula for calculating the period length. The content of the field determines how often the entry on the manual expense line is registered. For example, if the line must be registered every month, you can enter 1M.';

                    trigger OnValidate()
                    var
                        RecurringFrequency: Text;
                    begin
                        RecurringFrequency := CashFlowManagement.RecurrenceToRecurringFrequency(Recurrence);
                        Evaluate("Recurring Frequency", RecurringFrequency);
                        EnableControls;
                    end;
                }
                field("Recurring Frequency"; "Recurring Frequency")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how often the entry on the manual expense line is registered, if the journal template used is set up to be recurring';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CashFlowManagement.RecurringFrequencyToRecurrence("Recurring Frequency", Recurrence);
                    end;
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'End By';
                    Enabled = EndingDateEnabled;
                    ToolTip = 'Specifies the last date from which manual expenses should be registered for the cash flow forecast.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Expenses")
            {
                Caption = '&Expenses';
                Image = ProjectExpense;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(850),
                                  "No." = FIELD(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetRecord;
    end;

    trigger OnAfterGetRecord()
    begin
        GetRecord;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        EnableControls;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        InitNewRecord;
    end;

    var
        CashFlowManagement: Codeunit "Cash Flow Management";
        Recurrence: Option " ",Daily,Weekly,Monthly,Quarterly,Yearly;
        EndingDateEnabled: Boolean;

    local procedure GetRecord()
    begin
        EnableControls;
        CashFlowManagement.RecurringFrequencyToRecurrence("Recurring Frequency", Recurrence);
    end;

    local procedure EnableControls()
    begin
        EndingDateEnabled := (Recurrence <> Recurrence::" ");
        if not EndingDateEnabled then
            "Ending Date" := 0D;
    end;
}

