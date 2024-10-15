namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using System.Globalization;

page 5832 "Capacity Ledger Entries"
{
    ApplicationArea = Assembly, Manufacturing;
    Caption = 'Capacity Ledger Entries';
    DataCaptionExpression = GetCaption();
    Editable = false;
    PageType = List;
    SourceTable = "Capacity Ledger Entry";
    SourceTableView = sorting("Entry No.")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the posting date of the entry.';
                }
                field("Order Type"; Rec."Order Type")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies which type of order the entry was created in.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the number of the order that created the entry.';
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the routing number belonging to the entry.';
                    Visible = false;
                }
                field("Routing Reference No."; Rec."Routing Reference No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies that the routing reference number corresponding to the routing reference number of the line.';
                    Visible = false;
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the work center number of the journal line.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the type of capacity entry.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the document number of the entry.';
                    Visible = false;
                }
                field("Operation No."; Rec."Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the operation associated with the entry.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the item number.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Work Shift Code"; Rec."Work Shift Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the work shift that this machine center was planned at, or in which work shift the related production operation took place.';
                    Visible = false;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting time of the capacity posted with this entry.';
                    Visible = false;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending time of the capacity posted with this entry.';
                    Visible = false;
                }
                field("Concurrent Capacity"; Rec."Concurrent Capacity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many people have worked concurrently on this entry.';
                    Visible = false;
                }
                field("Setup Time"; Rec."Setup Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how long it takes to set up the machines for this entry.';
                    Visible = false;
                }
                field("Run Time"; Rec."Run Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the run time of this entry.';
                    Visible = false;
                }
                field("Stop Time"; Rec."Stop Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the stop time of this entry.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the quantity of this entry, in base units of measure.';
                }
                field("Output Quantity"; Rec."Output Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the output quantity, in base units of measure.';
                }
                field("Scrap Quantity"; Rec."Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the scrap quantity, in base units of measure.';
                }
                field("Direct Cost"; Rec."Direct Cost")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the direct cost in LCY of the quantity posting.';
                }
                field("Overhead Cost"; Rec."Overhead Cost")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the overhead cost in LCY of the quantity posting.';
                }
                field("Direct Cost (ACY)"; Rec."Direct Cost (ACY)")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the direct cost in the additional reporting currency.';
                    Visible = false;
                }
                field("Overhead Cost (ACY)"; Rec."Overhead Cost (ACY)")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the overhead cost in the additional reporting currency.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = Dim2Visible;
                }
                field("Stop Code"; Rec."Stop Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the stop code.';
                    Visible = false;
                }
                field("Scrap Code"; Rec."Scrap Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies why an item has been scrapped.';
                    Visible = false;
                }
                field("Completely Invoiced"; Rec."Completely Invoiced")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies if the entry has been fully invoiced or if more posted invoices are expected.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Assembly, Manufacturing;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
                    Visible = Dim8Visible;
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
                        Rec.ShowDimensions();
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
                        Rec.SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter());
                    end;
                }
                action("&Value Entries")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Value Entries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Capacity Ledger Entry No." = field("Entry No.");
                    RunPageView = sorting("Capacity Ledger Entry No.", "Entry Type");
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
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    if Rec."Order Type" = Rec."Order Type"::Production then
                        Navigate.SetDoc(Rec."Posting Date", Rec."Order No.")
                    else
                        Navigate.SetDoc(Rec."Posting Date", '');
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                group(Category_Entry)
                {
                    Caption = 'Entry';

                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                    actionref(SetDimensionFilter_Promoted; SetDimensionFilter)
                    {
                    }
                    actionref("&Value Entries_Promoted"; "&Value Entries")
                    {
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        DimensionSetIDFilter: Page "Dimension Set ID Filter";

#pragma warning disable AA0074
        Text000: Label 'Machine Center';
#pragma warning restore AA0074

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;

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
            Rec.GetFilter("Work Center No.") <> '':
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 99000754);
                    SourceFilter := Rec.GetFilter("Work Center No.");
                    if MaxStrLen(WorkCenter."No.") >= StrLen(SourceFilter) then
                        if WorkCenter.Get(SourceFilter) then
                            Description := WorkCenter.Name;
                end;
            (Rec.GetFilter("No.") <> '') and (Rec.GetFilter(Type) = Text000):
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 99000758);
                    SourceFilter := Rec.GetFilter("No.");
                    if MaxStrLen(MachineCenter."No.") >= StrLen(SourceFilter) then
                        if MachineCenter.Get(SourceFilter) then
                            Description := MachineCenter.Name;
                end;
            (Rec.GetFilter("Order No.") <> '') and (Rec."Order Type" = Rec."Order Type"::Production):
                begin
                    SourceTableName := ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, 5405);
                    SourceFilter := Rec.GetFilter("Order No.");
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

