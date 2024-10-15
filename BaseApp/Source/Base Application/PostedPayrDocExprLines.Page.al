page 17489 "Posted Payr. Doc. Expr. Lines"
{
    Caption = 'Posted Payr. Doc. Expr. Lines';
    Editable = false;
    PageType = Card;
    SourceTable = "Posted Payroll Doc. Line Expr.";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Assign to Variable"; "Assign to Variable")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Assign to Field No."; "Assign to Field No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Assign to Field Name"; "Assign to Field Name")
                {
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Source Table"; "Source Table")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Field No."; "Field No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Field Name"; "Field Name")
                {
                    Visible = false;
                }
                field("Result Value"; "Result Value")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Logical Result"; "Logical Result")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Left Bracket"; "Left Bracket")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Logical Prefix"; "Logical Prefix")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Expression; Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';

                    trigger OnAssistEdit()
                    begin
                        ViewExpression;
                    end;
                }
                field(Operator; Operator)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Comparison; Comparison)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Right Bracket"; "Right Bracket")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Logical Suffix"; "Logical Suffix")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Error Code"; "Error Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Error Text"; "Error Text")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

