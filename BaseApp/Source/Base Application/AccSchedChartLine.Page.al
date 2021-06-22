page 765 "Acc. Sched. Chart Line"
{
    Caption = 'Acc. Sched. Chart Line';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Acc. Sched. Chart Setup Line";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Account Schedule Name"; "Account Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account schedule name.';
                    Visible = false;
                }
                field("Account Schedule Line No."; "Account Schedule Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account schedule line that the chart is based on.';
                    Visible = false;
                }
                field("Column Layout Name"; "Column Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Column Layout Line No."; "Column Layout Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Original Measure Name"; "Original Measure Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account schedule columns or lines that you select to include in the Account Schedules Chart Setup window.';
                }
                field("Chart Type"; "Chart Type")
                {
                    ApplicationArea = All;
                    Editable = IsMeasure;
                    ToolTip = 'Specifies how the account schedule values are represented graphically in the chart.';
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
                ApplicationArea = Basic, Suite;
                Caption = 'Select All';
                Image = AllLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Select all lines.';

                trigger OnAction()
                var
                    AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
                    AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
                begin
                    AccSchedChartSetupLine.Copy(Rec);
                    AccSchedChartManagement.SelectAll(AccSchedChartSetupLine, IsMeasure);
                end;
            }
            action(ShowNone)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deselect All';
                Image = CancelAllLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Unselect all lines.';

                trigger OnAction()
                var
                    AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
                    AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
                begin
                    AccSchedChartSetupLine.Copy(Rec);
                    AccSchedChartManagement.DeselectAll(AccSchedChartSetupLine, IsMeasure);
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

