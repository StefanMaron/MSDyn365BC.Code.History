page 31049 "Report Selection - Credit"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Credit (Obsolete)';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Credit Report Selections";
    UsageCategory = Tasks;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                OptionCaption = 'Credit,Posted Credit';
                ToolTip = 'Specifies type of credit report';

                trigger OnValidate()
                begin
                    SetUsageFilter;
                    ReportUsage2OnAfterValidate;
                end;
            }
            repeater(Control1220003)
            {
                ShowCaption = false;
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies sequence of credit report';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID of the report that the program will print.';
                }
                field("Report Name"; "Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the name of the object that is selected in the Object ID to Run field.';
                }
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
        ReportUsage2: Option Credit,"Posted Credit";

    local procedure SetUsageFilter()
    begin
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Credit:
                SetRange(Usage, Usage::Credit);
            ReportUsage2::"Posted Credit":
                SetRange(Usage, Usage::"Posted Credit");
        end;
        FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

