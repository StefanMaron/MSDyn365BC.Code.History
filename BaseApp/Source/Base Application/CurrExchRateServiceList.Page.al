page 1650 "Curr. Exch. Rate Service List"
{
    ApplicationArea = Suite;
    Caption = 'Currency Exchange Rate Services';
    CardPageID = "Curr. Exch. Rate Service Card";
    Editable = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Curr. Exch. Rate Update Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the setup of a service to update currency exchange rates.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the setup of a service to update currency exchange rates.';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the currency exchange rate service is enabled.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Enable)
            {
                ApplicationArea = Suite;
                Caption = 'Enable';
                Image = Default;
                ToolTip = 'Enable a service for keeping your for currency exchange rates up to date. You can then change the job that controls how often exchange rates are updated.';

                trigger OnAction()
                begin
                    Validate(Enabled, true);
                    Modify(true);
                end;
            }
            action(TestUpdate)
            {
                ApplicationArea = Suite;
                Caption = 'Preview';
                Image = ReviewWorksheet;
                ToolTip = 'Test the setup of the currency exchange rate service to make sure the service is working.';

                trigger OnAction()
                var
                    TempCurrencyExchangeRate: Record "Currency Exchange Rate" temporary;
                    UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
                begin
                    UpdateCurrencyExchangeRates.GenerateTempDataFromService(TempCurrencyExchangeRate, Rec);
                    PAGE.Run(PAGE::"Currency Exchange Rates", TempCurrencyExchangeRate);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Enable_Promoted; Enable)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Setup', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(TestUpdate_Promoted; TestUpdate)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetupService();
    end;
}

