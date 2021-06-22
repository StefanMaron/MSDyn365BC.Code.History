page 847 "Cash Flow Forecast Card"
{
    Caption = 'Cash Flow Forecast Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Cash Flow Forecast';
    SourceTable = "Cash Flow Forecast";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies a description of the cash flow forecast.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of a forecast.';
                }
                field("Consider Discount"; "Consider Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to include the cash discounts that are assigned in entries and documents in cash flow forecast.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled;
                    end;
                }
                field("Consider Pmt. Disc. Tol. Date"; "Consider Pmt. Disc. Tol. Date")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ConsiderPmtDiscTolDateEnable;
                    ToolTip = 'Specifies if the payment discount tolerance date is considered when the cash flow date is calculated. If the check box is cleared, the due date or payment discount date from the customer and vendor ledger entries and the sales order or purchase order are used.';
                }
                field("Consider Pmt. Tol. Amount"; "Consider Pmt. Tol. Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the payment tolerance amounts from the posted customer and vendor ledger entries are used in the cash flow forecast. If the check box is cleared, the amount without any payment tolerance amount from the customer and vendor ledger entries are used.';
                }
                field("Consider CF Payment Terms"; "Consider CF Payment Terms")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to use cash flow payment terms for cash flow forecast. Cash flow payment terms overrule the standard payment terms that you have defined for customers, vendors, and orders. They also overrule the payment terms that you have manually entered on entries or documents.';
                }
                field(ShowInChart; ShowInChart)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show in Chart on Role Center';
                    ToolTip = 'Specifies the cash flow forecast chart on the Role Center page.';

                    trigger OnValidate()
                    begin
                        if not ValidateShowInChart(ShowInChart) then;
                        CurrPage.Update;
                    end;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date that the forecast was created.';
                }
                field("Created By"; "Created By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the user who created the forecast.';
                }
                field("G/L Budget From"; "G/L Budget From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting date from which you want to use the budget values from the general ledger in the cash flow forecast.';
                }
                field("G/L Budget To"; "G/L Budget To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date to which you want to use the budget values from the general ledger in the cash flow forecast.';
                }
                field("Manual Payments From"; "Manual Payments From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a starting date from which manual payments should be included in cash flow forecast.';
                }
                field("Manual Payments To"; "Manual Payments To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a starting date to which manual payments should be included in cash flow forecast.';
                }
                field("Overdue CF Dates to Work Date"; "Overdue CF Dates to Work Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Overdue Cash Flow Dates to Work Date';
                    ToolTip = 'Specifies if you want to change overdue dates to the current work date for the cash flow forecast. Choose the field if this forecast is shown in the forecast chart.';
                }
                field("Default G/L Budget Name"; "Default G/L Budget Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger budget to be used when recalculating the cash flow forecast.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1905906307; "CF Forecast Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cash Flow Forecast")
            {
                Caption = '&Cash Flow Forecast';
                Image = CashFlow;
                action("E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&ntries';
                    Image = Entries;
                    RunObject = Page "Cash Flow Forecast Entries";
                    RunPageLink = "Cash Flow Forecast No." = FIELD("No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View entries for the cash flow account.';
                }
                action("&Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Cash Flow Forecast Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View detailed historical information for the cash flow forecast.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Cash Flow Comment";
                    RunPageLink = "Table Name" = CONST("Cash Flow Forecast"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                separator(Action1037)
                {
                    Caption = '';
                }
                action("CF &Availability by Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'CF &Availability by Periods';
                    Image = ShowMatrix;
                    RunObject = Page "CF Availability by Periods";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'View a scrollable summary of the forecasted amounts per source type, by period. The rows represent individual periods, and the columns represent the source types in the cash flow forecast.';
                }
            }
        }
        area(processing)
        {
            action(CashFlowWorksheet)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Flow Worksheet';
                Image = Worksheet2;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Cash Flow Worksheet";
                ToolTip = 'Get an overview of cash inflows and outflows and create a short-term forecast that predicts how and when you expect money to be received and paid out by your business.';
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action(CashFlowDateList)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow &Date List';
                    Ellipsis = true;
                    Image = "Report";
                    Promoted = true;
                    PromotedCategory = "Report";
                    ToolTip = 'View forecast entries for a period of time that you specify. The registered cash flow forecast entries are organized by source types, such as receivables, sales orders, payables, and purchase orders. You specify the number of periods and their length.';

                    trigger OnAction()
                    var
                        CashFlowForecast: Record "Cash Flow Forecast";
                    begin
                        CurrPage.SetSelectionFilter(CashFlowForecast);
                        CashFlowForecast.PrintRecords;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateEnabled;
    end;

    trigger OnInit()
    begin
        ConsiderPmtDiscTolDateEnable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateEnabled;
    end;

    var
        [InDataSet]
        ConsiderPmtDiscTolDateEnable: Boolean;
        ShowInChart: Boolean;

    local procedure UpdateEnabled()
    begin
        ConsiderPmtDiscTolDateEnable := "Consider Discount";
        ShowInChart := GetShowInChart;
    end;
}

