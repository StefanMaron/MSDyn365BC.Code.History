page 5870 "BOM Structure"
{
    Caption = 'BOM Structure';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Item Availability by';
    SourceTable = "BOM Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            grid(Option)
            {
                Caption = 'Option';
                field(ItemFilter; ItemFilter)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the items that are shown in the BOM Structure window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        ItemList.SetTableView(Item);
                        ItemList.LookupMode := true;
                        if ItemList.RunModal = ACTION::LookupOK then begin
                            ItemList.GetRecord(Item);
                            Text := Item."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;

                    trigger OnValidate()
                    begin
                        RefreshPage;
                    end;
                }
            }
            repeater(Group)
            {
                Caption = 'Lines';
                IndentationColumn = Indentation;
                ShowAsTree = true;
                field(Type; Type)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the item''s position in the BOM structure. Lower-level items are indented under their parents.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = IsParentExpr;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = IsParentExpr;
                    ToolTip = 'Specifies the item''s description.';
                }
                field(HasWarning; HasWarning)
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'Warning';
                    Editable = false;
                    Style = Attention;
                    StyleExpr = HasWarning;
                    ToolTip = 'Specifies if the BOM line has setup or data issues.';

                    trigger OnDrillDown()
                    begin
                        if HasWarning then
                            ShowWarnings;
                    end;
                }
                field("Low-Level Code"; "Low-Level Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s level in the BOM structure.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant code that you entered in the Variant Filter field in the Item Availability by BOM Level window.';
                    Visible = false;
                }
                field("Qty. per Parent"; "Qty. per Parent")
                {
                    ApplicationArea = Assembly;
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce one unit of the parent.';
                }
                field("Qty. per Top Item"; "Qty. per Top Item")
                {
                    ApplicationArea = Assembly;
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce one unit of the top item.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Replenishment System"; "Replenishment System")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies the item''s replenishment system.';
                }
                field("Lead-Time Offset"; "Lead-Time Offset")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total number of days that are required to assemble or produce the item.';
                    Visible = false;
                }
                field("Safety Lead Time"; "Safety Lead Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies any safety lead time that is defined for the item.';
                    Visible = false;
                }
                field("Lead Time Calculation"; "Lead Time Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how long it takes to replenish the item, by purchase, assembly, or production.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Item Availability by")
            {
                Caption = '&Item Availability by';
                Image = ItemAvailability;
                action("Event")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Event';
                    Image = "Event";
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                    trigger OnAction()
                    begin
                        ItemAvail(ItemAvailFormsMgt.ByEvent);
                    end;
                }
                action(Period)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period';
                    Image = Period;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                    trigger OnAction()
                    begin
                        ItemAvail(ItemAvailFormsMgt.ByPeriod);
                    end;
                }
                action(Variant)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant';
                    Image = ItemVariant;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                    trigger OnAction()
                    begin
                        ItemAvail(ItemAvailFormsMgt.ByVariant);
                    end;
                }
                action(Location)
                {
                    AccessByPermission = TableData Location = R;
                    ApplicationArea = Location;
                    Caption = 'Location';
                    Image = Warehouse;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'View the actual and projected quantity of the item per location.';

                    trigger OnAction()
                    begin
                        ItemAvail(ItemAvailFormsMgt.ByLocation);
                    end;
                }
                action("BOM Level")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BOM Level';
                    Image = BOMLevel;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                    trigger OnAction()
                    begin
                        ItemAvail(ItemAvailFormsMgt.ByBOM);
                    end;
                }
            }
        }
        area(processing)
        {
            action("Show Warnings")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Warnings';
                Image = ErrorLog;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'View details about bottlenecks.';

                trigger OnAction()
                begin
                    ShowWarningsForAllLines;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        DummyBOMWarningLog: Record "BOM Warning Log";
    begin
        IsParentExpr := not "Is Leaf";

        HasWarning := not IsLineOk(false, DummyBOMWarningLog);

        if Type = Type::Item then
            "Low-Level Code" := Indentation;
    end;

    trigger OnOpenPage()
    begin
        RefreshPage;
    end;

    var
        Item: Record Item;
        AsmHeader: Record "Assembly Header";
        ProdOrderLine: Record "Prod. Order Line";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        [InDataSet]
        IsParentExpr: Boolean;
        ItemFilter: Code[250];
        ShowBy: Option Item,Assembly,Production;
        CouldNotFindBOMLevelsErr: Label 'Could not find items with BOM levels.';
        [InDataSet]
        HasWarning: Boolean;
        Text001: Label 'There are no warnings.';

    procedure InitItem(var NewItem: Record Item)
    begin
        Item := NewItem;
        ItemFilter := Item."No.";
        ShowBy := ShowBy::Item;
    end;

    procedure InitAsmOrder(NewAsmHeader: Record "Assembly Header")
    begin
        AsmHeader := NewAsmHeader;
        ShowBy := ShowBy::Assembly;
    end;

    procedure InitProdOrder(NewProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine := NewProdOrderLine;
        ShowBy := ShowBy::Production;
    end;

    procedure RefreshPage()
    var
        CalcBOMTree: Codeunit "Calculate BOM Tree";
        RaiseError: Boolean;
        ErrorText: Text;
    begin
        Item.SetFilter("No.", ItemFilter);
        Item.SetRange("Date Filter", 0D, WorkDate);
        CalcBOMTree.SetItemFilter(Item);
        case ShowBy of
            ShowBy::Item:
                begin
                    Item.FindFirst;
                    RaiseError := (not Item.HasBOM) and (Item."Routing No." = '');
                    ErrorText := CouldNotFindBOMLevelsErr;
                    OnRefreshPageOnBeforeRaiseError(Item, RaiseError, ErrorText);
                    if RaiseError then
                        Error(ErrorText);
                    CalcBOMTree.GenerateTreeForItems(Item, Rec, 0);
                end;
            ShowBy::Production:
                CalcBOMTree.GenerateTreeForProdLine(ProdOrderLine, Rec, 0);
            ShowBy::Assembly:
                CalcBOMTree.GenerateTreeForAsm(AsmHeader, Rec, 0);
        end;

        CurrPage.Update(false);
    end;

    local procedure ShowWarnings()
    var
        TempBOMWarningLog: Record "BOM Warning Log" temporary;
    begin
        if IsLineOk(true, TempBOMWarningLog) then
            Message(Text001)
        else
            PAGE.RunModal(PAGE::"BOM Warning Log", TempBOMWarningLog);
    end;

    local procedure ShowWarningsForAllLines()
    var
        TempBOMWarningLog: Record "BOM Warning Log" temporary;
    begin
        if AreAllLinesOk(TempBOMWarningLog) then
            Message(Text001)
        else
            PAGE.RunModal(PAGE::"BOM Warning Log", TempBOMWarningLog);
    end;

    local procedure ItemAvail(AvailType: Option)
    var
        Item: Record Item;
    begin
        TestField(Type, Type::Item);

        Item.Get("No.");
        Item.SetFilter("No.", "No.");
        Item.SetRange("Date Filter", 0D, "Needed by Date");
        Item.SetFilter("Variant Filter", "Variant Code");
        if ShowBy <> ShowBy::Item then
            Item.SetFilter("Location Filter", "Location Code");

        ItemAvailFormsMgt.ShowItemAvailFromItem(Item, AvailType);
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnRefreshPageOnBeforeRaiseError(var Item: Record Item; var RaiseError: Boolean; var ErrorText: Text)
    begin
    end;
}

