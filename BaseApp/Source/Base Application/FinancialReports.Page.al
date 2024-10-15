page 108 "Financial Reports"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Reports';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Print/Send';
    SourceTable = "Financial Report";
    AdditionalSearchTerms = 'Account Schedules';
    UsageCategory = Lists;

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
                    ToolTip = 'Specifies the name of the financial report.';
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
                    ToolTip = 'Specifies a description of the financial report.';
                }
                field("Financial Report Row Group"; Rec."Financial Report Row Group")
                {
                    Caption = 'Row Definition';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the row definition to be used for this financial report.';
                }
                field("Financial Report Column Group"; Rec."Financial Report Column Group")
                {
                    Caption = 'Column Definition';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the column definition to be used for this financial report.';
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
            action(EditRowGroup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Row Definition';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Return';
                ToolTip = 'Edit the row definition of this financial report.';

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
                Ellipsis = true;
                Image = SetupColumns;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Create or change the column definition of this financial report.';

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
                Caption = 'Copy Financial Report';
                Image = Copy;
                Promoted = true;
                PromotedCategory = Process;
                Scope = Repeater;
                ToolTip = 'Create a copy of the current financial report.';

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
                Caption = 'Import Financial Report';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = false;
                Scope = Repeater;
                ToolTip = 'Import a RapidStart configuration package that contains settings for a financial report. Importing financial reports lets you share them, for example, with another business unit. This requires that the financial report has been exported.';

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
                Caption = 'Export Financial Report';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = false;
                Scope = Repeater;
                ToolTip = 'Export settings for the selected financial report to a RapidStart configuration package. Exporting a financial report lets you share it with another business unit.';

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
                Caption = 'Edit Financial Report';
                Ellipsis = true;
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Edit the selected financial report.';

                trigger OnAction()
                var
                    AccSchedOverview: Page "Acc. Schedule Overview";
                begin
                    AccSchedOverview.SetViewOnlyMode(false);
                    AccSchedOverview.SetFinancialReportName(Name);
                    AccSchedOverview.Run();
                end;
            }
        }
        area(reporting)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    FinancialReportMgt: Codeunit "Financial Report Mgt.";
                begin
                    FinancialReportMgt.Print(Rec);
                end;
            }
        }
    }

    trigger OnInit()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReportMgt.Initialize();
    end;

}