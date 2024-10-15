// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

pageextension 13613 GeneralJournal extends "General Journal"
{
    actions
    {
        addafter(ImportBankStatement)
        {
            action(ImportFIK)
            {
                Caption = 'Import FIK Statement';
                ToolTip = 'Import a file with FIK payments. The Fik payments are automatically applied as suggestions.';
                Promoted = true;
                Visible = false;
                PromotedIsBig = true;
                Image = Import;
                PromotedCategory = Category4;
                trigger OnAction();
                var
                    FIKMgt: Codeunit FIKManagement;
                begin
                    IF FINDLAST() THEN;
                    FIKMgt.ImportFIKGenJournalLine(Rec);
                    CODEUNIT.RUN(CODEUNIT::FIK_MatchGenJournalLines, Rec);
                    CurrPage.UPDATE(FALSE);
                end;
            }
        }
    }
}