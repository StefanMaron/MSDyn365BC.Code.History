page 5884 "Posted Phys. Invt. Order List"
{
    ApplicationArea = Warehouse;
    Caption = 'Posted Physical Inventory Orders';
    CardPageID = "Posted Phys. Invt. Order";
    Editable = false;
    PageType = List;
    SourceTable = "Pstd. Phys. Invt. Order Hdr";
    SourceTableView = SORTING("Posting Date")
                      ORDER(Descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the No. of the table physical inventory order header.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Description of the table physical inventory order header.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Order Date of the table physical inventory order header.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Posting Date of the table physical inventory order header.';
                }
                field("Person Responsible"; "Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Person Responsible of the table physical inventory order header.';
                }
                field("No. Finished Recordings"; "No. Finished Recordings")
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
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Run Navigate.';

                trigger OnAction()
                begin
                    Navigate;
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
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Phys. Invt. Order Diff. List";
                ToolTip = 'View or print the list of differences after counting.';
            }
        }
    }
}

