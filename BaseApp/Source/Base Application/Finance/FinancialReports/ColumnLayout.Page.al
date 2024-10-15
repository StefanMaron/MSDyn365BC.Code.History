namespace Microsoft.Finance.FinancialReports;

using Microsoft.CostAccounting.Account;

page 489 "Column Layout"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Column Definition';
    DataCaptionFields = "Column Layout Name";
    PageType = Worksheet;
    SourceTable = "Column Layout";
    AnalysisModeEnabled = false;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(CurrentColumnName; CurrentColumnName)
            {
                ApplicationArea = Basic, Suite;
                AssistEdit = false;
                Caption = 'Name';
                Lookup = true;
                TableRelation = "Column Layout Name".Name;
                ToolTip = 'Specifies the name of the record.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    exit(AccSchedManagement.LookupColumnName(CurrentColumnName, Text));
                end;

                trigger OnValidate()
                begin
                    AccSchedManagement.CheckColumnName(CurrentColumnName);
                    CurrentColumnNameOnAfterValida();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number for the financial report column.';
                    Visible = false;
                }
                field("Column No."; Rec."Column No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number for the column in the analysis view.';
                }
                field("Column Header"; Rec."Column Header")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a header for the column.';
                }
                field("Column Type"; Rec."Column Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the analysis column type, which determines how the amounts in the column are calculated.';
                }
                field("Ledger Entry Type"; Rec."Ledger Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of ledger entries that will be included in the amounts in the financial report column.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of entries that will be included in the amounts in the financial report column.';
                }
                field("Budget Name"; Rec."Budget Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which budget amounts will be totaled in this column.';
                }
                field(Formula; Rec.Formula)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula. The result of the formula will appear in the column when the financial report is printed.';
                }
                field("Show Opposite Sign"; Rec."Show Opposite Sign")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to show debits in reports as negative amounts (that is, with a minus sign) and credits as positive amounts.';
                }
                field("Comparison Date Formula"; Rec."Comparison Date Formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a date formula that specifies which dates should be used to calculate the amount in this column.';
                }
                field("Comparison Period Formula"; Rec."Comparison Period Formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a period formula that specifies the accounting periods you want to use to calculate the amount in this column.';
                    Visible = false;
                }
                field(Show; Rec.Show)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when you want the amounts in the column to be shown in reports.';
                }
                field("Show Indented Lines"; Rec."Show Indented Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that indented lines are shown.';
                    Visible = false;
                }
                field("Rounding Factor"; Rec."Rounding Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a rounding factor for amounts in the column.';
                }
                field("Business Unit Totaling"; Rec."Business Unit Totaling")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which business unit amounts will be totaled in this column.';
                    Visible = false;
                }
                field("Dimension 1 Totaling"; Rec."Dimension 1 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled in this column. If the column type of the column is Formula, you must not enter anything in this field. Also, if you do not wish the amounts on the line to be filtered by dimension, you should leave this field blank.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(1, Text));
                    end;
                }
                field("Dimension 2 Totaling"; Rec."Dimension 2 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled in this column. If the column type of the column is Formula, you must not enter anything in this field. Also, if you do not wish the amounts on the line to be filtered by dimension, you should leave this field blank.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(2, Text));
                    end;
                }
                field("Dimension 3 Totaling"; Rec."Dimension 3 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled in this column. If the column type is Formula, you must not enter anything in this field. Also, if you do not wish the amounts on the line to be filtered by dimension, you should leave this field blank.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(3, Text));
                    end;
                }
                field("Dimension 4 Totaling"; Rec."Dimension 4 Totaling")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value amounts will be totaled in this column. If the column type is Formula, you must not enter anything in this field. Also, if you do not wish the amounts on the line to be filtered by dimension, you should leave this field blank.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(4, Text));
                    end;
                }
                field("Cost Center Totaling"; Rec."Cost Center Totaling")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies which cost center amounts will be totaled in this column.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostCenter: Record "Cost Center";
                    begin
                        exit(CostCenter.LookupCostCenterFilter(Text));
                    end;
                }
                field("Cost Object Totaling"; Rec."Cost Object Totaling")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies which cost object amounts will be totaled in this column.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostObject: Record "Cost Object";
                    begin
                        exit(CostObject.LookupCostObjectFilter(Text));
                    end;
                }
                field(HideCurrencySymbol; Rec."Hide Currency Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to hide currency symbols when a calculated result is not a currency.';
                    Visible = false;
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
            action(CopyColumnLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Column Layout';
                Image = Copy;
                Scope = Repeater;
                ToolTip = 'Create a copy of the current column layout.';

                trigger OnAction()
                var
                    ColLayoutName: Record "Column Layout Name";
                begin
                    ColLayoutName.Get(CurrentColumnName);
                    ColLayoutName.SetRecFilter();
                    Report.RunModal(Report::"Copy Column Layout", true, true, ColLayoutName);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopyColumnLayout_Promoted; CopyColumnLayout)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not DimCaptionsInitialized then
            DimCaptionsInitialized := true;
    end;

    trigger OnOpenPage()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReportMgt.LaunchEditColumnsWarningNotification();
        AccSchedManagement.OpenColumns(CurrentColumnName, Rec);
    end;

    var
        AccSchedManagement: Codeunit AccSchedManagement;
        CurrentColumnName: Code[10];
        DimCaptionsInitialized: Boolean;

    local procedure CurrentColumnNameOnAfterValida()
    begin
        CurrPage.SaveRecord();
        AccSchedManagement.SetColumnName(CurrentColumnName, Rec);
        CurrPage.Update(false);
    end;

    procedure SetColumnLayoutName(NewColumnName: Code[10])
    begin
        CurrentColumnName := NewColumnName;
    end;
}

