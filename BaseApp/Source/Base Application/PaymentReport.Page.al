page 10863 "Payment Report"
{
    Caption = 'Payment Report';
    Editable = false;
    PageType = List;
    SourceTable = "Payment Status";
    SourceTableView = WHERE(ReportMenu = CONST(true));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Payment Class"; "Payment Class")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the payment class.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies text to describe the payment status.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OK)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    PaymentLine: Record "Payment Line";
                begin
                    PaymentLine.SetRange("Payment Class", "Payment Class");
                    PaymentLine.SetRange("Status No.", Line);
                    REPORT.RunModal(REPORT::"Payment List", true, true, PaymentLine);
                end;
            }
        }
    }
}

