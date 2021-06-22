page 7351 "Movement Worksheet"
{
    ApplicationArea = Warehouse;
    Caption = 'Movement Worksheets';
    DataCaptionFields = Name;
    DelayedInsert = true;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Line,Item';
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Whse. Worksheet Line";
    SourceTableView = SORTING("Worksheet Template Name", Name, "Location Code", "Sorting Sequence No.");
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentWkshName; CurrentWkshName)
            {
                ApplicationArea = Warehouse;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the worksheet in which you plan movements of inventory in the warehouse.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord;
                    LookupWhseWkshName(Rec, CurrentWkshName, CurrentLocationCode);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    CheckWhseWkshName(CurrentWkshName, CurrentLocationCode, Rec);
                    CurrentWkshNameOnAfterValidate;
                end;
            }
            field(CurrentLocationCode; CurrentLocationCode)
            {
                ApplicationArea = Warehouse;
                Caption = 'Location Code';
                Editable = false;
                ToolTip = 'Specifies the location where you plan to move inventory in the warehouse.';
            }
            field(CurrentSortingMethod; CurrentSortingMethod)
            {
                ApplicationArea = Warehouse;
                Caption = 'Sorting Method';
                OptionCaption = ' ,Item,,To Bin Code,Due Date';
                ToolTip = 'Specifies the method by which the movement worksheet lines are sorted.';

                trigger OnValidate()
                begin
                    CurrentSortingMethodOnAfterVal;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that the line concerns.';

                    trigger OnValidate()
                    begin
                        GetItem("Item No.", ItemDescription);
                        ItemNoOnAfterValidate;
                    end;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item on the line.';
                }
                field("From Zone Code"; "From Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone from which the items should be taken.';
                }
                field("From Bin Code"; "From Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin from which the items should be taken.';
                }
                field("To Zone Code"; "To Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone in which the items should be placed.';
                }
                field("To Bin Code"; "To Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin into which the items should be placed.';

                    trigger OnValidate()
                    begin
                        ToBinCodeOnAfterValidate;
                    end;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item you want to move.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate;
                    end;
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be handled in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Outstanding"; "Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled.';
                }
                field("Qty. Outstanding (Base)"; "Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled, expressed in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. to Handle"; "Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item you want to move.';

                    trigger OnValidate()
                    begin
                        QtytoHandleOnAfterValidate;
                    end;
                }
                field("Qty. to Handle (Base)"; "Qty. to Handle (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity you want to handle, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Handled"; "Qty. Handled")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that has been handled and registered.';
                }
                field("Qty. Handled (Base)"; "Qty. Handled (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that has been handled and registered, in the base unit of measure.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the due date of the line.';

                    trigger OnValidate()
                    begin
                        DueDateOnAfterValidate;
                    end;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("ROUND(CheckAvailQtytoMove / ItemUOM.""Qty. per Unit of Measure"",UOMMgt.QtyRndPrecision)"; Round(CheckAvailQtytoMove / ItemUOM."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision))
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Available Qty. to Move';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many item units are available to be moved from the From bin, taking into account other warehouse movements for the item.';
                }
            }
            group(Control22)
            {
                ShowCaption = false;
                fixed(Control1900669001)
                {
                    ShowCaption = false;
                    group("Item Description")
                    {
                        Caption = 'Item Description';
                        field(ItemDescription; ItemDescription)
                        {
                            ApplicationArea = Warehouse;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(Control8; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = ItemTracking;
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(ItemTrackingLines)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines;
                    end;
                }
            }
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Card)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = FIELD("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Warehouse Entries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Entries';
                    Image = BinLedger;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Warehouse Entries";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Location Code" = FIELD("Location Code");
                    RunPageView = SORTING("Item No.", "Location Code", "Variant Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View completed warehouse activities related to the document.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Ledger E&ntries';
                    Image = ItemLedger;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Item Ledger Entries";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Location Code" = FIELD("Location Code");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Image = BinContent;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = FIELD("Location Code"),
                                  "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code");
                    RunPageView = SORTING("Location Code", "Item No.", "Variant Code");
                    ToolTip = 'View items in the bin if the selected line contains a bin code.';
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
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Handle field.';

                    trigger OnAction()
                    var
                        WhseWkshLine: Record "Whse. Worksheet Line";
                    begin
                        WhseWkshLine.Copy(Rec);
                        AutofillQtyToHandle(WhseWkshLine);
                    end;
                }
                action("Delete Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Delete Qty. to Handle';
                    Image = DeleteQtyToHandle;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Have the system clear the value in the Qty. To Handle field. ';

                    trigger OnAction()
                    var
                        WhseWkshLine: Record "Whse. Worksheet Line";
                    begin
                        WhseWkshLine.Copy(Rec);
                        DeleteQtyToHandle(WhseWkshLine);
                    end;
                }
                separator(Action54)
                {
                }
                action("Calculate Bin &Replenishment")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate Bin &Replenishment';
                    Ellipsis = true;
                    Image = CalculateBinReplenishment;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Calculate the movement of items from bulk storage bins with lower bin rankings to bins with a high bin ranking in the picking areas.';

                    trigger OnAction()
                    var
                        Location: Record Location;
                        BinContent: Record "Bin Content";
                        ReplenishBinContent: Report "Calculate Bin Replenishment";
                    begin
                        Location.Get("Location Code");
                        ReplenishBinContent.InitializeRequest(
                          "Worksheet Template Name", Name, "Location Code",
                          Location."Allow Breakbulk", false, false);

                        ReplenishBinContent.SetTableView(BinContent);
                        ReplenishBinContent.Run;
                        Clear(ReplenishBinContent);
                    end;
                }
                action("Get Bin Content")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Get Bin Content';
                    Ellipsis = true;
                    Image = GetBinContent;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Use a function to create transfer lines with items to put away or pick based on the actual content in the specified bin.';

                    trigger OnAction()
                    var
                        BinContent: Record "Bin Content";
                        DummyRec: Record "Whse. Internal Put-away Header";
                        GetBinContent: Report "Whse. Get Bin Content";
                    begin
                        BinContent.SetRange("Location Code", "Location Code");
                        GetBinContent.SetTableView(BinContent);
                        GetBinContent.InitializeReport(Rec, DummyRec, 0);
                        GetBinContent.Run;
                    end;
                }
                separator(Action3)
                {
                }
                action("Create Movement")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Movement';
                    Ellipsis = true;
                    Image = CreateMovement;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Create the specified warehouse movement documents.';

                    trigger OnAction()
                    var
                        WhseWkshLine: Record "Whse. Worksheet Line";
                    begin
                        WhseWkshLine.SetFilter(Quantity, '>0');
                        WhseWkshLine.CopyFilters(Rec);
                        if WhseWkshLine.FindFirst then
                            MovementCreate(WhseWkshLine)
                        else
                            Error(Text001);

                        WhseWkshLine.Reset();
                        CopyFilters(WhseWkshLine);
                        FilterGroup(2);
                        SetRange("Worksheet Template Name", "Worksheet Template Name");
                        SetRange(Name, Name);
                        SetRange("Location Code", CurrentLocationCode);
                        FilterGroup(0);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetItem("Item No.", ItemDescription);
    end;

    trigger OnAfterGetRecord()
    begin
        if not ItemUOM.Get("Item No.", "From Unit of Measure Code") then
            ItemUOM.Init();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        ItemDescription := '';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "Sorting Sequence No." := GetSortSeqNo(CurrentSortingMethod);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        "Sorting Sequence No." := GetSortSeqNo(CurrentSortingMethod);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(
          CurrentWkshTemplateName, CurrentWkshName,
          CurrentLocationCode, CurrentSortingMethod, xRec."Line No.");
    end;

    trigger OnOpenPage()
    var
        WhseWkshSelected: Boolean;
    begin
        OpenedFromBatch := (Name <> '') and ("Worksheet Template Name" = '');
        if OpenedFromBatch then begin
            CurrentWkshName := Name;
            CurrentLocationCode := "Location Code";
            OpenWhseWksh(Rec, CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode);
            exit;
        end;
        TemplateSelection(PAGE::"Movement Worksheet", 2, Rec, WhseWkshSelected);
        if not WhseWkshSelected then
            Error('');
        OpenWhseWksh(Rec, CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode);
    end;

    var
        ItemUOM: Record "Item Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";
        CurrentWkshTemplateName: Code[10];
        CurrentWkshName: Code[10];
        CurrentLocationCode: Code[10];
        CurrentSortingMethod: Option " ",Item,,"Shelf/Bin No.","Due Date";
        ItemDescription: Text[100];
        Text001: Label 'There is nothing to handle.';
        OpenedFromBatch: Boolean;

    local procedure ItemNoOnAfterValidate()
    begin
        if CurrentSortingMethod = CurrentSortingMethod::Item then
            CurrPage.Update;
    end;

    local procedure ToBinCodeOnAfterValidate()
    begin
        if CurrentSortingMethod = CurrentSortingMethod::"Shelf/Bin No." then
            CurrPage.Update;
    end;

    local procedure QuantityOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure QtytoHandleOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure DueDateOnAfterValidate()
    begin
        if CurrentSortingMethod = CurrentSortingMethod::"Due Date" then
            CurrPage.Update;
    end;

    local procedure CurrentWkshNameOnAfterValidate()
    begin
        CurrPage.SaveRecord;
        SetWhseWkshName(CurrentWkshName, CurrentLocationCode, Rec);
        CurrPage.Update(false);
    end;

    local procedure CurrentSortingMethodOnAfterVal()
    begin
        SortWhseWkshLines(
          CurrentWkshTemplateName, CurrentWkshName,
          CurrentLocationCode, CurrentSortingMethod);
        CurrPage.Update(false);
        SetCurrentKey("Worksheet Template Name", Name, "Location Code", "Sorting Sequence No.");
    end;
}

