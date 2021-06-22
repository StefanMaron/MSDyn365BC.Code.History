page 6060 "Contract Trendscape"
{
    Caption = 'Contract Trendscape';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = "Service Contract Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ContractNo; ContractNo)
                {
                    ApplicationArea = Service;
                    Caption = 'Contract No.';
                    ToolTip = 'Specifies billable profits for the job task that are related to items, expressed in the local currency.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Clear(ServContract);
                        ServContract.SetRange("Contract Type", ServContract."Contract Type"::Contract);
                        ServContract."Contract No." := ContractNo;
                        if PAGE.RunModal(0, ServContract) = ACTION::LookupOK then begin
                            Get(ServContract."Contract Type"::Contract, ServContract."Contract No.");
                            SetRange("Contract Type", "Contract Type"::Contract);
                            SetRange("Contract No.", ServContract."Contract No.");
                            ContractNo := ServContract."Contract No.";
                            CurrPage.Update(false);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Clear(ServContract);
                        ServContract.SetRange("Contract Type", ServContract."Contract Type"::Contract);
                        ServContract.SetRange("Contract No.", ContractNo);
                        if ServContract.FindFirst then begin
                            Get(ServContract."Contract Type"::Contract, ServContract."Contract No.");
                            SetRange("Contract No.", ServContract."Contract No.");
                            SetRange("Contract Type", "Contract Type"::Contract);
                            ContractNo := ServContract."Contract No.";
                        end;
                        ContractNoOnAfterValidate;
                    end;
                }
                field(Name; Name)
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer in the service contract.';
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Service;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        if PeriodType = PeriodType::Period then
                            PeriodPeriodTypeOnValidate;
                        if PeriodType = PeriodType::Year then
                            YearPeriodTypeOnValidate;
                        if PeriodType = PeriodType::Quarter then
                            QuarterPeriodTypeOnValidate;
                        if PeriodType = PeriodType::Month then
                            MonthPeriodTypeOnValidate;
                        if PeriodType = PeriodType::Week then
                            WeekPeriodTypeOnValidate;
                        if PeriodType = PeriodType::Day then
                            DayPeriodTypeOnValidate;
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Service;
                    Caption = 'View as';
                    OptionCaption = 'Net Change,Balance at Date';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        if AmountType = AmountType::"Balance at Date" then
                            BalanceatDateAmountTypeOnValid;
                        if AmountType = AmountType::"Net Change" then
                            NetChangeAmountTypeOnValidate;
                    end;
                }
            }
            part(TrendLines; "Contract Trend Lines")
            {
                ApplicationArea = Service;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        ContractNo := "Contract No.";
        UpdateSubform;
    end;

    var
        ServContract: Record "Service Contract Header";
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";
        ContractNo: Code[20];

    local procedure UpdateSubform()
    begin
        CurrPage.TrendLines.PAGE.Set(Rec, PeriodType, AmountType);
    end;

    local procedure ContractNoOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure DayPeriodTypeOnPush()
    begin
        UpdateSubform;
    end;

    local procedure WeekPeriodTypeOnPush()
    begin
        UpdateSubform;
    end;

    local procedure MonthPeriodTypeOnPush()
    begin
        UpdateSubform;
    end;

    local procedure QuarterPeriodTypeOnPush()
    begin
        UpdateSubform;
    end;

    local procedure YearPeriodTypeOnPush()
    begin
        UpdateSubform;
    end;

    local procedure PeriodPeriodTypeOnPush()
    begin
        UpdateSubform;
    end;

    local procedure BalanceatDateAmountTypeOnPush()
    begin
        UpdateSubform;
    end;

    local procedure NetChangeAmountTypeOnPush()
    begin
        UpdateSubform;
    end;

    local procedure DayPeriodTypeOnValidate()
    begin
        DayPeriodTypeOnPush;
    end;

    local procedure WeekPeriodTypeOnValidate()
    begin
        WeekPeriodTypeOnPush;
    end;

    local procedure MonthPeriodTypeOnValidate()
    begin
        MonthPeriodTypeOnPush;
    end;

    local procedure QuarterPeriodTypeOnValidate()
    begin
        QuarterPeriodTypeOnPush;
    end;

    local procedure YearPeriodTypeOnValidate()
    begin
        YearPeriodTypeOnPush;
    end;

    local procedure PeriodPeriodTypeOnValidate()
    begin
        PeriodPeriodTypeOnPush;
    end;

    local procedure NetChangeAmountTypeOnValidate()
    begin
        NetChangeAmountTypeOnPush;
    end;

    local procedure BalanceatDateAmountTypeOnValid()
    begin
        BalanceatDateAmountTypeOnPush;
    end;
}

