page 5875 "Physical Inventory Order"
{
    Caption = 'Physical Inventory Order';
    PageType = Document;
    SourceTable = "Phys. Invt. Order Header";

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
                    ToolTip = 'Specifies the number for the physical inventory order.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a short description of the physical inventory order.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location where items on this line should be counted.';
                }
                field("Person Responsible"; "Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the person who is responsible for performing this physical inventory order.';
                }
                field("No. Finished Recordings"; "No. Finished Recordings")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of entered physical inventory recording documents that have the status set to Finished.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the order date for the physical inventory order.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the posting date of the physical inventory order.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the physical inventory order is open or finished.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            part(OrderLines; "Physical Inventory Order Subf.")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Document No." = FIELD("No.");
                SubPageView = SORTING("Document No.", "Line No.");
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
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
                    RunObject = Page "Phys. Invt. Order Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information for the physical inventory order.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Phys. Inventory Comment Sheet";
                    RunPageLink = "Document Type" = CONST(Order),
                                  "Order No." = FIELD("No."),
                                  "Recording No." = CONST(0);
                    ToolTip = 'View or edit comments for the physical inventory order.';
                }
                action("&Recordings")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Recordings';
                    Image = Document;
                    RunObject = Page "Phys. Inventory Recording List";
                    RunPageLink = "Order No." = FIELD("No.");
                    RunPageView = SORTING("Order No.", "Recording No.");
                    ToolTip = 'Open any related physical inventory recordings, the documents that are used to record the actual counting.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as a project or department, that are assigned to the physical inventory order for financial analysis.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.SaveRecord;
                    end;
                }
                action("Show &Duplicate Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show &Duplicate Lines';
                    Image = CheckDuplicates;
                    RunObject = Codeunit "Phys. Invt.-Show Duplicates";
                    ToolTip = 'Show lines that have the same value in the Item No., Variant Code, Location Code, and Bin Code fields.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CalculateLines)
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Calculate Lines';
                    Ellipsis = true;
                    Image = CalculateLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Add physical inventory lines for items that are currently recorded in inventory.';

                    trigger OnAction()
                    var
                        CalcPhysInvtOrderLines: Report "Calc. Phys. Invt. Order Lines";
                    begin
                        CalcPhysInvtOrderLines.SetPhysInvtOrderHeader(Rec);
                        CalcPhysInvtOrderLines.RunModal;
                        Clear(CalcPhysInvtOrderLines);
                    end;
                }
                action(CalculateCountingPeriod)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate Counting &Period';
                    Ellipsis = true;
                    Image = CalculateCalendar;
                    ToolTip = 'Add physical inventory order lines for items and SKUs that are set up with counting periods. See the Phys Invt Counting Period Code field on the item card or SKU card.';

                    trigger OnAction()
                    var
                        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
                    begin
                        PhysInvtCountMgt.InitFromPhysInvtOrder(Rec);
                        PhysInvtCountMgt.Run;
                        Clear(PhysInvtCountMgt);
                    end;
                }
                action(CalculateLinesBins)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate Lines (&Bins)';
                    Ellipsis = true;
                    Image = CalculateBinReplenishment;
                    ToolTip = 'Add physical inventory lines for items that are currently recorded in bins in the warehouse.';

                    trigger OnAction()
                    var
                        CalcPhysInvtOrderBins: Report "Calc. Phys. Invt. Order (Bins)";
                    begin
                        CalcPhysInvtOrderBins.SetPhysInvtOrderHeader(Rec);
                        CalcPhysInvtOrderBins.RunModal;
                        Clear(CalcPhysInvtOrderBins);
                    end;
                }
                action(CopyDocument)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Copy &Document';
                    Ellipsis = true;
                    Image = CopyDocument;
                    ToolTip = 'Copy Document.';

                    trigger OnAction()
                    var
                        CopyPhysInvtOrder: Report "Copy Phys. Invt. Order";
                    begin
                        CopyPhysInvtOrder.SetPhysInvtOrderHeader(Rec);
                        CopyPhysInvtOrder.RunModal;
                        Clear(CopyPhysInvtOrder);
                    end;
                }
                action("Calc. &Qty. Expected")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calc. &Qty. Expected';
                    Ellipsis = true;
                    Image = AllLines;
                    RunObject = Codeunit "Phys. Invt.-Calc. Qty. All";
                    ToolTip = 'Update the value in the Qty. Expected (Base) field on the lines with any inventory changes made since you created the order. When you have used this function, the Qty. Exp. Calculated check box is selected.';
                }
                action(MakeNewRecording)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Make New &Recording';
                    Ellipsis = true;
                    Image = NewDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create a physical inventory recording document for the lines on the order. On the request page that appears, you can select to only create recording lines for items that are not already on other recordings for the order.';

                    trigger OnAction()
                    begin
                        PhysInvtOrderHeader := Rec;
                        PhysInvtOrderHeader.SetRecFilter;
                        REPORT.RunModal(REPORT::"Make Phys. Invt. Recording", true, false, PhysInvtOrderHeader);
                    end;
                }
                action("Fi&nish")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Fi&nish';
                    Ellipsis = true;
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Codeunit "Phys. Invt. Order-Finish (Y/N)";
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Indicate that the counting is completed. This is only possible if all related recordings are set to Finished.';
                }
                action("Reo&pen")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Reo&pen';
                    Ellipsis = true;
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Codeunit "Phys. Invt. Order-Reopen (Y/N)";
                    ToolTip = 'Change the status of the physical inventory order from Finished to Open.';
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(TestReport)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Preview the inventory counting that will be recorded when you choose the Post action.';

                    trigger OnAction()
                    begin
                        DocPrint.PrintInvtOrderTest(Rec, true);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Update the involved item ledger entries with the counted inventory quantities.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post (Y/N)", Rec);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Update the involved item ledger entries with the counted inventory and print the Phys. Inventory Order Difference List report, which shows counted quantities compared to expected as negative or positive differences.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post + Print", Rec);
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the Phys. Inventory Order Difference List report, which shows counted quantities compared to expected as negative or positive differences.';

                trigger OnAction()
                begin
                    DocPrint.PrintInvtOrder(Rec, true);
                end;
            }
        }
        area(creation)
        {
            action("New Phys. Inventory Recording")
            {
                ApplicationArea = Warehouse;
                Caption = 'New Phys. Inventory Recording';
                Image = PhysicalInventory;
                Promoted = true;
                PromotedCategory = New;
                RunObject = Page "Phys. Inventory Recording";
                ToolTip = 'Create new physical inventory recording.';
            }
        }
        area(reporting)
        {
            action("Physical Inventory Recording")
            {
                ApplicationArea = Warehouse;
                Caption = 'Physical Inventory Recording';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Phys. Invt. Recording";
                ToolTip = 'Print the first physical inventory recording that exists for the order. The printed document has an empty column in which to write the counted quantities.';
            }
        }
    }

    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        DocPrint: Codeunit "Document-Print";
}

