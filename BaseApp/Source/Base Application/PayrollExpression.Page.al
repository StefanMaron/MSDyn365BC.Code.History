page 17436 "Payroll Expression"
{
    Caption = 'Payroll Expression';
    PageType = Worksheet;
    SourceTable = "Payroll Element Expression";

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
                        ExprAssistEdit;
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
            }
            group(Control1210009)
            {
                ShowCaption = false;
                field("Field Name"; "Field Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Assign to Field Name"; "Assign to Field Name")
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "Element Code" := ParentExprLine."Element Code";
        "Period Code" := ParentExprLine."Period Code";
        "Calculation Line No." := ParentExprLine."Calculation Line No.";
        Level := ParentExprLine.Level;
        "Parent Line No." := ParentExprLine."Line No.";
    end;

    var
        ParentExprLine: Record "Payroll Element Expression";

    [Scope('OnPrem')]
    procedure SetFromCalcLine(NewPayrollCalcLine: Record "Payroll Calculation Line")
    begin
        ParentExprLine.Init;
        ParentExprLine."Element Code" := NewPayrollCalcLine."Element Code";
        ParentExprLine."Period Code" := NewPayrollCalcLine."Period Code";
        ParentExprLine."Calculation Line No." := NewPayrollCalcLine."Line No.";
        ParentExprLine.Level := 0;
        ParentExprLine."Line No." := 0;
    end;

    [Scope('OnPrem')]
    procedure SetFromElementExpr(NewPayrollElementExpr: Record "Payroll Element Expression")
    begin
        ParentExprLine.Init;
        ParentExprLine."Element Code" := NewPayrollElementExpr."Element Code";
        ParentExprLine."Period Code" := NewPayrollElementExpr."Period Code";
        ParentExprLine."Calculation Line No." := NewPayrollElementExpr."Calculation Line No.";
        ParentExprLine.Level := NewPayrollElementExpr.Level + 1;
        ParentExprLine."Line No." := NewPayrollElementExpr."Line No.";
    end;

    [Scope('OnPrem')]
    procedure SetFromDocLineCalc(NewDocLineCalc: Record "Payroll Document Line Calc.")
    begin
        ParentExprLine.Init;
        ParentExprLine."Element Code" := NewDocLineCalc."Element Code";
        ParentExprLine."Period Code" := NewDocLineCalc."Period Code";
        ParentExprLine."Calculation Line No." := NewDocLineCalc."Line No.";
        ParentExprLine.Level := 0;
        ParentExprLine."Line No." := 0;
    end;
}

