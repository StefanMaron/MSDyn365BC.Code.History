page 7345 "Pick Worksheet"
{
    ApplicationArea = Warehouse;
    Caption = 'Pick Worksheets';
    DataCaptionFields = Name;
    InsertAllowed = false;
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
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

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
                ToolTip = 'Specifies the location where the warehouse activity takes place. ';
            }
            field(CurrentSortingMethod; CurrentSortingMethod)
            {
                ApplicationArea = Warehouse;
                Caption = 'Sorting Method';
                OptionCaption = ' ,Item,Document,Shelf or Bin,Due Date,Ship-To';
                ToolTip = 'Specifies the method by which the movement lines are sorted.';

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
                    OptionCaption = ' ,,Shipment,,Internal Pick,Production,,,Assembly';
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
                field("To Zone Code"; "To Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the code of the zone in which the items should be placed.';
                    Visible = false;
                }
                field("To Bin Code"; "To Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the code of the bin into which the items should be placed.';
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
                field("Qty. to Handle"; "Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units of the item you want to move.';

                    trigger OnValidate()
                    begin
                        QtytoHandleOnAfterValidate;
                    end;
                }
                field("Qty. Outstanding"; "Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled.';
                }
                field(AvailableQtyToPickExcludingQCBins; AvailableQtyToPickExcludingQCBins)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Available Qty. to Pick';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity on the pick worksheet line that is available to pick. This quantity includes released warehouse shipment lines.';
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
                field("Shipping Advice"; "Shipping Advice")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shipping advice on the warehouse shipment line associated with this worksheet line.';
                }
                field("Destination Type"; "Destination Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of destination associated with the warehouse worksheet line.';
                }
                field("Destination No."; "Destination No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the customer, vendor, or location for which the items should be processed.';
                }
                field("Source Document"; "Source Document")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                    Visible = false;
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                    Visible = false;
                }
                field("Source Line No."; "Source Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the line number of the source document that the entry originates from.';
                    Visible = false;
                }
                field(QtyCrossDockedUOM; QtyCrossDockedUOM)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Qty. on Cross-Dock Bin';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of items to be cross-docked.';

                    trigger OnDrillDown()
                    begin
                        CrossDockMgt.ShowBinContentsCrossDocked("Item No.", "Variant Code", "Unit of Measure Code", "Location Code", true);
                    end;
                }
                field(QtyCrossDockedUOMBase; QtyCrossDockedUOMBase)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Qty. on Cross-Dock (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of items to be cross-docked.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        CrossDockMgt.ShowBinContentsCrossDocked("Item No.", "Variant Code", "Unit of Measure Code", "Location Code", true);
                    end;
                }
                field(QtyCrossDockedAllUOMBase; QtyCrossDockedAllUOMBase)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Qty. on Cross-Dock Bin (Base all UOM)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of items to be cross-docked. ';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        CrossDockMgt.ShowBinContentsCrossDocked("Item No.", "Variant Code", "Unit of Measure Code", "Location Code", false);
                    end;
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
                action("Source &Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source &Document Line';
                    Image = SourceDocLine;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
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
                    PromotedCategory = Category4;
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
                    RunPageView = SORTING("Item No.", "Location Code", "Variant Code", "Bin Type Code", "Unit of Measure Code", "Lot No.", "Serial No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View completed warehouse activities related to the document.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
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
                action("Get Warehouse Documents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Get Warehouse Documents';
                    Ellipsis = true;
                    Image = GetSourceDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Select a warehouse document to pick for, such as a warehouse shipment.';

                    trigger OnAction()
                    var
                        RetrieveWhsePickDoc: Codeunit "Get Source Doc. Outbound";
                    begin
                        RetrieveWhsePickDoc.GetSingleWhsePickDoc(
                          CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode);
                        SortWhseWkshLines(
                          CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode, CurrentSortingMethod);
                    end;
                }
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
                        PickWkshLine: Record "Whse. Worksheet Line";
                    begin
                        PickWkshLine.Copy(Rec);
                        AutofillQtyToHandle(PickWkshLine);
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
                        PickWkshLine: Record "Whse. Worksheet Line";
                    begin
                        PickWkshLine.Copy(Rec);
                        DeleteQtyToHandle(PickWkshLine);
                    end;
                }
                action(CreatePick)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Pick';
                    Ellipsis = true;
                    Image = CreateInventoryPickup;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Create warehouse pick documents for the specified picks. ';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Whse. Create Pick", Rec);
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
        CrossDockMgt.CalcCrossDockedItems("Item No.", "Variant Code", "Unit of Measure Code", "Location Code",
          QtyCrossDockedUOMBase,
          QtyCrossDockedAllUOMBase);
        QtyCrossDockedUOM := 0;
        if "Qty. per Unit of Measure" <> 0 then
            QtyCrossDockedUOM := Round(QtyCrossDockedUOMBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
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
        TemplateSelection(PAGE::"Pick Worksheet", 1, Rec, WhseWkshSelected);
        if not WhseWkshSelected then
            Error('');
        OpenWhseWksh(Rec, CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode);
    end;

    var
        WMSMgt: Codeunit "WMS Management";
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        CurrentWkshTemplateName: Code[10];
        CurrentWkshName: Code[10];
        CurrentLocationCode: Code[10];
        CurrentSortingMethod: Option " ",Item,Document,"Shelf/Bin No.","Due Date","Ship-To";
        ItemDescription: Text[100];
        QtyCrossDockedUOM: Decimal;
        QtyCrossDockedAllUOMBase: Decimal;
        QtyCrossDockedUOMBase: Decimal;
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
          CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode, CurrentSortingMethod);
        CurrPage.Update(false);
        SetCurrentKey("Worksheet Template Name", Name, "Location Code", "Sorting Sequence No.");
    end;
}

