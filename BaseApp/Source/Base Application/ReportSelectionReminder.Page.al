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
                OptionCaption = 'Reminder,Fin. Charge,Reminder Test,Fin. Charge Test';
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; "Report Caption")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field("Use for Email Body"; "Use for Email Body")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to insert summarized information, such as invoice number, due date in the body of the email that you send.';
                }
                field("Use for Email Attachment"; "Use for Email Attachment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to attach the related document to the email.';
                }
                field("Email Body Layout Code"; "Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Description"; "Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the email body layout that is used.';

                    trigger OnDrillDown()
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        if CustomReportLayout.LookupLayoutOK("Report ID") then
                            Validate("Email Body Layout Code", CustomReportLayout.Code);
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
        NewRecord;
    end;

    trigger OnOpenPage()
    begin
        InitUsageFilter();
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Option Reminder,"Fin. Charge","Reminder Test","Fin. Charge Test";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Modify then;
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Reminder:
                SetRange(Usage, Usage::Reminder);
            ReportUsage2::"Fin. Charge":
                SetRange(Usage, Usage::"Fin.Charge");
            ReportUsage2::"Reminder Test":
                SetRange(Usage, Usage::"Rem.Test");
            ReportUsage2::"Fin. Charge Test":
                SetRange(Usage, Usage::"F.C.Test");
        end;
        FilterGroup(0);
        CurrPage.Update;
    end;

    local procedure InitUsageFilter()
    var
        DummyReportSelections: Record "Report Selections";
    begin
        if GetFilter(Usage) <> '' then begin
            if Evaluate(DummyReportSelections.Usage, GetFilter(Usage)) then
                case DummyReportSelections.Usage of
                    Usage::Reminder:
                        ReportUsage2 := ReportUsage2::Reminder;
                    Usage::"Fin.Charge":
                        ReportUsage2 := ReportUsage2::"Fin. Charge";
                    Usage::"Rem.Test":
                        ReportUsage2 := ReportUsage2::"Reminder Test";
                    Usage::"F.C.Test":
                        ReportUsage2 := ReportUsage2::"Fin. Charge Test";
                end;
            SetRange(Usage);
        end;
    end;
}

