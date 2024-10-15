page 7000045 "Report Selection - Cartera"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cartera Report Selections';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Cartera Report Selections";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                OptionCaption = 'Bill Group,Posted Bill Group,Closed Bill Group,Bill,Bill Group - Test,Payment Order,Posted Payment Order,Payment Order - Test,Closed Payment Order';
                ToolTip = 'Specifies the business purpose of the report.';

                trigger OnValidate()
                begin
                    SetUsageFilter;
                    ReportUsage2OnAfterValidate;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order number or the sequence in which you want to print this report.';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the report to be printed.';
                }
                field("Report Name"; "Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the number of the report you want to print.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, "Report ID");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NewRecord;
    end;

    trigger OnOpenPage()
    begin
        SetUsageFilter;
    end;

    var
        ObjTransl: Record "Object Translation";
        ReportUsage2: Option "Bill Group","Posted Bill Group","Closed Bill Group",Bill,"Bill Group - Test","Payment Order","Posted Payment Order","Payment Order - Test","Closed Payment Order";

    local procedure SetUsageFilter()
    begin

        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"Bill Group":
                SetRange(Usage, Usage::"Bill Group");
            ReportUsage2::"Posted Bill Group":
                SetRange(Usage, Usage::"Posted Bill Group");
            ReportUsage2::"Closed Bill Group":
                SetRange(Usage, Usage::"Closed Bill Group");
            ReportUsage2::Bill:
                SetRange(Usage, Usage::Bill);
            ReportUsage2::"Bill Group - Test":
                SetRange(Usage, Usage::"Bill Group - Test");
            ReportUsage2::"Payment Order":
                SetRange(Usage, Usage::"Payment Order");
            ReportUsage2::"Posted Payment Order":
                SetRange(Usage, Usage::"Posted Payment Order");
            ReportUsage2::"Payment Order - Test":
                SetRange(Usage, Usage::"Payment Order - Test");
            ReportUsage2::"Closed Payment Order":
                SetRange(Usage, Usage::"Closed Payment Order");
        end;
        FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update;
    end;
}

