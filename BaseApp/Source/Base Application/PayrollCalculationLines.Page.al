page 17408 "Payroll Calculation Lines"
{
    AutoSplitKey = true;
    Caption = 'Payroll Calculation Lines';
    DataCaptionFields = "Element Code";
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Payroll Calculation Line";

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
                field(Expression; Expression)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the expression of the related XML element.';

                    trigger OnAssistEdit()
                    begin
                        ExprAssistEdit;
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
                field("Rounding Type"; "Rounding Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Rounding Precision"; "Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the interval that you want to use as the rounding difference.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
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
        area(processing)
        {
            action("Move Left")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Left';
                Image = PreviousRecord;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Move Left';

                trigger OnAction()
                begin
                    if Indentation > 0 then
                        Indentation := Indentation - 1;
                    Modify;
                    CurrPage.Update;
                end;
            }
            action("Move Right")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Right';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Move Right';

                trigger OnAction()
                begin
                    Indentation := Indentation + 1;
                    Modify;
                    CurrPage.Update;
                end;
            }
        }
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

