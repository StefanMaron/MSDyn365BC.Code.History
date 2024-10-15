page 5 Currencies
{
    AdditionalSearchTerms = 'multiple foreign currency';
    ApplicationArea = Suite;
    Caption = 'Currencies';
    CardPageID = "Currency Card";
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Exchange Rate Service';
    SourceTable = Currency;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a currency code that you can select. The code must comply with ISO 4217.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a text to describe the currency code.';
                }
                field("ISO Code"; "ISO Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a three-letter currency code defined in ISO 4217.';
                }
                field("ISO Numeric Code"; "ISO Numeric Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a three-digit code number defined in ISO 4217.';
                }
                field(ExchangeRateDate; ExchangeRateDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Exchange Rate Date';
                    Editable = false;
                    ToolTip = 'Specifies the date of the exchange rate in the Exchange Rate field. You can update the rate by choosing the Update Exchange Rates button.';

                    trigger OnDrillDown()
                    begin
                        DrillDownActionOnPage;
                    end;
                }
                field(ExchangeRateAmt; ExchangeRateAmt)
                {
                    ApplicationArea = Suite;
                    Caption = 'Exchange Rate';
                    DecimalPlaces = 0 : 7;
                    Editable = false;
                    ToolTip = 'Specifies the currency exchange rate. You can update the rate by choosing the Update Exchange Rates button.';

                    trigger OnDrillDown()
                    begin
                        DrillDownActionOnPage;
                    end;
                }
                field("EMU Currency"; "EMU Currency")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the currency is an EMU currency, for example DEM or EUR.';
                }
                field("Realized Gains Acc."; "Realized Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which realized exchange rate gains will be posted.';
                }
                field("Realized Losses Acc."; "Realized Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which realized exchange rate losses will be posted.';
                }
                field("Unrealized Gains Acc."; "Unrealized Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which unrealized exchange rate gains will be posted when the Adjust Exchange Rates batch job is run.';
                }
                field("Unrealized Losses Acc."; "Unrealized Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account number to which unrealized exchange rate losses will be posted when the Adjust Exchange Rates batch job is run.';
                }
                field("Realized G/L Gains Account"; "Realized G/L Gains Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account to post exchange rate gains to for currency adjustments between LCY and the additional reporting currency.';
                    Visible = false;
                }
                field("Realized G/L Losses Account"; "Realized G/L Losses Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account to post exchange rate gains to for currency adjustments between LCY and the additional reporting currency.';
                    Visible = false;
                }
                field("Residual Gains Account"; "Residual Gains Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account to post residual amount gains to, if you post in the general ledger application area in both LCY and an additional reporting currency.';
                    Visible = false;
                }
                field("Residual Losses Account"; "Residual Losses Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account to post residual amount losses to, if you post in the general ledger application area in both LCY and an additional reporting currency.';
                    Visible = false;
                }
                field("Amount Rounding Precision"; "Amount Rounding Precision")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the size of the interval to be used when rounding amounts in this currency.';
                }
                field("Amount Decimal Places"; "Amount Decimal Places")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of decimal places the program will display for amounts in this currency.';
                }
                field("Invoice Rounding Precision"; "Invoice Rounding Precision")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the size of the interval to be used when rounding amounts in this currency. You can specify invoice rounding for each currency in the Currency table.';
                }
                field("Invoice Rounding Type"; "Invoice Rounding Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether an invoice amount will be rounded up or down. The program uses this information together with the interval for rounding that you have specified in the Invoice Rounding Precision field.';
                }
                field("Unit-Amount Rounding Precision"; "Unit-Amount Rounding Precision")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the size of the interval to be used when rounding unit amounts (that is, item prices per unit) in this currency.';
                }
                field("Unit-Amount Decimal Places"; "Unit-Amount Decimal Places")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of decimal places the program will display for amounts in this currency.';
                }
                field("Appln. Rounding Precision"; "Appln. Rounding Precision")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the size of the interval that will be allowed as a rounding difference when you apply entries in different currencies to one another.';
                }
                field("Conv. LCY Rndg. Debit Acc."; "Conv. LCY Rndg. Debit Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies conversion information that must also contain a debit account if you wish to insert correction lines for rounding differences in the general journals using the Insert Conv. LCY Rndg. Lines function.';
                }
                field("Conv. LCY Rndg. Credit Acc."; "Conv. LCY Rndg. Credit Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies conversion information that must also contain a credit account if you wish to insert correction lines for rounding differences in the general journals using the Insert Conv. LCY Rndg. Lines function.';
                }
                field("Max. VAT Difference Allowed"; "Max. VAT Difference Allowed")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the maximum VAT correction amount allowed for the currency.';
                    Visible = false;
                }
                field("VAT Rounding Type"; "VAT Rounding Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the program will round VAT when calculated for this currency.';
                    Visible = false;
                }
                field("Last Date Adjusted"; "Last Date Adjusted")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the exchange rates were last adjusted, that is, the last date on which the Adjust Exchange Rates batch job was run.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the last date on which any information in the Currency table was modified.';
                }
                field("Payment Tolerance %"; "Payment Tolerance %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the percentage that the payment or refund is allowed to be, less than the amount on the invoice or credit memo.';
                }
                field("Max. Payment Tolerance Amount"; "Max. Payment Tolerance Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the maximum allowed amount that the payment or refund can differ from the amount on the invoice or credit memo.';
                }
                field(CurrencyFactor; CurrencyFactor)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Factor';
                    DecimalPlaces = 1 : 6;
                    ToolTip = 'Specifies the relationship between the additional reporting currency and the local currency. Amounts are recorded in both LCY and the additional reporting currency, using the relevant exchange rate and the currency factor.';

                    trigger OnValidate()
                    var
                        CurrencyExchangeRate: Record "Currency Exchange Rate";
                    begin
                        CurrencyExchangeRate.SetCurrentCurrencyFactor(Code, CurrencyFactor);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Change Payment &Tolerance")
                {
                    ApplicationArea = Suite;
                    Caption = 'Change Payment &Tolerance';
                    Image = ChangePaymentTolerance;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Change either or both the maximum payment tolerance and the payment tolerance percentage and filters by currency.';

                    trigger OnAction()
                    var
                        ChangePmtTol: Report "Change Payment Tolerance";
                    begin
                        ChangePmtTol.SetCurrency(Rec);
                        ChangePmtTol.RunModal;
                    end;
                }
                action(SuggestAccounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Accounts';
                    Image = Default;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Suggest G/L Accounts for selected currency.';

                    trigger OnAction()
                    begin
                        SuggestSetupAccounts;
                    end;
                }
            }
            action("Exch. &Rates")
            {
                ApplicationArea = Suite;
                Caption = 'Exch. &Rates';
                Image = CurrencyExchangeRates;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Currency Exchange Rates";
                RunPageLink = "Currency Code" = FIELD(Code);
                ToolTip = 'View updated exchange rates for the currencies that you use.';
            }
            action("Adjust Exchange Rate")
            {
                ApplicationArea = Suite;
                Caption = 'Adjust Exchange Rate';
                Image = AdjustExchangeRates;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Adjust Exchange Rates";
                ToolTip = 'Adjust general ledger, customer, vendor, and bank account entries to reflect a more updated balance if the exchange rate has changed since the entries were posted.';
            }
            action("Exchange Rate Adjust. Register")
            {
                ApplicationArea = Suite;
                Caption = 'Exchange Rate Adjust. Register';
                Image = ExchangeRateAdjustRegister;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Exchange Rate Adjmt. Register";
                RunPageLink = "Currency Code" = FIELD(Code);
                ToolTip = 'View the results of running the Adjust Exchange Rates batch job. One line is created for each currency or each combination of currency and posting group that is included in the adjustment.';
            }
            action("Exchange Rate Services")
            {
                ApplicationArea = Suite;
                Caption = 'Exchange Rate Services';
                Image = Web;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "Curr. Exch. Rate Service List";
                ToolTip = 'View or edit the setup of the services that are set up to fetch updated currency exchange rates when you choose the Update Exchange Rates action.';
            }
            action(UpdateExchangeRates)
            {
                ApplicationArea = Suite;
                Caption = 'Update Exchange Rates';
                Image = UpdateXML;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Codeunit "Update Currency Exchange Rates";
                ToolTip = 'Get the latest currency exchange rates from a service provider.';
            }
        }
        area(reporting)
        {
            action("Foreign Currency Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Foreign Currency Balance';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Foreign Currency Balance";
                ToolTip = 'View the balances for all customers and vendors in both foreign currencies and in local currency (LCY). The report displays two LCY balances. One is the foreign currency balance converted to LCY by using the exchange rate at the time of the transaction. The other is the foreign currency balance converted to LCY by using the exchange rate of the work date.';
            }
        }
        area(navigation)
        {
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Image = Administration;
                Visible = CRMIntegrationEnabled;
                action(CRMGotoTransactionCurrency)
                {
                    ApplicationArea = Suite;
                    Caption = 'Transaction Currency';
                    Image = CoupledCurrency;
                    ToolTip = 'Open the coupled Dynamics 365 Sales transaction currency.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        Currency: Record Currency;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        CurrencyRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Currency);
                        Currency.Next;

                        if Currency.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Currency.RecordId)
                        else begin
                            CurrencyRecordRef.GetTable(Currency);
                            CRMIntegrationManagement.UpdateMultipleNow(CurrencyRecordRef);
                        end
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales Transaction Currency.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales Transaction Currency.';

                        trigger OnAction()
                        var
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(RecordId);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the currency table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(RecordId);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
    end;

    trigger OnAfterGetRecord()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyFactor := CurrencyExchangeRate.GetCurrentCurrencyFactor(Code);
        CurrencyExchangeRate.GetLastestExchangeRate(Code, ExchangeRateDate, ExchangeRateAmt);
    end;

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
    end;

    var
        CurrencyFactor: Decimal;
        ExchangeRateAmt: Decimal;
        ExchangeRateDate: Date;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;

    procedure GetSelectionFilter(): Text
    var
        Currency: Record Currency;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Currency);
        exit(SelectionFilterManagement.GetSelectionFilterForCurrency(Currency));
    end;

    procedure GetCurrency(var CurrencyCode: Code[10])
    begin
        CurrencyCode := Code;
    end;

    local procedure DrillDownActionOnPage()
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.SetRange("Currency Code", Code);
        PAGE.RunModal(0, CurrExchRate);
        CurrPage.Update(false);
    end;
}

