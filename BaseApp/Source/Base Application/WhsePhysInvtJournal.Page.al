page 7326 "Whse. Phys. Invt. Journal"
{
    AdditionalSearchTerms = 'physical count';
    ApplicationArea = Warehouse;
    AutoSplitKey = true;
    Caption = 'Warehouse Physical Inventory Journal';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Post/Print,Item,Line';
    SaveValues = true;
    SourceTable = "Warehouse Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Warehouse;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord;
                    LookupName(CurrentJnlBatchName, CurrentLocationCode, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    CheckName(CurrentJnlBatchName, CurrentLocationCode, Rec);
                    CurrentJnlBatchNameOnAfterVali;
                end;
            }
            field(CurrentLocationCode; CurrentLocationCode)
            {
                ApplicationArea = Warehouse;
                Caption = 'Location Code';
                Editable = false;
                Lookup = true;
                TableRelation = Location;
                ToolTip = 'Specifies the code for the location where the warehouse activity takes place.';
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Registering Date"; "Registering Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date the line is registered.';
                }
                field("Whse. Document No."; "Whse. Document No.")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Whse. Document No.';
                    ToolTip = 'Specifies the warehouse document number of the journal line.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item on the journal line.';

                    trigger OnValidate()
                    begin
                        GetItem("Item No.", ItemDescription);
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
                    ToolTip = 'Specifies the description of the item.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = SerialNoEditable;
                    ToolTip = 'Specifies the same as for the field in the Item Journal window.';
                    Visible = false;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = LotNoEditable;
                    ToolTip = 'Specifies the same as for the field in the Item Journal window.';
                    Visible = false;
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the zone code where the bin on this line is located.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field("Qty. (Calculated) (Base)"; "Qty. (Calculated) (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the same as for the field in the Item Journal window.';
                    Visible = false;
                }
                field("Qty. (Phys. Inventory) (Base)"; "Qty. (Phys. Inventory) (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the same as for the field in the Item Journal window.';
                    Visible = false;
                }
                field("Qty. (Calculated)"; "Qty. (Calculated)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the bin item that is calculated when you use the function, Calculate Inventory, in the Whse. Physical Inventory Journal.';
                }
                field("Qty. (Phys. Inventory)"; "Qty. (Phys. Inventory)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items in the bin that you have counted.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of units of the item in the adjustment (positive or negative) or the reclassification.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Reason Code';
                    ToolTip = 'Specifies the reason code for the warehouse journal line.';
                    Visible = false;
                }
                field("Phys Invt Counting Period Type"; "Phys Invt Counting Period Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether the physical inventory counting period was assigned to a stockkeeping unit or an item.';
                    Visible = false;
                }
                field("Phys Invt Counting Period Code"; "Phys Invt Counting Period Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a code for the physical inventory counting period, if the counting period functionality was used when the line was created.';
                    Visible = false;
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
                    PromotedCategory = Category6;
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
                action("Calculate &Inventory")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate &Inventory';
                    Ellipsis = true;
                    Image = CalculateInventory;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Start the process of counting inventory by filling the journal with known quantities.';

                    trigger OnAction()
                    var
                        BinContent: Record "Bin Content";
                        WhseCalcInventory: Report "Whse. Calculate Inventory";
                    begin
                        BinContent.SetRange("Location Code", "Location Code");
                        WhseCalcInventory.SetWhseJnlLine(Rec);
                        WhseCalcInventory.SetTableView(BinContent);
                        WhseCalcInventory.SetProposalMode(true);
                        WhseCalcInventory.RunModal;
                        Clear(WhseCalcInventory);
                    end;
                }
                action("&Calculate Counting Period")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Calculate Counting Period';
                    Ellipsis = true;
                    Image = CalculateCalendar;
                    ToolTip = 'Show all items that a counting period has been assigned to, according to the counting period, the last counting period update, and the current work date.';

                    trigger OnAction()
                    var
                        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
                        SortingMethod: Option " ",Item,Bin;
                    begin
                        PhysInvtCountMgt.InitFromWhseJnl(Rec);
                        PhysInvtCountMgt.Run;

                        PhysInvtCountMgt.GetSortingMethod(SortingMethod);
                        case SortingMethod of
                            SortingMethod::Item:
                                SetCurrentKey("Location Code", "Item No.", "Variant Code");
                            SortingMethod::Bin:
                                SetCurrentKey("Location Code", "Bin Code");
                        end;

                        Clear(PhysInvtCountMgt);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    WhseJournalBatch.SetRange("Journal Template Name", "Journal Template Name");
                    WhseJournalBatch.SetRange(Name, "Journal Batch Name");
                    WhseJournalBatch.SetRange("Location Code", CurrentLocationCode);
                    WhsePhysInventoryList.SetTableView(WhseJournalBatch);
                    WhsePhysInventoryList.RunModal;
                    Clear(WhsePhysInventoryList);
                end;
            }
            group("&Registering")
            {
                Caption = '&Registering';
                Image = PostOrder;
                action("Test Report")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintWhseJnlLine(Rec);
                    end;
                }
                action("&Register")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Register';
                    Image = Confirm;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';
                    ToolTip = 'Register the warehouse entry in question, such as a positive adjustment. ';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register", Rec);
                        CurrentJnlBatchName := GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
                action("Register and &Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Register and &Print';
                    Image = ConfirmAndPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Register the warehouse entry adjustments and print an overview of the changes. ';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register+Print", Rec);
                        CurrentJnlBatchName := GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetItem("Item No.", ItemDescription);
        SetControls;
    end;

    trigger OnInit()
    begin
        LotNoEditable := true;
        SerialNoEditable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(xRec);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        if IsOpenedFromBatch then begin
            CurrentJnlBatchName := "Journal Batch Name";
            CurrentLocationCode := "Location Code";
            OpenJnl(CurrentJnlBatchName, CurrentLocationCode, Rec);
            exit;
        end;
        TemplateSelection(PAGE::"Whse. Phys. Invt. Journal", 1, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        OpenJnl(CurrentJnlBatchName, CurrentLocationCode, Rec);
    end;

    var
        WhseJournalBatch: Record "Warehouse Journal Batch";
        WhsePhysInventoryList: Report "Whse. Phys. Inventory List";
        ReportPrint: Codeunit "Test Report-Print";
        CurrentJnlBatchName: Code[10];
        CurrentLocationCode: Code[10];
        ItemDescription: Text[100];
        [InDataSet]
        SerialNoEditable: Boolean;
        [InDataSet]
        LotNoEditable: Boolean;

    procedure SetControls()
    begin
        SerialNoEditable := not "Phys. Inventory";
        LotNoEditable := not "Phys. Inventory";
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord;
        SetName(CurrentJnlBatchName, CurrentLocationCode, Rec);
        CurrPage.Update(false);
    end;
}

