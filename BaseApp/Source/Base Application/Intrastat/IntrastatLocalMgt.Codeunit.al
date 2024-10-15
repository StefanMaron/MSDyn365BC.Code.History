codeunit 11403 "Intrastat Local Mgt."
{
    trigger OnRun()
    begin
    end;

    internal procedure CheckIntrastatJournalLineForCorrection(IntrastatJnlLine: Record "Intrastat Jnl. Line"; var ItemDirectionType: Option): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        IF ItemLedgerEntry.Get(IntrastatJnlLine."Source Entry No.") then
            case ItemLedgerEntry."Document Type" of
                ItemLedgerEntry."Document Type"::"Purchase Return Shipment",
                ItemLedgerEntry."Document Type"::"Purchase Credit Memo":
                    begin
                        ItemDirectionType := IntrastatJnlLine.Type::Receipt;
                        exit(true);
                    end;
                ItemLedgerEntry."Document Type"::"Sales Return Receipt",
                ItemLedgerEntry."Document Type"::"Sales Credit Memo",
                ItemLedgerEntry."Document Type"::"Service Credit Memo":
                    begin
                        ItemDirectionType := IntrastatJnlLine.Type::Shipment;
                        exit(true);
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Get Item Ledger Entries", 'OnBeforeInsertItemJnlLine', '', false, false)]
    local procedure IntrastatOnBeforeInsertItemJnlLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
        IntrastatLineCheckUpdate(IntrastatJnlLine);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Get Item Ledger Entries", 'OnBeforeInsertJobLedgerLine', '', false, false)]
    local procedure IntrastatOnBeforeInsertJobLedgerLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; JobLedgerEntry: Record "Job Ledger Entry"; var IsHandled: Boolean)
    begin
        IntrastatLineCheckUpdate(IntrastatJnlLine);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Get Item Ledger Entries", 'OnBeforeInsertValueEntryLine', '', false, false)]
    local procedure IntrastatOnBeforeInsertValueEntryLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
        IntrastatLineCheckUpdate(IntrastatJnlLine);
    end;

    local procedure IntrastatLineCheckUpdate(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IF CheckIntrastatJournalLineForCorrection(IntrastatJnlLine, IntrastatJnlLine.Type) then begin
            IntrastatJnlLine.Quantity := -IntrastatJnlLine.Quantity;
            IntrastatJnlLine."Total Weight" := -IntrastatJnlLine."Total Weight";
            IntrastatJnlLine."Statistical Value" := -IntrastatJnlLine."Statistical Value";
            IntrastatJnlLine.Amount := -IntrastatJnlLine.Amount;
        end;
    end;
}

