page 17410 "Payroll Document Calc. Lines"
{
    AutoSplitKey = true;
    Caption = 'Payroll Document Calc. Lines';
    DataCaptionFields = "Element Code";
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Payroll Document Line Calc.";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = ExpressionIndent;
                IndentationControls = Expression;
                ShowCaption = false;
                field(Label; Label)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Result Field No."; "Result Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Result Field Name"; "Result Field Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement 1"; "Statement 1")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement 2"; "Statement 2")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Variable; Variable)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Result Value"; "Result Value")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                }
                field("Logical Result"; "Logical Result")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. of Runs"; "No. of Runs")
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
                field(Structured; Structured)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Function Code"; "Function Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Range Type"; "Range Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Range Code"; "Range Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Base Amount Code"; "Base Amount Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Time Activity Group"; "Time Activity Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("AE Setup Code"; "AE Setup Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the related average-earnings setup.';
                }
                field("Result Flag"; "Result Flag")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ToolTip = 'Specifies the description associated with this line.';
                    Visible = false;
                }
                field(ShowCodeLine; ShowCodeLine)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Code';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ExpressionIndent := 0;
        ExpressionOnFormat;
    end;

    var
        [InDataSet]
        ExpressionIndent: Integer;

    local procedure ExpressionOnFormat()
    begin
        ExpressionIndent := Indentation;
    end;
}

