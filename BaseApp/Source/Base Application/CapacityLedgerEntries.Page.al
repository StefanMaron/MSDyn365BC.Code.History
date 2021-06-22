page 5832 "Capacity Ledger Entries"
{
    ApplicationArea = Assembly, Manufacturing;
    Caption = 'Capacity Ledger Entries';
    DataCaptionExpression = GetCaption;
    Editable = false;
    PageType = List;
    SourceTable = "Capacity Ledger Entry";
    SourceTableView = SORTING("Entry No.")
                      ORDER(Descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the posting date of the entry.';
                }
                field("Order Type"; "Order Type")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies which type of order the entry was created in.';
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the number of the order that created the entry.';
                }
                field("Routing No."; "Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the routing number belonging to the entry.';
                    Visible = false;
                }
                field("Routing Reference No."; "Routing Reference No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies that the routing reference number corresponding to the routing reference number of the line.';
                    Visible = false;
                }
                field("Work Center No."; "Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the work center number of the journal line.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the type of capacity entry.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the document number of the entry.';
                    Visible = false;
                }
                field("Operation No."; "Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the operation associated with the entry.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the item number.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Work Shift Code"; "Work Shift Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the work shift that this machine center was planned at, or in which work shift the related production operation took place.';
                    Visible = false;
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting time of the capacity posted with this entry.';
                    Visible = false;
                }
                field("Ending Time"; "Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending time of the capacity posted with this entry.';
                    Visible = false;
                }
                field("Concurrent Capacity"; "Concurrent Capacity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many people have worked concurrently on this entry.';
                    Visible = false;
                }
                field("Setup Time"; "Setup Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how long it takes to set up the machines for this entry.';
                    Visible = false;
                }
                field("Run Time"; "Run Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the run time of this entry.';
                    Visible = false;
                }
                field("Stop Time"; "Stop Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the stop time of this entry.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the quantity of this entry, in base units of measure.';
                }
                field("Output Quantity"; "Output Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the output quantity, in base units of measure.';
                }
                field("Scrap Quantity"; "Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the scrap quantity, in base units of measure.';
                }
                field("Direct Cost"; "Direct Cost")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the direct cost in LCY of the quantity posting.';
                }
                field("Overhead Cost"; "Overhead Cost")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the overhead cost in LCY of the quantity posting.';
                }
                field("Direct Cost (ACY)"; "Direct Cost (ACY)")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the direct cost in the additional reporting currency.';
                    Visible = false;
                }
                field("Overhead Cost (ACY)"; "Overhead Cost (ACY)")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the overhead cost in the additional reporting currency.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Stop Code"; "Stop Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the stop code.';
                    Visible = false;
                }
                field("Scrap Code"; "Scrap Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies why an item has been scrapped.';
                    Visible = false;
                }
                field("Completely Invoiced"; "Completely Invoiced")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies if the entry has been fully invoiced or if more posted invoices are expected.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Dimension Set ID"; "Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
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
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
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
                        ShowDimensions;
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter);
                    end;
                }
                action("&Value Entries")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Value Entries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Capacity Ledger Entry No." = FIELD("Entry No.");
                    RunPageView = SORTING("Capacity Ledger Entry No.", "Entry Type");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    if "Order Type" = "Order Type"::Production then
                        Navigate.SetDoc("Posting Date", "Order No.")
                    else
                        Navigate.SetDoc("Posting Date", '');
                    Navigate.Run;
                end;
            }
        }
    }

    var
        Text000: Label 'Machine Center';
        DimensionSetIDFilter: Page "Dimension Set ID Filter";

    local procedure GetCaption(): Text[250]
    var
        ObjTransl: Record "Object Translation";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ProdOrder: Record "Production Order";
        SourceTableName: Text[100];
        SourceFilter: Text;
        Description: Text[100];
    begin
        Description := '';

        case true of
            GetFilter("Work Center No.") <> '':
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 99000754);
                    SourceFilter := GetFilter("Work Center No.");
                    if MaxStrLen(WorkCenter."No.") >= StrLen(SourceFilter) then
                        if WorkCenter.Get(SourceFilter) then
                            Description := WorkCenter.Name;
                end;
            (GetFilter("No.") <> '') and (GetFilter(Type) = Text000):
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 99000758);
                    SourceFilter := GetFilter("No.");
                    if MaxStrLen(MachineCenter."No.") >= StrLen(SourceFilter) then
                        if MachineCenter.Get(SourceFilter) then
                            Description := MachineCenter.Name;
                end;
            (GetFilter("Order No.") <> '') and ("Order Type" = "Order Type"::Production):
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 5405);
                    SourceFilter := GetFilter("Order No.");
                    if MaxStrLen(ProdOrder."No.") >= StrLen(SourceFilter) then
                        if ProdOrder.Get(ProdOrder.Status::Released, SourceFilter) or
                           ProdOrder.Get(ProdOrder.Status::Finished, SourceFilter)
                        then begin
                            SourceTableName := StrSubstNo('%1 %2', ProdOrder.Status, SourceTableName);
                            Description := ProdOrder.Description;
                        end;
                end;
        end;
        exit(StrSubstNo('%1 %2 %3', SourceTableName, SourceFilter, Description));
    end;
}

