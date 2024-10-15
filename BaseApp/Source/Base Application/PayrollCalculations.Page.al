page 17407 "Payroll Calculations"
{
    Caption = 'Payroll Calculations';
    DataCaptionFields = "Element Code";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Payroll Calculation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Calculation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Calculation';
                Image = Calculate;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Payroll Calculation Lines";
                RunPageLink = "Element Code" = FIELD("Element Code"),
                              "Period Code" = FIELD("Period Code");
            }
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
                    CopyCalcLines.SetCalculation(Rec);
                    CopyCalcLines.Run;
                    Clear(CopyCalcLines);
                end;
            }
        }
    }

    var
        CopyCalcLines: Report "Copy Payroll Calculation";
}

