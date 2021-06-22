page 99000917 "Report Selection - Prod. Order"
{
    ApplicationArea = Manufacturing;
    Caption = 'Report Selections Production Order';
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
                ApplicationArea = Manufacturing;
                Caption = 'Usage';
                OptionCaption = 'Job Card,Mat. & Requisition,Shortage List,Gantt Chart,Prod. Order';
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
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Manufacturing;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; "Report Caption")
                {
                    ApplicationArea = Manufacturing;
                    DrillDown = false;
                    ToolTip = 'Specifies the display name of the report.';
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
        ReportUsage2: Option "Job Card","Mat. & Requisition","Shortage List","Gantt Chart","Prod. Order";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Modify then;
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"Job Card":
                SetRange(Usage, Usage::M1);
            ReportUsage2::"Mat. & Requisition":
                SetRange(Usage, Usage::M2);
            ReportUsage2::"Shortage List":
                SetRange(Usage, Usage::M3);
            ReportUsage2::"Gantt Chart":
                SetRange(Usage, Usage::M4);
            ReportUsage2::"Prod. Order":
                SetRange(Usage, Usage::"Prod.Order");
        end;
        FilterGroup(0);
        CurrPage.Update;
    end;
}

