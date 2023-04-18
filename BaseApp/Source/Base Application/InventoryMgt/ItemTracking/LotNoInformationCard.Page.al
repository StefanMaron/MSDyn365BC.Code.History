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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a lot number information record is created.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies this number from the Tracking Specification table when a lot number information record is created.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a description of the lot no. information record.';
                }
                field("Test Quality"; Rec."Test Quality")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quality of a given lot if you have inspected the items.';
                }
                field("Certificate Number"; Rec."Certificate Number")
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
                field("Expired Inventory"; Rec."Expired Inventory")
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
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'View serial or lot numbers that are assigned to items.';

                    trigger OnAction()
                    var
                        ItemTrackingSetup: Record "Item Tracking Setup";
                        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                    begin
                        ItemTrackingSetup."Lot No." := "Lot No.";
                        ItemTrackingDocMgt.ShowItemTrackingForEntity(0, '', "Item No.", "Variant Code", '', ItemTrackingSetup);
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
                        ItemTracing.FindRecords();
                        ItemTracing.RunModal();
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
                        FocusOnRecord.SetRange("Lot No.", TrackingSpecification."Lot No.");

                        LotNoInfoList.SetTableView(ShowRecords);

                        if FocusOnRecord.FindFirst() then
                            LotNoInfoList.SetRecord(FocusOnRecord);
                        if LotNoInfoList.RunModal() = ACTION::LookupOK then begin
                            LotNoInfoList.GetRecord(SelectedRecord);
                            ItemTrackingMgt.CopyLotNoInformation(SelectedRecord, "Lot No.");
                        end;
                    end;
                }
            }
            action(Navigate)
            {
                ApplicationArea = ItemTracking;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                var
                    ItemTrackingSetup: Record "Item Tracking Setup";
                    Navigate: Page Navigate;
                begin
                    ItemTrackingSetup."Lot No." := Rec."Lot No.";
                    Navigate.SetTracking(ItemTrackingSetup);
                    Navigate.Run();
                end;
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
                actionref(CopyInfo_Promoted; CopyInfo)
                {
                }
            }
            group("Category_Lot No.")
            {
                Caption = 'Lot No.';

                actionref("Item &Tracking Entries_Promoted"; "Item &Tracking Entries")
                {
                }
                actionref("&Item Tracing_Promoted"; "&Item Tracing")
                {
                }
                actionref(Comment_Promoted; Comment)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetFilter("Date Filter", '>%1&<=%2', 0D, WorkDate());
        if ShowButtonFunctions then
            ButtonFunctionsVisible := true;
    end;

    var
        ShowButtonFunctions: Boolean;
        [InDataSet]
        ButtonFunctionsVisible: Boolean;

    protected var
        TrackingSpecification: Record "Tracking Specification";

    procedure Init(CurrentTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification := CurrentTrackingSpecification;
        ShowButtonFunctions := true;
    end;

    procedure InitWhse(CurrentTrackingSpecification: Record "Whse. Item Tracking Line")
    begin
        TrackingSpecification."Lot No." := CurrentTrackingSpecification."Lot No.";
        ShowButtonFunctions := true;

        OnAfterInitWhse(TrackingSpecification, CurrentTrackingSpecification);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitWhse(var TrackingSpecification: Record "Tracking Specification"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;
}

