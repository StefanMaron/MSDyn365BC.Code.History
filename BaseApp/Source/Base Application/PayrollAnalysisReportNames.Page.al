page 14960 "Payroll Analysis Report Names"
{
    Caption = 'Payroll Analysis Report Names';
    PageType = List;
    SourceTable = "Payroll Analysis Report Name";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Analysis Line Template Name"; "Analysis Line Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Analysis Column Template Name"; "Analysis Column Template Name")
                {
                    ApplicationArea = Basic, Suite;
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Export Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Settings';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export the setup information.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(PayrollAnalysisReportName);
                        PayrollDataExchangeMgt.ExportPayrollAnalysisReports(PayrollAnalysisReportName);
                    end;
                }
            }
        }
    }

    var
        PayrollAnalysisReportName: Record "Payroll Analysis Report Name";
        PayrollDataExchangeMgt: Codeunit "Payroll Data Exchange Mgt.";
}

