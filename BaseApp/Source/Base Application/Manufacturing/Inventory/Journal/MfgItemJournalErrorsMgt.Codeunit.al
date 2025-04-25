// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Journal;

codeunit 99000761 "Mfg. Item Journal Errors Mgt."
{
    var
        ItemJournalErrorsMgt: Codeunit "Item Journal Errors Mgt.";

    [EventSubscriber(ObjectType::Page, Page::"Capacity Journal", 'OnDeleteRecordEvent', '', true, true)]
    local procedure OnDeleteRecordEventCapacityJournal(var Rec: Record "Item Journal Line"; var AllowDelete: Boolean)
    begin
        ItemJournalErrorsMgt.InsertDeletedItemJnlLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Capacity Journal", 'OnModifyRecordEvent', '', true, true)]
    local procedure OnModifyRecordEventCapacityJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowModify: Boolean)
    begin
        ItemJournalErrorsMgt.SetItemJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Capacity Journal", 'OnInsertRecordEvent', '', true, true)]
    local procedure OnInsertRecordEventCapacityJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowInsert: Boolean)
    begin
        ItemJournalErrorsMgt.SetItemJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Consumption Journal", 'OnDeleteRecordEvent', '', true, true)]
    local procedure OnDeleteRecordEventConsumptionJournal(var Rec: Record "Item Journal Line"; var AllowDelete: Boolean)
    begin
        ItemJournalErrorsMgt.InsertDeletedItemJnlLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Consumption Journal", 'OnModifyRecordEvent', '', true, true)]
    local procedure OnModifyRecordEventConsumptionJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowModify: Boolean)
    begin
        ItemJournalErrorsMgt.SetItemJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Consumption Journal", 'OnInsertRecordEvent', '', true, true)]
    local procedure OnInsertRecordEventConsumptionJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowInsert: Boolean)
    begin
        ItemJournalErrorsMgt.SetItemJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Output Journal", 'OnDeleteRecordEvent', '', true, true)]
    local procedure OnDeleteRecordEventOutputJournal(var Rec: Record "Item Journal Line"; var AllowDelete: Boolean)
    begin
        ItemJournalErrorsMgt.InsertDeletedItemJnlLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Output Journal", 'OnModifyRecordEvent', '', true, true)]
    local procedure OnModifyRecordEventOutputJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowModify: Boolean)
    begin
        ItemJournalErrorsMgt.SetItemJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Output Journal", 'OnInsertRecordEvent', '', true, true)]
    local procedure OnInsertRecordEventOutputJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowInsert: Boolean)
    begin
        ItemJournalErrorsMgt.SetItemJnlLineOnModify(Rec);
    end;
}