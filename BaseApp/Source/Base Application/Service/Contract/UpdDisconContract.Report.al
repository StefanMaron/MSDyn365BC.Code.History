namespace Microsoft.Service.Contract;

report 6035 "Upd. Disc.% on Contract"
{
    Caption = 'Upd. Disc.% on Contract';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Contract Line"; "Service Contract Line")
        {
            RequestFilterFields = "Contract Type", "Contract No.";

            trigger OnAfterGetRecord()
            begin
                SuspendStatusCheck(true);
                if "Line Discount %" + DiscountPct <= 0 then
                    Validate("Line Discount %", 0)
                else
                    Validate("Line Discount %", "Line Discount %" + DiscountPct);
                Modify(true);
                i := i + 1;
            end;

            trigger OnPostDataItem()
            begin
                if i > 0 then begin
                    UpdateContractAnnualAmount(false);
                    Message(Text000);
                end
            end;

            trigger OnPreDataItem()
            begin
                if DiscountPct = 0 then
                    CurrReport.Break();
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
                    field(DiscountPct; DiscountPct)
                    {
                        ApplicationArea = Service;
                        Caption = 'Add/Subtract Discount %';
                        ToolTip = 'Specifies if any contract discount percent is included in the batch job. ';
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
        if DiscountPct = 0 then
            Error(Text001);
    end;

    var
        Text000: Label 'Service contract lines have been updated.';
        DiscountPct: Decimal;
        i: Integer;
        Text001: Label 'You must enter a value in the "Add/Subtract Discount ''%''" field.';

    procedure InitializeRequest(DiscountPercent: Decimal)
    begin
        DiscountPct := DiscountPercent;
    end;
}

