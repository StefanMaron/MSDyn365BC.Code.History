page 17412 "Payroll Ranges"
{
    Caption = 'Payroll Ranges';
    DataCaptionFields = "Element Code";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Payroll Range Header";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period Code"; "Period Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Range Type"; "Range Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow Employee Gender"; "Allow Employee Gender")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the employee''s gender is shown.';
                }
                field("Allow Employee Age"; "Allow Employee Age")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the employee''s age is shown.';
                }
                field("Consider Relative"; "Consider Relative")
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
            action(Setup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PayrollRangeLines: Page "Payroll Range Lines";
                begin
                    PayrollRangeLine.SetRange("Element Code", "Element Code");
                    PayrollRangeLine.SetRange("Range Code", Code);
                    PayrollRangeLine.SetRange("Period Code", "Period Code");

                    PayrollRangeLines.Set("Range Type");
                    PayrollRangeLines.SetTableView(PayrollRangeLine);
                    PayrollRangeLines.Run;
                    Clear(PayrollRangeLines);
                end;
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
                    CopyRange.GetRangeHeader(Rec);
                    CopyRange.Run;
                end;
            }
        }
    }

    var
        PayrollRangeLine: Record "Payroll Range Line";
        CopyRange: Report "Copy Payroll Range";
}

