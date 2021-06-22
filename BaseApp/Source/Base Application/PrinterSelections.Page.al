page 64 "Printer Selections"
{
    ApplicationArea = Suite;
    Caption = 'Printer Selections';
    PageType = List;
    SourceTable = "Printer Selection";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user for whom you want to define permissions.';
                }
                field("Report ID"; "Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; "Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field("Printer Name"; "Printer Name")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Printers;
                    ToolTip = 'Specifies the printer that the user will be allowed to use or on which the report will be printed.';
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
        area(Navigation)
        {
            action(OpenPrinterManagement)
            {
                ApplicationArea = All;
                Caption = 'Printer Management';
                Image = Open;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Open the Printer Management page.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Printer Management");
                end;
            }
        }
    }
}

