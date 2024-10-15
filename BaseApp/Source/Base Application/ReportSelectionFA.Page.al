page 12484 "Report Selection - FA"
{
    Caption = 'Report Selection - Fixed Asset';
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
                ApplicationArea = FixedAssets;
                Caption = 'Usage';
                OptionCaption = 'Unposted FA Writeoff,Unposted FA Release,Unposted FA Movement,FA Writeoff,FA Release,FA Movement,FA Jnl.,FA Rec.Jnl';

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
                    ApplicationArea = FixedAssets;
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = FixedAssets;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; "Report Caption")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field(Default; Default)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if the report ID is the default for the report selection.';
                }
                field("Excel Export"; "Excel Export")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if the report selection will be exported.';
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
        ReportUsage2: Option "Unposted FA Writeoff","Unposted FA Release","Unposted FA Movement","FA Writeoff","FA Release","FA Movement","FA Jnl.","FA Rec.Jnl";

    local procedure SetUsageFilter()
    begin
        FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"Unposted FA Writeoff":
                SetRange(Usage, Usage::UFAW);
            ReportUsage2::"Unposted FA Release":
                SetRange(Usage, Usage::UFAR);
            ReportUsage2::"Unposted FA Movement":
                SetRange(Usage, Usage::UFAM);
            ReportUsage2::"FA Writeoff":
                SetRange(Usage, Usage::FAW);
            ReportUsage2::"FA Release":
                SetRange(Usage, Usage::FAR);
            ReportUsage2::"FA Movement":
                SetRange(Usage, Usage::FAM);
            ReportUsage2::"FA Jnl.":
                SetRange(Usage, Usage::FAJ);
            ReportUsage2::"FA Rec.Jnl":
                SetRange(Usage, Usage::FARJ);
        end;
        FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

