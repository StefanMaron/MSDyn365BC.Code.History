page 385 "Report Selection - Bank Acc."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Bank Account';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                OptionCaption = 'Statement,Reconciliation - Test,Check,Unposted Cash Ingoing Order,Unposted Cash Outgoing Order,Cash Book,Cash Ingoing Order,Cash Outgoing Order';
                ToolTip = 'Specifies which type of document the report is used for.';

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; "Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field(Default; Default)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the report ID is the default for the report selection.';
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NewRecord;
    end;

    trigger OnOpenPage()
    begin
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Option Statement,"Reconciliation - Test",Check,"Unposted Cash Ingoing Order","Unposted Cash Outgoing Order","Cash Book","Cash Ingoing Order","Cash Outgoing Order";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Modify then;
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Statement:
                SetRange(Usage, Usage::"B.Stmt");
            ReportUsage2::"Reconciliation - Test":
                SetRange(Usage, Usage::"B.Recon.Test");
            ReportUsage2::Check:
                SetRange(Usage, Usage::"B.Check");
            ReportUsage2::"Unposted Cash Ingoing Order":
                SetRange(Usage, Usage::UCI);
            ReportUsage2::"Unposted Cash Outgoing Order":
                SetRange(Usage, Usage::UCO);
            ReportUsage2::"Cash Book":
                SetRange(Usage, Usage::CB);
            ReportUsage2::"Cash Ingoing Order":
                SetRange(Usage, Usage::CI);
            ReportUsage2::"Cash Outgoing Order":
                SetRange(Usage, Usage::CO);
        end;
        FilterGroup(0);
        CurrPage.Update;
    end;
}

