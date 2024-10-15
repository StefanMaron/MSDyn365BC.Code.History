report 17409 "Copy Payroll Calc Type"
{
    Caption = 'Copy Payroll Calc Type';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Payroll Calc Type Line"; "Payroll Calc Type Line")
        {
            DataItemTableView = SORTING("Calc Type Code", "Line No.");

            trigger OnAfterGetRecord()
            begin
                PayrollCalcTypeLine2 := "Payroll Calc Type Line";
                PayrollCalcTypeLine2."Calc Type Code" := PayrollCalcTypeCode2;
                PayrollCalcTypeLine2."Line No." := NextLineNo;
                PayrollCalcTypeLine2.Insert();
                NextLineNo := NextLineNo + 10000;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Calc Type Code", PayrollCalcTypeCode);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PayrollCalcTypeCode; PayrollCalcTypeCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copying from Calculation';
                        MultiLine = true;
                        TableRelation = "Payroll Calc Type";

                        trigger OnValidate()
                        begin
                            PayrollCalcTypeCode2 := PayrollCalcTypeLine2."Calc Type Code";
                            PayrollCalcTypeLine2.SetRange("Calc Type Code", PayrollCalcTypeCode2);
                            if not PayrollCalcTypeLine2.FindLast then
                                NextLineNo := 10000
                            else
                                NextLineNo := PayrollCalcTypeLine2."Line No." + 10000;
                            if PayrollCalcTypeCode2 = PayrollCalcTypeCode then
                                Error(Text001);
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        PayrollCalcTypeLine2: Record "Payroll Calc Type Line";
        PayrollCalcTypeCode: Code[20];
        PayrollCalcTypeCode2: Code[20];
        NextLineNo: Integer;
        Text001: Label 'Cannot copy from same Payroll Group.';

    [Scope('OnPrem')]
    procedure GetPayrollLineCalc(NewPayrollLineCalc: Record "Payroll Calc Type Line")
    begin
        PayrollCalcTypeLine2 := NewPayrollLineCalc;
    end;
}

