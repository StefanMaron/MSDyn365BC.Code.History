page 7352 "Put-away Worksheet"
{
    ApplicationArea = Warehouse;
    Caption = 'Put-away Worksheets';
    DataCaptionFields = Name;
    InsertAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Prepare,Line,Item';
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
                ToolTip = 'Specifies the name of the worksheet in which you can organize various kinds of put-aways, including put-aways with lines from several orders.';

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
                ToolTip = 'Specifies the location that is set up to use directed put-away.';
            }
            field(CurrentSortingMethod; CurrentSortingMethod)
            {
                ApplicationArea = Warehouse;
                Caption = 'Sorting Method';
                OptionCaption = ' ,Item,Document,Shelf or Bin,Due Date';
                ToolTip = 'Specifies the method by which the warehouse internal put-away lines are sorted.';

                trigger OnValidate()
                begin
                    CurrentSortingMethodOnAfterVal;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Whse. Document Type"; "Whse. Document Type")
                {
                    ApplicationArea = Warehouse;
                    OptionCaption = ' ,Receipt,,Internal Put-away';
                    ToolTip = 'Specifies the type of warehouse document this line is associated with.';
                }
                field("Whse. Document No."; "Whse. Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the warehouse document.';
                }
                field("Whse. Document Line No."; "Whse. Document Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the line in the warehouse document that is the basis for the worksheet line.';
                    Visible = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the number of the item that the line concerns.';

                    trigger OnValidate()
                    begin
                        GetItem("Item No.", ItemDescription);
                    end;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the description of the item on the line.';
                }
                field("From Zone Code"; "From Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the zone from which the items should be taken.';
                    Visible = false;
                }
                field("From Bin Code"; "From Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the code of the bin from which the items should be taken.';
                    Visible = false;
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for information use.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item you want to move.';
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
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
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
                ApplicationArea = Warehouse;
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
                action("Source &Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source &Document Line';
                    Image = SourceDocLine;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'View the line on a released source document that the warehouse activity is for. ';

                    trigger OnAction()
                    begin
                        WMSMgt.ShowSourceDocLine(
                          "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                    end;
                }
                action("Whse. Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Whse. Document Line';
                    Image = Line;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Scope = Repeater;
                    ToolTip = 'View the line on another warehouse document that the warehouse activity is for.';

                    trigger OnAction()
                    begin
                        WMSMgt.ShowWhseDocLine(
                          "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Scope = Repeater;
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
                    PromotedCategory = Category6;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = FIELD("Item No.");
                    Scope = Repeater;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Warehouse Entries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Entries';
                    Image = BinLedger;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Warehouse Entries";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Location Code" = FIELD("Location Code");
                    RunPageView = SORTING("Item No.", "Location Code", "Variant Code");
                    Scope = Repeater;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View completed warehouse activities related to the document.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Ledger E&ntries';
                    Image = ItemLedger;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Item Ledger Entries";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Location Code" = FIELD("Location Code");
                    RunPageView = SORTING("Item No.");
                    Scope = Repeater;
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Image = BinContent;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = FIELD("Location Code"),
                                  "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code");
                    RunPageView = SORTING("Location Code", "Item No.", "Variant Code");
                    Scope = Repeater;
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
                action(GetWarehouseDocuments)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Get Warehouse Documents';
                    Ellipsis = true;
                    Image = GetSourceDoc;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Select a warehouse document to pick for, such as a warehouse shipment.';

                    trigger OnAction()
                    var
                        GetWhsePutAwayDoc: Codeunit "Get Source Doc. Inbound";
                    begin
                        OnBeforeGetWarehouseDocuments();

                        GetWhsePutAwayDoc.GetSingleWhsePutAwayDoc(
                          CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode);
                        SortWhseWkshLines(
                          CurrentWkshTemplateName, CurrentWkshName,
                          CurrentLocationCode, CurrentSortingMethod);
                    end;
                }
                action("Autofill Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. to Handle';
                    Image = AutofillQtyToHandle;
                    Promoted = true;
                    PromotedCategory = Process;
                    Scope = Repeater;
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
                    Scope = Repeater;
                    ToolTip = 'Have the system clear the value in the Qty. To Handle field. ';

                    trigger OnAction()
                    var
                        WhseWkshLine: Record "Whse. Worksheet Line";
                    begin
                        WhseWkshLine.Copy(Rec);
                        DeleteQtyToHandle(WhseWkshLine);
                    end;
                }
                action(CreatePutAway)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Put-away';
                    Ellipsis = true;
                    Image = CreatePutAway;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Create warehouse put-away documents for the specified put-aways. ';

                    trigger OnAction()
                    var
                        WhseWkshLine: Record "Whse. Worksheet Line";
                    begin
                        WhseWkshLine.CopyFilters(Rec);
                        if WhseWkshLine.FindFirst then
                            PutAwayCreate(WhseWkshLine)
                        else
                            Error(Text001);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetItem("Item No.", ItemDescription);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        ItemDescription := '';
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
        TemplateSelection(PAGE::"Put-away Worksheet", 0, Rec, WhseWkshSelected);
        if not WhseWkshSelected then
            Error('');
        OpenWhseWksh(Rec, CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode);
    end;

    var
        WMSMgt: Codeunit "WMS Management";
        CurrentWkshTemplateName: Code[10];
        CurrentWkshName: Code[10];
        CurrentLocationCode: Code[10];
        CurrentSortingMethod: Option " ",Item,Document,"Shelf/Bin No.","Due Date";
        ItemDescription: Text[100];
        Text001: Label 'There is nothing to handle.';
        OpenedFromBatch: Boolean;

    local procedure QtytoHandleOnAfterValidate()
    begin
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

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetWarehouseDocuments();
    begin
    end;
}

