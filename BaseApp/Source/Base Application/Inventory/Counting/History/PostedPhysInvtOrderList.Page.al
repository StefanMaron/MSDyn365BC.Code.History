namespace Microsoft.Inventory.Counting.History;

using Microsoft.Inventory.Counting.Reports;

page 5884 "Posted Phys. Invt. Order List"
{
    ApplicationArea = Warehouse;
    Caption = 'Posted Physical Inventory Orders';
    CardPageID = "Posted Phys. Invt. Order";
    Editable = false;
    PageType = List;
    SourceTable = "Pstd. Phys. Invt. Order Hdr";
    SourceTableView = sorting("Posting Date")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the No. of the table physical inventory order header.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Description of the table physical inventory order header.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Order Date of the table physical inventory order header.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Posting Date of the table physical inventory order header.';
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Person Responsible of the table physical inventory order header.';
                }
                field("No. Finished Recordings"; Rec."No. Finished Recordings")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the No. Finished Recordings.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Navigate)
            {
                ApplicationArea = Warehouse;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
        }
        area(reporting)
        {
            action("Phys. Inventory Order Diff.")
            {
                ApplicationArea = Warehouse;
                Caption = 'Phys. Inventory Order Diff.';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Phys. Invt. Order Diff. List";
                ToolTip = 'View or print the list of differences after counting.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Navigate_Promoted; Navigate)
                {
                }
            }
        }
    }
}

