page 5877 "Physical Inventory Order Subf."
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Phys. Invt. Order Line";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item, which should be counted when taking the physical inventory.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies an additional description of the item.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the location where the item must be counted.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the item must be counted.';
                    Visible = false;
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit of measure, such as bottle or piece, that is currently used for the item.';
                    Visible = false;
                }
                field("Base Unit of Measure Code"; "Base Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the base unit of measure that is set up for the item.';
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number where the item can be found normally.';
                    Visible = false;
                }
                field("Qty. Expected (Base)"; "Qty. Expected (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the expected inventory quantity in the base unit of measure.';
                }
                field("Qty. Exp. Calculated"; "Qty. Exp. Calculated")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the Qty. Expected (Base) field has been updated with the Calculate Expected Qty. function.';
                }
                field("Qty. Exp. Item Tracking (Base)"; "Qty. Exp. Item Tracking (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item''s expected inventory of serial and lot numbers in the base unit of measure.';
                }
                field("Use Item Tracking"; "Use Item Tracking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the counting of the item is done by counting its serial and lot numbers.';
                }
                field("Qty. Recorded (Base)"; "Qty. Recorded (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the counted quantity in the base unit of measure on the physical inventory order line.';
                }
                field("On Recording Lines"; "On Recording Lines")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the item exists on one or more physical inventory recording lines.';
                }
                field("No. Finished Rec.-Lines"; "No. Finished Rec.-Lines")
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
                    ToolTip = 'Specifies how many of the related physical inventory recordings are closed.';
                }
                field("Recorded Without Order"; "Recorded Without Order")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that no physical inventory order lines existed for the recorded item, and that the line was generated based on the related recording.';
                    Visible = false;
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the difference in the Quantity (Base) field on the related closed recording is positive or negative.';
                    Visible = false;
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the difference between the Qty. Expected (Base) and the Qty. Recorded (Base) fields.';
                    Visible = false;
                }
                field("Pos. Qty. (Base)"; "Pos. Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
                    ToolTip = 'Specifies the positive difference between the Qty. Expected (Base) and the Qty. Recorded (Base) fields.';
                }
                field("Neg. Qty. (Base)"; "Neg. Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
                    ToolTip = 'Specifies the negative difference between the Qty. Expected (Base) and the Qty. Recorded (Base) fields.';
                }
                field("Unit Amount"; "Unit Amount")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit price of the item.';
                    Visible = false;
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit costs of the item, which will be used when posting the physical inventory.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible2;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Recording Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Recording Lines';
                    ToolTip = 'View one or more physical inventory recording lines where the selected item exists';

                    trigger OnAction()
                    begin
                        ShowPhysInvtRecordingLines;
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as a project or department, that are assigned to the physical inventory order line for financial analysis.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                group("Item &Tracking Lines")
                {
                    Caption = 'Item &Tracking Lines';
                    Image = AllLines;
                    action("E&xpected Tracking Lines")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'E&xpected Tracking Lines';
                        ToolTip = 'View the serial or lot numbers that are currently recorded (expected) for the item on the line.';

                        trigger OnAction()
                        begin
                            ShowExpectPhysInvtTrackLines;
                        end;
                    }
                    action("&All Diff. Tracking Lines")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&All Diff. Tracking Lines';
                        ToolTip = 'View the serial or lot numbers that are different on the related recording than currently recorded (expected) for the item on the line.';

                        trigger OnAction()
                        begin
                            ShowItemTrackingLines(0);
                        end;
                    }
                    action("&Pos. Diff. Tracking Lines")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Pos. Diff. Tracking Lines';
                        ToolTip = 'View the serial or lot numbers that are counted as more on the related recording than currently recorded (expected) for the item on the line.';

                        trigger OnAction()
                        begin
                            ShowItemTrackingLines(1);
                        end;
                    }
                    action("&Neg. Diff. Tracking Lines")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Neg. Diff. Tracking Lines';
                        ToolTip = 'View the serial or lot numbers that are counted as less on the related recording than currently recorded (expected) for the item on the line.';

                        trigger OnAction()
                        begin
                            ShowItemTrackingLines(2);
                        end;
                    }
                }
                group("E&ntries")
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Ledger E&ntries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Ledger E&ntries';
                        ToolTip = 'View the item''s item ledger entries.';

                        trigger OnAction()
                        begin
                            ShowItemLedgerEntries;
                        end;
                    }
                    action("&Phys. Inventory Ledger Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Phys. Inventory Ledger Entries';
                        Image = PhysicalInventoryLedger;
                        ToolTip = 'View the item''s physical inventory ledger entries, meaning the history of the item''s ledger entry changes from counting.';

                        trigger OnAction()
                        begin
                            ShowPhysInvtLedgerEntries;
                        end;
                    }
                }
                action("Bin Content (&Item)")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Content (&Item)';
                    ToolTip = 'View the item''s content in bins.';

                    trigger OnAction()
                    begin
                        ShowBinContentItem;
                    end;
                }
                action("Bin Content (&Bin)")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Content (&Bin)';
                    ToolTip = 'View the content of the bins where the item exists.';

                    trigger OnAction()
                    begin
                        ShowBinContentBin;
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate Expected &Qty.")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate Expected &Qty.';
                    Ellipsis = true;
                    Image = Line;
                    ToolTip = 'Update the value in the Qty. Expected (Base) field on the line with any inventory changes made since you created the order. When you have used this function, the Qty. Exp. Calculated check box is selected.';

                    trigger OnAction()
                    begin
                        CalculateQtyExpected;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility;
    end;

    var
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;

    procedure CalculateQtyExpected()
    var
        PhysInvtCalcQtyOne: Codeunit "Phys. Invt.-Calc. Qty. One";
    begin
        PhysInvtCalcQtyOne.Run(Rec);
        Clear(PhysInvtCalcQtyOne);
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;
}

