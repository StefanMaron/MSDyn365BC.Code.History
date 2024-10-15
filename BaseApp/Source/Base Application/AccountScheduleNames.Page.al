page 103 "Account Schedule Names"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Account Schedules';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Print/Send';
    SourceTable = "Acc. Schedule Name";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the account schedule.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the account schedule.';
                }
                field("Default Column Layout"; "Default Column Layout")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a column layout name that you want to use as a default for this account schedule.';
                }
                field(Standardized; Standardized)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the account schedule must be printed on a preprinted standardized form issued by the mercantile register.';
                }
                field("Analysis View Name"; "Analysis View Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the analysis view you want the account schedule to be based on.';
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
                Caption = 'Edit Account Schedule';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ShortCutKey = 'Return';
                ToolTip = 'Change the account schedule based on the current account schedule name.';

                trigger OnAction()
                var
                    AccSchedule: Page "Account Schedule";
                begin
                    AccSchedule.SetAccSchedName(Name);
                    AccSchedule.Run;
                end;
            }
            action(EditColumnLayoutSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Column Layout Setup';
                Ellipsis = true;
                Image = SetupColumns;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Create or change the column layout for the current account schedule name.';

                trigger OnAction()
                var
                    ColumnLayout: Page "Column Layout";
                begin
                    ColumnLayout.SetColumnLayoutName("Default Column Layout");
                    ColumnLayout.Run;
                end;
            }
            action(CopyAccountSchedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Account Schedule';
                Image = Copy;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Create a copy of the current account schedule.';

                trigger OnAction()
                var
                    AccScheduleName: Record "Acc. Schedule Name";
                begin
                    CurrPage.SetSelectionFilter(AccScheduleName);
                    REPORT.RunModal(REPORT::"Copy Account Schedule", true, true, AccScheduleName);
                end;
            }
        }
        area(navigation)
        {
            action(Overview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Overview';
                Ellipsis = true;
                Image = ViewDetails;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'See an overview of the current account schedule based on the current account schedule name and column layout.';

                trigger OnAction()
                var
                    AccSchedOverview: Page "Acc. Schedule Overview";
                begin
                    AccSchedOverview.SetAccSchedName(Name);
                    AccSchedOverview.Run;
                end;
            }
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
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Report "Export Schedules to ASC format";
                    ToolTip = 'Export the account schedule data to a digital file format approved by the local tax authorities for the following annual reports: Balance de Situación Abreviado, Balance de Situación Normal, Cuenta de PyG Abreviado, Cuenta de PyG Normal.';
                }
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
                PromotedCategory = Category4;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    Print;
                end;
            }
        }
    }
}

