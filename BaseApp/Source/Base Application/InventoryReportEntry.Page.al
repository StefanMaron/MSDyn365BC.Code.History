page 5846 "Inventory Report Entry"
{
    Caption = 'Inventory Report Entry';
    PageType = List;
    SourceTable = "Inventory Report Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the inventory report entry refers to an item or a general ledger account.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory report entry.';
                }
                field(Inventory; Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInventory(Rec);
                    end;
                }
                field("Inventory (Interim)"; "Inventory (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInventoryInterim(Rec);
                    end;
                }
                field("WIP Inventory"; "WIP Inventory")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownWIPInventory(Rec);
                    end;
                }
#if not CLEAN18
                field(Consumption; Consumption)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the consumption value.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownConsumption(Rec);
                    end;
                }
                field("Change In Inv.Of WIP"; "Change In Inv.Of WIP")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the change in inventory for the work in process (WIP) value.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownChInvWip(Rec);
                    end;
                }
                field("Change In Inv.Of Product"; "Change In Inv.Of Product")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the change in the inventory product value.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownChInvProd(Rec);
                    end;
                }
#endif
                field("Direct Cost Applied Actual"; "Direct Cost Applied Actual")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownDirectCostApplActual(Rec);
                    end;
                }
                field("Overhead Applied Actual"; "Overhead Applied Actual")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownOverheadAppliedActual(Rec);
                    end;
                }
                field("Purchase Variance"; "Purchase Variance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownPurchaseVariance(Rec);
                    end;
                }
                field("Inventory Adjmt."; "Inventory Adjmt.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInventoryAdjmt(Rec);
                    end;
                }
                field("Invt. Accrual (Interim)"; "Invt. Accrual (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInvtAccrualInterim(Rec);
                    end;
                }
                field(COGS; COGS)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownCOGS(Rec);
                    end;
                }
                field("COGS (Interim)"; "COGS (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownCOGSInterim(Rec);
                    end;
                }
                field("Material Variance"; "Material Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownMaterialVariance(Rec);
                    end;
                }
                field("Capacity Variance"; "Capacity Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownCapVariance(Rec);
                    end;
                }
                field("Subcontracted Variance"; "Subcontracted Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownSubcontractedVariance(Rec);
                    end;
                }
                field("Capacity Overhead Variance"; "Capacity Overhead Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownCapOverheadVariance(Rec);
                    end;
                }
                field("Mfg. Overhead Variance"; "Mfg. Overhead Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownMfgOverheadVariance(Rec);
                    end;
                }
                field("Direct Cost Applied WIP"; "Direct Cost Applied WIP")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownDirectCostApplToWIP(Rec);
                    end;
                }
                field("Overhead Applied WIP"; "Overhead Applied WIP")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        GetInvtReport.DrillDownOverheadAppliedToWIP(Rec);
                    end;
                }
                field("Inventory To WIP"; "Inventory To WIP")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInvtToWIP(Rec);
                    end;
                }
                field("WIP To Interim"; "WIP To Interim")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownWIPToInvtInterim(Rec);
                    end;
                }
                field("Direct Cost Applied"; "Direct Cost Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownDirectCostApplied(Rec);
                    end;
                }
                field("Overhead Applied"; "Overhead Applied")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownOverheadApplied(Rec);
                    end;
                }
#if not CLEAN18
                field("Inv. Rounding Adj."; "Inv. Rounding Adj.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the inventory rounding adjustment value.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInvAdjmtRnd(Rec);
                    end;
                }
#endif
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
    }

    var
        GetInvtReport: Codeunit "Get Inventory Report";
}

