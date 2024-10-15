namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Inventory.Counting.Reports;

page 5876 "Physical Inventory Orders"
{
    ApplicationArea = Warehouse;
    Caption = 'Physical Inventory Orders';
    CardPageID = "Physical Inventory Order";
    Editable = false;
    PageType = List;
    SourceTable = "Phys. Invt. Order Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a number for the physical inventory order.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a short description of the physical inventory order.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the physical inventory order is open or finished.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the order date for the physical inventory order.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the posting date of the physical inventory order.';
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the person who is responsible for performing this physical inventory order.';
                }
                field("No. Finished Recordings"; Rec."No. Finished Recordings")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of entered physical inventory recording documents that have the status set to finished.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
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
            action("Phys. Invt. Order - Test")
            {
                ApplicationArea = Warehouse;
                Caption = 'Phys. Invt. Order - Test';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Phys. Invt. Order - Test";
                ToolTip = 'View the result of posting the counted inventory quantities before you actually post.';
            }
        }
        area(Promoted)
        {
        }
    }
}

