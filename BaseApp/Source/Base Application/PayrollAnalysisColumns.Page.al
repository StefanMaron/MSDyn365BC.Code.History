page 14964 "Payroll Analysis Columns"
{
    AutoSplitKey = true;
    Caption = 'Payroll Analysis Columns';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Payroll Analysis Column";

    layout
    {
        area(content)
        {
            field(CurrentColumnName; CurrentColumnName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Name';
                ToolTip = 'Specifies the name of the related record.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord;
                    if PayrollAnalysisRepMgmt.LookupColumnName(CurrentColumnName) then begin
                        Text := CurrentColumnName;
                        exit(true);
                    end;
                end;

                trigger OnValidate()
                begin
                    PayrollAnalysisRepMgmt.GetColumnTemplate(CurrentColumnName);
                    CurrentColumnNameOnAfterValida;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Column No."; "Column No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number for the column in the view.';
                }
                field("Column Header"; "Column Header")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Column Type"; "Column Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the analysis column type, which determines how the amounts in the column are calculated.';
                }
                field("Amount Type"; "Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Formula; Formula)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Show Opposite Sign"; "Show Opposite Sign")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to show debits in reports as negative amounts with a minus sign and credits as positive amounts.';
                }
                field(Show; Show)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Rounding Factor"; "Rounding Factor")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Comparison Period Formula"; "Comparison Period Formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a period formula that specifies the accounting periods you want to use to calculate the amount in this column.';
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

    trigger OnOpenPage()
    begin
        PayrollAnalysisRepMgmt.OpenColumns2(CurrentColumnName, Rec);
    end;

    var
        PayrollAnalysisRepMgmt: Codeunit "Payroll Analysis Report Mgt.";
        CurrentColumnName: Code[10];

    [Scope('OnPrem')]
    procedure SetCurrentColumnName(ColumnlName: Code[10])
    begin
        CurrentColumnName := ColumnlName;
    end;

    local procedure CurrentColumnNameOnAfterValida()
    begin
        CurrPage.SaveRecord;
        PayrollAnalysisRepMgmt.SetColumnName(CurrentColumnName, Rec);
        CurrPage.Update(false);
    end;
}

