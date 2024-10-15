// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;
using Microsoft.Utilities;
using Microsoft.HumanResources.Absence;
using Microsoft.Projects.Project.Job;

page 948 "TimeSheet Line Details FactBox"
{
    PageType = CardPart;
    Caption = 'Time Sheet Line Details';
    Editable = false;
    LinksAllowed = false;
    ApplicationArea = Jobs;
    UsageCategory = None;
    SourceTable = "Time Sheet Line";

    layout
    {
        area(Content)
        {
            group(Comments)
            {
                Caption = 'Comments';
                field(CommentsExist; CommentsFieldValue)
                {
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        if CommentsFieldValue = '' then
                            exit;

                        ShowComments();
                    end;
                }
            }
            group(ResourceDetails)
            {
                Caption = 'Resource Details';
                Visible = WorkTypeCodeVisible;

                field(WorkTypeDescription; WorkTypeDescription)
                {
                    Editable = false;
                    Caption = 'Work Type Description';
                    ToolTip = 'Specifies a description of the work type.';
                }

            }
            group(JobDetails)
            {
                Caption = 'Project Details';
                Visible = JobFieldsVisible;

                field(JobName; JobName)
                {
                    Editable = false;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the project.';
                }
                field(JobTaskDescription; JobTaskDescription)
                {
                    Editable = false;
                    Caption = 'Task Description';
                    ToolTip = 'Specifies a description of the project task.';
                }

            }
            group(AbsenceDetails)
            {
                Caption = 'Absence Details';
                Visible = AbsenceCauseVisible;

                field(CauseOfAbsenceDescription; CauseOfAbsenceDescription)
                {
                    Editable = false;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the cause of absence.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not SkipOnAfterGetRecordUpdate then begin
            GlobalTimeSheetLine := Rec;
            UpdateData();
        end;
    end;

    var
        TimeSheetCommentLine: Record "Time Sheet Comment Line";
        TimeSheetCmtLineArchive: Record "Time Sheet Cmt. Line Archive";
        GlobalTimeSheetLine: Record "Time Sheet Line";
        WorkType: Record "Work Type";
        CauseOfAbsence: Record "Cause of Absence";
        Job: Record Job;
        JobTask: Record "Job Task";
        WorkTypeCodeVisible, JobFieldsVisible, AbsenceCauseVisible, IsArchive, SkipOnAfterGetRecordUpdate : Boolean;
        CommentsFieldValue, WorkTypeDescription, JobName, JobTaskDescription, CauseOfAbsenceDescription : Text;
        ViewCommentTxt: Label 'View Comments';

    procedure SetSource(var TimeSheetLine: Record "Time Sheet Line"; IsArchiveLine: Boolean);
    begin
        IsArchive := IsArchiveLine;
        SkipOnAfterGetRecordUpdate := true;
        Rec := TimeSheetLine;
        GlobalTimeSheetLine := TimeSheetLine;
        UpdateData();
    end;

    local procedure UpdateData()
    begin
        SetCommentDetails();
        SetWorkTypeDetails();
        SetJobDetails();
        SetAbsenceDetails();

        CurrPage.Update(false);
    end;

    local procedure SetCommentDetails()
    begin
        CommentsFieldValue := '';

        if IsArchive then begin
            TimeSheetCmtLineArchive.SetRange("No.", Rec."Time Sheet No.");
            TimeSheetCmtLineArchive.SetRange("Time Sheet Line No.", Rec."Line No.");
            if not TimeSheetCmtLineArchive.IsEmpty() then
                CommentsFieldValue := ViewCommentTxt;
        end else begin
            TimeSheetCommentLine.SetRange("No.", Rec."Time Sheet No.");
            TimeSheetCommentLine.SetRange("Time Sheet Line No.", Rec."Line No.");
            if not TimeSheetCommentLine.IsEmpty() then
                CommentsFieldValue := ViewCommentTxt;
        end;
    end;

    local procedure SetWorkTypeDetails()
    begin
        WorkTypeDescription := '';
        WorkTypeCodeVisible := Rec."Work Type Code" <> '';

        if Rec."Work Type Code" = '' then
            exit;

        if WorkType.Code <> Rec."Work Type Code" then
            WorkType.Get(Rec."Work Type Code");

        WorkTypeDescription := WorkType.Description;
    end;

    local procedure SetJobDetails()
    begin
        JobName := '';
        JobTaskDescription := '';
        JobFieldsVisible := Rec."Job No." <> '';

        if Rec."Job No." = '' then
            exit;

        if Job."No." <> Rec."Job No." then
            Job.Get(Rec."Job No.");

        JobName := Job.Description;

        if Rec."Job Task No." = '' then
            exit;

        if (JobTask."Job No." <> Rec."Job No.") or (JobTask."Job Task No." <> Rec."Job Task No.") then
            JobTask.Get(Rec."Job No.", Rec."Job Task No.");

        JobTaskDescription := JobTask.Description;
    end;

    local procedure SetAbsenceDetails()
    begin
        CauseOfAbsenceDescription := '';
        AbsenceCauseVisible := Rec."Cause of Absence Code" <> '';

        if Rec."Cause of Absence Code" = '' then
            exit;

        if CauseOfAbsence.Code <> Rec."Cause of Absence Code" then
            CauseOfAbsence.Get(Rec."Cause of Absence Code");

        CauseOfAbsenceDescription := CauseOfAbsence.Description;
    end;

    local procedure ShowComments()
    var
        TimeSheetCommentSheet: Page "Time Sheet Comment Sheet";
        TimeSheetArcCommentSheet: Page "Time Sheet Arc. Comment Sheet";
    begin
        if IsArchive then begin
            TimeSheetCmtLineArchive.SetRange("No.", GlobalTimeSheetLine."Time Sheet No.");
            TimeSheetCmtLineArchive.SetRange("Time Sheet Line No.", GlobalTimeSheetLine."Line No.");
            TimeSheetArcCommentSheet.SetTableView(TimeSheetCmtLineArchive);
            TimeSheetArcCommentSheet.RunModal();
        end else begin
            TimeSheetCommentLine.SetRange("No.", GlobalTimeSheetLine."Time Sheet No.");
            TimeSheetCommentLine.SetRange("Time Sheet Line No.", GlobalTimeSheetLine."Line No.");
            TimeSheetCommentSheet.SetTableView(TimeSheetCommentLine);
            TimeSheetCommentSheet.RunModal();
        end;
    end;
}