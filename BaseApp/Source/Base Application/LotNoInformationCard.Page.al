page 6505 "Lot No. Information Card"
{
    Caption = 'Lot No. Information Card';
    PageType = Card;
    PopulateAllFields = true;
    SourceTable = "Lot No. Information";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Item No."; "Item No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a lot number information record is created.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a lot number information record is created.';
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemTracking;
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
            }
            group(Inventory)
            {
                Caption = 'Inventory';
                field(InventoryField; Inventory)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory quantity of the specified lot number.';
                }
                field("Expired Inventory"; "Expired Inventory")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory of the lot number with an expiration date before the posting date on the associated document.';
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
                separator(Action28)
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
            group(ButtonFunctions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                Visible = ButtonFunctionsVisible;
                action(CopyInfo)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Copy &Info';
                    Ellipsis = true;
                    Image = CopySerialNo;
                    ToolTip = 'Copy the information record from the old lot number.';

                    trigger OnAction()
                    var
                        SelectedRecord: Record "Lot No. Information";
                        ShowRecords: Record "Lot No. Information";
                        FocusOnRecord: Record "Lot No. Information";
                        ItemTrackingMgt: Codeunit "Item Tracking Management";
                        LotNoInfoList: Page "Lot No. Information List";
                    begin
                        ShowRecords.SetRange("Item No.", "Item No.");
                        ShowRecords.SetRange("Variant Code", "Variant Code");

                        FocusOnRecord.Copy(ShowRecords);
                        FocusOnRecord.SetRange("Lot No.", TrackingSpec."Lot No.");

                        LotNoInfoList.SetTableView(ShowRecords);

                        if FocusOnRecord.FindFirst then
                            LotNoInfoList.SetRecord(FocusOnRecord);
                        if LotNoInfoList.RunModal = ACTION::LookupOK then begin
                            LotNoInfoList.GetRecord(SelectedRecord);
                            ItemTrackingMgt.CopyLotNoInformation(SelectedRecord, "Lot No.");
                        end;
                    end;
                }
            }
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

    trigger OnOpenPage()
    begin
        SetFilter("Date Filter", '..%1', WorkDate);
        if ShowButtonFunctions then
            ButtonFunctionsVisible := true;
    end;

    var
        TrackingSpec: Record "Tracking Specification";
        ShowButtonFunctions: Boolean;
        [InDataSet]
        ButtonFunctionsVisible: Boolean;

    procedure Init(CurrentTrackingSpec: Record "Tracking Specification")
    begin
        TrackingSpec := CurrentTrackingSpec;
        ShowButtonFunctions := true;
    end;

    procedure InitWhse(CurrentTrackingSpec: Record "Whse. Item Tracking Line")
    begin
        TrackingSpec."Lot No." := CurrentTrackingSpec."Lot No.";
        ShowButtonFunctions := true;

        OnAfterInitWhse(TrackingSpec, CurrentTrackingSpec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitWhse(var TrackingSpecification: Record "Tracking Specification"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;
}

