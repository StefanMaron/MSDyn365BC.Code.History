page 5872 "BOM Cost Shares"
{
    Caption = 'BOM Cost Shares';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
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
                    ToolTip = 'Specifies the items that are shown in the BOM Cost Shares window.';

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
                    ToolTip = 'Specifies if the field can be chosen to open the BOM Warning Log window to see a description of the issue.';

                    trigger OnDrillDown()
                    begin
                        if HasWarning then
                            ShowWarnings;
                    end;
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
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce one unit of the parent.';
                }
                field("Qty. per Top Item"; "Qty. per Top Item")
                {
                    ApplicationArea = Assembly;
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce one unit of the top item.';
                }
                field("Qty. per BOM Line"; "Qty. per BOM Line")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce one unit of the item on the BOM line.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("BOM Unit of Measure Code"; "BOM Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies the unit of measure of the BOM item. ';
                }
                field("Replenishment System"; "Replenishment System")
                {
                    ApplicationArea = Assembly;
                    Editable = false;
                    ToolTip = 'Specifies the item''s replenishment system.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Scrap %"; "Scrap %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the percentage of the item that you expect to be scrapped in the production process.';
                    Visible = false;
                }
                field("Scrap Qty. per Parent"; "Scrap Qty. per Parent")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many units of the item are scrapped to output the top item quantity.';
                    Visible = false;
                }
                field("Scrap Qty. per Top Item"; "Scrap Qty. per Top Item")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many units of the item are scrapped to output the parent item quantity.';
                    Visible = false;
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    Visible = false;
                }
                field("Overhead Rate"; "Overhead Rate")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the item''s overhead rate.';
                    Visible = false;
                }
                field("Lot Size"; "Lot Size")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s lot size. The value is copied from the Lot Size field on the item card.';
                    Visible = false;
                }
                field("Production BOM No."; "Production BOM No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the production BOM that the item represents.';
                    Visible = false;
                }
                field("Routing No."; "Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the item''s production order routing.';
                    Visible = false;
                }
                field("Resource Usage Type"; "Resource Usage Type")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how the cost of the resource on the assembly BOM is allocated during assembly.';
                    Visible = false;
                }
                field("Rolled-up Material Cost"; "Rolled-up Material Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the material cost of all items at all levels of the parent item''s BOM, added to the material cost of the item itself.';
                }
                field("Rolled-up Capacity Cost"; "Rolled-up Capacity Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the capacity costs related to the item''s parent item and other items in the parent item''s BOM.';
                }
                field("Rolled-up Subcontracted Cost"; "Rolled-up Subcontracted Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the single-level cost of outsourcing operations to a subcontractor.';
                }
                field("Rolled-up Mfg. Ovhd Cost"; "Rolled-up Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item''s overhead capacity cost rolled up from underlying item levels.';
                }
                field("Rolled-up Capacity Ovhd. Cost"; "Rolled-up Capacity Ovhd. Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the rolled-up manufacturing overhead cost of the item.';
                }
                field("Rolled-up Scrap Cost"; "Rolled-up Scrap Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of all component material that will eventually be scrapped to produce the parent item.';
                }
                field("Single-Level Material Cost"; "Single-Level Material Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the total material cost of all components on the parent item''s BOM.';
                    Visible = false;
                }
                field("Single-Level Capacity Cost"; "Single-Level Capacity Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the capacity costs related to the item''s parent item only.';
                    Visible = false;
                }
                field("Single-Level Subcontrd. Cost"; "Single-Level Subcontrd. Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the single-level cost of outsourcing operations to a subcontractor.';
                    Visible = false;
                }
                field("Single-Level Cap. Ovhd Cost"; "Single-Level Cap. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the single-level capacity overhead cost.';
                    Visible = false;
                }
                field("Single-Level Mfg. Ovhd Cost"; "Single-Level Mfg. Ovhd Cost")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the single-level manufacturing overhead cost.';
                    Visible = false;
                }
                field("Single-Level Scrap Cost"; "Single-Level Scrap Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of material at this BOM level that will eventually be scrapped in order to produce the parent item.';
                    Visible = false;
                }
                field("Total Cost"; "Total Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the sum of all cost at this BOM level.';
                }
            }
        }
    }

    actions
    {
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
        area(reporting)
        {
            action("BOM Cost Share Distribution")
            {
                ApplicationArea = Assembly;
                Caption = 'BOM Cost Share Distribution';
                Image = "Report";
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Get a graphical overview of how an assembled or produced item''s cost is distributed through its BOM. The first chart shows the total unit cost of the parent item''s components and labor resources broken down in up to five different cost shares. The pie chart labeled By Material/Labor shows the proportional distribution between the parent item''s material and labor costs, as well as its own manufacturing overhead. The material cost share includes the item''s material costs. The labor cost share includes capacity, capacity overhead and subcontracted costs. The pie chart labeled By Direct/Indirect shows the proportional distribution between the parent item''s direct and indirect costs. The direct cost share includes the item''s material, capacity, and subcontracted costs.';

                trigger OnAction()
                begin
                    ShowBOMCostShareDistribution;
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
    end;

    trigger OnOpenPage()
    begin
        RefreshPage;
    end;

    var
        Item: Record Item;
        AsmHeader: Record "Assembly Header";
        ProdOrderLine: Record "Prod. Order Line";
        [InDataSet]
        IsParentExpr: Boolean;
        ItemFilter: Code[250];
        ShowBy: Option Item,Assembly,Production;
        Text000: Label 'None of the items in the filter have a BOM.';
        Text001: Label 'There are no warnings.';
        [InDataSet]
        HasWarning: Boolean;

    procedure InitItem(var NewItem: Record Item)
    begin
        Item.Copy(NewItem);
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

    local procedure RefreshPage()
    var
        CalcBOMTree: Codeunit "Calculate BOM Tree";
        HasBOM: Boolean;
    begin
        Item.SetFilter("No.", ItemFilter);
        Item.SetRange("Date Filter", 0D, WorkDate);
        CalcBOMTree.SetItemFilter(Item);

        case ShowBy of
            ShowBy::Item:
                begin
                    Item.FindSet;
                    repeat
                        HasBOM := Item.HasBOM or (Item."Routing No." <> '')
                    until HasBOM or (Item.Next = 0);

                    if not HasBOM then
                        Error(Text000);
                    CalcBOMTree.GenerateTreeForItems(Item, Rec, 2);
                end;
            ShowBy::Production:
                CalcBOMTree.GenerateTreeForProdLine(ProdOrderLine, Rec, 2);
            ShowBy::Assembly:
                CalcBOMTree.GenerateTreeForAsm(AsmHeader, Rec, 2);
        end;

        CurrPage.Update(false);
    end;

    local procedure ShowBOMCostShareDistribution()
    var
        Item: Record Item;
    begin
        TestField(Type, Type::Item);

        Item.Get("No.");
        Item.SetFilter("No.", "No.");
        Item.SetFilter("Variant Filter", "Variant Code");
        if ShowBy <> ShowBy::Item then
            Item.SetFilter("Location Filter", "Location Code");

        REPORT.Run(REPORT::"BOM Cost Share Distribution", true, true, Item);
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
}

