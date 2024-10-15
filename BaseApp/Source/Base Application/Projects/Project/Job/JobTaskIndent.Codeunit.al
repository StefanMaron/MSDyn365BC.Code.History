﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using System.Text;

codeunit 1003 "Job Task-Indent"
{
    TableNo = "Job Task";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        Rec.TestField("Job No.");

        IsHandled := false;
        OnRunOnBeforeConfirm(Rec, IsHandled);
        if not IsHandled then
            if not
               Confirm(
                 Text000 +
                 Text001 +
                 Text002 +
                 Text003, true)
            then
                exit;

        JobTask := Rec;
        Indent(Rec."Job No.");
    end;

    var
        JobTask: Record "Job Task";
        Window: Dialog;
        i: Integer;

#pragma warning disable AA0074
        Text000: Label 'This function updates the indentation of all the Project Tasks.';
        Text001: Label 'All Project Tasks between a Begin-Total and the matching End-Total are indented one level. ';
        Text002: Label 'The Totaling for each End-total is also updated.';
        Text003: Label '\\Do you want to indent the Project Tasks?';
#pragma warning disable AA0470
        Text004: Label 'Indenting the Project Tasks #1##########.';
        Text005: Label 'End-Total %1 is missing a matching Begin-Total.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ArrayExceededErr: Label 'You can only indent %1 levels for project tasks of the type Begin-Total.', Comment = '%1 = A number bigger than 1';

    procedure Indent(JobNo: Code[20])
    var
        SelectionFilterManagement: Codeunit "SelectionFilterManagement";
        JobTaskNo: array[10] of Text;
    begin
        Window.Open(Text004);
        JobTask.SetRange("Job No.", JobNo);
        if JobTask.Find('-') then
            repeat
                Window.Update(1, JobTask."Job Task No.");

                if JobTask."Job Task Type" = "Job Task Type"::"End-Total" then begin
                    if i < 1 then
                        Error(
                            Text005,
                            JobTask."Job Task No.");

                    JobTask.Totaling := JobTaskNo[i] + '..' + SelectionFilterManagement.AddQuotes(JobTask."Job Task No.");
                    i := i - 1;
                end;

                JobTask.Indentation := i;
                OnBeforeJobTaskModify(JobTask, JobNo);
                JobTask.Modify();

                if JobTask."Job Task Type" = "Job Task Type"::"Begin-Total" then begin
                    i := i + 1;
                    if i > ArrayLen(JobTaskNo) then
                        Error(ArrayExceededErr, ArrayLen(JobTaskNo));
                    JobTaskNo[i] := SelectionFilterManagement.AddQuotes(JobTask."Job Task No.");
                end;
            until JobTask.Next() = 0;

        Window.Close();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobTaskModify(var JobTask: Record "Job Task"; JobNo: Code[20]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeConfirm(var JobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;
}

