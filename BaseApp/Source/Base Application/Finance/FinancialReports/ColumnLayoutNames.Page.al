namespace Microsoft.Finance.FinancialReports;

page 488 "Column Layout Names"
{
    Caption = 'Column Definitions';
    PageType = List;
    SourceTable = "Column Layout Name";

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
                    ToolTip = 'Specifies the name of the financial report columns definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the financial report columns definition.';
                }
                field("Analysis View Name"; Rec."Analysis View Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the analysis view you want the column layout to be based on.';
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
            action(EditColumnLayoutSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Column Definition';
                Ellipsis = true;
                Image = SetupColumns;
                ToolTip = 'Create or change the column definition for the current financial report name.';

                trigger OnAction()
                var
                    ColumnLayout: Page "Column Layout";
                begin
                    ColumnLayout.SetColumnLayoutName(Rec.Name);
                    ColumnLayout.Run();
                end;
            }
            action(CopyColumnLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Column Definition';
                Image = Copy;
                Scope = Repeater;
                ToolTip = 'Create a copy of the current column definition.';

                trigger OnAction()
                var
                    ColumnLayoutName: Record "Column Layout Name";
                begin
                    CurrPage.SetSelectionFilter(ColumnLayoutName);
                    Report.RunModal(Report::"Copy Column Layout", true, true, ColumnLayoutName);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(EditColumnLayoutSetup_Promoted; EditColumnLayoutSetup)
                {
                }
                actionref(CopyColumnLayout_Promoted; CopyColumnLayout)
                {
                }
            }
        }
    }
}

