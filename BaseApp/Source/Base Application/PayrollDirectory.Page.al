page 17424 "Payroll Directory"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Directory';
    DataCaptionFields = Type;
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Payroll Directory";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentType; CurrentType)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Type';
                OptionCaption = ',Income,Allowance,Tax Deduction,Tax';

                trigger OnValidate()
                begin
                    CurrentTypeOnAfterValidate;
                end;
            }
            repeater(Dictionary)
            {
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Income Type"; "Income Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Deduction Type"; "Tax Deduction Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Income Tax Percent"; "Income Tax Percent")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Deduction Code"; "Tax Deduction Code")
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
    }

    trigger OnOpenPage()
    begin
        if GetFilter(Type) <> '' then
            CurrentType := GetRangeMin(Type)
        else
            CurrentType := CurrentType::Income;

        CurrPage.Editable := not CurrPage.LookupMode;
    end;

    var
        CurrentType: Option " ",Income,Allowance,"Tax Deduction",Tax;

    local procedure CurrentTypeOnAfterValidate()
    begin
        SetRange(Type, CurrentType);
        CurrPage.Update(false);
    end;
}

