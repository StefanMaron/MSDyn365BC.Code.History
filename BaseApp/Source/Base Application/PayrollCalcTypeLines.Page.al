page 17406 "Payroll Calc Type Lines"
{
    AutoSplitKey = true;
    Caption = 'Payroll Calc Type Line';
    DataCaptionFields = "Calc Type Code";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Payroll Calc Type Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Element Code"; "Element Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related payroll element for tax registration purposes.';
                }
                field(Activity; Activity)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payroll Posting Group"; "Payroll Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Copy)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy';
                Ellipsis = true;
                Image = Copy;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CopyListPayrollCalc.GetPayrollLineCalc(Rec);
                    CopyListPayrollCalc.Run;
                end;
            }
        }
    }

    var
        CopyListPayrollCalc: Report "Copy Payroll Calc Type";
}

