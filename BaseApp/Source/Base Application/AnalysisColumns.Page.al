page 7114 "Analysis Columns"
{
    AutoSplitKey = true;
    Caption = 'Analysis Columns';
    DataCaptionFields = "Analysis Area";
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Analysis Column";

    layout
    {
        area(content)
        {
            field(CurrentColumnName; CurrentColumnName)
            {
                ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                Caption = 'Name';
                ToolTip = 'Specifies the name of the record.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord;
                    if AnalysisRepMgmt.LookupColumnName(
                         GetRangeMax("Analysis Area"), CurrentColumnName)
                    then begin
                        Text := CurrentColumnName;
                        exit(true);
                    end;
                end;

                trigger OnValidate()
                begin
                    AnalysisRepMgmt.GetColumnTemplate(GetRangeMax("Analysis Area"), CurrentColumnName);
                    CurrentColumnNameOnAfterValida;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Column No."; "Column No.")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a number for the column in the analysis view.';
                }
                field("Column Header"; "Column Header")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a header for the column as you want it to appear on printed reports.';
                }
                field("Item Ledger Entry Type Filter"; "Item Ledger Entry Type Filter")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the filter that applies to the item ledger entry type that you want this column to be calculated from.';
                    Visible = false;
                }
                field("Value Entry Type Filter"; "Value Entry Type Filter")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the filter that applies to the item value entry type that you want this column to be calculated from.';
                    Visible = false;
                }
                field(Invoiced; Invoiced)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies if you want the analysis report to be based on invoiced amounts. If left field blank, the report will be based on expected amounts.';
                }
                field("Column Type"; "Column Type")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the analysis column type, which determines how the amounts in the column are calculated.';
                }
                field("Ledger Entry Type"; "Ledger Entry Type")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the type of ledger entries that will be included in the amounts in the analysis column.';
                }
                field(Formula; Formula)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a formula for how data is shown in the column when the analysis report is printed.';
                }
                field("Show Opposite Sign"; "Show Opposite Sign")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies if you want purchases and positive adjustments to be shown as negative amounts and sales and negative adjustments to be shown as positive amounts.';
                }
                field("Comparison Date Formula"; "Comparison Date Formula")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a date formula that specifies which dates should be used to calculate the amount in this column.';
                }
                field("Analysis Type Code"; "Analysis Type Code")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the analysis type to apply to the column.';
                }
                field("Value Type"; "Value Type")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the source data that the source data type in the Analysis Type Code field, in the Analysis Columns window, is based on.';
                }
                field(Show; Show)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies when you want the amounts in the column to be shown in reports.';
                }
                field("Rounding Factor"; "Rounding Factor")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a rounding factor for the amounts in the column.';
                }
                field("Comparison Period Formula"; "Comparison Period Formula")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a period formula that specifies the accounting periods you want to use to calculate the amount in this column.';
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
    }

    trigger OnAfterGetRecord()
    begin
        ItemLedgerEntryTypeFilterOnFor(Format("Item Ledger Entry Type Filter"));
        ValueEntryTypeFilterOnFormat(Format("Value Entry Type Filter"));
    end;

    trigger OnOpenPage()
    begin
        AnalysisRepMgmt.OpenColumns(CurrentColumnName, Rec);
    end;

    var
        AnalysisRepMgmt: Codeunit "Analysis Report Management";
        CurrentColumnName: Code[10];

    procedure SetCurrentColumnName(ColumnlName: Code[10])
    begin
        CurrentColumnName := ColumnlName;
    end;

    local procedure CurrentColumnNameOnAfterValida()
    begin
        CurrPage.SaveRecord;
        AnalysisRepMgmt.SetColumnName(GetRangeMax("Analysis Area"), CurrentColumnName, Rec);
        CurrPage.Update(false);
    end;

    local procedure ItemLedgerEntryTypeFilterOnFor(Text: Text[1024])
    begin
        Text := "Item Ledger Entry Type Filter";
        AnalysisRepMgmt.ValidateFilter(Text, DATABASE::"Analysis Column", FieldNo("Item Ledger Entry Type Filter"), false);
    end;

    local procedure ValueEntryTypeFilterOnFormat(Text: Text[1024])
    begin
        Text := "Value Entry Type Filter";
        AnalysisRepMgmt.ValidateFilter(Text, DATABASE::"Analysis Column", FieldNo("Value Entry Type Filter"), false);
    end;
}

