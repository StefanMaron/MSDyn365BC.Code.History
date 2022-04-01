page 307 "Report Selection - Job"
{
    Caption = 'Report Selection - Job';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Administration;
    ApplicationArea = Jobs;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                Caption = 'Usage';
                ToolTip = 'Specifies which type of document the report is used for.';
                ApplicationArea = Jobs;

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
                    ToolTip = 'Specifies the sequence number for the report.';
                    ApplicationArea = Jobs;
                }
                field("Report ID"; Rec."Report ID")
                {
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                    ApplicationArea = Jobs;
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                    ApplicationArea = Jobs;
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
        InitUsageFilter();
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Enum "Report Selection Usage Job";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Job"::Quote:
                Rec.SetRange(Usage, "Report Selection Usage"::JQ);
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2);
        Rec.FilterGroup(0);
        CurrPage.Update();
    end;

    local procedure InitUsageFilter()
    var
        ReportUsage: Enum "Report Selection Usage";
    begin
        if Rec.GetFilter(Usage) <> '' then begin
            if Evaluate(ReportUsage, Rec.GetFilter(Usage)) then
                case ReportUsage of
                    "Report Selection Usage"::JQ:
                        ReportUsage2 := "Report Selection Usage Job"::Quote;
                    else
                        OnInitUsageFilterOnElseCase(ReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(
      var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Job"
    )
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(
      ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Job"
    )
    begin
    end;
}
