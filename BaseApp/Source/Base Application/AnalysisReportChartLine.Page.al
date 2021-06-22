page 777 "Analysis Report Chart Line"
{
    Caption = 'Analysis Report Chart Line';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Analysis Report Chart Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Analysis Line Template Name"; "Analysis Line Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Analysis Line Line No."; "Analysis Line Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the analysis report line that the specific chart is based on.';
                    Visible = false;
                }
                field("Analysis Column Template Name"; "Analysis Column Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Analysis Column Line No."; "Analysis Column Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the analysis report column that the advanced chart is based on.';
                    Visible = false;
                }
                field("Original Measure Name"; "Original Measure Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the analysis report columns or lines that you select to insert in the Analysis Report Chart Setup window.';
                }
                field("Chart Type"; "Chart Type")
                {
                    ApplicationArea = All;
                    Editable = IsMeasure;
                    ToolTip = 'Specifies how the analysis report values are represented graphically in the specific chart.';
                    Visible = IsMeasure;
                }
                field(Show; Show)
                {
                    ApplicationArea = All;
                    Caption = 'Show';
                    Editable = NOT IsMeasure;
                    ToolTip = 'Specifies if the selected value is shown in the window.';
                    Visible = NOT IsMeasure;

                    trigger OnValidate()
                    begin
                        if Show then
                            "Chart Type" := GetDefaultChartType
                        else
                            "Chart Type" := "Chart Type"::" ";
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Select All';
                Image = AllLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Select all lines.';

                trigger OnAction()
                var
                    AnalysisReportChartLine: Record "Analysis Report Chart Line";
                    AnalysisReportChartMgt: Codeunit "Analysis Report Chart Mgt.";
                begin
                    AnalysisReportChartLine.Copy(Rec);
                    AnalysisReportChartMgt.SelectAll(AnalysisReportChartLine, IsMeasure);
                end;
            }
            action(ShowNone)
            {
                ApplicationArea = Suite;
                Caption = 'Deselect All';
                Image = CancelAllLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Unselect all lines.';

                trigger OnAction()
                var
                    AnalysisReportChartLine: Record "Analysis Report Chart Line";
                    AnalysisReportChartMgt: Codeunit "Analysis Report Chart Mgt.";
                begin
                    AnalysisReportChartLine.Copy(Rec);
                    AnalysisReportChartMgt.DeselectAll(AnalysisReportChartLine, IsMeasure);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Show := "Chart Type" <> "Chart Type"::" ";
    end;

    var
        Show: Boolean;
        IsMeasure: Boolean;

    procedure SetViewAsMeasure(Value: Boolean)
    begin
        IsMeasure := Value;
    end;
}

