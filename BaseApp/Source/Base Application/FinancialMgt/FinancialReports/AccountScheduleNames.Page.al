namespace Microsoft.Finance.FinancialReports;

page 103 "Account Schedule Names"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Row Definitions';
    PageType = List;
    SourceTable = "Acc. Schedule Name";
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
                    ToolTip = 'Specifies the name of the row definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the row definition.';
                }
#if not CLEAN22
                field("Default Column Layout"; Rec."Default Column Layout")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a column layout name that you want to use as a default for this account schedule.';
                    ObsoleteReason = 'This relation is now stored in the field Financial Report Column Group of the table Financial Reports';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';
                    Visible = false;
                }
#endif
                field(Standardized; Rec.Standardized)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the account schedule must be printed on a preprinted standardized form issued by the mercantile register.';
                }
                field("Analysis View Name"; Rec."Analysis View Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the analysis view you want the row definitions to be based on.';
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
            action(EditAccountSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Row Definition';
                Image = Edit;
                ShortCutKey = 'Return';
                ToolTip = 'Change the row definition based on the current row definition.';

                trigger OnAction()
                var
                    AccSchedule: Page "Account Schedule";
                begin
                    AccSchedule.SetAccSchedName(Rec.Name);
                    AccSchedule.Run();
                end;
            }
#if not CLEAN22
            action(EditColumnLayoutSetup)
            {
                ObsoleteReason = 'This relation is now stored in the field Financial Report Column Group from the table Financial Report';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                Visible = false;
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Column Definition';
                Ellipsis = true;
                Image = SetupColumns;
                ToolTip = 'Create or change the column layout for the current account schedule name.';

                trigger OnAction()
                var
                    ColumnLayout: Page "Column Layout";
                begin
                    ColumnLayout.SetColumnLayoutName(Rec."Default Column Layout");
                    ColumnLayout.Run();
                end;
            }
#endif
            action(CopyAccountSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Row Definition';
                Image = Copy;
                Scope = Repeater;
                ToolTip = 'Create a copy of the current row definition.';

                trigger OnAction()
                var
                    AccScheduleName: Record "Acc. Schedule Name";
                begin
                    CurrPage.SetSelectionFilter(AccScheduleName);
                    REPORT.RunModal(REPORT::"Copy Account Schedule", true, true, AccScheduleName);
                end;
            }
            action(ImportAccountSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Row Definition';
                Image = Import;
                Scope = Repeater;
                ToolTip = 'Import a RapidStart configuration package that contains settings for a set of row definitions. Importing row definitions lets you share them, for example, with another business unit. This requires that the row definition has been exported.';

                trigger OnAction()
                begin
                    Rec.Import();
                end;
            }
            action(ExportAccountSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export Row Definition';
                Image = Export;
                Scope = Repeater;
                ToolTip = 'Export settings for the selected rows definition to a RapidStart configuration package. Exporting a rows definitions lets you share it with another business unit.';

                trigger OnAction()
                begin
                    Rec.Export();
                end;
            }
        }
        area(navigation)
        {
#if not CLEAN22
            action(Overview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Report';
                Ellipsis = true;
                Image = ViewDetails;
                ToolTip = 'See an overview of the current account schedule based on the current account schedule name and column layout.';
                Visible = false;
                ObsoleteReason = 'This page is now opened from Financial Reports Page intead (Overview action).';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                trigger OnAction()
                var
                    AccSchedOverview: Page "Acc. Schedule Overview";
                begin
                    AccSchedOverview.SetAccSchedName(Rec.Name);
                    AccSchedOverview.Run();
                end;
            }
#endif
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                Visible = false;
                action("Export Schedules to ASC format")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Schedules to ASC format';
                    Image = ExportElectronicDocument;
                    RunObject = Report "Export Schedules to ASC format";
                    ToolTip = 'Export the account schedule data to a digital file format approved by the local tax authorities for the following annual reports: Balance de Situación Abreviado, Balance de Situación Normal, Cuenta de PyG Abreviado, Cuenta de PyG Normal.';
                }
            }
        }
#if not CLEAN22
        area(reporting)
        {
            ObsoleteReason = 'AccScheduleName is no longer printable directly as they are only row definitions, print instead related Financial Report by calling directly the Account Schedule Report with SetFinancialReportName or SetFinancialReportNameNonEditable.';
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Scope = Repeater;
                Visible = false;
                ObsoleteReason = 'AccScheduleName is no longer printable directly as they are only row definitions, print instead related Financial Report by calling directly the Account Schedule Report with SetFinancialReportName or SetFinancialReportNameNonEditable.';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';
                trigger OnAction()
                begin
                    Rec.Print();
                end;
            }
        }
#endif
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

#if not CLEAN22
                actionref(Overview_Promoted; Overview)
                {
                    ObsoleteReason = 'This page is now opened from Financial Reports Page instead (Overview action).';
                    ObsoleteState = Pending;
                    ObsoleteTag = '22.0';
                }
#endif
                actionref(EditAccountSchedule_Promoted; EditAccountSchedule)
                {
                }
#if not CLEAN22
                actionref(EditColumnLayoutSetup_Promoted; EditColumnLayoutSetup)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This relation is now stored in the field Financial Report Column Group from the table Financial Report';
                    ObsoleteTag = '22.0';
                }
#endif
                actionref(CopyAccountSchedule_Promoted; CopyAccountSchedule)
                {
                }
                actionref(ExportAccountSchedule_Promoted; ExportAccountSchedule)
                {
                }
                actionref(ImportAccountSchedule_Promoted; ImportAccountSchedule)
                {
                }
                actionref("Export Schedules to ASC format_Promoted"; "Export Schedules to ASC format")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';

#if not CLEAN22
                actionref(Print_Promoted; Print)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'AccScheduleName is no longer printable directly as they are only row definitions, print instead related Financial Report by calling directly the Account Schedule Report with SetFinancialReportName or SetFinancialReportNameNonEditable.';
                    ObsoleteTag = '22.0';
                }
#endif
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }
}

