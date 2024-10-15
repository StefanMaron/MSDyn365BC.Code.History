page 14963 "Pay. Analysis Column Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Pay. Analysis Column Templates';
    PageType = List;
    SourceTable = "Payroll Analysis Column Tmpl.";
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
            action("&Columns")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Columns';
                Image = Column;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Enter settings to define the values that the column displays in a report.';

                trigger OnAction()
                var
                    PayrollAnalysisLine: Record "Payroll Analysis Line";
                    PayrollAnalysisReportMgt: Codeunit "Payroll Analysis Report Mgt.";
                begin
                    PayrollAnalysisReportMgt.OpenAnalysisColumnsForm(PayrollAnalysisLine, Name);
                end;
            }
        }
    }
}

