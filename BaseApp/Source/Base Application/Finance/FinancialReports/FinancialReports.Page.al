namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;

page 108 "Financial Reports"
{
    AboutText = 'With the Financial Reports feature, you can get insights into the financial data shown on your chart of accounts (COA). Using row and column definitions, you can set up financial reports to analyse figures in general ledger (G/L) accounts, and compare general ledger entries with budget entries.';
    AboutTitle = 'About Financial Reports';
    AdditionalSearchTerms = 'account schedule,finance reports,financial reporting';
    AnalysisModeEnabled = false;
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Reports';
    PageType = List;
    SourceTable = "Financial Report";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique name (code) of the financial report.';
                    trigger OnDrillDown()
                    var
                        AccScheduleOverview: Page "Acc. Schedule Overview";
                    begin
                        AccScheduleOverview.SetFinancialReportName(Rec.Name);
                        AccScheduleOverview.SetViewOnlyMode(true);
                        AccScheduleOverview.Run();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the financial report definition. The description is shown as a title on the final report when you run it to get a PDF or to print it.';
                }
                field("Financial Report Row Group"; Rec."Financial Report Row Group")
                {
                    Caption = 'Row Definition';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the row definition (code) to be used for this financial report.';
                }
                field(AnalysisViewRow; AnalysisViewRow)
                {
                    Caption = 'Row Analysis View Name';
                    ApplicationArea = Basic, Suite;
                    Tooltip = 'Specifies the name of the analysis view you want the row definitions to be based on. Using an analysis view is optional.';
                    TableRelation = "Analysis View".Code;

                    trigger OnValidate()
                    var
                        AccScheduleName: Record "Acc. Schedule Name";
                        AnalysisView: Record "Analysis View";
                    begin
                        AccScheduleName.Get(Rec."Financial Report Row Group");
                        if AnalysisViewRow <> '' then begin
                            AnalysisView.Get(AnalysisViewRow);
                            AccScheduleName."Analysis View Name" := AnalysisView.Code;
                        end else
                            Clear(AccScheduleName."Analysis View Name");

                        AccScheduleName.Modify();
                    end;
                }
                field("Financial Report Column Group"; Rec."Financial Report Column Group")
                {
                    Caption = 'Column Definition';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the column definition (code) to be used for this financial report.';
                }
                field(AnalysisViewColumn; AnalysisViewColumn)
                {
                    Caption = 'Column Analysis View Name';
                    ApplicationArea = Basic, Suite;
                    Tooltip = 'Specifies the name of the analysis view you want the column layout to be based on. Using an analysis view is optional.';
                    TableRelation = "Analysis View".Code;

                    trigger OnValidate()
                    var
                        ColumnLayoutName: Record "Column Layout Name";
                        AnalysisView: Record "Analysis View";
                    begin
                        ColumnLayoutName.Get(Rec."Financial Report Column Group");
                        if AnalysisViewRow <> '' then begin
                            AnalysisView.Get(AnalysisViewRow);
                            ColumnLayoutName."Analysis View Name" := AnalysisView.Code;
                        end else
                            Clear(ColumnLayoutName."Analysis View Name");

                        ColumnLayoutName.Modify();
                    end;
                }
            }
        }

        area(factboxes)
        {
            systempart(ControlLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(ControlNotes; Notes)
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
            action(ViewFinancialReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Financial Report';
                Image = View;
                ToolTip = 'View the selected financial report with data.';
                AboutTitle = 'View Financial Report';
                AboutText = 'This action will open the financial report in a sandbox like environment, where all changes are saved to the user and not the report';
                trigger OnAction()
                var
                    AccScheduleOverview: Page "Acc. Schedule Overview";
                begin
                    AccScheduleOverview.SetFinancialReportName(Rec.Name);
                    AccScheduleOverview.SetViewOnlyMode(true);
                    AccScheduleOverview.Run();
                end;
            }
            action(EditRowGroup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Row Definition';
                Image = Edit;
                ShortCutKey = 'Return';
                ToolTip = 'Edit the row definition of the selected financial report.';

                trigger OnAction()
                var
                    AccSchedule: Page "Account Schedule";
                begin
                    AccSchedule.SetAccSchedName(Rec."Financial Report Row Group");
                    AccSchedule.Run();
                end;
            }
            action(EditColumnGroup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Column Definition';
                Ellipsis = false;
                Image = Edit;
                ToolTip = 'Edit the column definition of the selected financial report.';

                trigger OnAction()
                var
                    ColumnLayout: Page "Column Layout";
                begin
                    ColumnLayout.SetColumnLayoutName(Rec."Financial Report Column Group");
                    ColumnLayout.Run();
                end;
            }
            action(CopyFinancialReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Report Definition';
                Image = Copy;
                Scope = Repeater;
                ToolTip = 'Create a copy of the selected financial report definition.';

                trigger OnAction()
                var
                    FinancialReport: Record "Financial Report";
                begin
                    CurrPage.SetSelectionFilter(FinancialReport);
                    REPORT.RunModal(REPORT::"Copy Financial Report", true, true, FinancialReport);
                end;
            }
            action(ImportFinancialReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Report Definition';
                Image = Import;
                Scope = Repeater;
                ToolTip = 'Import a RapidStart configuration package that contains the definition for a financial report. Importing a financial report definition lets you share it, for example, with another business unit. This requires that the financial report definition has been exported.';

                trigger OnAction()
                var
                    FinancialReportMgt: Codeunit "Financial Report Mgt.";
                begin
                    FinancialReportMgt.XMLExchangeImport(Rec);
                end;
            }
            action(ExportFinancialReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Report Definition';
                Image = Export;
                Scope = Repeater;
                ToolTip = 'Export the definition for the selected financial report to a RapidStart configuration package. Exporting a financial report definition lets you share it with another business unit.';

                trigger OnAction()
                var
                    FinancialReportMgt: Codeunit "Financial Report Mgt.";
                begin
                    FinancialReportMgt.XMLExchangeExport(Rec);
                end;
            }
        }
        area(navigation)
        {
            action(Overview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Report Definition';
                Ellipsis = false;
                Image = Edit;
                AboutTitle = 'Edit Financial Report';
                AboutText = 'This action will open the financial report in edit mode, where all changes are visible to other users';
                ToolTip = 'Edit the default settings (such as row/column definitions to be used) on the selected financial report.';
                trigger OnAction()
                var
                    AccSchedOverview: Page "Acc. Schedule Overview";
                begin
                    AccSchedOverview.SetViewOnlyMode(false);
                    AccSchedOverview.SetFinancialReportName(Rec.Name);
                    AccSchedOverview.Run();
                end;
            }
        }
        area(reporting)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print/PDF';
                Ellipsis = false;
                Image = Print;
                Scope = Repeater;
                ToolTip = 'Prepare to print or get a PDF of the selected report. A report request window opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    FinancialReportMgt: Codeunit "Financial Report Mgt.";
                begin
                    FinancialReportMgt.Print(Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ViewFinancialReport_Promoted; ViewFinancialReport) { }
            actionref(Print_Promoted; Print) { }

            group(Category_Edit)
            {
                Caption = 'Edit definitions';
                actionref(Overview_Promoted; Overview) { }
                actionref(EditRowGroup_Promoted; EditRowGroup) { }
                actionref(EditColumnGroup_Promoted; EditColumnGroup) { }
            }
            group(CopyExportImport)
            {
                Caption = 'Copy/Export/Import';
                actionref(CopyFinancialReport_Promoted; CopyFinancialReport) { }
                actionref(ExportFinancialReport_Promoted; ExportFinancialReport) { }
                actionref(ImportFinancialReport_Promoted; ImportFinancialReport) { }
            }
        }
    }

    trigger OnInit()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReportMgt.Initialize();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateCalculatedFields();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateCalculatedFields();
    end;

    local procedure UpdateCalculatedFields()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
    begin
        Clear(AnalysisViewColumn);
        Clear(AnalysisViewRow);
        if Rec."Financial Report Row Group" <> '' then
            if AccScheduleName.Get(Rec."Financial Report Row Group") then
                AnalysisViewRow := AccScheduleName."Analysis View Name";

        if Rec."Financial Report Column Group" <> '' then
            if ColumnLayoutName.Get(Rec."Financial Report Column Group") then
                AnalysisViewColumn := ColumnLayoutName."Analysis View Name";
    end;

    var
        AnalysisViewRow: Text;
        AnalysisViewColumn: Text;
}