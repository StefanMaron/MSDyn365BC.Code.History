// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using System;
using System.Environment.Configuration;

table 5392 "CRM Annotation Coupling"
{
    Caption = 'CRM Annotation Coupling';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Record Link Record ID"; RecordID)
        {
            Caption = 'Record Link Record ID';
            DataClassification = CustomerContent;
        }
        field(3; "CRM Annotation ID"; Guid)
        {
            Caption = 'CRM Annotation ID';
            DataClassification = SystemMetadata;
        }
        field(4; "Last Synch. DateTime"; DateTime)
        {
            Caption = 'Last Synch. DateTime';
            DataClassification = SystemMetadata;
        }
        field(5; "CRM Created On"; DateTime)
        {
            Caption = 'CRM Created On';
            DataClassification = SystemMetadata;
        }
        field(6; "CRM Modified On"; DateTime)
        {
            Caption = 'CRM Modified On';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Record Link Record ID", "CRM Annotation ID")
        {
            Clustered = true;
        }
        key(Key2; "Last Synch. DateTime")
        {
        }
        key(Key3; "CRM Created On")
        {
        }
        key(Key4; "CRM Modified On")
        {
        }
    }

    fieldgroups
    {
    }

    var
        RecordLinkAlreadyCoupledErr: Label 'Record Link %1 is already coupled to another CRM Annotation.', Comment = '%1 - an integer';
        CRMAnnotationAlreadyCoupledErr: Label 'CRM Annotation %1 is already coupled to another Record Link.', Comment = '%1 - a GUID';

    [Scope('OnPrem')]
    procedure CoupleRecordLinkToCRMAnnotation(RecordLink: Record "Record Link"; CRMAnnotation: Record "CRM Annotation")
    begin
        if Get(RecordLink.RecordId, CRMAnnotation.AnnotationId) then
            exit;

        if FindByRecordId(RecordLink.RecordId) then
            Error(RecordLinkAlreadyCoupledErr, RecordLink."Link ID");

        if FindByCRMId(CRMAnnotation.AnnotationId) then
            Error(CRMAnnotationAlreadyCoupledErr, CRMAnnotation.AnnotationId);

        Init();
        "Record Link Record ID" := RecordLink.RecordId;
        "CRM Annotation ID" := CRMAnnotation.AnnotationId;
        "Last Synch. DateTime" := CurrentDateTime;
        "CRM Created On" := CRMAnnotation.CreatedOn;
        "CRM Modified On" := CRMAnnotation.ModifiedOn;
        Insert();
    end;

    [Scope('OnPrem')]
    procedure FindByRecordId(RecordId: RecordID): Boolean
    begin
        SetRange("Record Link Record ID", RecordId);
        exit(FindFirst());
    end;

    [Scope('OnPrem')]
    procedure FindByCRMId(CRMId: Guid): Boolean
    begin
        SetRange("CRM Annotation ID", CRMId);
        exit(FindFirst());
    end;

    [Scope('OnPrem')]
    procedure ExtractNoteText(AnnotationText: Text): Text
    var
        HttpUtility: DotNet HttpUtility;
        LastIndexOfSlashDiv: Integer;
        NoteLineStartIndex: Integer;
        PlainNoteText: Text;
        NoteLine: Text;
        CurrentAnnotationText: Text;
        LF: Char;
    begin
        LF := 10;
        LastIndexOfSlashDiv := AnnotationText.LastIndexOf('</div>');
        if LastIndexOfSlashDiv = 0 then
            exit(AnnotationText);

        CurrentAnnotationText := AnnotationText;
        repeat
            CurrentAnnotationText := CopyStr(CurrentAnnotationText, 1, LastIndexOfSlashDiv - 1);
            NoteLineStartIndex := CurrentAnnotationText.LastIndexOf('div>');
            if NoteLineStartIndex <= 0 then
                exit(AnnotationText);
            NoteLineStartIndex += 4;
            NoteLine := CopyStr(CurrentAnnotationText, NoteLineStartIndex, StrLen(CurrentAnnotationText) - NoteLineStartIndex + 1);
            NoteLine := HttpUtility.HtmlDecode(NoteLine);
            RemoveHTMLStyleTagsFromNoteLine(NoteLine);
            if PlainNoteText = '' then
                PlainNoteText := NoteLine
            else
                PlainNoteText := NoteLine + LF + PlainNoteText;
            LastIndexOfSlashDiv := CurrentAnnotationText.LastIndexOf('</div>');
        until LastIndexOfSlashDiv = 0;
        exit(PlainNoteText)
    end;

    local procedure RemoveHTMLStyleTagsFromNoteLine(var NoteLine: Text)
    begin
        NoteLine := NoteLine.Replace('<br>', '');
        NoteLine := NoteLine.Replace('<br/>', '');
        NoteLine := NoteLine.Replace('<br />', '');
        NoteLine := NoteLine.Replace('<i>', '');
        NoteLine := NoteLine.Replace('</i>', '');
        NoteLine := NoteLine.Replace('<b>', '');
        NoteLine := NoteLine.Replace('</b>', '');
        NoteLine := NoteLine.Replace('<u>', '');
        NoteLine := NoteLine.Replace('</u>', '');
        NoteLine := NoteLine.Replace('<s>', '');
        NoteLine := NoteLine.Replace('</s>', '');
        NoteLine := NoteLine.Replace('<strong>', '');
        NoteLine := NoteLine.Replace('</strong>', '');
        NoteLine := NoteLine.Replace('<em>', '');
        NoteLine := NoteLine.Replace('</em>', '');
        NoteLine := NoteLine.Replace('<small>', '');
        NoteLine := NoteLine.Replace('</small>', '');
        NoteLine := NoteLine.Replace('<hr>', '');
        NoteLine := NoteLine.Replace('<hr/>', '');
        NoteLine := NoteLine.Replace('<hr />', '');
        NoteLine := NoteLine.Replace('<p>', '');
        NoteLine := NoteLine.Replace('</p>', '');
        NoteLine := NoteLine.Replace('</span>', '');
        RemoveSpanTags(NoteLine);
    end;

    local procedure RemoveSpanTags(var NoteLine: Text)
    var
        LeftPart: Text;
        RightPart: Text;
        IndexOfSpan: Integer;
        IndexOfSpanEnding: Integer;
    begin
        IndexOfSpan := NoteLine.IndexOf('<span');
        while IndexOfSpan > 0 do begin
            LeftPart := CopyStr(NoteLine, 1, IndexOfSpan - 1);
            RightPart := CopyStr(NoteLine, IndexOfSpan);
            IndexOfSpanEnding := RightPart.IndexOf('>');
            if IndexOfSpanEnding = 0 then
                exit;
            if IndexOfSpanEnding = StrLen(RightPart) then
                RightPart := ''
            else
                RightPart := CopyStr(RightPart, IndexOfSpanEnding + 1);
            NoteLine := LeftPart + RightPart;
            IndexOfSpan := NoteLine.IndexOf('<span');
        end;
    end;
}

