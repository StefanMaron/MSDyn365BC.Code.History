report 17419 "Apply Budget Tax Payments"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Apply Budget Tax Payments';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
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
                    field("PayrollPeriod.Code"; PayrollPeriod.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payroll Period';
                        TableRelation = "Payroll Period";

                        trigger OnValidate()
                        begin
                            PayrollPeriod.Get(PayrollPeriod.Code);
                            FromDate := PayrollPeriod."Starting Date";
                            ToDate := PayrollPeriod."Ending Date";
                        end;
                    }
                    field(FromDate; FromDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From Date';
                        ToolTip = 'Specifies the starting date.';
                    }
                    field(ToDate; ToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To Date';
                        ToolTip = 'Specifies a search method. If you select To Date, and there is no currency exchange rate on a certain date, the exchange rate for the nearest date is used.';
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

    trigger OnPreReport()
    begin
        PayrollPeriod.Get(PayrollPeriod.Code);
        PayrollApplyMgt.ApplyTaxAuthority(VendLedgEntry, PayrollPeriod, FromDate, ToDate);
    end;

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        PayrollPeriod: Record "Payroll Period";
        PayrollApplyMgt: Codeunit "Payroll Application Management";
        FromDate: Date;
        ToDate: Date;

    [Scope('OnPrem')]
    procedure Set(EntryNo: Integer)
    begin
        VendLedgEntry.Get(EntryNo);
    end;
}

