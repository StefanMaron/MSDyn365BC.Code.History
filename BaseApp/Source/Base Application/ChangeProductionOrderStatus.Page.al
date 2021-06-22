page 99000914 "Change Production Order Status"
{
    ApplicationArea = Manufacturing;
    Caption = 'Change Production Order Status';
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Prod. Order';
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
                        ProdOrderStatusOnAfterValidate;
                    end;
                }
                field(StartingDate; StartingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Must Start Before';
                    ToolTip = 'Specifies a date to define a filter on the lines.';

                    trigger OnValidate()
                    begin
                        StartingDateOnAfterValidate;
                    end;
                }
                field(EndingDate; EndingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ends Before';
                    ToolTip = 'Specifies a date to define a filter on the lines.';

                    trigger OnValidate()
                    begin
                        EndingDateOnAfterValidate;
                    end;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description of the production order.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date on which you created the production order.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the source type of the production order.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting time of the production order.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date of the production order.';
                }
                field("Ending Time"; "Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending time of the production order.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending date of the production order.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the due date of the production order.';
                }
                field("Finished Date"; "Finished Date")
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
                        Promoted = true;
                        PromotedCategory = Category4;
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
                        Promoted = true;
                        PromotedCategory = Category4;
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
                        Promoted = true;
                        PromotedCategory = Category4;
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
                    Promoted = true;
                    PromotedCategory = Category4;
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
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.SaveRecord;
                    end;
                }
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
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
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Change the production order to another status, such as Released.';

                    trigger OnAction()
                    var
                        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
                        ChangeStatusForm: Page "Change Status on Prod. Order";
                        Window: Dialog;
                        NewStatus: Option Simulated,Planned,"Firm Planned",Released,Finished;
                        NewPostingDate: Date;
                        NewUpdateUnitCost: Boolean;
                        NoOfRecords: Integer;
                        POCount: Integer;
                        LocalText000: Label 'Simulated,Planned,Firm Planned,Released,Finished';
                    begin
                        ChangeStatusForm.Set(Rec);

                        if ChangeStatusForm.RunModal <> ACTION::Yes then
                            exit;

                        ChangeStatusForm.ReturnPostingInfo(NewStatus, NewPostingDate, NewUpdateUnitCost);

                        NoOfRecords := Count;

                        Window.Open(
                          StrSubstNo(Text000, SelectStr(NewStatus + 1, LocalText000)) +
                          Text001);

                        POCount := 0;

                        if Find('-') then
                            repeat
                                POCount := POCount + 1;
                                Window.Update(1, "No.");
                                Window.Update(2, Round(POCount / NoOfRecords * 10000, 1));
                                ProdOrderStatusMgt.ChangeStatusOnProdOrder(
                                  Rec, NewStatus, NewPostingDate, NewUpdateUnitCost);
                                Commit();
                            until Next = 0;
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        BuildForm;
    end;

    var
        Text000: Label 'Changing status to %1...\\';
        Text001: Label 'Prod. Order #1###### @2@@@@@@@@@@@@@';
        ProdOrderStatus: Option Simulated,Planned,"Firm Planned",Released;
        StartingDate: Date;
        EndingDate: Date;

    local procedure BuildForm()
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
        BuildForm;
    end;

    local procedure StartingDateOnAfterValidate()
    begin
        BuildForm;
    end;

    local procedure EndingDateOnAfterValidate()
    begin
        BuildForm;
    end;
}

