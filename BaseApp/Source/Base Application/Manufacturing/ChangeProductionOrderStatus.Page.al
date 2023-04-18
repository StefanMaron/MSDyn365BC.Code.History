page 99000914 "Change Production Order Status"
{
    ApplicationArea = Manufacturing;
    Caption = 'Change Production Order Status';
    PageType = Worksheet;
    SourceTable = "Production Order";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ProdOrderStatus; ProdOrderStatus)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Status Filter';
                    OptionCaption = 'Simulated,Planned,Firm Planned,Released';
                    ToolTip = 'Specifies the status of the production orders to define a filter on the lines.';

                    trigger OnValidate()
                    begin
                        ProdOrderStatusOnAfterValidate();
                    end;
                }
                field(StartingDate; StartingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Must Start Before';
                    ToolTip = 'Specifies a date to define a filter on the lines.';

                    trigger OnValidate()
                    begin
                        StartingDateOnAfterValidate();
                    end;
                }
                field(EndingDate; EndingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ends Before';
                    ToolTip = 'Specifies a date to define a filter on the lines.';

                    trigger OnValidate()
                    begin
                        EndingDateOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description of the production order.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date on which you created the production order.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the source type of the production order.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting time of the production order.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date of the production order.';
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending time of the production order.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending date of the production order.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the due date of the production order.';
                }
                field("Finished Date"; Rec."Finished Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the actual finishing date of a finished production order.';
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Pro&d. Order")
            {
                Caption = 'Pro&d. Order';
                Image = "Order";
                group("E&ntries")
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Item Ledger E&ntries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Item Ledger E&ntries';
                        Image = ItemLedger;
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the item ledger entries of the item on the document or journal line.';

                        trigger OnAction()
                        var
                            ItemLedgEntry: Record "Item Ledger Entry";
                        begin
                            if Status <> Status::Released then
                                exit;

                            ItemLedgEntry.Reset();
                            ItemLedgEntry.SetCurrentKey("Order Type", "Order No.");
                            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
                            ItemLedgEntry.SetRange("Order No.", "No.");
                            PAGE.RunModal(0, ItemLedgEntry);
                        end;
                    }
                    action("Capacity Ledger Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Ledger Entries';
                        Image = CapacityLedger;
                        ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';

                        trigger OnAction()
                        var
                            CapLedgEntry: Record "Capacity Ledger Entry";
                        begin
                            if Status <> Status::Released then
                                exit;

                            CapLedgEntry.Reset();
                            CapLedgEntry.SetCurrentKey("Order Type", "Order No.");
                            CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
                            CapLedgEntry.SetRange("Order No.", "No.");
                            PAGE.RunModal(0, CapLedgEntry);
                        end;
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Value Entries';
                        Image = ValueLedger;
                        ToolTip = 'View the value entries of the item on the document or journal line.';

                        trigger OnAction()
                        var
                            ValueEntry: Record "Value Entry";
                        begin
                            if Status <> Status::Released then
                                exit;

                            ValueEntry.Reset();
                            ValueEntry.SetCurrentKey("Order Type", "Order No.");
                            ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
                            ValueEntry.SetRange("Order No.", "No.");
                            PAGE.RunModal(0, ValueEntry);
                        end;
                    }
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Prod. Order Comment Sheet";
                    RunPageLink = Status = FIELD(Status),
                                  "Prod. Order No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
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
                        ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Production Order Statistics";
                    RunPageLink = Status = FIELD(Status),
                                  "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Change &Status")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Change &Status';
                    Ellipsis = true;
                    Image = ChangeStatus;
                    ToolTip = 'Change the production order to another status, such as Released.';

                    trigger OnAction()
                    var
                        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
                        ChangeStatusForm: Page "Change Status on Prod. Order";
                        Window: Dialog;
                        NewStatus: Enum "Production Order Status";
                        NewPostingDate: Date;
                        NewUpdateUnitCost: Boolean;
                        NoOfRecords: Integer;
                        POCount: Integer;
                        IsHandled: Boolean;
                    begin
                        ChangeStatusForm.Set(Rec);

                        if ChangeStatusForm.RunModal() <> ACTION::Yes then
                            exit;

                        ChangeStatusForm.ReturnPostingInfo(NewStatus, NewPostingDate, NewUpdateUnitCost);

                        NoOfRecords := Count;

                        Window.Open(StrSubstNo(Text000, NewStatus) + Text001);

                        POCount := 0;

                        if Find('-') then
                            repeat
                                POCount := POCount + 1;
                                Window.Update(1, "No.");
                                Window.Update(2, Round(POCount / NoOfRecords * 10000, 1));
                                IsHandled := false;
                                OnBeforeChangeProdOrderStatus(Rec, NewStatus, NewPostingDate, NewUpdateUnitCost, IsHandled);
                                if not IsHandled then
                                    ProdOrderStatusMgt.ChangeProdOrderStatus(Rec, NewStatus, NewPostingDate, NewUpdateUnitCost);
                                Commit();
                            until Next() = 0;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Change &Status_Promoted"; "Change &Status")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Prod. Order', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("Item Ledger E&ntries_Promoted"; "Item Ledger E&ntries")
                {
                }
                actionref("Capacity Ledger Entries_Promoted"; "Capacity Ledger Entries")
                {
                }
                actionref("Value Entries_Promoted"; "Value Entries")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        BuildPage();
    end;

    var
        Text000: Label 'Changing status to %1...\\';
        Text001: Label 'Prod. Order #1###### @2@@@@@@@@@@@@@';
        ProdOrderStatus: Option Simulated,Planned,"Firm Planned",Released;
        StartingDate: Date;
        EndingDate: Date;

    protected procedure BuildPage()
    begin
        FilterGroup(2);
        SetRange(Status, ProdOrderStatus);
        FilterGroup(0);

        if StartingDate <> 0D then
            SetFilter("Starting Date", '..%1', StartingDate)
        else
            SetRange("Starting Date");

        if EndingDate <> 0D then
            SetFilter("Ending Date", '..%1', EndingDate)
        else
            SetRange("Ending Date");

        CurrPage.Update(false);
    end;

    local procedure ProdOrderStatusOnAfterValidate()
    begin
        BuildPage();
    end;

    local procedure StartingDateOnAfterValidate()
    begin
        BuildPage();
    end;

    local procedure EndingDateOnAfterValidate()
    begin
        BuildPage();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeProdOrderStatus(Rec: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewPostingDate: Date; NewUpdateUnitCost: Boolean; var IsHandled: Boolean)
    begin
    end;
}

