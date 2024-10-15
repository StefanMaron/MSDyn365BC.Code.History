#if not CLEAN17
page 5883 "Posted Phys. Invt. Order"
{
    ApplicationArea = Warehouse;
    Caption = 'Posted Phys. Invt. Order';
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Pstd. Phys. Invt. Order Hdr";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the No. of the table physical inventory order header.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the Description of the table physical inventory order header.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the Location Code of the table physical inventory order header.';
                }
                field("Person Responsible"; "Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the Person Responsible of the table physical inventory order header.';
                }
                field("No. Finished Recordings"; "No. Finished Recordings")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the No. Finished Recordings.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the Order Date of the table physical inventory order header.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the Posting Date of the table physical inventory order header.';
                }
                field("Pre-Assigned No."; "Pre-Assigned No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the number of the physical inventory header, from which the posted physical inventory order was posted.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            part(OrderLines; "Posted Phys. Invt. Order Subf.")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Document No." = FIELD("No.");
                SubPageView = SORTING("Document No.", "Line No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action(Statistics)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Posted Phys. Invt. Order Stat.";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'Show statistics.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Phys. Inventory Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Posted Order"),
                                  "Order No." = FIELD("No."),
                                  "Recording No." = CONST(0);
                    ToolTip = 'Show comments.';
                }
                action("&Recordings")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Recordings';
                    Image = Document;
                    RunObject = Page "Posted Phys. Invt. Rec. List";
                    RunPageLink = "Order No." = FIELD("No.");
                    RunPageView = SORTING("Order No.", "Recording No.");
                    ToolTip = 'Show recordings.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'Show dimensions.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
            }
        }
        area(processing)
        {
            action(Print)
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print order.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintPostedInvtOrder(Rec, true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Warehouse;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Shift+Ctrl+I';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
        area(reporting)
        {
            action("Posted Phys. Invt. Order Diff.")
            {
                ApplicationArea = Warehouse;
                Caption = 'Posted Phys. Invt. Order Diff.';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Posted Phys. Invt. Order Diff.";
                ToolTip = 'View or print the list of differences after counting.';
            }
            action("Phys. Invt. Counting Document")
            {
                ApplicationArea = Warehouse;
                Caption = 'Phys. Invt. Counting Document';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                ToolTip = 'Open the report for physical inventory counting document';
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '17.0';
                Visible = false;

                trigger OnAction()
                var
                    PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
                begin
                    // NAVCZ
                    PhysInventoryLedgerEntry.SetRange("Document No.", "No.");
                    PhysInventoryLedgerEntry.SetRange("Posting Date", "Posting Date");
                    REPORT.Run(REPORT::"Phys. Invt. Counting Document", true, false, PhysInventoryLedgerEntry);
                end;
            }
        }
    }
}

#endif