page 7153 "Item Analysis View Entries"
{
    Caption = 'Analysis View Entries';
    DataCaptionFields = "Analysis View Code";
    Editable = false;
    PageType = List;
    SourceTable = "Item Analysis View Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item Ledger Entry Type"; "Item Ledger Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction that the entry is created from.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value entry type for an analysis view entry.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item number to which the item ledger entry in an analysis view entry was posted.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location to which the item ledger entry in an analysis view entry was posted.';
                }
                field("Dimension 1 Value Code"; "Dimension 1 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 1 on the analysis view card.';
                }
                field("Dimension 2 Value Code"; "Dimension 2 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 2 on the analysis view card.';
                }
                field("Dimension 3 Value Code"; "Dimension 3 Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 3 on the analysis view card.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the item ledger entry in an analysis view entry was posted.';
                }
                field("Sales Amount (Actual)"; "Sales Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the actual sales amounts posted for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field("Sales Amount (Expected)"; "Sales Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the expected sales amounts posted for the item ledger entries, included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field("Cost Amount (Actual)"; "Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the actual cost amounts posted for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field("Cost Amount (Expected)"; "Cost Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the expected cost amounts posted for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field("Cost Amount (Non-Invtbl.)"; "Cost Amount (Non-Invtbl.)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the non-inventoriable cost amounts posted for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the quantity for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
                }
                field("Invoiced Quantity"; "Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of the quantity invoiced for the item ledger entries included in the analysis view entry.';

                    trigger OnDrillDown()
                    begin
                        DrillDown;
                    end;
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
    }

    trigger OnAfterGetCurrRecord()
    begin
        if "Analysis View Code" <> xRec."Analysis View Code" then;
    end;

    var
        TempValueEntry: Record "Value Entry" temporary;

    local procedure DrillDown()
    begin
        SetAnalysisViewEntry(Rec);
        TempValueEntry.FilterGroup(DATABASE::"Item Analysis View Entry"); // Trick: FILTERGROUP is used to transfer an integer value
        PAGE.RunModal(PAGE::"Value Entries", TempValueEntry);
    end;

    procedure SetAnalysisViewEntry(ItemAnalysisViewEntry: Record "Item Analysis View Entry")
    var
        ItemAViewEntryToValueEntries: Codeunit ItemAViewEntryToValueEntries;
    begin
        TempValueEntry.Reset();
        TempValueEntry.DeleteAll();
        ItemAViewEntryToValueEntries.GetValueEntries(ItemAnalysisViewEntry, TempValueEntry);
    end;
}

