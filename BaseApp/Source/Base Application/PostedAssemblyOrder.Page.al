page 920 "Posted Assembly Order"
{
    Caption = 'Posted Assembly Order';
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Order,Print/Send';
    SourceTable = "Posted Assembly Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the assembly order that the posted assembly order line originates from.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted assembly item.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the posted assembly item.';
                }
                group(Control8)
                {
                    ShowCaption = false;
                    field(Quantity; Quantity)
                    {
                        ApplicationArea = Assembly;
                        ToolTip = 'Specifies how many units of the assembly item were posted with this posted assembly order.';
                    }
                    field("Unit of Measure Code"; "Unit of Measure Code")
                    {
                        ApplicationArea = Assembly;
                        ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    }
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order was posted.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembled item is due to be available for use.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date on which the posted assembly order started.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the posted assembly order finished, which means the date on which all assembly items were output.';
                }
                field("Assemble to Order"; "Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the posted assembly order was linked to a sales order, which indicates that the item was assembled to order.';

                    trigger OnDrillDown()
                    begin
                        ShowAsmToOrder;
                    end;
                }
                field(Reversed; Reversed)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the posted assembly order has been undone.';
                }
            }
            part(Lines; "Posted Assembly Order Subform")
            {
                ApplicationArea = Assembly;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies to which location the assembly item was output from this posted assembly order header.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies to which bin the assembly item was posted as output on the posted assembly order header.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Cost Amount"; "Cost Amount")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the total unit cost of the posted assembly order.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control21; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control22; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Statistics)
            {
                ApplicationArea = Assembly;
                Caption = 'Statistics';
                Image = Statistics;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ShortCutKey = 'F7';
                ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                trigger OnAction()
                begin
                    ShowStatistics;
                end;
            }
            action(Dimensions)
            {
                AccessByPermission = TableData Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                trigger OnAction()
                begin
                    ShowDimensions;
                end;
            }
            action("Item &Tracking Lines")
            {
                ApplicationArea = ItemTracking;
                Caption = 'Item &Tracking Lines';
                Image = ItemTrackingLines;
                ShortCutKey = 'Shift+Ctrl+I';
                ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                trigger OnAction()
                begin
                    ShowItemTrackingLines;
                end;
            }
            action(Comments)
            {
                ApplicationArea = Comments;
                Caption = 'Co&mments';
                Image = ViewComments;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Assembly Comment Sheet";
                RunPageLink = "Document Type" = CONST("Posted Assembly"),
                              "Document No." = FIELD("No."),
                              "Document Line No." = CONST(0);
                ToolTip = 'View or add comments for the record.';
            }
        }
        area(processing)
        {
            action(Print)
            {
                ApplicationArea = Assembly;
                Caption = 'Print';
                Image = Print;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    PostedAssemblyHeader: Record "Posted Assembly Header";
                begin
                    CurrPage.SetSelectionFilter(PostedAssemblyHeader);
                    PostedAssemblyHeader.PrintRecords(true);
                end;
            }
            action(Navigate)
            {
                ApplicationArea = Assembly;
                Caption = 'Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
            action("Undo Post")
            {
                ApplicationArea = Assembly;
                Caption = 'Undo Assembly';
                Enabled = UndoPostEnabledExpr;
                Image = Undo;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Cancel the posting of the assembly order. A set of corrective item ledger entries is created to reverse the original entries. Each positive output entry for the assembly item is reversed by a negative output entry. Each negative consumption entry for an assembly component is reversed by a positive consumption entry. Fixed cost application is automatically created between the corrective and original entries to ensure exact cost reversal.';

                trigger OnAction()
                begin
                    CODEUNIT.Run(CODEUNIT::"Pstd. Assembly - Undo (Yes/No)", Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UndoPostEnabledExpr := not Reversed and not IsAsmToOrder;
    end;

    var
        [InDataSet]
        UndoPostEnabledExpr: Boolean;
}

