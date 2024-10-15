report 17416 "Apply Employee Payments"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Apply Employee Payments';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.";
            dataitem("Payroll Period"; "Payroll Period")
            {
                RequestFilterFields = "Code";

                trigger OnAfterGetRecord()
                begin
                    PayrollApplMgt.ApplyEmployee(Employee, "Payroll Period", ToPaymentDate);
                end;
            }
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
                    field(ToPaymentDate; ToPaymentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To Payment Date';
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
        PayrollApplMgt: Codeunit "Payroll Application Management";
        ToPaymentDate: Date;
}

