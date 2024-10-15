page 14961 "Pay. Analysis Line Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Pay. Analysis Line Templates';
    PageType = List;
    SourceTable = "Payroll Analysis Line Template";
    UsageCategory = Administration;

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
                field("Default Column Template Name"; "Default Column Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the column template name that you have set up for this analysis report.';
                }
                field("Payroll Analysis View Code"; "Payroll Analysis View Code")
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
            action("&Lines")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Lines';
                Image = AllLines;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View or edit payroll analysis lines.';

                trigger OnAction()
                var
                    PayrollAnalysisLine: Record "Payroll Analysis Line";
                    PayrollAnalysisReportMngt: Codeunit "Payroll Analysis Report Mgt.";
                begin
                    PayrollAnalysisReportMngt.OpenAnalysisLinesForm(PayrollAnalysisLine, Name);
                end;
            }
        }
    }
}

