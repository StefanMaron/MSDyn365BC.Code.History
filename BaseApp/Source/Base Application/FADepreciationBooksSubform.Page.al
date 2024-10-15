page 5666 "FA Depreciation Books Subform"
{
    Caption = 'Lines';
    DataCaptionFields = "FA No.", "Depreciation Book Code";
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "FA Depreciation Book";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Depreciation Book Code"; "Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = true;
                    ToolTip = 'Specifies the depreciation book that is assigned to the fixed asset.';
                }
                field(AddCurrCode; GetACYCode)
                {
                    ApplicationArea = Suite;
                    Caption = 'FA Add.-Currency Code';
                    ToolTip = 'Specifies an additional currency to be used when posting.';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameterFA("FA Add.-Currency Factor", GetACYCode, WorkDate);
                        if ChangeExchangeRate.RunModal = ACTION::OK then
                            "FA Add.-Currency Factor" := ChangeExchangeRate.GetParameter;

                        Clear(ChangeExchangeRate);
                    end;
                }
                field("FA Posting Group"; "FA Posting Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies which posting group is used for the depreciation book when posting fixed asset transactions.';
                }
                field("Depreciation Method"; "Depreciation Method")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies how depreciation is calculated for the depreciation book.';
                }
                field("Depreciation Starting Date"; "Depreciation Starting Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date on which depreciation of the fixed asset starts.';
                }
                field("No. of Depreciation Years"; "No. of Depreciation Years")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the length of the depreciation period, expressed in years.';
                }
                field("Depreciation Ending Date"; "Depreciation Ending Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date on which depreciation of the fixed asset ends.';
                }
                field("No. of Depreciation Months"; "No. of Depreciation Months")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the length of the depreciation period, expressed in months.';
                    Visible = false;
                }
                field("Straight-Line %"; "Straight-Line %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the percentage to depreciate the fixed asset by the straight-line principle, but with a fixed yearly percentage.';
                    Visible = false;
                }
                field("Fixed Depr. Amount"; "Fixed Depr. Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies an amount to depreciate the fixed asset, by a fixed yearly amount.';
                    Visible = false;
                }
                field("Declining-Balance %"; "Declining-Balance %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the percentage to depreciate the fixed asset by the declining-balance principle, but with a fixed yearly percentage.';
                }
                field("First User-Defined Depr. Date"; "First User-Defined Depr. Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the starting date for the user-defined depreciation table if you have entered a code in the Depreciation Table Code field.';
                    Visible = false;
                }
                field("""Disposal Date"" > 0D"; "Disposal Date" > 0D)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Disposed Of';
                    Editable = false;
                    ToolTip = 'Specifies whether the fixed asset has been disposed of.';
                }
                field(BookValue; BookValue)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Book Value';
                    Editable = false;
                    ToolTip = 'Specifies the book value for the fixed asset as a FlowField.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOnBookValue;
                    end;
                }
                field("Depreciation Table Code"; "Depreciation Table Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code of the depreciation table to use if you have selected the User-Defined option in the Depreciation Method field.';
                    Visible = false;
                }
                field("Final Rounding Amount"; "Final Rounding Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the final rounding amount to use.';
                    Visible = false;
                }
                field("Ending Book Value"; "Ending Book Value")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the amount to use as the ending book value.';
                    Visible = false;
                }
                field("Ignore Def. Ending Book Value"; "Ignore Def. Ending Book Value")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that the default ending book value is ignored, and the value in the Ending Book Value is used.';
                    Visible = false;
                }
                field("FA Exchange Rate"; "FA Exchange Rate")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a decimal number, which will be used as an exchange rate when duplicating journal lines to this depreciation book.';
                    Visible = false;
                }
                field("Use FA Ledger Check"; "Use FA Ledger Check")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies which checks to perform before posting a journal line.';
                    Visible = false;
                }
                field("Depr. below Zero %"; "Depr. below Zero %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a percentage if you have selected the Allow Depr. below Zero field in the depreciation book.';
                    Visible = false;
                }
                field("Fixed Depr. Amount below Zero"; "Fixed Depr. Amount below Zero")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a positive amount if you have selected the Allow Depr. below Zero field in the depreciation book.';
                    Visible = false;
                }
                field("Projected Disposal Date"; "Projected Disposal Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date on which you want to dispose of the fixed asset.';
                    Visible = false;
                }
                field("Projected Proceeds on Disposal"; "Projected Proceeds on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the expected proceeds from disposal of the fixed asset.';
                    Visible = false;
                }
                field("Depr. Starting Date (Custom 1)"; "Depr. Starting Date (Custom 1)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the starting date for depreciation of custom 1 entries.';
                    Visible = false;
                }
                field("Depr. Ending Date (Custom 1)"; "Depr. Ending Date (Custom 1)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the ending date for depreciation of custom 1 entries.';
                    Visible = false;
                }
                field("Accum. Depr. % (Custom 1)"; "Accum. Depr. % (Custom 1)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total percentage for depreciation of custom 1 entries.';
                    Visible = false;
                }
                field("Depr. This Year % (Custom 1)"; "Depr. This Year % (Custom 1)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the percentage for depreciation of custom 1 entries for the current year.';
                    Visible = false;
                }
                field("Property Class (Custom 1)"; "Property Class (Custom 1)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the property class of the asset.';
                    Visible = false;
                }
                field("Use Half-Year Convention"; "Use Half-Year Convention")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that the Half-Year Convention is to be applied to the selected depreciation method.';
                    Visible = false;
                }
                field("Use DB% First Fiscal Year"; "Use DB% First Fiscal Year")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that the depreciation methods DB1/SL and DB2/SL use the declining balance depreciation amount in the first fiscal year.';
                    Visible = false;
                }
                field("Temp. Ending Date"; "Temp. Ending Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the ending date of the period during which a temporary fixed depreciation amount will be used.';
                    Visible = false;
                }
                field("Temp. Fixed Depr. Amount"; "Temp. Fixed Depr. Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a temporary fixed depreciation amount.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Depr. Book")
            {
                Caption = '&Depr. Book';
                Image = DepreciationBooks;
                action("Ledger E&ntries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    trigger OnAction()
                    begin
                        ShowFALedgEntries;
                    end;
                }
                action("Error Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Error Ledger Entries';
                    Image = ErrorFALedgerEntries;
                    ToolTip = 'View the entries that have been posted as a result of you using the Cancel function to cancel an entry.';

                    trigger OnAction()
                    begin
                        ShowFAErrorLedgEntries;
                    end;
                }
                action("Maintenance Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance Ledger Entries';
                    Image = MaintenanceLedgerEntries;
                    ToolTip = 'View the maintenance ledger entries for the fixed asset.';

                    trigger OnAction()
                    begin
                        ShowMaintenanceLedgEntries;
                    end;
                }
                action(Statistics)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';
                    ToolTip = 'View detailed historical information about the fixed asset.';

                    trigger OnAction()
                    begin
                        ShowStatistics;
                    end;
                }
                action("Main &Asset Statistics")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Main &Asset Statistics';
                    Image = StatisticsDocument;
                    ToolTip = 'View statistics for all the components that make up the main asset for the selected book. ';

                    trigger OnAction()
                    begin
                        ShowMainAssetStatistics;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        BookValue := GetBookValue;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        BookValue := GetBookValue;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        BookValue := 0;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        FADeprBook: Record "FA Depreciation Book";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        ChangeExchangeRate: Page "Change Exchange Rate";
        AddCurrCodeIsFound: Boolean;
        BookValue: Decimal;

    local procedure GetACYCode(): Code[10]
    begin
        if not AddCurrCodeIsFound then
            GLSetup.Get;
        exit(GLSetup."Additional Reporting Currency");
    end;

    local procedure ShowFALedgEntries()
    begin
        DepreciationCalc.SetFAFilter(FALedgEntry, "FA No.", "Depreciation Book Code", false);
        PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
    end;

    local procedure ShowFAErrorLedgEntries()
    begin
        FALedgEntry.Reset;
        FALedgEntry.SetCurrentKey("Canceled from FA No.");
        FALedgEntry.SetRange("Canceled from FA No.", "FA No.");
        FALedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
        PAGE.Run(PAGE::"FA Error Ledger Entries", FALedgEntry);
    end;

    local procedure ShowMaintenanceLedgEntries()
    begin
        MaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code");
        MaintenanceLedgEntry.SetRange("FA No.", "FA No.");
        MaintenanceLedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
        PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintenanceLedgEntry);
    end;

    local procedure ShowStatistics()
    begin
        FADeprBook.SetRange("FA No.", "FA No.");
        FADeprBook.SetRange("Depreciation Book Code", "Depreciation Book Code");
        PAGE.Run(PAGE::"Fixed Asset Statistics", FADeprBook);
    end;

    local procedure ShowMainAssetStatistics()
    begin
        FADeprBook.SetRange("FA No.", "FA No.");
        FADeprBook.SetRange("Depreciation Book Code", "Depreciation Book Code");
        PAGE.Run(PAGE::"Main Asset Statistics", FADeprBook);
    end;

    local procedure GetBookValue(): Decimal
    begin
        if "Disposal Date" > 0D then
            exit(0);
        CalcFields("Book Value");
        exit("Book Value");
    end;
}

