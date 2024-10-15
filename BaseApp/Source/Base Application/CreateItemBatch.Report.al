report 17206 "Create Item Batch"
{
    Caption = 'Create Item Batch';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Item Application Entry"; "Item Application Entry")
        {
            DataItemTableView = SORTING("Entry No.");
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Entry No." = FIELD("Item Ledger Entry No.");
                DataItemTableView = SORTING("Entry No.") WHERE("Entry Type" = FILTER(<> Transfer));

                trigger OnAfterGetRecord()
                begin
                    if Quantity >= 0 then
                        ItemLedgEntry."Entry No." := "Entry No."
                    else begin
                        if not ItemLedgEntry.Get(ItemApplEntry."Inbound Item Entry No.") then
                            CurrReport.Skip();
                        while ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Transfer do begin
                            ItemApplEntry0.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                            ItemApplEntry0.FindFirst();
                            if ItemApplEntry0."Transferred-from Entry No." = 0 then
                                ItemApplEntry0."Transferred-from Entry No." := ItemApplEntry0."Transferred-from Entry No.";
                            if not ItemLedgEntry.Get(ItemApplEntry0."Transferred-from Entry No.") then
                                CurrReport.Skip();
                        end;
                    end;
                    ItemApplEntry."Batch Item Ledger Entry No." := ItemLedgEntry."Entry No.";
                    ItemApplEntry.Modify();
                end;

                trigger OnPreDataItem()
                begin
                    ItemApplEntry0.SetCurrentKey("Item Ledger Entry No.");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ItemApplEntry := "Item Application Entry";
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplEntry: Record "Item Application Entry";
        ItemApplEntry0: Record "Item Application Entry";
}

