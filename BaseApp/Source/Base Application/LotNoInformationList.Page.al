page 6508 "Lot No. Information List"
{
    Caption = 'Lot No. Information List';
    CardPageID = "Lot No. Information Card";
    ApplicationArea = ItemTracking;
    Editable = false;
    PageType = List;
    SourceTable = "Lot No. Information";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a lot number information record is created.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a lot number information record is created.';
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemTracking;
                    Editable = true;
                    ToolTip = 'Specifies a description of the lot no. information record.';
                }
                field("Test Quality"; "Test Quality")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quality of a given lot if you have inspected the items.';
                }
                field("Certificate Number"; "Certificate Number")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number provided by the supplier to indicate that the batch or lot meets the specified requirements.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field(CommentField; Comment)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that a comment has been recorded for the lot number.';
                }
                field(Inventory; Inventory)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory quantity of the specified lot number.';
                    Visible = false;
                }
                field("Expired Inventory"; "Expired Inventory")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory of the lot number with an expiration date before the posting date on the associated document.';
                    Visible = false;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Lot No.")
            {
                Caption = '&Lot No.';
                Image = Lot;
                action("Item &Tracking Entries")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View serial or lot numbers that are assigned to items.';

                    trigger OnAction()
                    var
                        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                    begin
                        ItemTrackingDocMgt.ShowItemTrackingForMasterData(0, '', "Item No.", "Variant Code", '', "Lot No.", '');
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Comment';
                    Image = ViewComments;
                    RunObject = Page "Item Tracking Comments";
                    RunPageLink = Type = CONST("Lot No."),
                                  "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Serial/Lot No." = FIELD("Lot No.");
                    ToolTip = 'View or add comments for the record.';
                }
                separator(Action1102601003)
                {
                }
                action("&Item Tracing")
                {
                    ApplicationArea = ItemTracking;
                    Caption = '&Item Tracing';
                    Image = ItemTracing;
                    ToolTip = 'Trace where a lot or serial number assigned to the item was used, for example, to find which lot a defective component came from or to find all the customers that have received items containing the defective component.';

                    trigger OnAction()
                    var
                        ItemTracingBuffer: Record "Item Tracing Buffer";
                        ItemTracing: Page "Item Tracing";
                    begin
                        Clear(ItemTracing);
                        ItemTracingBuffer.SetRange("Item No.", "Item No.");
                        ItemTracingBuffer.SetRange("Variant Code", "Variant Code");
                        ItemTracingBuffer.SetRange("Lot No.", "Lot No.");
                        ItemTracing.InitFilters(ItemTracingBuffer);
                        ItemTracing.FindRecords;
                        ItemTracing.RunModal;
                    end;
                }
            }
        }
        area(processing)
        {
            action(Navigate)
            {
                ApplicationArea = ItemTracking;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetTracking('', "Lot No.");
                    Navigate.Run;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnOpenPage()
    begin
        SetFilter("Date Filter", '..%1', WorkDate);
    end;

    procedure GetSelectionFilter(): Text
    var
        LotNoInfo: Record "Lot No. Information";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(LotNoInfo);
        exit(SelectionFilterManagement.GetSelectionFilterForLotNoInformation(LotNoInfo));
    end;
}

