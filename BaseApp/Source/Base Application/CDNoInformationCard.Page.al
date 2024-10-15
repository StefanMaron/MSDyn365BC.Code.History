page 12469 "CD No. Information Card"
{
    Caption = 'CD No. Information Card';
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "CD No. Information";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("CD No."; "CD No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customs declaration number.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("CD Header No."; "CD Header No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customs declaration. ';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Temporary CD No."; "Temporary CD No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Inventory)
            {
                Caption = 'Inventory';
                field(Control23; Inventory)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Purchases; Purchases)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item quantity of the posted purchase invoice associated with this line.';
                }
                field(Sales; Sales)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item quantity of the posted sales invoice associated with this line.';
                }
                field("Positive Adjmt."; "Positive Adjmt.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Negative Adjmt."; "Negative Adjmt.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&CD")
            {
                Caption = '&CD';
                action("Item &Tracking Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    var
                        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                    begin
                        TestField(Type, Type::Item);
                        ItemTrackingDocMgt.ShowItemTrackingForMasterData(0, '', "No.", "Variant Code", '', '', "CD No.", '');
                    end;
                }
                action(Comment)
                {
                    Caption = 'Comment';
                    Image = ViewComments;
                    RunObject = Page "Item Tracking Comments";
                    RunPageLink = Type = CONST("CD No."),
                                  "Item No." = FIELD("No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Serial/Lot/CD No." = FIELD("CD No.");
                }
                separator(Action28)
                {
                }
                action("&Item Tracing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Item Tracing';
                    Image = ItemTracing;

                    trigger OnAction()
                    var
                        ItemTracingBuffer: Record "Item Tracing Buffer";
                        ItemTracing: Page "Item Tracing";
                    begin
                        TestField(Type, Type::Item);
                        Clear(ItemTracing);
                        ItemTracingBuffer.SetRange("Item No.", "No.");
                        ItemTracingBuffer.SetRange("Variant Code", "Variant Code");
                        ItemTracingBuffer.SetRange("CD No.", "CD No.");
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
                action("Copy &Info")
                {
                    Caption = 'Copy &Info';
                    Ellipsis = true;
                    Image = CopySerialNo;

                    trigger OnAction()
                    var
                        SelectedRecord: Record "CD No. Information";
                        ShowRecords: Record "CD No. Information";
                        FocusOnRecord: Record "CD No. Information";
                        ItemTrackingMgt: Codeunit "Item Tracking Management";
                        CDNoInfoList: Page "CD No. Information List";
                    begin
                        ShowRecords.SetRange(Type, Type);
                        ShowRecords.SetRange("No.", "No.");
                        ShowRecords.SetRange("Variant Code", "Variant Code");

                        FocusOnRecord.Copy(ShowRecords);
                        FocusOnRecord.SetRange("CD No.", TrackingSpec."CD No.");

                        CDNoInfoList.SetTableView(ShowRecords);

                        if FocusOnRecord.FindFirst then
                            CDNoInfoList.SetRecord(FocusOnRecord);
                        if CDNoInfoList.RunModal = ACTION::LookupOK then begin
                            CDNoInfoList.GetRecord(SelectedRecord);
                            ItemTrackingMgt.CopyCDNoInformation(SelectedRecord, "CD No.");
                        end;
                    end;
                }
            }
            action(Navigate)
            {
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetTracking('', '', "CD No.");
                    Navigate.Run;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetRange("Date Filter", 00000101D, WorkDate);
        ButtonFunctionsVisible := ShowButtonFunctions;
    end;

    var
        TrackingSpec: Record "Tracking Specification";
        ShowButtonFunctions: Boolean;
        [InDataSet]
        ButtonFunctionsVisible: Boolean;

    [Scope('OnPrem')]
    procedure Init(CurrentTrackingSpec: Record "Tracking Specification")
    begin
        TrackingSpec := CurrentTrackingSpec;
        ShowButtonFunctions := true;
    end;

    [Scope('OnPrem')]
    procedure InitWhse(CurrentTrackingSpec: Record "Whse. Item Tracking Line")
    begin
        TrackingSpec."CD No." := CurrentTrackingSpec."CD No.";
        ShowButtonFunctions := true;
    end;
}

