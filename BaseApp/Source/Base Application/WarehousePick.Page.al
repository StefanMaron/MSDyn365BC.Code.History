page 5779 "Warehouse Pick"
{
    Caption = 'Warehouse Pick';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Warehouse Activity Header";
    SourceTableView = WHERE(Type = CONST(Pick));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(CurrentLocationCode; CurrentLocationCode)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Code';
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the location where the warehouse activity takes place. ';
                }
                field("Breakbulk Filter"; Rec."Breakbulk Filter")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the intermediate Take and Place lines will not show as put-away, pick, or movement lines, when the quantity in the larger unit of measure is being put-away, picked or moved completely.';

                    trigger OnValidate()
                    begin
                        BreakbulkFilterOnAfterValidate();
                    end;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
                }
                field("Assignment Time"; Rec."Assignment Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the time when the user was assigned the activity.';
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the lines are sorted on the warehouse header, such as Item or Document.';

                    trigger OnValidate()
                    begin
                        SortingMethodOnAfterValidate();
                    end;
                }
            }
            part(WhseActivityLines; "Whse. Pick Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Activity Type" = FIELD(Type),
                              "No." = FIELD("No.");
                SubPageView = SORTING("Activity Type", "No.", "Sorting Sequence No.")
                              WHERE(Breakbulk = CONST(false));
            }
        }
        area(factboxes)
        {
            part(Control1901796907; "Item Warehouse FactBox")
            {
                ApplicationArea = Warehouse;
                Provider = WhseActivityLines;
                SubPageLink = "No." = FIELD("Item No.");
                Visible = true;
            }
            part(Control4; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = Warehouse;
                Provider = WhseActivityLines;
                SubPageLink = "Item No." = FIELD("Item No."),
                              "Variant Code" = FIELD("Variant Code"),
                              "Location Code" = FIELD("Location Code");
                Visible = false;
            }
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
            group("P&ick")
            {
                Caption = 'P&ick';
                Image = CreateInventoryPickup;
#if not CLEAN19
                action(List)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all warehouse documents of this type that exist.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by platform capabilities.';
                    ObsoleteTag = '19.0';

                    trigger OnAction()
                    begin
                        LookupActivityHeader(CurrentLocationCode, Rec);
                    end;
                }
#endif
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Whse. Activity Header"),
                                  Type = FIELD(Type),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Registered Picks")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Picks';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Activity List";
                    RunPageLink = Type = FIELD(Type),
                                  "Whse. Activity No." = FIELD("No.");
                    RunPageView = SORTING("Whse. Activity No.");
                    ToolTip = 'View the quantities that have already been picked.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Autofill Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. to Handle';
                    Image = AutofillQtyToHandle;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Handle field.';

                    trigger OnAction()
                    begin
                        AutofillQtyToHandle();
                    end;
                }
                action("Delete Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Delete Qty. to Handle';
                    Image = DeleteQtyToHandle;
                    ToolTip = 'Have the system clear the value in the Qty. To Handle field. ';

                    trigger OnAction()
                    begin
                        DeleteQtyToHandle();
                    end;
                }
                separator(Action32)
                {
                }
            }
            group("&Registering")
            {
                Caption = '&Registering';
                Image = PostOrder;
                action(RegisterPick)
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Register Pick';
                    Image = RegisterPick;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record that the items have been picked.';

                    trigger OnAction()
                    begin
                        RegisterActivityYesNo();
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    WhseActPrint.PrintPickHeader(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(RegisterPick_Promoted; RegisterPick)
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                group("Category_Qty. to Handle")
                {
                    Caption = 'Qty. to Handle';
                    ShowAs = SplitButton;

                    actionref("Autofill Qty. to Handle_Promoted"; "Autofill Qty. to Handle")
                    {
                    }
                    actionref("Delete Qty. to Handle_Promoted"; "Delete Qty. to Handle")
                    {
                    }
                }
            }
            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Category5)
            {
                Caption = 'Pick', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref("Registered Picks_Promoted"; "Registered Picks")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CurrentLocationCode := "Location Code";
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update();
    end;

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        ErrorIfUserIsNotWhseEmployee();
        FilterGroup(2); // set group of filters user cannot change
        SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(UserId));
        FilterGroup(0); // set filter group back to standard
    end;

    var
        WhseActPrint: Codeunit "Warehouse Document-Print";
        CurrentLocationCode: Code[10];

    local procedure AutofillQtyToHandle()
    begin
        CurrPage.WhseActivityLines.PAGE.AutofillQtyToHandle();
    end;

    local procedure DeleteQtyToHandle()
    begin
        CurrPage.WhseActivityLines.PAGE.DeleteQtyToHandle();
    end;

    local procedure RegisterActivityYesNo()
    begin
        CurrPage.WhseActivityLines.PAGE.RegisterActivityYesNo();
    end;

    local procedure SortingMethodOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure BreakbulkFilterOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

