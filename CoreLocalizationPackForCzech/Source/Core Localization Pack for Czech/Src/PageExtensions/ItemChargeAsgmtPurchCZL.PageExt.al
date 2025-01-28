// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Ledger;

pageextension 31103 "Item Charge Asgmt. (Purch) CZL" extends "Item Charge Assignment (Purch)"
{
#if not CLEAN22
    layout
    {
        addlast(Control1)
        {
            field("Incl. in Intrastat Amount CZL"; Rec."Incl. in Intrastat Amount CZL")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Incl. in Intrastat Amount (Obsolete)';
                ToolTip = 'Specifies whether additional cost of the item should be included in the Intrastat amount.';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
            }
            field("Incl. in Intrastat S.Value CZL"; Rec."Incl. in Intrastat S.Value CZL")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Incl. in Intrastat Stat. Value (Obsolete)';
                ToolTip = 'Specifies whether additional cost of the item should be included in the Intrastat statistical value.';
                ObsoleteState = Pending;
                ObsoleteTag = '22.0';
                ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
            }
        }
    }
#endif
    actions
    {
        addafter(SuggestItemChargeAssignment)
        {
            action(GetPosAdjLedgerEntriesCZL)
            {
                AccessByPermission = TableData "Item Ledger Entry" = R;
                ApplicationArea = Basic, Suite;
                Caption = 'Get Positive Adjmt. Ledger Entries';
                Image = ReceiveLoaner;
                ToolTip = 'Open the page for the selection of the posting item ledger entries.';

                trigger OnAction()
                var
                    ItemLedgerEntry: Record "Item Ledger Entry";
                    ItemChargeAssigmentPurch: Record "Item Charge Assignment (Purch)";
                begin
                    ItemChargeAssigmentPurch.SetRange("Document Type", Rec."Document Type");
                    ItemChargeAssigmentPurch.SetRange("Document No.", Rec."Document No.");
                    ItemChargeAssigmentPurch.SetRange("Document Line No.", Rec."Document Line No.");
                    if not ItemChargeAssigmentPurch.FindLast() then
                        ItemChargeAssigmentPurch := Rec;

                    ItemLedgerEntry.FilterGroup(2);
                    ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
                    ItemLedgerEntry.SetRange(Positive, true);
                    ItemLedgerEntry.FilterGroup(0);
                    OnGetPosAdjLedgerEntrieOnActionOnAfterItemChargeAssgntPurchSetFiltersCZL(Rec, ItemLedgerEntry);

                    OpenItemLedgerEntries(ItemChargeAssigmentPurch, ItemLedgerEntry);
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(GetPosAdjLedgerEntriesCZLPromotedCZL; GetPosAdjLedgerEntriesCZL)
            {
            }
        }
    }

    local procedure OpenItemLedgerEntries(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        AssignItemChargeAssgntPurchCZL: Codeunit "Item Charge Assgnt. Purch. CZL";
        ItemLedgerEntriesPage: Page "Item Ledger Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenItemLedgerEntriesCZL(Rec, ItemChargeAssignmentPurch, IsHandled);
        if IsHandled then
            exit;

        ItemLedgerEntriesPage.SetTableView(ItemLedgerEntry);
        ItemLedgerEntriesPage.LookupMode(true);
        if ItemLedgerEntriesPage.RunModal() = Action::LookupOK then begin
            ItemLedgerEntriesPage.SetSelectionFilter(ItemLedgerEntry);
            if not ItemLedgerEntry.IsEmpty() then begin
                ItemChargeAssignmentPurch."Unit Cost" := PurchLine2."Unit Cost";
                AssignItemChargeAssgntPurchCZL.CreateItemEntryChargeAssgnt(ItemLedgerEntry, ItemChargeAssignmentPurch);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPosAdjLedgerEntrieOnActionOnAfterItemChargeAssgntPurchSetFiltersCZL(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemLedgerEntriesCZL(var RecItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;
}
