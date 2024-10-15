page 12418 "CD No. Information List"
{
    Caption = 'CD No. Information List';
    Editable = false;
    PageType = List;
    SourceTable = "CD No. Information";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("No."; "No.")
                {
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("CD No."; "CD No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customs declaration number.';
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
                field("Temporary CD No."; "Temporary CD No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field(Control16; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment associated with this line.';
                }
                field(Inventory; Inventory)
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&CD No.")
            {
                Caption = '&CD No.';
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
                separator(Action1102601003)
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
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
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
            group(ButtonFunctions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&CD No. Information Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&CD No. Information Card';
                    Image = SNInfo;
                    RunObject = Page "CD No. Information Card";
                    RunPageLink = Type = FIELD(Type),
                                  "No." = FIELD("No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "CD No." = FIELD("CD No.");
                    ShortCutKey = 'Shift+F7';
                }
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    [Scope('OnPrem')]
    procedure SetSelection(var CDNoInfo: Record "CD No. Information")
    begin
        CurrPage.SetSelectionFilter(CDNoInfo);
    end;

    [Scope('OnPrem')]
    procedure GetSelectionFilter(): Text
    var
        CDNoInfo: Record "CD No. Information";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(CDNoInfo);
        exit(SelectionFilterManagement.GetSelectionFilterForCDNoInformation(CDNoInfo));
    end;
}

