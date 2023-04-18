page 932 "Assembly Quotes"
{
    ApplicationArea = Assembly;
    Caption = 'Assembly Quotes';
    CardPageID = "Assembly Quote";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Assembly Header";
    SourceTableView = WHERE("Document Type" = FILTER(Quote));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the type of assembly document the record represents in assemble-to-order scenarios.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                    ObsoleteTag = '17.0';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly item.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembled item is due to be available for use.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to start.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to finish.';
                }
                field("Assemble to Order"; Rec."Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the assembly order is linked to a sales order, which indicates that the item is assembled to order.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item that is being assembled with the assembly order.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly item that you expect to assemble with the assembly order.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location to which you want to post output of the assembly item.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin the assembly item is posted to as output and from where it is taken to storage or shipped if it is assembled to a sales order.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly item remain to be posted as assembled output.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                    ObsoleteTag = '17.0';
                }
            }
        }
        area(factboxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Caption = 'RecordLinks';
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
        area(navigation)
        {
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                group(Entries)
                {
                    Caption = 'Entries';
                    Image = Entries;
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                    ObsoleteTag = '17.0';
                    action("Item Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Ledger E&ntries';
                        Image = ItemLedger;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Order Type" = CONST(Assembly),
                                      "Order No." = FIELD("No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the item ledger entries of the item on the document or journal line.';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                        ObsoleteTag = '17.0';
                    }
                    action("Capacity Ledger Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Ledger Entries';
                        Image = CapacityLedger;
                        RunObject = Page "Capacity Ledger Entries";
                        RunPageLink = "Order Type" = CONST(Assembly),
                                      "Order No." = FIELD("No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                        ObsoleteTag = '17.0';
                    }
                    action("Resource Ledger Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Ledger Entries';
                        Image = ResourceLedger;
                        RunObject = Page "Resource Ledger Entries";
                        RunPageLink = "Order Type" = CONST(Assembly),
                                      "Order No." = FIELD("No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ToolTip = 'View the ledger entries for the resource.';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                        ObsoleteTag = '17.0';
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value Entries';
                        Image = ValueLedger;
                        RunObject = Page "Value Entries";
                        RunPageLink = "Order Type" = CONST(Assembly),
                                      "Order No." = FIELD("No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ToolTip = 'View the value entries of the item on the document or journal line.';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                        ObsoleteTag = '17.0';
                    }
                    action("Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Warehouse Entries';
                        Image = BinLedger;
                        RunObject = Page "Warehouse Entries";
                        RunPageLink = "Source Type" = FILTER(83 | 901),
                                      "Source Subtype" = FILTER("1" | "6"),
                                      "Source No." = FIELD("No.");
                        RunPageView = SORTING("Source Type", "Source Subtype", "Source No.");
                        ToolTip = 'View the history of quantities that are registered for the item in warehouse activities. ';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                        ObsoleteTag = '17.0';
                    }
                }
                action("Show Order")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Show Quote';
                    Image = ViewOrder;
                    RunObject = Page "Assembly Quote";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the selected assembly order.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                    ObsoleteTag = '17.0';
                }
            }
            group("Item Availability by")
            {
                Caption = 'Item Availability by';
                Image = ItemAvailability;
                action("Event")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Event';
                    Image = "Event";
                    ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromAsmHeader(Rec, ItemAvailFormsMgt.ByEvent());
                    end;
                }
                action(Period)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Period';
                    Image = Period;
                    ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromAsmHeader(Rec, ItemAvailFormsMgt.ByPeriod());
                    end;
                }
                action(Variant)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant';
                    Image = ItemVariant;
                    ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromAsmHeader(Rec, ItemAvailFormsMgt.ByVariant());
                    end;
                }
                action(Location)
                {
                    AccessByPermission = TableData Location = R;
                    ApplicationArea = Location;
                    Caption = 'Location';
                    Image = Warehouse;
                    ToolTip = 'View the actual and projected quantity of the item per location.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromAsmHeader(Rec, ItemAvailFormsMgt.ByLocation());
                    end;
                }
                action(Lot)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot';
                    Image = LotInfo;
                    RunObject = Page "Item Availability by Lot No.";
                    RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                    ToolTip = 'View the current and projected quantity of the item in each lot.';
                }
                action("BOM Level")
                {
                    ApplicationArea = Assembly;
                    Caption = 'BOM Level';
                    Image = BOMLevel;
                    ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromAsmHeader(Rec, ItemAvailFormsMgt.ByBOM());
                    end;
                }
            }
            group("&Quote")
            {
                Caption = '&Quote';
                Image = Quote;
                action(Statistics)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Assembly Order Statistics";
                    RunPageOnRec = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action("Assembly BOM")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly BOM';
                    Image = AssemblyBOM;
                    RunObject = Page "Assembly BOM";
                    RunPageLink = "Parent Item No." = FIELD("Item No.");
                    ToolTip = 'View or edit the bill of material that specifies which items and resources are required to assemble the assembly item.';
                }
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Assembly Comment Sheet";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "Document No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                ObsoleteState = Pending;
                ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                ObsoleteTag = '17.0';
            }
            group(ReleaseGroup)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        AssemblyHeader: Record "Assembly Header";
                    begin
                        AssemblyHeader := Rec;
                        AssemblyHeader.Find();
                        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document for additional warehouse activity.';

                    trigger OnAction()
                    var
                        AssemblyHeader: Record "Assembly Header";
                        ReleaseAssemblyDoc: Codeunit "Release Assembly Document";
                    begin
                        AssemblyHeader := Rec;
                        AssemblyHeader.Find();
                        ReleaseAssemblyDoc.Reopen(AssemblyHeader);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                ObsoleteTag = '17.0';
                action("P&ost")
                {
                    ApplicationArea = Assembly;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Assembly-Post (Yes/No)", Rec);
                    end;
                }
                action("Post &Batch")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Assembly Orders", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

#if not CLEAN22
                actionref("P&ost_Promoted"; "P&ost")
                {
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                    ObsoleteTag = '17.0';
                }
#endif
#if not CLEAN22
                actionref("Post &Batch_Promoted"; "Post &Batch")
                {
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'It no longer adds value or it has been replaced by something new.';
                    ObsoleteTag = '17.0';
                }
#endif
            }
            group(Category_Category6)
            {
                Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 5.';
                ShowAs = SplitButton;

                actionref(Release_Promoted; Release)
                {
                }
                actionref(Reopen_Promoted; Reopen)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Quote', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
                actionref("Assembly BOM_Promoted"; "Assembly BOM")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'View', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group("Category_Item Availability by")
            {
                Caption = 'Item Availability by';

                actionref(Event_Promoted; "Event")
                {
                }
                actionref(Period_Promoted; Period)
                {
                }
                actionref(Variant_Promoted; Variant)
                {
                }
                actionref(Location_Promoted; Location)
                {
                }
                actionref(Lot_Promoted; Lot)
                {
                }
                actionref("BOM Level_Promoted"; "BOM Level")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 6.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
}
