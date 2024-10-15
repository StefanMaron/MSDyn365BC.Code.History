﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 4470 "Record Link Impl."
{
    Access = Internal;
    SingleInstance = true;

    var
        RecordLinkManagement: Codeunit "Record Link Management";
        RemoveLinkConfirmQst: Label 'Do you want to remove links with no record reference?';
        RemovingMsg: Label 'Removing Record Links without record reference.\';
        RemovingStatusMsg: Label '@1@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
        ResultMsg: Label '%1 orphaned links were removed.', Comment = '%1 = number of orphaned record links found.';

    local procedure ResetNotifyOnLinks(RecVar: Variant)
    var
        RecordLink: Record "Record Link";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        RecordLink.SetRange("Record ID", RecRef.RecordId());
        RecordLink.SetRange(Notify, true);
        if not RecordLink.IsEmpty() then
            RecordLink.ModifyAll(Notify, false);
    end;

    procedure CopyLinks(FromRecord: Variant; ToRecord: Variant)
    var
        RecRefTo: RecordRef;
    begin
        RecRefTo.GetTable(ToRecord);
        RecRefTo.CopyLinks(FromRecord);
        ResetNotifyOnLinks(RecRefTo);
        RecordLinkManagement.OnAfterCopyLinks(FromRecord, ToRecord);
    end;

    procedure WriteNote(var RecordLink: Record "Record Link"; Note: Text)
    var
        BinWriter: DotNet BinaryWriter;
        OStr: OutStream;
    begin
        RecordLink.Note.CreateOutStream(OStr, TEXTENCODING::UTF8);
        BinWriter := BinWriter.BinaryWriter(OStr);
        BinWriter.Write(Note);
    end;

    procedure ReadNote(RecordLink: Record "Record Link") Note: Text
    var
        BinReader: DotNet BinaryReader;
        IStr: InStream;
    begin
        RecordLink.Note.CreateInStream(IStr, TEXTENCODING::UTF8);
        BinReader := BinReader.BinaryReader(IStr);
        // Peek if stream is empty
        if BinReader.BaseStream().Position() = BinReader.BaseStream().Length() then
            exit;
        Note := BinReader.ReadString();
    end;

    procedure RemoveOrphanedLinks()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        NoOfRemovedLinks: Integer;
    begin
        if ConfirmManagement.GetResponseOrDefault(RemoveLinkConfirmQst, true) then begin
            NoOfRemovedLinks := RemoveOrphanedLink();
            if GuiAllowed() then
                Message(ResultMsg, NoOfRemovedLinks);
        end;
    end;

    local procedure RemoveOrphanedLink() NoOfRemovedLinks: Integer
    var
        RecordLink: Record "Record Link";
        RecordRef: RecordRef;
        PrevRecID: RecordID;
        Window: Dialog;
        i: Integer;
        Total: Integer;
        TimeLocked: Time;
        InTransaction: Boolean;
        RecordExists: Boolean;
    begin
        if GuiAllowed() then
            Window.Open(RemovingMsg + RemovingStatusMsg);
        TimeLocked := Time();
        with RecordLink do begin
            SetFilter(Company, '%1|%2', '', CompanyName());
            SetCurrentKey("Record ID");
            Total := Count();
            if Total = 0 then
                exit;
            InTransaction := false;
            if Find('-') then
                repeat
                    i := i + 1;
                    if GuiAllowed() and ((i mod 1000) = 0) then
                        Window.Update(1, Round(i / Total * 10000, 1));
                    if Format("Record ID") <> Format(PrevRecID) then begin  // Direct comparison doesn't work.
                        PrevRecID := "Record ID";
                        RecordExists := RecordRef.Get("Record ID");
                    end;
                    if not RecordExists then begin
                        Delete();
                        NoOfRemovedLinks += 1;
                        if not InTransaction then
                            TimeLocked := Time();
                        InTransaction := true;
                    end;
                    if InTransaction and (Time() > (TimeLocked + 1000)) then begin
                        Commit();
                        TimeLocked := Time();
                        InTransaction := false;
                    end;
                until Next() = 0;
        end;
        if GuiAllowed() then
            Window.Close();
    end;
}

