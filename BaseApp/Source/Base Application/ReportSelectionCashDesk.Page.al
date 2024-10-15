page 11759 "Report Selection - Cash Desk"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Cash Desk (Obsolete)';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Cash Desk Report Selections";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.4';

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                OptionCaption = 'Cash Receipt,Cash Withdrawal,Posted Cash Receipt,Posted Cash Withdrawal';
                ToolTip = 'Specifies type of purchase advance payment';

                trigger OnValidate()
                begin
                    SetUsageFilter;
                    CurrPage.Update;
                end;
            }
            repeater(Control1220006)
            {
                ShowCaption = false;
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies sequence of purchase advance payment';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID of the report that the program will print.';
                }
                field("Report Caption"; "Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies captiom of report';
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
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NewRecord;
    end;

    trigger OnOpenPage()
    begin
        SetUsageFilter;
    end;

    var
        ReportUsage2: Option "C.Rcpt","C.Wdrwl","P.C.Rcpt","P.C.Wdrwl";

    local procedure SetUsageFilter()
    begin
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"C.Rcpt":
                SetRange(Usage, Usage::"C.Rcpt");
            ReportUsage2::"C.Wdrwl":
                SetRange(Usage, Usage::"C.Wdrwl");
            ReportUsage2::"P.C.Rcpt":
                SetRange(Usage, Usage::"P.C.Rcpt");
            ReportUsage2::"P.C.Wdrwl":
                SetRange(Usage, Usage::"P.C.Wdrwl");
        end;
        FilterGroup(0);
    end;
}

