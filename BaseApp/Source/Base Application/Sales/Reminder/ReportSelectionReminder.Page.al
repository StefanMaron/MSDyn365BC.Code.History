namespace Microsoft.Sales.Reminder;

using Microsoft.Foundation.Reporting;
using System.Reflection;

page 524 "Report Selection - Reminder"
{
    ApplicationArea = Suite;
    Caption = 'Report Selections Reminder/Finance Charge';
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
                ApplicationArea = Suite;
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field("Use for Email Body"; Rec."Use for Email Body")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to insert summarized information, such as invoice number, due date in the body of the email that you send.';
                }
                field("Use for Email Attachment"; Rec."Use for Email Attachment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to attach the related document to the email.';
                }
                field(EmailBodyName; Rec."Email Body Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the email body layout that is used.';
                }
                field(EmailBodyPublisher; Rec."Email Body Layout Publisher")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the publisher of the email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Code"; Rec."Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Description"; Rec."Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the email body custom layout that is used.';
                    Visible = CustomLayoutsExist;

                    trigger OnDrillDown()
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        if CustomReportLayout.LookupLayoutOK(Rec."Report ID") then
                            Rec.Validate("Email Body Layout Code", CustomReportLayout.Code);
                    end;
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
        CustomLayoutsExist := Rec.DoesAnyCustomLayotExist();
    end;

    var
        ReportUsage2: Enum "Report Selection Usage Reminder";
        CustomLayoutsExist: Boolean;

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            Enum::"Report Selection Usage Reminder"::Reminder:
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::Reminder);
            Enum::"Report Selection Usage Reminder"::"Fin. Charge":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Fin.Charge");
            Enum::"Report Selection Usage Reminder"::"Reminder Test":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Rem.Test");
            Enum::"Report Selection Usage Reminder"::"Fin. Charge Test":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"F.C.Test");
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
                    Enum::"Report Selection Usage"::Reminder:
                        ReportUsage2 := ReportUsage2::Reminder;
                    Enum::"Report Selection Usage"::"Fin.Charge":
                        ReportUsage2 := ReportUsage2::"Fin. Charge";
                    Enum::"Report Selection Usage"::"Rem.Test":
                        ReportUsage2 := ReportUsage2::"Reminder Test";
                    Enum::"Report Selection Usage"::"F.C.Test":
                        ReportUsage2 := ReportUsage2::"Fin. Charge Test";
                    else
                        OnInitUsageFilterOnElseCase(ReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Reminder")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Reminder")
    begin
    end;
}

