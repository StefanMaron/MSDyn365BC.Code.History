page 241 "Business Unit Card"
{
    Caption = 'Business Unit Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Exch. Rates';
    SourceTable = "Business Unit";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the identifier for the business unit in the consolidated company.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the business unit in the consolidated company.';
                }
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the company that will become a business unit in the consolidated company.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency to use for this business unit during consolidation.';
                }
                field("Currency Exchange Rate Table"; "Currency Exchange Rate Table")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies where to get currency exchange rates from when importing consolidation data. If you choose Local, the currency exchange rate table in the current (local) company is used. If you choose Business Unit, the currency exchange rate table in the business unit is used.';
                }
                field(Consolidate; Consolidate)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether to include the business unit in the Consolidation report.';
                }
                field("Consolidation %"; "Consolidation %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the percentage of each transaction for the business unit to include in the consolidation. For example, if a sales invoice is for $1000, and you specify 70%, consolidation will include $700 for the invoice. This is useful when you own only a percentage of a business unit.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the starting date of the fiscal year that the business unit uses. Enter a date only if the business unit and consolidated company have different fiscal years.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ending date of the business unit''s fiscal year. Enter a date only if the business unit and the consolidated company have different fiscal years.';
                }
                field("Data Source"; "Data Source")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether data is retrieved in the local currency (LCY) or the additional reporting currency (ACY) from the business unit.';
                }
                field("File Format"; "File Format")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the file format to use for the business unit data. If the business unit has version 3.70 or earlier, it must submit a .txt file. If the version is 4.00 or later, it must use an XML file.';
                }
                field("Last Run"; "Last Run")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the last date on which consolidation was run.';
                }
            }
            group("G/L Accounts")
            {
                Caption = 'G/L Accounts';
                field("Exch. Rate Gains Acc."; "Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account that revenue gained from exchange rates during consolidation is posted to.';
                }
                field("Exch. Rate Losses Acc."; "Exch. Rate Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account that revenue losses due to exchange rates during consolidation are posted.';
                }
                field("Comp. Exch. Rate Gains Acc."; "Comp. Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account where gains from exchange rates during consolidation are posted for accounts that use the Composite Rate in the Consol. Translation Method field.';
                }
                field("Comp. Exch. Rate Losses Acc."; "Comp. Exch. Rate Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account where losses due to exchange rates during consolidation are posted for accounts that use the Composite Rate in the Consol. Translation Method field.';
                }
                field("Equity Exch. Rate Gains Acc."; "Equity Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account for gains from exchange rates during consolidation are posted to for accounts that use the Equity Rate. If this field is blank, the account in the Exch. Rate Gains Acc. field is used.';
                }
                field("Equity Exch. Rate Losses Acc."; "Equity Exch. Rate Losses Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account where losses due to exchange rates during consolidation are posted for accounts that use the Equity Rate. If this field is blank, the account in the Exch. Rate Losses Acc. field is used.';
                }
                field("Residual Account"; "Residual Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account for residual amounts that occur during consolidation.';
                }
                field("Minority Exch. Rate Gains Acc."; "Minority Exch. Rate Gains Acc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account where gains from exchange rates during consolidation are posted for business units that you do not own 100%. If this field is blank, the account in the Exch. Rate Gains Acc. field is used.';
                }
                field("Minority Exch. Rate Losses Acc"; "Minority Exch. Rate Losses Acc")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general ledger account that losses due to exchange rates during consolidation are posted to for business units that you do not own 100%. If this field is blank, the account in the Exch. Rate Losses Acc. field is used.';
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
        area(navigation)
        {
            group("E&xch. Rates")
            {
                Caption = 'E&xch. Rates';
                Image = ManualExchangeRate;
                action("Average Rate (Manual)")
                {
                    ApplicationArea = Suite;
                    Caption = 'Average Rate (Manual)';
                    Ellipsis = true;
                    Image = ManualExchangeRate;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Manage exchange rate calculations.';

                    trigger OnAction()
                    begin
                        ChangeExchangeRate.SetCaption(Text000);
                        ChangeExchangeRate.SetParameter("Currency Code", "Income Currency Factor", WorkDate);
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            "Income Currency Factor" := ChangeExchangeRate.GetParameter;
                            Modify;
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                action("Closing Rate")
                {
                    ApplicationArea = Suite;
                    Caption = 'Closing Rate';
                    Ellipsis = true;
                    Image = Close;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'The currency exchange rate that is valid on the date that the balance sheet or income statement is prepared.';

                    trigger OnAction()
                    begin
                        ChangeExchangeRate.SetCaption(Text001);
                        ChangeExchangeRate.SetParameter("Currency Code", "Balance Currency Factor", WorkDate);
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            "Balance Currency Factor" := ChangeExchangeRate.GetParameter;
                            Modify;
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                action("Last Closing Rate")
                {
                    ApplicationArea = Suite;
                    Caption = 'Last Closing Rate';
                    Image = Close;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'The rate that was used in the last balance sheet closing.';

                    trigger OnAction()
                    begin
                        ChangeExchangeRate.SetCaption(Text002);
                        ChangeExchangeRate.SetParameter("Currency Code", "Last Balance Currency Factor", WorkDate);
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            "Last Balance Currency Factor" := ChangeExchangeRate.GetParameter;
                            Modify;
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
            }
            group("&Reports")
            {
                Caption = '&Reports';
                Image = "Report";
                action(Eliminations)
                {
                    ApplicationArea = Suite;
                    Caption = 'Eliminations';
                    Ellipsis = true;
                    Image = "Report";
                    RunObject = Report "G/L Consolidation Eliminations";
                    ToolTip = 'View or edit elimination entries to remove transactions that are recorded across more than one company or remove entries involving intercompany transactions.';
                }
                action("Trial B&alance")
                {
                    ApplicationArea = Suite;
                    Caption = 'Trial B&alance';
                    Ellipsis = true;
                    Image = "Report";
                    RunObject = Report "Consolidated Trial Balance";
                    ToolTip = 'View general ledger balances and activities.';
                }
                action("Trial &Balance (4)")
                {
                    ApplicationArea = Suite;
                    Caption = 'Trial &Balance (4)';
                    Ellipsis = true;
                    Image = "Report";
                    RunObject = Report "Consolidated Trial Balance (4)";
                    ToolTip = 'View detailed general ledger balances.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Test Database")
                {
                    ApplicationArea = Suite;
                    Caption = 'Test Database';
                    Ellipsis = true;
                    Image = TestDatabase;
                    RunObject = Report "Consolidation - Test Database";
                    ToolTip = 'Preview the consolidation, without transferring data.';
                }
                action("T&est File")
                {
                    ApplicationArea = Suite;
                    Caption = 'T&est File';
                    Ellipsis = true;
                    Image = TestFile;
                    RunObject = Report "Consolidation - Test File";
                    ToolTip = 'Preview the consolidation in a file, without transferring data.';
                }
                separator(Action54)
                {
                }
                action("Run Consolidation")
                {
                    ApplicationArea = Suite;
                    Caption = 'Run Consolidation';
                    Ellipsis = true;
                    Image = ImportDatabase;
                    RunObject = Report "Import Consolidation from DB";
                    ToolTip = 'Run consolidation.';
                }
                action("I&mport File")
                {
                    ApplicationArea = Suite;
                    Caption = 'I&mport File';
                    Ellipsis = true;
                    Image = Import;
                    RunObject = Report "Import Consolidation from File";
                    ToolTip = 'Run consolidation for the file that you import.';
                }
                action("Export File")
                {
                    ApplicationArea = Suite;
                    Caption = 'Export File';
                    Image = Export;
                    RunObject = Report "Export Consolidation";
                    ToolTip = 'Export transactions from the business units to a file.';
                }
            }
        }
    }

    var
        ChangeExchangeRate: Page "Change Exchange Rate";
        Text000: Label 'Average Rate (Manual)';
        Text001: Label 'Closing Rate';
        Text002: Label 'Last Closing Rate';
}

