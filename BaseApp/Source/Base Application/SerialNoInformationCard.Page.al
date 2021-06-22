page 6504 "Serial No. Information Card"
{
    Caption = 'Serial No. Information Card';
    PageType = Card;
    PopulateAllFields = true;
    SourceTable = "Serial No. Information";

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
                    ToolTip = 'Specifies the number that is copied from the Tracking Specification table, when a serial number information record is created.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a serial number information record is created.';
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a description of the serial no. information record.';
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
                field(Control19; Inventory)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory quantity of the specified serial number.';
                }
                field("Expired Inventory"; "Expired Inventory")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the inventory of the serial number with an expiration date before the posting date on the associated document.';
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
            group("&Serial No.")
            {
                Caption = '&Serial No.';
                Image = SerialNo;
                action("Item &Tracking Entries")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View serial or lot numbers that are assigned to items.';

                    trigger OnAction()
                    var
                        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                    begin
                        ItemTrackingDocMgt.ShowItemTrackingForMasterData(0, '', "Item No.", "Variant Code", "Serial No.", '', '');
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Comment';
                    Image = ViewComments;
                    RunObject = Page "Item Tracking Comments";
                    RunPageLink = Type = CONST("Serial No."),
                                  "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Serial/Lot No." = FIELD("Serial No.");
                    ToolTip = 'View or add comments for the record.';
                }
                separator(Action24)
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
                        ItemTracingBuffer.SetRange("Serial No.", "Serial No.");
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
                    ToolTip = 'Copy the information record from the old serial number.';

                    trigger OnAction()
                    var
                        SelectedRecord: Record "Serial No. Information";
                        ShowRecords: Record "Serial No. Information";
                        FocusOnRecord: Record "Serial No. Information";
                        ItemTrackingMgt: Codeunit "Item Tracking Management";
                        SerialNoInfoList: Page "Serial No. Information List";
                    begin
                        ShowRecords.SetRange("Item No.", "Item No.");
                        ShowRecords.SetRange("Variant Code", "Variant Code");

                        FocusOnRecord.Copy(ShowRecords);
                        FocusOnRecord.SetRange("Serial No.", TrackingSpec."Serial No.");

                        SerialNoInfoList.SetTableView(ShowRecords);

                        if FocusOnRecord.FindFirst then
                            SerialNoInfoList.SetRecord(FocusOnRecord);
                        if SerialNoInfoList.RunModal = ACTION::LookupOK then begin
                            SerialNoInfoList.GetRecord(SelectedRecord);
                            ItemTrackingMgt.CopySerialNoInformation(SelectedRecord, "Serial No.");
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
                    Navigate.SetTracking("Serial No.", '');
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
        TrackingSpec."Serial No." := CurrentTrackingSpec."Serial No.";
        ShowButtonFunctions := true;
    end;
}

