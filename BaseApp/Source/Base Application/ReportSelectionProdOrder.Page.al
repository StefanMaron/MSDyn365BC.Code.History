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
                ToolTip = 'Specifies which type of document the report is used for.';

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Manufacturing;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Manufacturing;
                    DrillDown = false;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field(Default; Default)
                {
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
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    begin
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Enum "Report Selection Usage Prod.";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Prod."::"Job Card":
                Rec.SetRange(Usage, "Report Selection Usage"::M1);
            "Report Selection Usage Prod."::"Mat. & Requisition":
                Rec.SetRange(Usage, "Report Selection Usage"::M2);
            "Report Selection Usage Prod."::"Shortage List":
                Rec.SetRange(Usage, "Report Selection Usage"::M3);
            "Report Selection Usage Prod."::"Gantt Chart":
                Rec.SetRange(Usage, "Report Selection Usage"::M4);
            "Report Selection Usage Prod."::"Prod. Order":
                Rec.SetRange(Usage, "Report Selection Usage"::"Prod.Order");
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2);
        Rec.FilterGroup(0);
        CurrPage.Update();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Prod.")
    begin
    end;
}

