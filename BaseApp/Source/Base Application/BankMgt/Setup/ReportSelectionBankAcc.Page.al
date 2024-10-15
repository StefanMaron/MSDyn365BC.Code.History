namespace Microsoft.Bank.Setup;

using Microsoft.Foundation.Reporting;
using System.Reflection;

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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
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
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    begin
        InitUsageFilter();
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Enum "Report Selection Usage Bank";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Bank"::Statement:
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"B.Stmt");
            "Report Selection Usage Bank"::"Reconciliation - Test":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"B.Recon.Test");
            "Report Selection Usage Bank"::Check:
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"B.Check");
            "Report Selection Usage Bank"::"Posted Payment Reconciliation":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Posted Payment Reconciliation");
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2);
        Rec.FilterGroup(0);
        CurrPage.Update();
    end;

    local procedure InitUsageFilter()
    var
        NewReportUsage: Enum "Report Selection Usage";
    begin
        if Rec.GetFilter(Usage) <> '' then begin
            if Evaluate(NewReportUsage, Rec.GetFilter(Usage)) then
                case NewReportUsage of
                    Enum::"Report Selection Usage"::"B.Stmt":
                        ReportUsage2 := "Report Selection Usage Bank"::Statement;
                    Enum::"Report Selection Usage"::"B.Recon.Test":
                        ReportUsage2 := "Report Selection Usage Bank"::"Reconciliation - Test";
                    Enum::"Report Selection Usage"::"B.Check":
                        ReportUsage2 := "Report Selection Usage Bank"::Check;
                    Enum::"Report Selection Usage"::"Posted Payment Reconciliation":
                        ReportUsage2 := "Report Selection Usage Bank"::"Posted Payment Reconciliation";
                    else
                        OnInitUsageFilterOnElseCase(NewReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Bank")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Bank")
    begin
    end;
}

